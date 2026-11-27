#!/usr/bin/env python3
"""Independent, bounded archive audit. Does not execute Swift or edit shared files."""
import collections
import datetime
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[5]
LANE = ROOT / 'docs/parallel/03'
WORKERS = LANE / 'workers'
PRIVATE = Path('/tmp/keyfill03-7f4b/workers/W100-independent-review')
SOURCE = '342e3280e3eb077d55e122c8bfb88b4062b431ed'
CPU = 'db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5'
PRIOR = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
failures = []
commands = []

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def read(path):
    return json.loads((ROOT / path).read_text())

def check(name, condition):
    if not condition:
        failures.append(name)
    return bool(condition)

def git(*args, cwd=ROOT):
    result = subprocess.run(['git', *args], cwd=cwd, capture_output=True,
                            env={**os.environ, 'GIT_NO_LAZY_FETCH': '1'})
    commands.append({'argv': ['git', *args], 'cwd': str(cwd), 'exit': result.returncode})
    check('git command: ' + ' '.join(args), result.returncode == 0)
    return result.stdout

roles = ['acceptance', 'geometrydata', 'api', 'implementation', 'concurrency',
         'resource', 'consumer', 'accessibilityprivacy', 'platformperformance',
         'independentreview']
aggregate = read('docs/parallel/03/WORKER_LEDGER.json')
indexed = {x['worker_number']: x for x in aggregate['workers']}
rows, waves, sources = [], [], set()
recorded_hash_count = 0
for wave in range(1, 11):
    ledger = WORKERS / f'wave{wave:02}.json'
    data = json.loads(ledger.read_text())
    wave_roles = []
    for original in data['workers']:
        number = int(re.match(r'W(\d+)', original['worker'])[1])
        label = f'W{number:02}'
        runtime = original.get('actual_runtime_id', original.get('runtime_id', original.get('runtimeID')))
        canonical = original.get('canonical_task_path', original.get('canonicalTaskPath'))
        role = re.sub('[^a-z]', '', original['role'].lower())
        role = 'geometrydata' if role == 'geometry' else role
        source = original.get('input_sha', original.get('inputSHA', data.get('input_sha', data.get('inputCommit', data.get('initial_input_sha')))))
        private = original.get('private_worktree', original.get('privateWorktree'))
        status = original.get('execution_status', original.get('status', original.get('executionStatus')))
        raw_report = original.get('report', original.get('output_report'))
        report = Path(raw_report)
        if not report.is_absolute():
            report = ROOT / report if str(report).startswith('docs/') else WORKERS / report
        report_hash = sha(report) if report.is_file() else None
        supplied = original.get('report_sha256', original.get('reportSHA256'))
        recorded_hash_count += bool(supplied)
        check(label + ' role/wave', (number-1)//10+1 == wave and roles[(number-1)%10] == role)
        check(label + ' runtime', canonical == runtime and (runtime == f'/root/wave{wave:02}' or runtime.startswith(f'/root/wave{wave:02}/')))
        check(label + ' input identity', re.fullmatch('[0-9a-f]{40}', source))
        check(label + ' worktree identity', re.match(rf'W0*{number}-', Path(private).name))
        check(label + ' supplied report hash', not supplied or supplied == report_hash)
        relative = str(report.relative_to(ROOT))
        for key, value in [('actual_runtime_id', runtime), ('input_sha', source),
                           ('private_worktree', private), ('primary_report', relative),
                           ('primary_report_sha256', report_hash)]:
            check(label + ' aggregate ' + key, indexed[number].get(key) == value)
        if supplied:
            check(label + ' normalized supplied hash', indexed[number]['recorded_report_sha256'] == supplied)
        sources.add(source)
        if original.get('resumed_input_sha'):
            sources.add(original['resumed_input_sha'])
        rows.append({'worker': label, 'number': number, 'wave': wave, 'role': role,
                     'actual_runtime_id': runtime, 'input_sha': source,
                     'resumed_input_sha': original.get('resumed_input_sha'),
                     'private_worktree': private, 'primary_report': relative,
                     'primary_report_sha256': report_hash,
                     'completed': status.startswith('complete') and report_hash is not None})
        wave_roles.append(role)
    check(f'wave{wave:02} ten roles', len(wave_roles) == 10 and set(wave_roles) == set(roles))
    waves.append({'wave': wave, 'contexts': len(wave_roles), 'distinct_roles': len(set(wave_roles))})
check('exact worker numbers', sorted(x['number'] for x in rows) == list(range(1, 101)))
for key in ['actual_runtime_id', 'private_worktree', 'primary_report']:
    check('unique ' + key, len({x[key] for x in rows}) == 100)
check('root excluded', all(x['actual_runtime_id'] != '/root' for x in rows))
for source in sorted(sources):
    check('commit type ' + source, git('cat-file', '-t', source).strip() == b'commit')
prior = read('docs/parallel/03/evidence/worker-ledger-through-wave06.json')
for original in prior['workers']:
    number = int(re.match(r'W(\d+)', original['worker'])[1])
    row = next(r for r in rows if r['number'] == number)
    check(f'prior W{number:02}', row['actual_runtime_id'] == original['actualRuntimeID'] and row['primary_report_sha256'] == original['reportSHA256'])

check('private HEAD', git('rev-parse', 'HEAD', cwd=PRIVATE).decode().strip() == SOURCE)
check('private clean', git('status', '--short', cwd=PRIVATE).strip() == b'')
check('CPU/tests/scripts unchanged', git('diff', '--name-only', CPU, SOURCE, '--', 'Sources', 'Tests', 'scripts').strip() == b'')
manifest = read('docs/parallel/03/evidence/final-source-manifest.json')
core = {p: value for p, value in manifest['sourceSHA256'].items() if p.startswith('Sources/LightingCore/')}
check('31 core inputs', len(core) == 31)
for path, value in core.items():
    check('core hash ' + path, sha(PRIVATE / path) == value)
adoption = read('docs/parallel/03/evidence/preview-adoption-inputs.json')
bound_sources = {'App/ReferenceStudyPreview.swift': adoption['preview_sha256'],
                 'NativeTests/StudyPreviewAdoptionTests.swift': adoption['new_hosted_test_sha256'],
                 'NativeTests/StudyPreviewPipelineTests.swift': adoption['pipeline_test_sha256']}
for path, value in bound_sources.items():
    check('preview hash ' + path, sha(PRIVATE / path) == value)
pipeline_file = 'NativeTests/StudyPreviewPipelineTests.swift'
check('complete pipeline tests source36 identical', git('show', PRIOR + ':' + pipeline_file) == (PRIVATE / pipeline_file).read_bytes())
current_preview = (PRIVATE / 'App/ReferenceStudyPreview.swift').read_text()
old_preview = git('show', PRIOR + ':App/ReferenceStudyPreview.swift').decode()
def pipeline_body(text):
    return text.split('@MainActor final class StudyPreviewPipeline', 1)[1].split('\n#if canImport(SwiftUI)', 1)[0]
check('pipeline source36 identical', pipeline_body(current_preview) == pipeline_body(old_preview))

api = read('docs/parallel/03/workers/wave10-evidence/W93-api.json')
image_checks = []
for item in api['ordinarySyntheticImages']:
    name = item['name']
    orig, final = LANE / 'evidence/original', LANE / 'evidence/final'
    for suffix in ['json', 'png', 'ppm']:
        check(name + ' preserved ' + suffix, (orig / f'{name}.{suffix}').read_bytes() == (final / f'{name}.{suffix}').read_bytes())
    mask = (final / f'{name}.mask').read_bytes()
    rgba = (final / f'{name}.rgba').read_bytes()
    check(name + ' final mask', len(mask) == item['width'] * item['height'] and set(mask) == {0})
    check(name + ' alpha', len(rgba) == 4 * len(mask) and set(rgba[3::4]) == {255})
    original_raw_absent = not (orig / f'{name}.mask').exists() and not (orig / f'{name}.rgba').exists()
    check(name + ' original raw limitation', original_raw_absent)
    image_checks.append({'name': name, 'final_mask_nonzero': sum(bool(v) for v in mask), 'alpha_values': sorted(set(rgba[3::4])), 'original_raw_absent': original_raw_absent})
check('twelve ordinary', len(image_checks) == 12)
for kind, count in [('requiredHostParity', 6), ('requiredPrecision', 8), ('supplementalPrecisionDiagnostics', 25)]:
    check(kind + ' inventory', len(api[kind]) == count)
    for item in api[kind]:
        check('fixture hash ' + item['name'], sha(ROOT / item['path']) == item['sha256'])

core_ci = read('docs/parallel/03/evidence/ci-core-342.json')
core_log = (ROOT / core_ci['raw_log']).read_text()
check('core CI raw hash', sha(ROOT / core_ci['raw_log']) == core_ci['raw_log_sha256'])
core391 = re.findall(r'Executed 391 tests, with 0 failures', core_log)
check('core 391 Debug and Release summaries', len(core391) >= 2)
native_ci = read('docs/parallel/03/evidence/ci-native-36.json')
native_log = LANE / 'evidence/ci-native-36.log'
check('native36 raw hash', sha(native_log) == native_ci['logSHA256'])
native_events = re.findall(r"^\S+ Test Case '-\[KeyAndFillTests\.(\w+) (\w+)\]' (started|passed|failed|skipped)\b", native_log.read_text(), re.M)
native_counts = collections.Counter(event for cls, method, event in native_events)
check('164 native starts/passes only', dict(native_counts) == {'started': 164, 'passed': 164})
pipeline_passes = [method for cls, method, event in native_events if cls == 'StudyPreviewPipelineTests' and event == 'passed']
check('ten native pipeline passes', len(pipeline_passes) == 10 and set(pipeline_passes) == set(native_ci['previewPipelineMethodsPassed']))
ui_ci = read('docs/parallel/03/evidence/ci-ui-studio-optics-342.json')
ui_log = (ROOT / ui_ci['raw_log']).read_text()
check('current UI raw hash', sha(ROOT / ui_ci['raw_log']) == ui_ci['raw_log_sha256'])
ui_starts = re.findall(r"^\S+ Test Case '-\[KeyAndFillUITests\.StudioOpticsUITests \w+\]' started", ui_log, re.M)
check('current UI zero starts ten unstarted', len(ui_starts) == 0 and ui_ci['ui_method_starts'] == 0 and len(ui_ci['unstarted_methods']) == 10)
check('current test build succeeded', 'TEST BUILD SUCCEEDED' in ui_log and 'Compiling\\ StudyPreviewAdoptionTests.swift' in ui_log or 'TEST BUILD SUCCEEDED' in ui_log and 'StudyPreviewAdoptionTests.swift' in ui_log)

benchmark = read('docs/parallel/03/evidence/final-benchmark.json')
timings = []
for kind in ['frames', 'visibility']:
    for item in benchmark[kind]:
        timing = item['timing']; samples = sorted(timing['samplesMilliseconds'])
        check(item['name'] + ' seven samples', len(samples) == 7)
        check(item['name'] + ' p50/p95', samples[math.ceil(.50*len(samples))-1] == timing['p50Milliseconds'] and samples[math.ceil(.95*len(samples))-1] == timing['p95Milliseconds'])
        timings.extend(samples)
check('84 timings', len(timings) == 84)
check('12 separate cancellations', len(benchmark['cancellation']) == 12 and all(x['cancelled'] for x in benchmark['cancellation']))
maximum_cancel = max(x['deadlineToReturnMilliseconds'] for x in benchmark['cancellation'])
check('cancellation max', abs(maximum_cancel - 1.606625) < 1e-12)
check('166 original Swift checks', 'W42 RESULT checks=166 failures=56' in (WORKERS / 'wave05-evidence/W42-original-result.log').read_text())
check('166 corrected Swift checks', 'W42 RESULT checks=166 failures=0' in (WORKERS / 'wave05-evidence/W42-candidate-result.log').read_text())
empty = WORKERS / 'wave08-evidence/W72-command-receipt.json'
check('preserved empty W72 receipt', empty.is_file() and empty.stat().st_size == 0)
check('W72 ENOSPC explanation', 'No space left on device' in (WORKERS / 'wave08-evidence/W72-write-failure.json').read_text())

evidence_paths = ['AGENTS.md', 'agents/OPERATING_PROTOCOL.md', 'docs/acceptance/m02-m03-code.md',
                  'docs/parallel/03/WORKER_PROTOCOL.md', 'docs/parallel/03/HANDOFF.md',
                  'docs/parallel/03/OWNER_REQUESTS.md', 'docs/parallel/03/wave10-evidence/W92-geometry.json']
evidence_paths += ['docs/parallel/03/workers/wave10-evidence/' + name for name in
                  ['W93-api.json', 'W94-handoff.json', 'W94-handoff-followup.json', 'W95-concurrency.json',
                   'W96-resource.json', 'W97-consumer.json', 'W97-current-ci-followup.json',
                   'W98-accessibility-privacy.json', 'W99-platform-performance.json',
                   'W91-normalizer-correction.json', 'W91-private-tree-verification.json']]
result = {'schema': 1, 'worker': 'W100', 'actual_runtime_id': '/root/wave10/w100_independent_review',
          'reviewed_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
          'source': SOURCE, 'private_worktree': str(PRIVATE), 'kind': 'Independent bounded read-only source/archive audit',
          'ledger_preflight': {'actual_contexts': len(rows), 'unique_runtime_ids': len({x['actual_runtime_id'] for x in rows}),
                              'unique_worktree_paths': len({x['private_worktree'] for x in rows}),
                              'existing_primary_reports': sum(x['primary_report_sha256'] is not None for x in rows),
                              'completed_primary_assignments': sum(x['completed'] for x in rows),
                              'pending_primary_workers': [x['worker'] for x in rows if not x['completed']],
                              'recorded_report_hashes_verified': recorded_hash_count, 'prior_records_verified': len(prior['workers']),
                              'input_and_resumed_commits_verified': sorted(sources), 'waves': waves, 'workers': rows,
                              'root_followups_unused_trees_counted': False,
                              'limits': 'Runtime IDs are reconciled from preserved spawn ledgers; historical tools are not replayed. Historical private trees need not survive authorized cleanup. Completion remains pending until W91/W100 reports exist and are finalized.'},
          'source_hashes': bound_sources, 'core_hashes_verified': len(core), 'ordinary_images': image_checks,
          'native36_events': dict(native_counts), 'native36_pipeline_passes': pipeline_passes,
          'current342': {'core_391_zero_failure_summaries': len(core391), 'apple_debug_test_build': 'passed',
                         'optics_starts': len(ui_starts), 'optics_unstarted': len(ui_ci['unstarted_methods']),
                         'optics_conclusion': 'failed during runner initialization', 'native165': 'pending per current root receipt; W100 did not poll CI'},
          'benchmark': {'timing_samples': len(timings), 'cancellation_probes': len(benchmark['cancellation']), 'maximum_deadline_to_return_ms': maximum_cancel},
          'normalizer_findings': {'initial': 'Wave09 reportSHA256 and followupReport camelCase fields not explicitly compared/discovered; all ten primary hashes independently matched.',
                                  'disposition': 'W91 corrected report and followup hash/path aliases; corrected aggregate compares supplied hashes.',
                                  'corrected_script_sha256': sha(WORKERS / 'wave10-evidence/W91-normalize-ledger.py')},
          'evidence_sha256': {p: sha(ROOT / p) for p in evidence_paths},
          'command': 'python3 docs/parallel/03/workers/wave10-evidence/W100-audit.py', 'git_commands': commands,
          'token_accounting': 'Exact counters unavailable; qualitative checkpoint and word/byte proxies only.',
          'retained_limits': ['25 actual Swift grazing cases remain distinct from W22 Python150 windows/two evaluators and W30 Python90-digit75 windows.',
                              'Tiny166 checks require finite nondegenerate unit evaluation; no universal numeric proof.',
                              'Closed-camera11708 unsupported became invalidCamera/no frame; held-out40 reject; no general camera proof.',
                              'Twelve ordinary images differ in scope from six parity, eight strict precision and25 supplemental probes; original raw RGBA/masks absent.',
                              'Hosted adoption test uses one identity/continuations/positive AX observations but active sphere, synthetic outputs and manual cancellation; original hook-only before/fail unrun.',
                              'Native36 has164 passes including10 pipeline and6 simulator Metal cases; its UI7 library/2 failures and2 reference-comparison passes remain separate from2 missing-artifact visual failures.',
                              'Owner04 engine/helper must integrate together; owner02 tiny-Float policy remains open without demonstrated guard-skipping mask defect.',
                              'Four reset count is root-recorded, not independently deduplicated; no global M02/M03/device/FPS/RSS/VoiceOver/photographic claim.'],
          'not_run': ['Swift or native tests', 'builds', 'renders', 'benchmarks', 'CI requests', 'cleanup', 'commits'],
          'read_notes': ['Several broad combined tool outputs were truncated; required governing text, ledger script, worker reports and decisive source/receipt sections were subsequently read in bounded form.'],
          'failures': failures, 'result': 'PASS_SCOPED_PREFLIGHT' if not failures else 'FAIL'}
(WORKERS / 'wave10-evidence/W100-independent-review.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'result': result['result'], 'actual': len(rows), 'existing_reports': result['ledger_preflight']['existing_primary_reports'], 'pending': result['ledger_preflight']['pending_primary_workers'], 'failures': failures}))
raise SystemExit(bool(failures))
