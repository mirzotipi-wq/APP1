"""Pinned-object inspection only; no compiler, build, test or network execution."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

REPO = Path('/tmp/keyfill05-be879deb/repo')
OUT = Path('/tmp/keyfill05-be879deb/waves/w10/implementation')
BASE = 'f150f98e35dd735927075aac4d2f8b02295c6a67'
SOURCE = '60059a0b8c5f099efb3fb5fffb3a1b8fee1df45a'
DOCS = '1d3195eb7ee6fcd87a9b1a379a4f12f7c555c65a'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=REPO)

def inventory(revision):
    files = git('ls-tree', '-r', '--name-only', revision, '--', 'NativeTests').decode().splitlines()
    result = {}
    for path in files:
        if not path.endswith('.swift'):
            continue
        contents = git('show', f'{revision}:{path}').decode()
        # Match declarations with same-line attributes too, as the repository
        # accounting script does (four PDF methods use @MainActor func).
        result[path] = re.findall(r'\bfunc\s+(test\w*)\s*\(', contents)
    return result

base = inventory(BASE)
source = inventory(SOURCE)
spatial = {p: methods for p, methods in source.items() if Path(p).name.startswith('Spatial')}
base_spatial = {p: methods for p, methods in base.items() if Path(p).name.startswith('Spatial')}
current_ids = {f'{p}:{m}' for p, methods in spatial.items() for m in methods}
base_ids = {f'{p}:{m}' for p, methods in base_spatial.items() for m in methods}
changed = git('diff', '--name-only', BASE, SOURCE, '--', 'App', 'NativeTests').decode().splitlines()
docs_changed = git('diff', '--name-only', SOURCE, DOCS).decode().splitlines()
file_records = []
for path in changed:
    raw = git('show', f'{SOURCE}:{path}')
    later = git('show', f'{DOCS}:{path}')
    file_records.append({
        'path': path,
        'source_blob': git('rev-parse', f'{SOURCE}:{path}').decode().strip(),
        'documentation_parent_blob': git('rev-parse', f'{DOCS}:{path}').decode().strip(),
        'source_sha256': hashlib.sha256(raw).hexdigest(),
        'bytes_equal_at_documentation_parent': raw == later,
    })
check = subprocess.run(['git', 'diff', '--check', BASE, SOURCE, '--', 'App', 'NativeTests'],
                       cwd=REPO, capture_output=True, text=True)
checkpoints = []
for commit in git('rev-list', '--reverse', f'{SOURCE}..{DOCS}').decode().splitlines():
    paths = git('diff', '--name-only', SOURCE, commit).decode().splitlines()
    checkpoints.append({'commit': commit, 'non_lane_documentation_changes':
                        [p for p in paths if not p.startswith('docs/parallel/05/')]})
data = {
    'baseline': BASE, 'source': SOURCE, 'documentation_parent': DOCS,
    'execution_scope': 'Python text enumeration, pinned git show/diff/tree/object inspection only; no native execution',
    'inventory_rule': r'\bfunc\s+(test\w*)\s*\( in NativeTests/**/*.swift; matches repository accounting',
    'inventory_parser_correction': 'First anchored pattern omitted four @MainActor func declarations in LightingPlanPDFTests; corrected before final evidence',
    'native_baseline': sum(map(len, base.values())),
    'native_current': sum(map(len, source.values())),
    'native_current_per_file': {p: len(m) for p, m in source.items()},
    'spatial_baseline': len(base_ids), 'spatial_current': len(current_ids),
    'spatial_added': len(current_ids - base_ids), 'spatial_removed': sorted(base_ids - current_ids),
    'arithmetic_state_methods': len(spatial['NativeTests/SpatialViewportStateTests.swift']),
    'direct_scenekit_methods': sum(len(m) for p, m in spatial.items()
                                  if p != 'NativeTests/SpatialViewportStateTests.swift'),
    'spatial_methods': spatial,
    'app_changed': sum(p.startswith('App/') for p in changed),
    'native_test_changed': sum(p.startswith('NativeTests/') for p in changed),
    'reviewed_files': file_records,
    'source_to_documentation_parent_changed_path_count': len(docs_changed),
    'source_to_documentation_parent_non_lane_documentation_changes':
        [p for p in docs_changed if not p.startswith('docs/parallel/05/')],
    'later_checkpoints': checkpoints,
    'diff_check': {'exit_code': check.returncode, 'stdout': check.stdout, 'stderr': check.stderr},
    'inspection_disposition': 'No new concrete defect demonstrated in the four App/seven native-test diff; no source edits requested',
    'review_anchors': {
        'App/SpatialPreview.swift': ['50-93 interaction/gesture refresh', '95-163 detach/current-hit membership',
                                     '204-272 invalid/mode recovery and fit state', '311-462 incremental equipment updates'],
        'App/RealityStudioPreview.swift': ['154-205 interaction/render/current-scene gates',
                                           '208-245 teardown and native projection upload', '247-299 gestures'],
        'App/StudioEntityGraph.swift': ['69-136 invalid-scene clearing and owned hit ancestry',
                                       '249-345 geometry, source/selection caching and rectangle face dimensions'],
        'App/SpatialViewportGeometry.swift': ['12-64 represented equipment bounds', '87-151 finite navigation and projection'],
        'App/StudioView.swift': ['506-511 inherited generation-keyed viewport; lane01 identity integration outstanding'],
    },
    'evidence_cutoffs': {
        'pinned_CI_progress_observed_utc': '2026-11-26T16:23:18Z',
        'pinned_native_job': 140022794410,
        'pinned_native_state': 'in_progress; native step pending',
        'root_supplied_at_assignment': 'native job 140022794410 remains running; current export UI 9 passed/1 failed, no viewport cause established',
        'preceding_source': '4e694bc377c4825d1d2dd52fcd7900e534c75072',
        'preceding_result_not_transferred': '184 native/38 spatial passed',
    },
    'owner_dependency': 'Integrate lane01 source 5ccfbaae821a32d88c12ed8b3abf1600aef25753 and verify first-save viewport retention plus replacement with overlapping UUIDs',
    'limits': ['Four recovered executor outages retained', 'Wave01 original reports lost; summary-only recovery retained',
               'No deallocation or renderer-thread atomicity claim', 'No FPS/device or manual-accessibility acceptance claim',
               'No measured token compliance claim', 'RealityKit runtime and delivered gestures unexecuted in this review'],
}
assert data['native_current'] == 185
assert (data['spatial_baseline'], data['spatial_current'], data['spatial_added']) == (8, 39, 31)
assert (data['arithmetic_state_methods'], data['direct_scenekit_methods']) == (11, 28)
assert (data['app_changed'], data['native_test_changed']) == (4, 7)
assert not data['spatial_removed']
assert not data['source_to_documentation_parent_non_lane_documentation_changes']
assert all(record['bytes_equal_at_documentation_parent'] for record in file_records)
assert check.returncode == 0
assert all(not record['non_lane_documentation_changes'] for record in checkpoints)
destination = OUT / 'evidence.json'
destination.write_text(json.dumps(data, indent=2) + '\n')
print(json.dumps({k: data[k] for k in ['native_baseline', 'native_current', 'spatial_baseline',
    'spatial_current', 'spatial_added', 'arithmetic_state_methods', 'direct_scenekit_methods',
    'app_changed', 'native_test_changed', 'source_to_documentation_parent_changed_path_count']}))
print(f'{hashlib.sha256(destination.read_bytes()).hexdigest()}  {destination}')
