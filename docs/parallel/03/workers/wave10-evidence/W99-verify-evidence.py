#!/usr/bin/env python3
"""Read retained CI/benchmark evidence; writes only the W99 reconciliation JSON.

No Swift, XCTest, renderer, benchmark, CI poll, cleanup or source mutation runs.
"""
import collections
import datetime
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess

REPO = Path(__file__).resolve().parents[5]
SOURCE = Path('/tmp/keyfill03-7f4b/workers/W99-platform-performance')
EVIDENCE = REPO / 'docs/parallel/03/evidence'
CURRENT = '342e3280e3eb077d55e122c8bfb88b4062b431ed'
PREVIOUS = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
EARLIER = 'ace9f2eba068bc31dd04bb2f1e2028af315d6bdb'
CPU = 'db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5'
hashes = {}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def read(name):
    path = EVIDENCE / name
    data = path.read_bytes()
    hashes[str(path.relative_to(REPO))] = digest(data)
    return data.decode()


def receipt(name):
    return json.loads(read(name))


def git(*args):
    return subprocess.check_output(['git', '-C', str(SOURCE), *args], text=True).strip()


def inventory(revision, directory):
    methods = set()
    for file in git('ls-tree', '-r', '--name-only', revision, directory).splitlines():
        if not file.endswith('.swift'):
            continue
        content = git('show', f'{revision}:{file}')
        found = re.findall(r'\bfunc\s+(test\w*)\s*\(', content)
        if not found:
            continue
        classes = re.findall(r'\bclass\s+(\w+)\s*:\s*XCTestCase\b', content)
        assert len(classes) == 1 and len(set(found)) == len(found), file
        for name in found:
            qualified = classes[0] + '.' + name
            assert qualified not in methods, qualified
            methods.add(qualified)
    return methods


def events(content, target):
    result = collections.defaultdict(list)
    pattern = r"Test Case '-\[" + re.escape(target) + r"\.(\w+) (\w+)\]' (started|passed|failed|skipped)"
    for cls, method, event in re.findall(pattern, content):
        result[cls + '.' + method].append(event)
    return dict(result)


def native(revision, receipt_name, log_name, count):
    meta = receipt(receipt_name)
    raw = read(log_name)
    assert digest(raw.encode()) == meta['logSHA256']
    expected = inventory(revision, 'NativeTests')
    observed = events(raw, 'KeyAndFillTests')
    assert len(expected) == count and set(observed) == expected
    assert all(sequence == ['started', 'passed'] for sequence in observed.values())
    metal = re.findall(r'Metal ([\w-]+): mean ([0-9.e-]+), max (\d+), outliers ([0-9.e-]+), invalid match (true|false)', raw)
    assert len(metal) == 6 and all(float(x[1]) <= 1 and int(x[2]) <= 1 and float(x[3]) <= .005 and x[4] == 'true' for x in metal)
    assert '** TEST BUILD SUCCEEDED **' in raw and '** BUILD SUCCEEDED **' in raw
    parity_source = git('show', f'{revision}:Sources/LightingCore/StudyValidationFixtures.swift')
    native_source = git('show', f'{revision}:NativeTests/StudyRendererTests.swift')
    assert 'invalidCountMatches && invalidMaskMatches && meanChannelError <= 1' in parity_source
    assert 'XCTAssertTrue(metrics.passes' in native_source
    return {'source': revision, 'method_count': count, 'started': count, 'passed': count,
            'failures': 0, 'skips': 0, 'duplicates': 0, 'omissions': 0,
            'expected_methods': sorted(expected),
            'pipeline_methods': sorted(x for x in expected if x.startswith('StudyPreviewPipelineTests.')),
            'actual_simulator_metal_fixtures': [{'name': a, 'mean': float(b), 'max': int(c), 'fraction_above_four': float(d), 'invalid_count_match': e == 'true'} for a, b, c, d, e in metal],
            'exact_masks': 'Successful StudyRendererTests.testMetalMatchesCPUOnAvailableDevice asserts StudyParityMetrics.passes; its predicate requires invalidMaskMatches in addition to printed invalid-count agreement.',
            'debug_app_and_test_build': 'success', 'release_app_build': 'success',
            'portable_391_summary_present': 'Executed 391 tests, with 0 failures' in raw,
            'toolchain': 'Apple Swift 6.3.3; Xcode 26.6; x86_64 macOS 26.6.1',
            'raw_log': str((EVIDENCE / log_name).relative_to(REPO))}


