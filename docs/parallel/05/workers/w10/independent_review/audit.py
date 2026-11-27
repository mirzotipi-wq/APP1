"""Read-only reconciliation; writes only this review's evidence.json."""
from pathlib import Path
from collections import Counter, defaultdict
import datetime, hashlib, json, re, subprocess, sys

REPO = Path('/tmp/keyfill05-be879deb/repo')
WAVE = Path('/tmp/keyfill05-be879deb/waves/w10')
OUT = WAVE / 'independent_review'
SOURCE = '60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a'
BASE = 'f150f98e35dd735927075aac4d2f8b02295c6a67'
OLD = '1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a'
DOCS = sys.argv[1] if len(sys.argv) > 1 else OLD
PREFIX = 'docs/parallel/05/'
inputs = {}
def digest(data): return hashlib.sha256(data).hexdigest()
def git(*args): return subprocess.check_output(['git', *args], cwd=REPO)
def pinned(pin, path):
    data = git('show', f'{pin}:{path}')
    inputs[f'{pin}:{path}'] = digest(data)
    return data
def current(path):
    data = path.read_bytes()
    inputs[str(path)] = digest(data)
    return data
def docs(path):
    if DOCS == OLD:
        return current(REPO / PREFIX / path)
    return pinned(DOCS, PREFIX + path)
def inventory(pin):
    methods = []
    for path in git('ls-tree', '-r', '--name-only', pin, 'NativeTests').decode().splitlines():
        if not path.endswith('.swift'): continue
        data = pinned(pin, path).decode()
        classes = list(re.finditer(r'\bclass\s+(\w+)\s*:\s*XCTestCase', data))
        for method in re.finditer(r'\bfunc\s+(test\w+)\s*\(', data):
            preceding = [m for m in classes if m.start() < method.start()]
            assert preceding, (path, method.group(1))
            methods.append(preceding[-1].group(1) + '.' + method.group(1))
    assert len(methods) == len(set(methods))
    return sorted(methods)

expected = inventory(SOURCE)
baseline = inventory(BASE)
raw = docs('validation/native-60059a0.log')
interval = docs('validation/native-60059a0-unit-output.log')
extraction = json.loads(docs('validation/native-60059a0-extraction.json'))
assert digest(raw) == extraction['raw_log_sha256']
assert digest(interval) == extraction['extracted_sha256']
assert interval == b''.join(raw.splitlines(keepends=True)[extraction['raw_first_line_1_based']-1:extraction['raw_last_line_1_based']])
assert interval.index(b'Simulator warm-up outcome: failure') < interval.index(b'Test Case ') < interval.index(b'** TEST EXECUTE SUCCEEDED **')
event_re = re.compile(r"Test Case '-\[(\w+)\.(\w+) (\w+)\]' (started|passed|failed|skipped)")
def events(data):
    result = defaultdict(list)
    for line, text in enumerate(data.decode().splitlines(), 1):
        m = event_re.search(text)
        if m: result[m[2] + '.' + m[3]].append({'event': m[4], 'line': line, 'target': m[1]})
    return dict(result)
native = events(interval)
assert set(native) == set(expected)
assert all([e['event'] for e in seq] == ['started', 'passed'] for seq in native.values())
assert all(e['target'] == 'KeyAndFillTests' for seq in native.values() for e in seq)
account = json.loads(docs('validation/native-60059a0-accounting.json'))
assert set(account['expected']) == set(expected) == set(account['passed'])
spatial = [m for m in expected if m.startswith('Spatial')]
spatial = [m for m in spatial if not m.startswith('SpatialViewportGeometryTests.')]
assert len(expected) == 185 and len(spatial) == 39
assert sum(m.startswith('SpatialViewportStateTests.') for m in spatial) == 11

