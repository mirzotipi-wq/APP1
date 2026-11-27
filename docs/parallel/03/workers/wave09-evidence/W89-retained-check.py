"""Bounded retained-data audit; never builds, runs XCTest, renders or benchmarks."""
import collections
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess

ROOT = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
PRIVATE = Path('/tmp/keyfill03-7f4b/workers/W89-platform-performance')
EVIDENCE = ROOT / 'docs/parallel/03/evidence'
OUT = Path(__file__).with_name('W89-platform-evidence.json')
BASE = 'a7c93be58a04154748c951b3d485b05300e9692c'
CPU = 'db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5'
NATIVE = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
CANDIDATE = '342e3280e3eb077d55e122c8bfb88b4062b431ed'
commands = []

def sha(data):
    return hashlib.sha256(data).hexdigest()

def git(*args, cwd=ROOT):
    result = subprocess.run(['git', *args], cwd=cwd, capture_output=True, check=True)
    commands.append({'argv': ['git', *args], 'cwd': str(cwd), 'exit': result.returncode,
                     'stdout_sha256': sha(result.stdout)})
    return result.stdout

def read(name):
    return json.loads((EVIDENCE / name).read_text())

assert git('rev-parse', 'HEAD', cwd=PRIVATE).decode().strip() == BASE
assert not git('status', '--short', cwd=PRIVATE).strip()
core_trees = {rev: git('rev-parse', f'{rev}:Sources/LightingCore').decode().strip()
              for rev in [CPU, NATIVE, BASE, CANDIDATE]}
assert len(set(core_trees.values())) == 1
manifest = read('final-source-manifest.json')['sourceSHA256']
core = {p: h for p, h in manifest.items() if p.startswith('Sources/LightingCore/')}
assert len(core) == 31
assert all(sha((ROOT / p).read_bytes()) == h for p, h in core.items())

native = read('ci-native-36.json')
native_bytes = (EVIDENCE / 'ci-native-36.log').read_bytes()
assert sha(native_bytes) == native['logSHA256']
log = native_bytes.decode()
events = collections.defaultdict(list)
for cls, method, event in re.findall(r"^\S+Z Test Case '-\[KeyAndFillTests\.(\w+) (test\w+)\]' (started|passed|failed|skipped)\b", log, re.M):
    events[f'{cls}.{method}'].append(event)
assert len(events) == 164 and all(v == ['started', 'passed'] for v in events.values())
pipeline = [k.split('.', 1)[1] for k in events if k.startswith('StudyPreviewPipelineTests.')]
assert sorted(pipeline) == sorted(native['previewPipelineMethodsPassed']) and len(pipeline) == 10
metal = re.findall(r'^\S+Z Metal ([\w-]+): mean ([\d.e+-]+), max (\d+), outliers ([\d.e+-]+), invalid match (true|false)$', log, re.M)
assert [x[0] for x in metal] == [x['name'] for x in native['actualSimulatorMetalFixtures']]
assert len(metal) == 6 and max(int(x[2]) for x in metal) == 1
source_paths = ['NativeTests/StudyRendererTests.swift', 'Sources/LightingCore/StudyValidationFixtures.swift',
                'NativeTests/StudyPreviewPipelineTests.swift', 'App/StudyKernel.h', 'scripts/benchmark-study.swift']
source_hashes = {}
for path in source_paths:
    before = git('show', f'{NATIVE}:{path}')
    after = git('show', f'{CANDIDATE}:{path}')
    assert before == after
    source_hashes[path] = sha(before)

host = {}
for name, count in [('final-kernel.log', 6), ('final-precision.log', 8)]:
    rows = (EVIDENCE / name).read_text().splitlines()
    assert len(rows) == count and all(x.endswith(', PASS') and 'invalid-mask-mismatches=0' in x for x in rows)
    host[name] = {'cases': count, 'zero_mask_mismatches': True,
                  'invalid_counts': re.findall(r'invalid=(\d+/\d+)', '\n'.join(rows))}
assert all('max-limit=1' in x for x in (EVIDENCE / 'final-precision.log').read_text().splitlines())
parity = read('final-parity-inputs.json')
assert all(sha((EVIDENCE / p).read_bytes()) == h for p, h in parity['fixtures'].items())
assert all(sha((ROOT / p).read_bytes()) == h for p, h in parity['sourceSHA256'].items())

bench = read('final-benchmark.json')
binding = read('final-benchmark-inputs.json')
assert sha((EVIDENCE / 'final-benchmark.json').read_bytes()) == binding['benchmarkSHA256']
assert binding['actualSourceCommit'] == CPU and bench['sourceRevision'].startswith('74f7584')
assert [len(bench[k]) for k in ['frames', 'cancellation', 'visibility']] == [8, 12, 4]
assert bench['optimizedBuild'] and bench['measuredSamplesPerWorkload'] == 7
for row in bench['frames'] + bench['visibility']:
    timing = row['timing']; values = sorted(timing['samplesMilliseconds'])
    assert len(values) == 7
    assert timing['p50Milliseconds'] == values[math.ceil(7 * .5) - 1]
    assert timing['p95Milliseconds'] == values[math.ceil(7 * .95) - 1]
assert all(x['unsupportedPixels'] == 0 for x in bench['frames'])
assert all(x['cancelled'] and x['observedAtMilliseconds'] is not None for x in bench['cancellation'])

ui = read('ci-ui-failures-36.json')
for item in ui['logs']:
    assert sha((ROOT / item['path']).read_bytes()) == item['sha256']
