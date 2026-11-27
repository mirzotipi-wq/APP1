"""Read-only pinned Git-object audit; writes only this lane's evidence.json."""
import collections
import datetime
import hashlib
import json
import pathlib
import re
import subprocess

REPO = pathlib.Path('/tmp/keyfill05-be879deb/repo')
OUT = pathlib.Path('/tmp/keyfill05-be879deb/waves/w10/resources')
DOCS = '1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a'
SOURCE = '60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a'
BASELINE = 'f150f98e35dd735927075aac4d2f8b02295c6a67'
BASE = 'docs/parallel/05/'

def git(*args):
    return subprocess.check_output(['git', '-C', str(REPO), *args])

def blob(path, rev=DOCS):
    return git('show', rev + ':' + path)

def digest(value):
    return hashlib.sha256(value).hexdigest()

def doc(path):
    return json.loads(blob(path))

def identity(worker):
    return worker.get('canonical_agent_id', worker.get('canonical_id', worker.get('id')))

def role_key(role):
    return {'geometry/invariants':'geometry', 'accessibility/privacy':'accessibility_privacy',
            'platform/performance':'platform_performance', 'independent review':'independent_review',
            'independentreview':'independent_review'}.get(role, role)

aggregate = doc(BASE + 'WORKER_LEDGER.json')
all_workers = aggregate['workers']
waves = {}
for number in range(1, 10):
    wave = f'w{number:02d}'
    path = BASE + f'workers/{wave}/ledger.json'
    payload = doc(path)
    workers = payload if isinstance(payload, list) else payload['workers']
    waves[wave] = {'path': path, 'payload': payload, 'workers': workers}

ledger_checks = []
reports = []
for wave, record in waves.items():
    declared = [x for x in all_workers if x['wave'] == wave]
    local = {identity(x): x for x in record['workers']}
    ledger_checks.append({
        'wave': wave,
        'source_ledger': record['path'],
        'source_ledger_sha256': digest(blob(record['path'])),
        'aggregate_count': len(declared),
        'source_count': len(local),
        'same_ids': set(local) == {identity(x) for x in declared},
        'same_roles': all(local[identity(x)]['role'] == x['role'] for x in declared),
        'normalized_roles_match': all(role_key(local[identity(x)]['role']) == x['role'] for x in declared),
        'role_aliases': [{'id':identity(x),'source_role':local[identity(x)]['role'],'aggregate_role':x['role']}
                         for x in declared if local[identity(x)]['role'] != x['role']],
        'aggregate_statuses': sorted({x['status'] for x in declared}),
        'source_statuses': sorted({x.get('status', x.get('state')) for x in record['workers']}),
    })
    for worker in declared:
        original = local[identity(worker)]
        entry = {'wave': wave, 'id': identity(worker), 'role': worker['role']}
        expected = worker['report_sha256']
        entry['expected_sha256'] = expected
        if wave == 'w01':
            entry.update(scope='Recovered summary only; original full report unavailable', verified_original=False,
                         source_storage=worker['report_storage'])
        else:
            if wave == 'w02':
                value = original['report'].encode('utf-8')
                entry.update(scope='Exact UTF-8 recovered report embedded in wave ledger, final LF included',
                             source=record['path'] + '#' + identity(worker))
                local_hash = original['output_sha256']
            else:
                path = BASE + worker['report']
                value = blob(path)
                entry.update(scope='Whole retained report file bytes', source=path)
                local_hash = original['report_sha256']
            actual = digest(value)
            entry.update(actual_sha256=actual, source_ledger_sha256=local_hash,
                         matches_aggregate=actual == expected, matches_source_ledger=actual == local_hash)
        reports.append(entry)

paths = git('ls-tree', '-r', '--name-only', DOCS, '--', BASE + 'workers').decode().splitlines()
manifest_checks = []
for path in paths:
    if not path.endswith('.sha256'):
        continue
    entries = []
    for line in blob(path).decode().splitlines():
        if not line.strip():
            continue
        match = re.fullmatch(r'([0-9a-f]{64})\s+\*?(.+)', line)
        if not match:
            raise ValueError((path, line))
        expected, target = match.groups()
        resolved = target if target.startswith('docs/') else str(pathlib.PurePosixPath(path).parent / target)
        actual = digest(blob(resolved))
        entries.append({'path': resolved, 'expected': expected, 'actual': actual, 'matches': actual == expected})
    manifest_checks.append({'path': path, 'sha256': digest(blob(path)), 'entries': entries})