scope = git('diff', '--name-only', BASE, SOURCE, '--', 'App', 'NativeTests').decode().splitlines()
scope_counts = Counter(p.split('/')[0] for p in scope)
assert scope_counts == {'App': 4, 'NativeTests': 7}, scope_counts
source_equal_docs = all(git('rev-parse', f'{SOURCE}:{p}') == git('rev-parse', f'{DOCS}:{p}') for p in scope)
assert source_equal_docs
docs_only = git('diff', '--name-only', SOURCE, DOCS).decode().splitlines()
assert all(p.startswith(PREFIX) for p in docs_only)
core_unchanged = not git('diff', '--name-only', BASE, SOURCE, '--', 'Sources/LightingCore').strip()
assert core_unchanged

creation = json.loads(current(WAVE/'worker-creation.json'))
ledger = json.loads(current(WAVE/'ledger.json'))
ids = [x['canonical_agent_id'] for x in creation['actual_created_contexts']]
assert len(ids) == len(set(ids)) == 10 and len([x for x in ids if x.count('/') == 3]) == 9
assert set(ids) == {x['canonical_agent_id'] for x in ledger['workers']}
reports = []
for row in ledger['workers']:
    if row['role'] == 'independent_review': continue
    data = current(WAVE / row['role'] / 'report.md')
    assert digest(data) == row['report_sha256']
    reports.append({'role': row['role'], 'sha256': digest(data)})
assert len(reports) == 9
manifest = current(WAVE/'manifest.sha256')
manifest_results = []
for line in manifest.decode().splitlines():
    declared, name = line.split(None, 1)
    name = name.lstrip('*')
    actual = digest(current(WAVE/name))
    manifest_results.append({'path': name, 'sha256': actual, 'matches': declared == actual})
assert all(x['matches'] for x in manifest_results)

aggregate = json.loads(pinned(OLD, PREFIX+'WORKER_LEDGER.json'))
prior_ids = [x['canonical_agent_id'] for x in aggregate['workers']]
assert len(prior_ids) == len(set(prior_ids)) == 90
assert not set(prior_ids).intersection(ids)
prior_hashes = []
for row in aggregate['workers']:
    if row['report_sha256'] is None:
        assert row['wave'] == 'w01'
        continue
    if row['wave'] == 'w02':
        original = json.loads(pinned(OLD, PREFIX+row['source_ledger']))
        record = next(x for x in original['workers'] if x['canonical_agent_id'] == row['canonical_agent_id'])
        data = record['report'].encode()
    else:
        data = pinned(OLD, PREFIX+row['report'])
    assert digest(data) == row['report_sha256']
    prior_hashes.append(row['canonical_agent_id'])
assert len(prior_hashes) == 80
historical_manifests = []
for path in git('ls-tree', '-r', '--name-only', OLD, PREFIX+'workers').decode().splitlines():
    if not path.endswith('/manifest.sha256'): continue
    count = 0
    for line in pinned(OLD, path).decode().splitlines():
        declared, name = line.split(None, 1)
        name = name.lstrip('*')
        target = name if name.startswith('docs/') else str(Path(path).parent / name)
        assert digest(pinned(OLD, target)) == declared, target
        count += 1
    historical_manifests.append({'path': path, 'entries': count})
assert len(historical_manifests) == 7 and sum(x['entries'] for x in historical_manifests) == 176
w08 = pinned(OLD, PREFIX+'workers/w08/resources/report.md')
body = w08.split(b'## Findings\n', 1)[1]
erratum = json.loads(docs('validation/worker-evidence-erratum.json'))
assert digest(w08) == erratum['authoritative_whole_file_sha256']
assert len(body) == erratum['scoped_bytes'] == 2659
assert digest(body) == erratum['correct_scoped_hash'] != erratum['declared_scoped_hash']

witness = json.loads(pinned(OLD, PREFIX+'workers/w08/implementation/portable_geometry_witness.json'))
assert len(witness['fixtures']) == 15
assert sum(x['primitives'] for x in witness['fixtures']) == 760
assert len(witness['fixtures'])*len(witness['layouts'])*len(witness['orbit_yaw_pitch']) == 240