assert git('rev-parse', 'HEAD') == CURRENT
core = receipt('ci-core-342.json')
core_raw = read('ci-core-342.log')
assert core['source'] == CURRENT
assert digest(core_raw.encode()) == core['raw_log_sha256'] == '126ab3bcfa0ec05f7b2c5c9ab410d68cded5073aa2c5a9d7fefe311769097384'
summaries = re.findall(r'Executed 391 tests, with (\d+) failures \(0 unexpected\) in ([0-9.]+)', core_raw)
assert summaries == [('0', '13.234'), ('0', '13.234'), ('0', '5.368'), ('0', '5.368')]
parity = [x for x in core_raw.splitlines() if '/kernel-fixtures/' in x and x.endswith('PASS')]
precision = [x for x in core_raw.splitlines() if '/precision-boundary/' in x and x.endswith('PASS')]
assert len(parity) == 6 and len(precision) == 8
assert all('invalid-mask-mismatches=0' in x for x in parity + precision)
assert 'swift test --configuration release --jobs 2' in core_raw
native36 = native(PREVIOUS, 'ci-native-36.json', 'ci-native-36.log', 164)
assert len(native36['pipeline_methods']) == 10 and native36['portable_391_summary_present']
native_earlier = native(EARLIER, 'ci-native-ace9.json', 'ci-native-ace9.log', 163)
assert len(native_earlier['pipeline_methods']) == 9
current_inventory = inventory(CURRENT, 'NativeTests')
assert len(current_inventory) == 165
assert current_inventory - set(native36['expected_methods']) == {'StudyPreviewAdoptionTests.testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade'}

old_ui = receipt('ci-ui-failures-36.json')
old_ui_raw = read('ci-ui-library-reference-36.log')
old_ui_events = events(old_ui_raw, 'KeyAndFillUITests')
assert len(old_ui_events) == 9
assert sum(v == ['started', 'failed'] for v in old_ui_events.values()) == 2
assert sum(v == ['started', 'passed'] for v in old_ui_events.values()) == 7
assert len([k for k in old_ui_events if k.startswith('ProjectLibraryUITests.')]) == 7
assert len([k for k, v in old_ui_events.items() if k.startswith('ReferenceComparisonUITests.') and v == ['started', 'passed']]) == 2
assert 'ReferenceComparisonUITests' in old_ui['actual_ui_results'] and 'ReferencePhotoUITests' not in old_ui['actual_ui_results']
for item in old_ui['logs']:
    assert digest((REPO / item['path']).read_bytes()) == item['sha256']
for name in ['ci-visual-axxxl-36.log', 'ci-visual-default-36.log']:
    assert 'Artifact not found for name: ui-app-accessibility-evidence-compact' in read(name)

build = receipt('ci-apple-build-342.json')
latest_ui = receipt('ci-ui-studio-optics-342.json')
latest_ui_raw = read('ci-ui-studio-optics-342.log')
assert digest(latest_ui_raw.encode()) == latest_ui['raw_log_sha256']
assert build['build_step']['conclusion'] == 'success'
assert '** TEST BUILD SUCCEEDED **' in latest_ui_raw
assert 'SwiftCompile normal x86_64 /Users/runner/work/APP1/APP1/NativeTests/StudyPreviewAdoptionTests.swift' in latest_ui_raw
assert not events(latest_ui_raw, 'KeyAndFillUITests')
optics_inventory = {m for m in inventory(CURRENT, 'UITests') if m.startswith('StudioOpticsUITests.')}
assert len(optics_inventory) == 10 and optics_inventory == set(latest_ui['unstarted_methods'])
assert 'recovery-preflight did not complete successfully before its deadline (status=timed_out, exit=-9)' in latest_ui_raw
assert 'XCTDaemonErrorDomain Code=18' in latest_ui_raw and 'Timed out waiting for AX loaded notification' in latest_ui_raw
assert 'Process completed with exit code 65.' in latest_ui_raw
project = (SOURCE / 'project.yml').read_text()
assert '- KeyAndFillTests' in project and '- KeyAndFillUITests' in project

