#!/usr/bin/env python3
"""W07-10 independent readonly source/evidence reconciliation; no builds."""
from pathlib import Path
from collections import Counter, defaultdict
from datetime import datetime, timezone
import hashlib, importlib.util, json, os, re, subprocess, sys

ROOT = Path('/workspace/scratch/e08d5190f17c/workers/w07-10/tree')
OUT = ROOT.parent
EVIDENCE = Path('/workspace/scratch/e08d5190f17c/keyfill-01/docs/parallel/01/evidence/wave07')
HEAD = '46a161cb01d0aee2e91940dbd06d82cfe2df5821'
CURRENT = '08e80c756cb7c8aa4eaf11f27932c8f701000be1'
CI = '5ccfbaae821a32d88c12ed8b3abf1600aef25753'
sys.dont_write_bytecode = True

def sha(data):
    return hashlib.sha256(data).hexdigest()

commands = []
def run(args):
    p = subprocess.run(args, cwd=ROOT, capture_output=True, env={**os.environ, 'PYTHONDONTWRITEBYTECODE':'1'})
    commands.append({'argv':args, 'cwd':str(ROOT), 'exit_code':p.returncode,
                     'stdout_sha256':sha(p.stdout), 'stderr_sha256':sha(p.stderr)})
    assert p.returncode == 0, (args, p.stderr.decode())
    return p.stdout

assert run(['git','rev-parse','HEAD']).decode().strip() == HEAD
assert not run(['git','status','--porcelain=v1']).strip()
startup = {name:run(['python3','scripts/agent_cycle.py',name]).decode().strip() for name in ('check','next')}
diff_paths = run(['git','diff','--name-only',CI,HEAD]).decode().splitlines()
assert diff_paths == ['App/StudioView.swift','UITests/StudioSmokeTests.swift','docs/parallel/01/NAVIGATION.md']
patch = run(['git','diff','--binary','HEAD'])
assert patch == b''
(OUT/'source.patch').write_bytes(patch)

manifests = {}
manifest_maps = {}
for filename, expected_revision in [('source-manifest.json',CURRENT),('ci-source-manifest.json',CI)]:
    raw = (EVIDENCE/filename).read_bytes()
    data = json.loads(raw)
    assert data['source_revision'] == expected_revision
    rows = data['files']
    paths = [row['path'] for row in rows]
    assert len(paths) == len(set(paths)) == 175
    tracked = run(['git','ls-tree','-r','--name-only',expected_revision,'--','App','NativeTests','Sources','Tests','UITests','Package.swift','project.yml']).decode().splitlines()
    assert set(paths) == set(tracked), (filename, set(paths)^set(tracked))
    for row in rows:
        assert sha(run(['git','show',expected_revision+':'+row['path']])) == row['sha256'], row
        if expected_revision == CURRENT:
            assert sha((ROOT/row['path']).read_bytes()) == row['sha256'], row
            assert sha(run(['git','show',HEAD+':'+row['path']])) == row['sha256'], row
    manifests[filename] = {'sha256':sha(raw), 'source_revision':expected_revision,'count':len(rows),
        'complete_for':['App','NativeTests','Sources','Tests','UITests','Package.swift','project.yml'],
        'all_git_blobs_match':True,'all_current_disk_and_head_match':expected_revision == CURRENT,
        'path_roots':dict(Counter(p.split('/')[0] for p in paths))}
    manifest_maps[filename] = {row['path']:row['sha256'] for row in rows}