captures = []
for name in ['captures/receipt-60059a0.json', 'captures/receipt-full-app-60059a0.json']:
    receipt = json.loads(docs(name))
    assert receipt['source'] == SOURCE
    archive_dir = 'native-60059a0' if 'captures' in receipt else 'ui-export-60059a0'
    archive = current(Path('/tmp/keyfill05-be879deb/output')/archive_dir/'original.zip')
    assert digest(archive) == receipt['archive_sha256'] and len(archive) == receipt['archive_bytes']
    for capture in receipt.get('captures', [receipt]):
        image_data = docs(capture['file'].removeprefix(PREFIX))
        assert digest(image_data) == capture['sha256'] and len(image_data) == capture['bytes']
        if 'identical_to_4e694bc' in capture:
            assert image_data == pinned(OLD, capture['file'].replace('60059a0','4e694bc'))
        captures.append({'path':capture['file'],'sha256':digest(image_data),'attachment':capture['attachment']['exportedFileName']})

ui = {}
for shard in ['studio-export','app-accessibility','studio-optics']:
    data = docs('validation/ui-'+shard+'-60059a0.log')
    found = events(data)
    stored = json.loads(docs('validation/ui-'+shard+'-60059a0-accounting.json'))
    assert set(found) == set(stored['expected'])
    passes = [m for m,v in found.items() if [e['event'] for e in v] == ['started','passed']]
    failures = [m for m,v in found.items() if [e['event'] for e in v] == ['started','failed']]
    assert set(passes) == set(stored['passed']) and set(failures) == set(stored['failed'])
    ui[shard] = {'passed':len(passes),'failed':len(failures),'unstarted':stored['unstarted'],'failed_methods':failures}

owner = json.loads(docs('validation/owner-check-60059a0.json'))
for row in owner['lane01']['files']:
    blob = git('rev-parse',owner['lane01']['revision']+':'+row['path']).decode().strip()
    assert blob == row['blob']
assert b'.id(generation)' in pinned(SOURCE,'App/StudioView.swift')
assert b'.id(session.workspaceResetID)' in pinned(owner['lane01']['revision'],'App/StudioView.swift')
for path in ['App/StudioSession.swift','NativeTests/StudioSessionTests.swift']:
    assert git('rev-parse',owner['lane01']['revision']+':'+path) == git('rev-parse','5ccfbaae821a32d88c12ed8b3abf1600aef25753:'+path)
for path in ['HANDOFF.md','GEOMETRY_COMPARISONS.md','INTERACTION_REGRESSIONS.md','OWNER_REQUESTS.md','RECOVERY.md','validation/NATIVE-60059a0.md','validation/run-60059a0-jobs.json']:
    docs(path)
for path in ['acceptance-matrix.md','synthesis.md','ci-observations.json','owner-update.json','archival-disposition.json']:
    current(WAVE/path)