benchmark = receipt('final-benchmark.json')
inputs = receipt('final-benchmark-inputs.json')
assert hashes['docs/parallel/03/evidence/final-benchmark.json'] == inputs['benchmarkSHA256']
assert inputs['actualSourceCommit'] == CPU
assert benchmark['sourceRevision'] == '74f7584b4e474c752ec0939add6b7522ba98094f'
bound = {path: digest((SOURCE / path).read_bytes()) for path in inputs['sourceSHA256']}
assert bound == inputs['sourceSHA256']
core_manifest = receipt('final-source-manifest.json')
core_paths = {p: h for p, h in core_manifest['sourceSHA256'].items() if p.startswith('Sources/LightingCore/')}
assert len(core_paths) == 31 and all(digest((SOURCE / p).read_bytes()) == h for p, h in core_paths.items())
unchanged = git('diff', '--name-only', CPU, CURRENT, '--', 'Sources/LightingCore', 'Tests/LightingCoreTests', 'scripts/benchmark-study.swift')
assert not unchanged
assert benchmark['optimizedBuild'] and benchmark['measuredSamplesPerWorkload'] == 7
assert len(benchmark['frames']) == 8 and len(benchmark['visibility']) == 4 and len(benchmark['cancellation']) == 12
assert {x['name'] for x in benchmark['frames']} == {f'{s}-{k}-{w}' for s in ['sphere', 'bust'] for k in ['point3', 'area3'] for w in [72, 144]}
timings = []
for category in ['frames', 'visibility']:
    for workload in benchmark[category]:
        samples = workload['timing']['samplesMilliseconds']
        assert len(samples) == 7 and all(math.isfinite(v) and v > 0 for v in samples)
        ordered = sorted(samples)
        p50, p95 = ordered[math.ceil(.5 * len(samples))-1], ordered[math.ceil(.95 * len(samples))-1]
        assert p50 == workload['timing']['p50Milliseconds'] and p95 == workload['timing']['p95Milliseconds']
        timings.append({'category': category, 'name': workload['name'], 'visibility_enabled': workload.get('visibilityEnabled'), 'samples': len(samples), 'p50_ms': p50, 'p95_ms': p95})
assert sum(x['samples'] for x in timings) == 84
assert all(x['unsupportedPixels'] == 0 and x['warmupMilliseconds'] > 0 for x in benchmark['frames'])
assert all(x['evaluationsPerSample'] == 1000 and x['receivers'] == 34 for x in benchmark['visibility'])
probes = benchmark['cancellation']
assert collections.Counter((x['name'], x['requestedAfterMilliseconds']) for x in probes) == collections.Counter({(name, deadline): 3 for name in ['bust-area3-144', 'bust-area12-144'] for deadline in [5, 25]})
for probe in probes:
    assert probe['cancelled'] and probe['observedAtMilliseconds'] is not None
    assert probe['precedingCheckAtMilliseconds'] < probe['requestedAfterMilliseconds'] <= probe['observedAtMilliseconds'] <= probe['finishedAfterMilliseconds']
    assert math.isclose(probe['finishedAfterMilliseconds'] - probe['requestedAfterMilliseconds'], probe['deadlineToReturnMilliseconds'], abs_tol=1e-12)
max_cancel = max(x['deadlineToReturnMilliseconds'] for x in probes)
assert math.isclose(max_cancel, 1.606625, abs_tol=1e-12)
benchmark_source = (SOURCE / 'scripts/benchmark-study.swift').read_text()
assert 'guard image == warmup, image.unsupportedPixels == 0' in benchmark_source
assert '_ = try operation()' in benchmark_source
local = receipt('wave05-test-inputs.json')
retained = []
for attempt in local['failedAttempts']:
    raw = read(attempt['log'])
    retained.append({**attempt, 'bytes': len(raw.encode())})
assert any(x['bytes'] == 0 and 'exit1' in x['result'] for x in retained)
assert 'signal 9' in read('wave05-release.log') and "ambiguous use of 'pow'" in read('wave05-debug-serial.log')
for file in ['camera-original-tests.log', 'camera-corrected-tests.log']:
    assert "failed (" in read(file)