scoped_report = BASE + 'workers/w08/resources/report.md'
scoped_text = blob(scoped_report).decode()
scoped_expected = re.search(r'^reporthash: ([0-9a-f]{64})$', scoped_text, re.M).group(1)
scoped_body = scoped_text.split('## Findings\n', 1)[1]
scoped_actual = digest(scoped_body.encode())

inputs = []
for rev, selected in [(DOCS, ['AGENTS.md', 'docs/ARCHITECTURE.md', 'docs/DESIGN.md',
    'docs/acceptance/m02-m03-code.md', BASE+'HANDOFF.md', BASE+'RECOVERY.md', BASE+'WORKER_LEDGER.json',
    BASE+'workers/w01/recovery-summary.md', BASE+'workers/w04/resource_checks.json',
    BASE+'workers/w06/resource-checks.json', BASE+'workers/w07/resource-provenance.json',
    BASE+'workers/w08/resource_provenance.md', BASE+'workers/w09/resource-provenance.json']),
    (SOURCE, ['Sources/LightingCore/Scene.swift', 'App/SpatialPreview.swift', 'App/StudioEntityGraph.swift',
              'App/RealityStudioPreview.swift']),
    (BASELINE, ['Sources/LightingCore/Scene.swift', 'App/SpatialPreview.swift', 'App/StudioEntityGraph.swift',
              'App/RealityStudioPreview.swift'])]:
    for path in selected:
        inputs.append({'revision':rev, 'path':path, 'sha256':digest(blob(path, rev))})

snapshots = []
for name in ['dispatch-resources.jsonl', 'worker-creation.json']:
    path = OUT.parent / name
    value = path.read_bytes()
    parsed = [json.loads(line) for line in value.decode().splitlines()] if name.endswith('jsonl') else json.loads(value)
    snapshots.append({'path':str(path), 'sha256_at_capture':digest(value), 'content_at_capture':parsed,
                      'limit':'Wave in progress; this snapshot is not final completion or runtime/peak telemetry.'})

topology = {
  'scope':'Explicit source-created adapter nodes/entities after a valid update with N distinct validated UUIDs and S elevated stands. Excludes framework roots/internals, UIKit, meshes, materials, components, external witness retention, allocations, memory bytes and peaks.',
  'validation':'Sources/LightingCore/Scene.swift:62-64 caps N at 12; S counts y > 0.05, so 0 <= S <= N.',
  'scenekit': {
    'base_breakdown':{'coordinator_content_and_camera':2,'floor_head_torso_ambient_camera_body_lens':6},
    'per_lamp':{'fixture':1,'source':1,'indicator':1,'stand_always_owned_even_detached':1},
    'owned_formula':'8 + 4N', 'owned_max':8+4*12,
    'attached_formula':'8 + 3N + S', 'attached_max':8+3*12+12,
    'content_direct_children_formula':'5 + 2N + S', 'direct_max':5+2*12+12,
    'content_descendants_formula':'6 + 3N + S', 'descendant_max':6+3*12+12,
    'anchors':'App/SpatialPreview.swift:311-369,449-479',
  },
  'realitykit': {
    'graph_base_breakdown':{'graph_anchor':1,'floor':1,'subject_and_camera_body_roots':2,
      'head_neck_torso_nose_body_lens':6,'neutral_fill':1,'grid_lines':42},
    'lamp_breakdown':{'root_fixture_emission_selection':4,
      'point_housing_face_stand_footX_footZ_aimLine_aimTarget':8,'outline_edges':12},
    'graph_formula':'53 + 24N', 'graph_max':53+24*12,
    'coordinator_camera_anchor_and_camera':2, 'owned_formula':'55 + 24N','owned_max':55+24*12,
    'attachment':'Both adapter anchors attached only while active and on-window; detachment does not establish deallocation.',
    'shading':'At most seven eligible authored lights plus separate neutral fill; all <=12 lamp representations retained.',
    'anchors':'App/StudioEntityGraph.swift:12-66,100-121,195-246; App/RealityStudioPreview.swift:98-100,170-225',
  },
}