changed_inputs = [p for p,h in manifest_maps['source-manifest.json'].items() if manifest_maps['ci-source-manifest.json'][p] != h]
assert changed_inputs == ['App/StudioView.swift','UITests/StudioSmokeTests.swift']
syntax = json.loads((EVIDENCE/'native-syntax.json').read_text())
assert syntax['source_revision'] == CURRENT and syntax['exit_code'] == 0 and syntax['input_count'] == 82
assert syntax['command'][1:3] == ['-frontend','-parse']
syntax_paths = syntax['command'][3:]
tracked_native = run(['git','ls-tree','-r','--name-only',CURRENT,'--','App','NativeTests','UITests']).decode().splitlines()
assert len(syntax_paths) == len(set(syntax_paths)) == 82
assert set(syntax_paths) == {p for p in tracked_native if p.endswith('.swift')}
assert all(p in manifest_maps['source-manifest.json'] for p in syntax_paths)
assert (EVIDENCE/'native-syntax.log').read_bytes() == b''
shard_receipt = json.loads((EVIDENCE/'shard-check.json').read_text())
assert shard_receipt['source_revision'] == CURRENT and shard_receipt['exit_code'] == 0
shard_output = run(['python3','scripts/native_test_shards.py','check']).decode().strip()
assert shard_output == (EVIDENCE/'shard-check.log').read_text().strip()
spec = importlib.util.spec_from_file_location('native_test_shards',ROOT/'scripts/native_test_shards.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
inventory = module.discover_methods('UITests')
method = 'testProtectedStorageKeepsSettingsAndPurchaseNavigationAvailable'
assert method in inventory['StudioSmokeTests']
assignments = [name for name,classes in module.SHARDS.items() if 'StudioSmokeTests' in classes]
assert assignments == ['studio-export']
assert 'sources: [UITests]' in (ROOT/'project.yml').read_text()

log_path = EVIDENCE/'ci-140017565927.log'
raw = log_path.read_bytes()
log = raw.decode()
lines = log.splitlines()
ci_receipt = json.loads((EVIDENCE/'ci-passing-core.json').read_text())
ci_cases = json.loads((EVIDENCE/'ci-case-reconciliation.json').read_text())
assert ci_receipt['source_sha'] == ci_cases['source_revision'] == CI
assert sha(raw) == ci_receipt['log_sha256'] == ci_cases['log_sha256']
assert ci_receipt['job'] == 140017565927 and ci_receipt['workflow_run'] == 45851159581
assert ci_receipt['conclusion'] == 'success'
assert any(re.fullmatch(r'\S+Z '+CI,line) for line in lines)
assert 'Swift version 6.4.2 (swift-6.4.2-RELEASE)' in log
markers = [(i,'release' if '--configuration release' in l else 'debug') for i,l in enumerate(lines) if 'swift test --' in l]
assert [v for _,v in markers] == ['debug','release']
case_pattern = re.compile(r"Test Case '([^']+)' (started|passed|failed|skipped)\b")
summaries = {}
all_events = 0
for n,(start,config) in enumerate(markers):
    stop = markers[n+1][0] if n+1 < len(markers) else len(lines)
    events = defaultdict(list)
    event_lines = []
    for i in range(start,stop):
        line = lines[i]
        if 'Test Case' not in line:
            continue
        match = case_pattern.search(line)
        assert match, (i+1,line)
        events[match[1]].append(match[2])
        event_lines.append(i+1)
    counts = Counter(event for sequence in events.values() for event in sequence)
    assert len(events) == counts['started'] == counts['passed'] == 431
    assert counts['failed'] == counts['skipped'] == 0
    assert all(sequence == ['started','passed'] for sequence in events.values())
    names = sorted(events)
    candidates = {'sorted_newline_join': '\n'.join(names).encode(),
                  'sorted_newline_join_trailing_newline': ('\n'.join(names)+'\n').encode()}
    matching = [fmt for fmt,data in candidates.items() if sha(data) == ci_cases[config]['case_inventory_sha256']]
    assert len(matching) == 1
    assert ci_cases[config]['started'] == ci_cases[config]['passed'] == ci_cases[config]['unique_cases'] == 431
    assert ci_cases[config]['failed'] == 0
    summaries[config] = {'started':431,'passed':431,'unique_cases':431,'failed':0,'skipped':0,
        'event_count':len(event_lines),'all_sequences_exactly_started_then_passed':True,
        'first_case_line':event_lines[0],'last_case_line':event_lines[-1],
        'case_inventory_sha256':ci_cases[config]['case_inventory_sha256'], 'inventory_format':matching[0]}
    all_events += len(event_lines)
assert all_events == sum('Test Case' in line for line in lines) == 1724
assert not re.search(r'Test (?:Case|Suite) .*\bfailed\b|##\[error\]',log)
historic = json.loads((EVIDENCE/'ci-compatibility.json').read_text())
oldraw = (EVIDENCE/'ci-139986642720.log').read_bytes()
assert sha(oldraw) == historic['log_sha256']
assert historic['workflow_run'] == 45842239860
oldlog = oldraw.decode()
assert 'expected named member of numeric literal' in oldlog
assert '##[error]' in oldlog
assert 'Double(0.05).nextDown' in (ROOT/'Tests/LightingCoreTests/StudioFieldCommandTests.swift').read_text()
boundary = json.loads((EVIDENCE/'boundary-command.json').read_text())
assert sha((EVIDENCE/'boundary-debug.log').read_bytes()) == boundary['log_sha256']
assert sha((ROOT/'Tests/LightingCoreTests/StudioFieldCommandTests.swift').read_bytes()) == boundary['test_source_sha256']

assert not run(['git','status','--porcelain=v1']).strip()
hashes = {p.name:sha(p.read_bytes()) for p in sorted(EVIDENCE.iterdir()) if p.is_file()}
reviewed_sources = ['App/StudioView.swift','UITests/StudioSmokeTests.swift','App/StudioFeatureSheets.swift',
    'App/StudioSession.swift','Sources/LightingCore/StudioFeatureContext.swift','Sources/LightingCore/StudioFeaturePresentation.swift',
    'App/ReferenceComparisonView.swift','App/SceneArrangementView.swift','App/LightTargetLuxView.swift',
    'App/StudioSettingsView.swift','App/ProFeaturesView.swift','scripts/native_test_shards.py',
    '.github/workflows/ios-prototype.yml','project.yml','docs/parallel/01/NAVIGATION.md','docs/parallel/01/FEATURE_ADAPTERS.md']
receipt = {
 'worker':'/root/w07_acceptance/w07_10_independent','role':'W07-10 independent readonly challenger',
 'checked_utc':datetime.now(timezone.utc).isoformat(),'head':HEAD,'native_source':CURRENT,'portable_ci_source':CI,
 'startup':startup,'worktree_clean_before_and_after':True,'changed_by_worker':[], 'new_commit':None,
 'review_diff_paths':diff_paths,'ci_to_current_changed_inputs':changed_inputs,'manifests':manifests,
 'syntax_receipt':{'input_count':82,'complete_native_swift_inventory':True,'exit_code':0,'log_bytes':0,
    'rerun_by_worker':False,'scope':'Retained Linux parse receipt verified; no Apple typecheck or runtime'},
 'test_discovery':{'exact_method':'StudioSmokeTests.'+method,'assigned_required_shard':'studio-export',
    'new_test_class':False,'static_check':shard_output,'new_method_executed':False},
 'raw_ci':{'source':CI,'log_bytes':len(raw),'log_sha256':sha(raw),'all_case_events':all_events,
    'total_passes':862,'compiler':'Swift 6.4.2 Linux','configurations':summaries,'runtime_scope':'Portable package tests only'},
 'historic_failure':{'workflow_run':45842239860,'log_sha256':sha(oldraw),'failure_preserved':True,
    'message':'expected named member of numeric literal','later_fix':'Double(0.05).nextDown'},
 'evidence_sha256':hashes,'reviewed_source_sha256':{p:sha((ROOT/p).read_bytes()) for p in reviewed_sources},
 'commands':commands,'audit_script_sha256':sha(Path(__file__).read_bytes()),
 'read_review_commands':[
  'cat AGENTS.md agents/OPERATING_PROTOCOL.md agents/HANDOFF.md agents/state.json',
  'cat docs/PRODUCT.md docs/ARCHITECTURE.md docs/ROADMAP.md docs/QUALITY.md docs/DESIGN.md',
  'cat docs/parallel/01/COORDINATOR.md docs/parallel/01/HANDOFF.md docs/parallel/01/INTERFACES.md docs/parallel/01/FEATURE_ADAPTERS.md',
  'git diff 5ccfbaae821a32d88c12ed8b3abf1600aef25753..HEAD -- App/StudioView.swift UITests/StudioSmokeTests.swift docs/parallel/01/NAVIGATION.md',
  'cat App/StudioFeatureSheets.swift',
  'cat Sources/LightingCore/StudioFeatureContext.swift Sources/LightingCore/StudioFeaturePresentation.swift',
  'rg -n -A 32 -B 8 "func (openFeature|allowsMutation|acceptsFeature|applyFeatureScene|applyFeatureLight|applyFeatureRoom|retireFeature|finishFeature|save)" App/StudioSession.swift',
  'rg -n -A 14 -B 8 "onApply|closeSession|didFinish = true|didApply = true" App/ReferenceComparisonView.swift App/SceneArrangementView.swift App/LightTargetLuxView.swift'],
 'corrected_read_attempts':[
   {'path':'.github/workflows/ci.yml','exit_code':2,'correct_path':'.github/workflows/ios-prototype.yml'},
   {'path':'Sources/LightingCore/StudioFeatureSession.swift','exit_code':2,'correct_path':'Sources/LightingCore/StudioFeatureContext.swift'}],
 'scope_limits':['No source edits, builds, Swift rerun, native execution, device/StoreKit/photo actions, external actions or native-queue waiting.',
   'Current 08e80c7 native changes are syntax/static review only. Older 5ccfbaa portable passes do not execute them.',
   'Reference, Arrangement and Target lux still consume rejected drafts through their Void producer callbacks.']}
(OUT/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps({'status':'verified','head':HEAD,'manifests':manifests,'syntax_inputs':82,
    'discovered_method':receipt['test_discovery'],'raw_ci':receipt['raw_ci'],
    'historic_failure_preserved':True,'worktree_clean':True},indent=2))