report = {
    'schema': 1, 'worker': 'W99 platform/performance', 'runtime_id': '/root/wave10/w99_platform_performance',
    'source': CURRENT, 'private_source_tree': str(SOURCE), 'durable_repository': str(REPO),
    'documentation_base': subprocess.check_output(['git', '-C', str(REPO), 'rev-parse', 'HEAD'], text=True).strip(),
    'review_kind': 'Independent read-only source/artifact reconciliation; no fresh product execution.',
    'reviewed_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'coordinator_followup': {'published_documentation_revision': '5c266d8ced40731a992c9717111a0f5ed5579082', 'source_change': False, 'native_job_status': 'Root reports Debug app/native-bundle build passed and Release simulator app build in progress; no 165-method runtime result. Not independently polled by W99.'},
    'core342': {'receipt': 'docs/parallel/03/evidence/ci-core-342.json', 'run': core['run_id'], 'job': core['job_id'], 'debug': core['debug'], 'standard_release': core['standard_release'], 'host_parity': len(parity), 'precision': len(precision), 'summary_repeat_scope': 'Two summary lines per configuration are nested suite totals, not additional executions.', 'host': 'Ubuntu 24.04.5 LTS; x86_64', 'compiler': 'Swift 6.4.2', 'linux_syntax_scope': 'Parsing does not typecheck UIKit/SwiftUI or execute hosted tests.'},
    'apple342': {'build': build, 'native_methods_discovered': len(current_inventory), 'native_job': 140042273149, 'native_execution_status': latest_ui['native_status_at_observation'], 'native_pass_claimed': False, 'latest_required_ui': latest_ui, 'source_scheme_contains_native_and_ui_targets': True},
    'native36': native36, 'historical_native_ace9': native_earlier,
    'ui36': {'receipt': 'docs/parallel/03/evidence/ci-ui-failures-36.json', 'method_events': old_ui_events, 'receipt_correction': old_ui['receipt_correction'], 'dependent_visual_jobs_failed': 2, 'visual_review_completed': False},
    'benchmark': {'actual_compiled_source': CPU, 'raw_revision': benchmark['sourceRevision'], 'raw_sha256': inputs['benchmarkSHA256'], 'bound_source_hashes': bound, 'current_core_hashes_matched': len(core_paths), 'cpu_diff_db7_to_current': [], 'configuration': inputs['compile'], 'arguments': inputs['arguments'], 'compiler': local['platform'], 'compiler_evidence': 'docs/parallel/03/evidence/wave05-test-inputs.json and final-source-manifest.json; raw benchmark does not emit compiler version.', 'host': {k: benchmark[k] for k in ['architecture', 'cpuModel', 'operatingSystem', 'reportedProcessors', 'reportedActiveProcessors']}, 'frame_workloads': 8, 'visibility_workloads': 4, 'warmups': 12, 'samples_per_timed_workload': 7, 'total_measured_timing_samples': 84, 'recomputed_timings': timings, 'separate_cancellation_probes': 12, 'all_cancellation_observed': True, 'max_deadline_to_return_ms': max_cancel, 'repeated_frame_check': 'Source compares each complete image against its warm-up; report exists only after checks succeed. JSON retains one RGBA hash per workload, not seven output hashes.', 'unsupported_frame_pixels': 0, 'configuration_distinction': 'Historical local per-file optimized build after signal9 differs from standard SwiftPM Release in source342 CI.', 'device_fps_rss_thermal_or_metal_claim': False},
    'hosted_adoption_scope': {'source_review_only': True, 'one_mounted_identity': True, 'controlled_continuations': True, 'positive_ax_control': True, 'synthetic_outputs': True, 'real_gpu_downgrade_or_pause_reattachment_or_actual_cancellation_delivery_proven': False, 'current_runtime_result': 'pending', 'original_hook_only_before_fail': 'UNRUN'},
    'retained_local_failures': retained,
    'retained_camera_probe_failures': ['docs/parallel/03/evidence/camera-original-tests.log', 'docs/parallel/03/evidence/camera-corrected-tests.log'],
    'handoff_corrections_sent': ['Latest source342 UI log is now retrieved: retain raw Apple build success and zero-start/ten-unstarted optics failure. Replace stale full-log-unretrieved text, with native165 still pending/in progress.', 'Current source36 UI class is ReferenceComparisonUITests; correction and original committed history are preserved.'],
    'commands_run': ['Read-only git status/log/show/ls-tree/diff, rg/cat/sed, SHA-256 and Python raw-log/benchmark parser', 'python3 docs/parallel/03/workers/wave10-evidence/W99-verify-evidence.py'],
    'not_run': ['Swift tests', 'Apple tests', 'new benchmark or render', 'CI polling', 'cleanup', 'commit or push', 'agent-cycle gates already owned by coordinator'],
    'read_attempts': ['Initial evidence/ path omitted docs/parallel/03; corrected.', 'Guessed StudyParityMetrics.swift/StudyMetalRendererTests.swift and prior W89 JSON paths absent; rg located actual sources. No product execution occurred.'],
    'local_verifier_correction': 'First whitespace-check wrapper mistakenly required exit0 from git diff --no-index --check; it returned1 for new-file difference with no diagnostics. Corrected wrapper accepts0/1 only with empty diagnostics and checks trailing whitespace and final newline explicitly. No product test failed or reran.',
    'checkpoint': 'Qualitative checkpoint sent to leader; exact token counters unavailable.',
    'global_m02_m03_or_release_promotion': False,
    'verification_status': 'PASS_RETAINED_EVIDENCE_ACCOUNTING', 'evidence_sha256': hashes,
}
destination = Path(__file__).with_name('W99-platform-performance.json')
destination.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'result': report['verification_status'], 'core_tests_per_configuration': 391, 'native36': 164, 'native_current': 'pending', 'current_optics_started': 0, 'current_optics_unstarted': 10, 'timing_samples': 84, 'cancellation_probes': 12, 'maximum_deadline_to_return_ms': max_cancel, 'receipt': str(destination)}))