identities = [identity(x) for x in all_workers]
summary = {
 'actual_completed_contexts':len(all_workers), 'unique_context_ids':len(set(identities)),
 'waves':dict(collections.Counter(x['wave'] for x in all_workers)),
 'root_present':'/root' in identities, 'all_fork_turns_none':all(x['fork_turns']=='none' for x in all_workers),
 'retained_report_hashes_verified':sum(x.get('matches_aggregate',False) and x.get('matches_source_ledger',False) for x in reports),
 'recovered_summary_only_reports':sum(x['wave']=='w01' for x in reports),
 'whole_report_files':sum(x['wave'] not in ('w01','w02') for x in reports),
 'embedded_recovered_report_texts':sum(x['wave']=='w02' for x in reports),
 'manifest_file_count':sum(x['path'].endswith('manifest.sha256') for x in manifest_checks),
 'manifest_entry_count':sum(len(x['entries']) for x in manifest_checks if x['path'].endswith('manifest.sha256')),
 'sidecar_entry_count':sum(len(x['entries']) for x in manifest_checks if not x['path'].endswith('manifest.sha256')),
 'all_manifest_and_sidecar_hashes_match':all(y['matches'] for x in manifest_checks for y in x['entries']),
 'all_ledger_id_sets_match':all(x['same_ids'] for x in ledger_checks),
 'all_normalized_role_sets_match':all(x['normalized_roles_match'] for x in ledger_checks),
 'embedded_scoped_findings_hash_matches':scoped_actual == scoped_expected,
}
evidence = {
 'created_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'revisions':{'documentation':DOCS,'production':SOURCE,'baseline':BASELINE},
 'executed':'Python standard-library JSON parsing, SHA256 hashing and integer arithmetic, with read-only git show/ls-tree; no build, install, application, native test or source mutation.',
 'summary':summary,'ledger_checks':ledger_checks,'report_hash_checks':reports,
 'manifest_and_sidecar_checks':manifest_checks,
 'scoped_findings_hash':{'path':scoped_report,'expected':scoped_expected,'actual':scoped_actual,'matches':scoped_actual==scoped_expected,
  'definition':'Bytes after the ## Findings heading and its terminating LF, with final LF preserved.',
  'disposition':'Concrete archival body-hash inconsistency; whole-file ledger/manifest/sidecar hashes match. Root should append a superseding clarification without rewriting historical report bytes.'},
 'input_hashes':inputs,'w10_resource_and_creation_snapshots':snapshots,'static_topology':topology,
 'provenance_limits':[
  'Four executor outages remain explicitly documented in RECOVERY.md; cause is not inferred.',
  'Wave01 summaries establish recorded completion identities but do not recover original reports or hashes.',
  'Wave02 hashes bind exact recovered text, not inaccessible original files.',
  'Wave04 unpublished reports include reconstruction labels; wave06 resource checks were reconstructed from tool results without an original JSON digest.',
  'Wave06 platform report reconstruction matched its preserved original hash; wave07 resource values are parent-provided, not lead-measured.',
  'Wave08 and wave09 distinguish root/lead resource snapshots and exact observation cutoffs; W10 dispatch snapshots are host free-space and MemAvailable values, not worker RSS, peak usage or device/runtime measurements.',
  '100 requires final W10 report retention/hash verification and root aggregate verification. Root and same-context followups receive no worker credit.',
  'Historical pending cutoffs are immutable history; newer root receipts must supersede separately. No previous source native pass transfers to changed source.',
  'No deallocation, leak, renderer-thread atomicity, FPS, device behavior, manual accessibility or measured token-compliance claim.',
 ]
}
(OUT/'evidence.json').write_text(json.dumps(evidence,indent=2)+'\n')
print(json.dumps(summary,indent=2))
print(json.dumps({'scoped_findings_hash_matches':scoped_actual==scoped_expected,'evidence_sha256':digest((OUT/'evidence.json').read_bytes())},indent=2))