ui_log = (EVIDENCE / 'ci-ui-library-reference-36.log').read_text()
ui_events = collections.defaultdict(list)
for cls, method, event in re.findall(r"^\S+Z Test Case '-\[KeyAndFillUITests\.(\w+) (test\w+)\]' (started|passed|failed|skipped)\b", ui_log, re.M):
    ui_events[f'{cls}.{method}'].append(event)
failed = [k for k, v in ui_events.items() if v == ['started', 'failed']]
reference = [k for k, v in ui_events.items() if k.startswith('ReferenceComparisonUITests.') and v == ['started', 'passed']]
assert len(ui_events) == 9 and len(failed) == 2 and len(reference) == 2
for file in ['ci-visual-default-36.log', 'ci-visual-axxxl-36.log']:
    assert 'Artifact not found for name: ui-app-accessibility-evidence-compact' in (EVIDENCE / file).read_text()
adoption = read('preview-adoption-inputs.json')
assert sha(git('show', f'{CANDIDATE}:App/ReferenceStudyPreview.swift')) == adoption['preview_sha256']
assert sha(git('show', f'{CANDIDATE}:NativeTests/StudyPreviewAdoptionTests.swift')) == adoption['new_hosted_test_sha256']
assert adoption['discovered_native_methods'] == 165

references = ['ci-native-36.json', 'ci-native-36.log', 'ci-ui-failures-36.json',
              'ci-ui-library-reference-36.log', 'ci-visual-default-36.log', 'ci-visual-axxxl-36.log',
              'final-parity-inputs.json', 'final-kernel.log', 'final-precision.log',
              'final-benchmark.json', 'final-benchmark-inputs.json', 'final-source-manifest.json',
              'preview-adoption-inputs.json']
receipt = {
    'runtime_id': '/root/wave09/w89_platform_performance', 'role': 'platform/performance',
    'input_commit': BASE, 'private_worktree': str(PRIVATE), 'candidate_commit': CANDIDATE,
    'execution': 'Python retained-data assertions only; no build/test/render/benchmark execution',
    'command': f'python3 {Path(__file__)}', 'script_sha256': sha(Path(__file__).read_bytes()),
    'commands': commands, 'core_trees': core_trees, 'core_manifest_hashes_checked': 31,
    'tested_source_hashes_unchanged_at_candidate': source_hashes,
    'native': {'source': NATIVE, 'run': native['runID'], 'job': native['jobID'],
               'methods_started_then_passed_once': 164, 'pipeline_methods': pipeline,
               'actual_simulator_metal_cases': [x[0] for x in metal], 'maximum_observed_channel_error': 1,
               'exact_masks': 'Executed test asserts metrics.passes; source36 predicate requires invalidMaskMatches, assigned full Data equality. Printed invalid-match flag alone proves only count equality.'},
    'host': host,
    'benchmark': {'compiled_source': CPU, 'raw_revision_preserved': bench['sourceRevision'],
                  'frame_workloads': 8, 'cancellation_probes': 12, 'visibility_workloads': 4,
                  'measured_samples_per_workload': 7, 'timed_samples': 84,
                  'all_retained_percentiles_match': True, 'all_cancellation_observed': True,
                  'all_frame_unsupported_counts_zero': True,
                  'limits': 'Source enforces image equality against warmup; JSON retains one FNV hash per workload, not all repeated bytes. Optimized historical host diagnostics; no portable timing threshold.'},
    'ui': {'actual_events': dict(ui_events), 'failed_methods': failed, 'reference_methods': reference,
           'receipt_label_correction': 'Initial ReferencePhotoUITests label contradicted terminals. W89 notified W81; root corrected to ReferenceComparisonUITests and preserved original receipt provenance.',
           'visual_reviews_completed': False, 'visual_terminal': 'Missing artifact from cancelled app-accessibility shard; no layout result.'},
    'candidate': {'preview_sha256': adoption['preview_sha256'],
                  'W84_preview_sha256': adoption['W84_candidate_preview_sha256'],
                  'hosted_test_sha256': adoption['new_hosted_test_sha256'],
                  'inventory_only': 165, 'native_status': 'pending',
                  'run_reported_by_parent': 45857561126,
                  'coverage_limits': 'Hosted test scripts backend labels/policy with synthetic outputs; it tests real hosted consumer sequencing only if executed successfully. No real engine downgrade, device or actual Metal claim.'},
    'artifact_references': [{'path': f'docs/parallel/03/evidence/{p}', 'sha256': sha((EVIDENCE / p).read_bytes())} for p in references],
    'limits': ['No whole-M03 pass: required library/UI/visual evidence failed or cancelled.',
               'Source36 verifies its own kernel; changed lane04 kernel remains outside this evidence.',
               'No physical calibration, device timing, thermal/RSS, sustained FPS, or manual VoiceOver claim.',
               'Initial guessed NativeTests/StudyMetalRendererTests.swift lookup exited2; actual StudyRendererTests.swift subsequently read.',
               'Qualitative 60% checkpoint sent; exact token counters unavailable.']
}
OUT.write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps({'receipt': str(OUT), 'native': len(events), 'pipeline': len(pipeline),
                  'metal': len(metal), 'host_cases': [6, 8], 'benchmark_workloads': [8, 12, 4],
                  'ui_methods': len(ui_events), 'ui_failures': len(failed), 'candidate_native': 'pending'}))