result = {
    'reviewer':'/root/w10_acceptance/independent_review',
    'observed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'source':SOURCE,'baseline':BASE,'original_docs':OLD,'supplemental_docs':DOCS,
    'execution':'Pinned Git reads, Python event/count/byte/hash reconciliation; no native execution, builds, installs, source edits or ref updates.',
    'native':{'declared':len(expected),'passed':len(native),'spatial_passed':len(spatial),'helper_state':11,'direct_scenekit':28,'baseline_declarations':len(baseline),'spatial_classes':dict(Counter(m.split('.')[0] for m in spatial)),'all_methods_have_exactly_one_ordered_start_pass':True,'float_regression_events':native['SpatialViewportStateTests.testFloatProjectionDoesNotNarrowTheSmallerViewportAxis'],'raw_extraction_verified':True,'warmup_failure_precedes_actual_test_success':True},
    'source_scope':{'changed_paths':scope,'all_equal_at_docs_parent':source_equal_docs,'core_unchanged':core_unchanged,'later_changes_only_lane_docs':True},
    'wave10':{'actual_created_ids':ids,'other_reports':reports,'provisional_manifest_sha256':digest(manifest),'manifest_entries':manifest_results,'reviewer_report_not_yet_included':True},
    'historical':{'unique_completed':90,'bound_hashes_verified':len(prior_hashes),'manifests':historical_manifests,'wave01_summary_only':10,'executor_interruptions':4,'body_hash_erratum_verified':erratum},
    'geometry':{'native_projection_points':26,'native_derivation':'8 corners x 2 layouts in SpatialPreviewTests + 5 housing/stand points x 2 layouts in SpatialInteractionTests; inspected loops, not rerun.','portable_source':witness['input_sha'],'scenes':15,'primitive_instances':760,'frustum_cases_per_model':240,'witness_not_rerun':True},
    'captures':captures,'ui':ui,'owner_source_confirmed_not_integrated':owner['lane01']['revision'],
    'visual_review':{'actually_viewed':['ordinary-60059a0.png','crowded-60059a0.png','full-app-fit-feet-60059a0.png'],'findings':'All represented rigs fit. Crowded panels obscure the bust/fixtures; selected right rectangle outline is visible. Ordinary selection is subtle; stands/camera are dark. Full app has selected3D, readable preview note and partly toolbar-covered Fit/footer; earlier passed tap does not establish full pose or gesture acceptance.'},
    'report_dispositions':{
        'acceptance':'Native and UI scope correct; accept bounded mapping. Current100complete claim remains withheld until this report is retained and final aggregate verified.',
        'geometry':'26=8x2+5x2 native point checks, not layouts; portable15/760/240 counts verified at old4e source. Outward-Float source and six accepted/two rejected layouts inspected; no native RealityKit-matrix inference.',
        'interfaces':'5cc source diagnosis confirmed at7b owner blobs; frozen .id(generation) remains. Predicted first-save coordinator replacement is source reasoning, not an executed reproduction.',
        'implementation':'185 inventory independently enumerated from pinned test declarations;11 helper/28SCN split and fourApp/sevenNativeTests scope correct. Eleven blobs unchanged at6cea; later changes only lane docs.',
        'concurrency':'Callback refresh precedes early exit. Deleted/invalid maps and current ancestry verified. Retained RK lookup after detachment is distinct from blocked delivery;SCN two let nodes persist. No deallocation/thread atomicity claim accepted.',
        'resources':'90 prior IDs/80 ledger hashes/176 historical manifest entries independently verified. W10ten IDs match creation and ledger; nine reports and44provisional entries match. Embedded W08body hash wrong, whole file correct; append-only erratum closes label defect.',
        'interactions':'Current originals directly viewed and archive/image hashes verified. Passing Fit action lacks pose/orbit/pan/pinch assertion; partly covered control snapshot does not prove permanently unreachable control.',
        'accessibility_privacy':'Disabled delegate-negative fixture has nil callback/no window; conclusions properly limited. NonAR automatic-session-disabled source is not camera/network audit. Plan-meter failure and no maximum-type3D/manual-VO pass remain explicit.',
        'platform_performance':'Independent native event parse confirms185/39 and failed-warmup/success sequence. Actual x86_64 fallback does not executeRK.16:52 optics-completing snapshot is superseded by later8/2/time-out receipt without alteration.'},
    'review_audit_history':'First reconciliation attempt stopped at a repo-relative W07 manifest entry treated as wave-relative; parser corrected. The subsequent completed audit verified all asserted hashes/counts. No production/test/native command was executed.',
    'limits':['Native185/39 does not pass failed UI shards or establish RealityKit runtime.','Successful terminal job observed by root16:52:09UTC; prior pending cutoffs remain historical.','Lookup may resolve detached retained RealityKit graph; delivery gates are separate.','SceneKit coordinator retains two fixed nodes; no deallocation or renderer-thread atomicity proof.','No gesture/device/FPS/manual accessibility or token-budget telemetry acceptance.','Prior90 plus10 created IDs is100created; final completed100 requires this retained report and final aggregate/hash verification.'],
    'input_sha256':inputs
}
(OUT/'evidence.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'native':len(native),'spatial':len(spatial),'ui':ui,'prior_hashes':len(prior_hashes),'provisional_manifest_entries':len(manifest_results),'source_scope':dict(scope_counts),'evidence_sha256':digest((OUT/'evidence.json').read_bytes())},indent=2))
