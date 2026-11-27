#!/usr/bin/env python3
"""Reconcile a pending GitHub library shard snapshot without inventing events."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess

ROOT = Path('/workspace/scratch/4633a14a0d5b')
REPO = ROOT / 'APP1'
OUT = ROOT / 'campaign/evidence/092'
OLD = '134f9adabe0203b1d6d8ed21abb6aaeb4e19d256'
NEW = 'f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5'

def source(rev, path):
    return subprocess.check_output(['git', 'show', f'{rev}:{path}'], cwd=REPO)

def digest(data):
    return hashlib.sha256(data).hexdigest()

jobs = json.loads((OUT / 'jobs-snapshot.json').read_text())['structuredContent']['jobs']
job = next(j for j in jobs if j['id'] == 140527589901)
run = json.loads(json.loads((OUT / 'run-snapshot.json').read_text())['structuredContent']['content'])
assert job['name'] == 'ui (library-reference)' and job['run_id'] == 46004241191
assert run['head_sha'] == NEW
assert job['status'] == 'in_progress' and job['conclusion'] is None
assert next(s for s in job['steps'] if s['name'] == 'Run selected native UI shard')['status'] == 'in_progress'
assert next(s for s in job['steps'] if s['name'] == 'Build native UI test bundle')['conclusion'] == 'success'
log_error = json.loads((OUT / 'job-log-request.json').read_text())
assert log_error['isError'] and log_error['structuredContent']['error_code'] == 'NOT_FOUND'

spec = importlib.util.spec_from_file_location('native_shards', REPO / 'scripts/native_test_shards.py')
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
mod.ROOT = REPO
inventory = mod.discover_methods('UITests')
expected = sorted(f'{cls}.{method}' for cls in mod.SHARDS['library-reference'] for method in inventory[cls])
assert len(expected) == 9

paths = ['UITests/ProjectLibraryUITests.swift', 'UITests/ReferenceComparisonUITests.swift',
         'App/ProjectLibraryView.swift', 'App/StudioTextLayoutDiagnostics.swift',
         'App/StudioView.swift', 'scripts/native_test_shards.py', '.github/workflows/ios-prototype.yml']
comparisons = []
for path in paths:
    old, new = source(OLD, path), source(NEW, path)
    comparisons.append({'path': path, 'oldSha256': digest(old), 'newSha256': digest(new), 'identical': old == new})
    if path == paths[0]:
        prefix_old, prefix_new = b'\n'.join(old.splitlines()[:405]), b'\n'.join(new.splitlines()[:405])
        assert prefix_old == prefix_new
        comparisons[-1]['first405LinesIdentical'] = True
        comparisons[-1]['first405LinesSha256'] = digest(prefix_new)
    else:
        assert old == new

old_findings = []
for method in ['testArchivedDeleteRequiresConfirmationAndPersistsOnlyThatRemoval', 'testCreateDuplicateRenameSwitchAndRelaunch']:
    path = ROOT / 'campaign/evidence/086/derived-summaries' / f'{method}.json'
    d = json.loads(path.read_text())
    assert d['testStatus'] == 'Failure'
    failures = []
    for f in d['failureSummaries']:
        symbols = [v['symbolInfo'] for v in f['sourceCodeContext']['callStack'] if 'symbolInfo' in v]
        failures.append({k:f[k] for k in ['lineNumber', 'message', 'timestamp']} | {'symbolicatedFrames': symbols})
    old_findings.append({'source': str(path.relative_to(ROOT)), 'sha256': digest(path.read_bytes()),
                         'method': method, 'testStatus': d['testStatus'], 'failures': failures})

record = {
    'worker': '/root/a092_current_library_ui', 'inputRevision': NEW,
    'sourceRun': 46004241191, 'job': job, 'runWrapperStatus': run['status'],
    'snapshotDateUTC': '2026-11-27',
    'logRequestProviderTimeUTC': '2026-11-27T13:32:09.0617168Z',
    'expectedMethods': expected, 'expectedCount': len(expected),
    'currentMethodCounts': {'started': None, 'passed': None, 'failed': None, 'incomplete': None, 'unstarted': None},
    'currentMethodCountsReason': 'The active job log endpoint returned BlobNotFound/404. Unknown is not zero.',
    'sourceComparisons': comparisons, 'priorFailures': old_findings,
    'conclusion': 'Current shard pending; earlier assertion failures remain historical failures and are not established fixed.',
    'noArtifactDownload': 'No artifact downloaded while the job was active; artifact availability was not queried.',
    'limitations': ['Job step success is not per-method success.', 'No native rerun performed by this worker.',
                    'No exact assertion-time visual or hit-routing conclusion inferred.']
}
(OUT / 'reconciliation.json').write_text(json.dumps(record, indent=2) + '\n')
files = []
for path in sorted(OUT.iterdir()):
    if path.is_file() and path.name != 'retained-hashes.json':
        files.append({'path': path.name, 'bytes': path.stat().st_size, 'sha256': digest(path.read_bytes())})
(OUT / 'retained-hashes.json').write_text(json.dumps(files, indent=2) + '\n')
print(json.dumps({'expected': len(expected), 'unchangedFullFiles': sum(c['identical'] for c in comparisons),
                  'unchangedLibraryPrefixLines': 405, 'current': 'pending',
                  'historicalFailuresRetained': len(old_findings), 'retainedFiles': len(files)}))
