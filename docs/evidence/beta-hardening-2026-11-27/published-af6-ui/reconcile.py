import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
REVISION = 'af6b7e56bb5d2b550ebefcc5fd7bb2afc4c20867'
RUN_ID = 46033956426
run = json.loads((ROOT / 'run-final.json').read_text())
jobs = json.loads((ROOT / 'jobs-final.json').read_text())
inventory = json.loads((ROOT / 'expected-methods.json').read_text())
assert run['id'] == RUN_ID and run['head_sha'] == REVISION
assert inventory['revision'] == REVISION
assert run['status'] == 'completed' and run['conclusion'] == 'failure'
results = {}
for job in jobs['jobs']:
    if not job['name'].startswith('ui ('):
        continue
    shard = job['name'][4:-1]
    expected = inventory['required'][shard]
    assert job['status'] == 'completed' and job['conclusion'] == 'failure'
    steps = {step['name']: step for step in job['steps']}
    assert steps['Select available iPhone simulator']['conclusion'] == 'success'
    assert steps['Build native UI test bundle']['conclusion'] == 'failure'
    assert steps['Warm selected iPhone simulator (diagnostic)']['conclusion'] == 'skipped'
    assert steps['Run selected native UI shard']['conclusion'] == 'skipped'
    assert steps['Verify required UI method accounting']['conclusion'] == 'failure'
    assert steps['Export finalized XCTest result bundle and genuine attachments']['conclusion'] == 'failure'
    path = ROOT / 'original-logs' / (shard + '.log')
    data = path.read_bytes()
    content = data.decode('utf-8')
    lines = content.splitlines()
    markers = [(i + 1, line) for i, line in enumerate(lines) if re.search(r'\bTest Case\b', line)]
    assert not markers
    errors = [{'line': i + 1, 'text': line} for i, line in enumerate(lines) if ' error: ' in line]
    assert errors and all("type 'AnyHashable' has no member 'titleAttribute'" in error['text'] for error in errors)
    assert 'Process completed with exit code 65.' in content
    assert '** TEST BUILD FAILED **' in content
    assert 'No finalized XCTest result bundle;' in content
    assert "No such file or directory: 'native-tests.log'" in content
    results[shard] = {
        'jobID': job['id'], 'jobURL': job['html_url'], 'conclusion': job['conclusion'],
        'startedAt': job['started_at'], 'completedAt': job['completed_at'],
        'expected': expected, 'expectedCount': len(expected),
        'started': [], 'passed': [], 'failed': [], 'skippedMethods': [],
        'incomplete': [], 'unstarted': expected,
        'compilerErrors': errors, 'buildExitCode': 65, 'testCaseMarkerCount': 0,
        'warmupStep': 'skipped', 'selectedTestStep': 'skipped',
        'startupExecuted': False, 'finalizedResultAvailable': False,
        'logSHA256': hashlib.sha256(data).hexdigest(), 'logBytes': len(data),
        'logLines': len(lines), 'excerpt': shard + '-excerpts.log'
    }
    indices = set()
    for i, line in enumerate(lines):
        if (' error: ' in line or '** TEST BUILD FAILED **' in line or
            'Process completed with exit code 65.' in line or
            'No finalized XCTest result bundle;' in line or
            "No such file or directory: 'native-tests.log'" in line):
            indices.update(range(max(0, i - 2), min(len(lines), i + 4)))
    (ROOT / (shard + '-excerpts.log')).write_text('\n'.join(f'{i + 1}: {lines[i]}' for i in sorted(indices)) + '\n')
assert len(results) == 9
assert sum(item['expectedCount'] for item in results.values()) == 44
assert len(set(method for item in results.values() for method in item['expected'])) == 44
accounting = {'revision': REVISION, 'runID': RUN_ID, 'observedUTC': jobs['observedUTC'],
              'status': 'all_ui_jobs_terminal_build_failure', 'shards': results,
              'totals': {'expected': 44, 'started': 0, 'passed': 0, 'failedMethods': 0,
                         'skippedMethods': 0, 'incomplete': 0, 'unstarted': 44}}
(ROOT / 'per-shard-accounting.json').write_text(json.dumps(accounting, indent=2) + '\n')
artifacts = json.loads((ROOT / 'compact-artifact-verification.json').read_text())
assert len(artifacts) == 2 and all(a['declaredDigestMatched'] and a['imageOrPDFCount'] == 0 for a in artifacts)
for artifact in artifacts:
    data = (ROOT / (artifact['name'] + '.zip')).read_bytes()
    assert len(data) == artifact['bytes'] and hashlib.sha256(data).hexdigest() == artifact['sha256']
visual = [{'jobID': job['id'], 'name': job['name'], 'status': job['status'],
           'conclusion': job['conclusion'],
           'failedSteps': [s['name'] for s in job['steps'] if s['conclusion'] == 'failure']}
          for job in jobs['jobs'] if job['name'].startswith('visual review')]
assert len(visual) == 2 and all(j['conclusion'] == 'failure' for j in visual)
receipt = {
    'worker': '/root/a097_final_ui_ci', 'revision': REVISION, 'runID': RUN_ID,
    'runURL': run['html_url'], 'observedUTC': jobs['observedUTC'],
    'runConclusion': run['conclusion'], 'runUpdatedAt': run['updated_at'],
    'scope': 'Nine required UI groups only; native/package evidence belongs to A095/A094.',
    'findings': accounting['totals'], 'requiredUIShards': 9,
    'commonFailure': {'path': 'NativeTests/LightingPlanPDFTests.swift', 'line': 188,
                      'diagnostic': "type 'AnyHashable' has no member 'titleAttribute'",
                      'buildExitCode': 65, 'verifiedOriginalLogs': 9},
    'startupFailuresObserved': 0, 'cancellationsObserved': 0,
    'warmupAndSelectedTestSteps': 'All skipped following each build failure.',
    'resultAccounting': 'All nine required-method and finalized-result gates failed closed.',
    'captureEvidence': {'required28Originals': 0, 'supplemental8Originals': 0,
                        'verifiedCompactArchives': [
                            {k: a[k] for k in ['id', 'name', 'bytes', 'sha256', 'imageOrPDFCount']}
                            for a in artifacts],
                        'contents': 'Only unavailable trace-status text; no image, PDF or attachment manifest.'},
    'visualReaders': visual,
    'executionPerformedByWorker': ['Read GitHub run/job metadata and all nine original decoded UI logs.',
                                   'Extract exact inventory from committed source af6, independently account for every required method.',
                                   'Verify original log transport counts and retained bytes.',
                                   'Download two compact artifacts, independently verify declared archive digests, safely enumerate contents.'],
    'notPerformed': ['Repository edits', 'Builds or tests', 'Workflow retries', 'Visual inspection of current-source app captures',
                     'Signing or distribution', 'Transfer of predecessor or successor passes'],
    'evidence': {'accounting': 'per-shard-accounting.json', 'inventory': 'expected-methods.json',
                 'failingSource': 'failing-source.json', 'transport': 'log-transport-counts.json',
                 'artifacts': 'compact-artifact-verification.json', 'jobs': 'jobs-final.json',
                 'run': 'run-final.json', 'reproducer': 'reconcile.py'}
}
(ROOT / 'receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps({'shards': len(results), 'totals': accounting['totals'], 'runConclusion': run['conclusion'],
                  'receiptSHA256': hashlib.sha256((ROOT / 'receipt.json').read_bytes()).hexdigest()}, indent=2))
