#!/usr/bin/env python3
"""W92 retained evidence reconciliation; no Swift/BVH/render/test execution.

Topology uses only W22's disclosed profile/vertex translation. It neither
repeats the archived ray probes nor establishes universal geometry correctness.
"""
import ast
from collections import Counter, defaultdict
from decimal import Decimal
import hashlib
import json
import math
from pathlib import Path
import platform
import re
import subprocess
import sys

WORK = Path('/tmp/keyfill03-7f4b/workers/W92-geometry')
ROOT = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
BASE = 'docs/parallel/03/'
OUT = ROOT / (BASE + 'wave10-evidence/W92-geometry.json')
EXPECTED = '342e3280e3eb077d55e122c8bfb88b4062b431ed'
CPU = 'db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5'
hashes = {}
commands = []

def digest(data):
    return hashlib.sha256(data).hexdigest()

def read(name, root=WORK):
    data = (root / name).read_bytes()
    key = name if root == WORK else 'integration:' + name
    hashes[key] = {'sha256': digest(data), 'bytes': len(data)}
    return data

def doc(name):
    return json.loads(read(BASE + name))

def git(*args):
    completed = subprocess.run(['git', *args], cwd=WORK, capture_output=True, text=True)
    commands.append({'argv': ['git', *args], 'cwd': str(WORK), 'exit': completed.returncode,
                     'stdout': completed.stdout, 'stderr': completed.stderr})
    assert completed.returncode == 0
    return completed.stdout.strip()

def ppm(name):
    data = read(BASE + name)
    magic, dimensions, maximum, rgb = data.split(b'\n', 3)
    width, height = map(int, dimensions.split())
    assert magic == b'P6' and maximum == b'255' and len(rgb) == width * height * 3
    return width, height, rgb

assert git('rev-parse', 'HEAD') == EXPECTED
tree = git('rev-parse', 'HEAD^{tree}')
assert git('status', '--short') == ''
git('diff', '--quiet', CPU, '--', 'Sources/LightingCore')
mesh_name = 'Sources/LightingCore/PortraitHeadMesh.swift'
study_name = 'Sources/LightingCore/PortraitStudy.swift'
mesh = read(mesh_name).decode()
study = read(study_name).decode()
mesh_tests = read('Tests/LightingCoreTests/PortraitHeadMeshTests.swift').decode()
camera_tests = read('Tests/LightingCoreTests/PortraitCameraDepthTests.swift').decode()
for name in ['AGENTS.md', 'agents/OPERATING_PROTOCOL.md', 'docs/acceptance/m02-m03-code.md', BASE+'WORKER_PROTOCOL.md']:
    read(name)
manifest = doc('evidence/final-source-manifest.json')
cpu_matches = {p: digest(read(p)) == h for p, h in manifest['sourceSHA256'].items() if p.startswith('Sources/LightingCore/')}
assert len(cpu_matches) == 31 and all(cpu_matches.values())

old_mesh = git('show', 'f150f98e35dd735927075aac4d2f8b02295c6a67:' + mesh_name)
def geometry_blocks(text):
    return [text[text.index('    static let latitudeSegments'):text.index('    private struct Profile')],
            text[text.index('    static func ringY'):text.index('    var triangleCount')]]
assert geometry_blocks(mesh) == geometry_blocks(old_mesh)
helper = read(BASE+'workers/wave03-evidence/W22-geometry/probe.py').decode()
definitions = [n for n in ast.parse(helper).body if isinstance(n, ast.FunctionDef) and n.name in {'profile','vertex'}]
assert len(definitions) == 2
profile = [tuple(map(float, x)) for x in re.findall(r'\.init\(y:\s*([-\d.]+), width:\s*([-\d.]+), front:\s*([-\d.]+), back:\s*([-\d.]+)\)', mesh)]
assert len(profile) == 12
scope = {'PROFILE': profile, 'ROWS': 42, 'COLS': 64, 'math': math}
exec(compile(ast.Module(body=definitions, type_ignores=[]), 'W22-profile-vertex-only', 'exec'), scope)
vertex = scope['vertex']
vertices, edges, directed, neighbors = {}, Counter(), Counter(), defaultdict(set)
retained, excluded, areas = 0, 0, []
for row in range(42):
    for col in range(64):
        a,b,c,d = vertex(row,col),vertex(row,col+1),vertex(row+1,col),vertex(row+1,col+1)
        for face in [(a,b,c),(b,d,c)]:
            e1 = tuple(x-y for x,y in zip(face[1],face[0])); e2 = tuple(x-y for x,y in zip(face[2],face[0]))
            cross = (e1[1]*e2[2]-e1[2]*e2[1], e1[2]*e2[0]-e1[0]*e2[2], e1[0]*e2[1]-e1[1]*e2[0])
            squared = sum(x*x for x in cross)
            if squared <= 1e-24:
                assert squared == 0
                excluded += 1
                continue
            retained += 1; areas.append(math.sqrt(squared))
            ids = [vertices.setdefault(p,len(vertices)) for p in face]
            for u,v in zip(ids,ids[1:]+ids[:1]):
                edges[tuple(sorted((u,v)))] += 1; directed[u,v] += 1
                neighbors[u].add(v); neighbors[v].add(u)
seen, pending = set(), [0]
while pending:
    v = pending.pop()
    if v not in seen:
        seen.add(v); pending.extend(neighbors[v]-seen)
topology = {'vertices': len(vertices), 'edges': len(edges), 'triangles': retained,
            'coincidentPoleTrianglesExcluded': excluded, 'connectedVertices': len(seen),
            'eulerCharacteristic': len(vertices)-len(edges)+retained,
            'edgeIncidenceHistogram': dict(Counter(edges.values())),
            'nonopposingEdges': sum(directed[u,v] != 1 or directed[v,u] != 1 for u,v in edges),
            'minimumTwiceAreaSquareMeters': min(areas),
            'geometryBlocksUnchangedFromCampaignFallback': True,
            'geometryBlockSHA256': [digest(s.encode()) for s in geometry_blocks(mesh)],
            'scope': 'Python topology from W22 surface translation; no Swift, self-intersection, BVH or universal ray proof.'}
assert (len(vertices),len(edges),retained,excluded,len(seen)) == (2626,7872,5248,128,2626)
assert topology['nonopposingEdges'] == 0 and set(edges.values()) == {2}

witness = doc('evidence/grazing-original.json')
w22 = doc('workers/wave03-evidence/W22-geometry/results.json')
rays = w22['rays']
assert len(rays) == 50
assert Counter(r['name'].split('/')[-1] for r in rays) == {'forward':25,'reverse':25}
assert all(r['planeWindows'] == r['mtWindows'] == [False,True,False] for r in rays)
assert all(len(r['plane']) == len(r['mt']) == 1 and r['plane'][0]['face'] == r['mt'][0]['face'] == r['face'] for r in rays)
w30 = doc('workers/wave03-evidence/W30-independent-review/results.json')
w30_inputs = doc('workers/wave03-evidence/W30-independent-review/inputs.json')
records = w30['records']
assert len(records) == len(w30_inputs['rays']) == 25
assert all(r['selectedFaceWindows'] == [False,True,False] for r in records)
assert all(Decimal(r['residual']) < Decimal('1e-80') for r in records)
assert {r['name']: (r['origin'],r['direction']) for r in rays if r['name'].endswith('/forward')} == {r['name']: (r['origin'],r['direction']) for r in w30_inputs['rays']}
w30_code = read(BASE+'workers/wave03-evidence/W30-independent-review/linear_oracle.py').decode()
assert 'ctx.prec=90' in w30_code
log_receipts = {}
for name in ['wave03-debug.log','wave03-release.log','wave05-release-serial.log']:
    lines = read(BASE+'evidence/'+name).decode().splitlines()
    log_receipts[name] = [line for line in lines if "Test Case 'PortraitHeadMeshTests.testNearTangentFiniteSegmentsAcrossPolarAndRegularFaces' passed" in line or "Test Case 'PortraitHeadMeshTests.testPreservedNearTangentPolarSegmentMatchesIndependentOracle' passed" in line or (name == 'wave05-release-serial.log' and "Test Case 'PortraitCameraDepthTests." in line and ' passed ' in line)]
    assert len(log_receipts[name]) == (7 if name == 'wave05-release-serial.log' else 2)
grazing = {'original': witness, 'swiftNearTangentCases': 25,
           'swiftCaseDerivation': '1 preserved plus 6 faces x 2 incidences x 2 directions; archived two test-method passes, not a new execution.',
           'w22': {'rays':len(rays), 'distinctInputWindows':sum(len(r['planeWindows']) for r in rays), 'windowsPerMethod':sum(len(r['planeWindows']) for r in rays),
                   'windowDefinition':'150 distinct input windows, each evaluated by both translated methods; not 300 distinct cases.',
                   'originalCutoffMisses':sum(not r['oldAbsoluteDeterminantHit'] for r in rays),
                   'uniqueMatchingFaces':len(rays), 'stressRows':len(w22['thresholdStress']),
                   'planeVsMTThresholdDisagreements':sum(r['planePass'] != r['determinantPass'] for r in w22['thresholdStress'])},
           'w30': {'decimalPrecision':90, 'selectedFaceSolves':len(records), 'distinctFaces':len({tuple(r['face']) for r in records}), 'windows':sum(len(r['selectedFaceWindows']) for r in records),
                   'originalCutoffMisses':sum(r['oldCutoffRejects'] for r in records),
                   'maximumResidual':str(max(Decimal(r['residual']) for r in records))},
           'limits':'W22 is translated Python full-mesh arithmetic; W30 is a selected-face 90-digit solve sharing W22 geometry/rounded inputs. Neither is Swift/BVH execution. Their windows do not add to the 25 Swift cases. No universal near-parallel or endpoint proof.'}
assert grazing['w22']['originalCutoffMisses'] == 14 and grazing['w30']['originalCutoffMisses'] == 7

original = doc('evidence/camera-original/result.json'); corrected = doc('evidence/camera-corrected/result.json')
width,height,rgb = ppm('evidence/camera-original/overhead-clipped.ppm')
mask = read(BASE+'evidence/camera-original/overhead-clipped.mask')
invalid = {i for i,x in enumerate(mask) if x}
magenta = {i for i in range(width*height) if rgb[3*i:3*i+3] == bytes([255,0,255])}
assert len(mask) == width*height and invalid == magenta and len(invalid) == 11708
assert next(r for r in original if r['name'] == 'overhead-clipped')['unsupportedPixels'] == len(invalid)
assert next(r for r in corrected if r['name'] == 'overhead-clipped')['error'] == 'invalidCamera'
assert not list((WORK/(BASE+'evidence/camera-corrected')).glob('overhead-clipped.*'))
clear_equal = {}
for extension in ['ppm','png','mask']:
    clear_equal[extension] = read(BASE+'evidence/camera-original/overhead-clear.'+extension) == read(BASE+'evidence/camera-corrected/overhead-clear.'+extension)
assert all(clear_equal.values())
before = doc('workers/wave04-evidence/W32-guard-scan-results.json')
after = doc('workers/wave04-evidence/W32-depth-corrected-results.json')
sidecar = doc('workers/wave04-evidence/W32-depth-corrected-inputs.json')
outcomes = {}
for label,data in [('facingOnly',before),('firstSurface',after)]:
    calls = [r for c in data['counterexamples'] for r in c['rendererOutcomes']]
    assert len(calls) == 40 and len(data['counterexamples']) == 8
    assert all([r['width'] for r in c['rendererOutcomes']] == [24,48,72,120,144] for c in data['counterexamples'])
    outcomes[label] = dict(Counter('invalidCamera' if r.get('error') == 'invalidCamera' else r['outcome'] for r in calls))
assert outcomes == {'facingOnly':{'returnedImage':32,'invalidCamera':8}, 'firstSurface':{'invalidCamera':40}}
assert [(r['camera'],r['focalLengthMillimeters']) for r in before['counterexamples']] == [(r['camera'],r['focalLengthMillimeters']) for r in after['counterexamples']]
assert all(sidecar['sourceSHA256'][p] == digest(read(p)) for p in [mesh_name,study_name])
camera_review = doc('evidence/camera-review.json')
primary_calls = re.findall(r'geometry\.hit\(', study[study.index('public enum PortraitStudyRenderer'):])
assert len(primary_calls) == 1 and 'direction: ray, minimum: 0)' in study
assert 'guard hit.region == .panel else { throw StudyError.invalidCamera }' in study
assert len(re.findall(r'func test\w+\(',camera_tests)) == 5
camera = {'originalClipped':{'width':width,'height':height,'invalidPositions':len(invalid),'maskEqualsMagentaPositions':True},
          'overheadCorrected':'invalidCamera; no overhead-clipped frame files in corrected archive',
          'clearFilesByteEqual':clear_equal, 'heldOutCalls':outcomes, 'heldOutCandidates':8,
          'heldOutGuardAcceptedClippedPoses':before['counts']['guardAcceptedClippedPoses'],
          'sidecarActualParent':sidecar['actualParent'], 'rawEmbeddedRevision':after['sourceRevision'],
          'sidecarMeshAndPortraitStudyMatchCurrent':True,
          'olderOverheadCorrectionSourceMatchesCurrent':camera_review['correctedSHA256'][study_name] == digest(read(study_name)),
          'provenanceNote':'camera-corrected overhead archive belongs to earlier facing-only repair; W32 exact-source sidecar binds final first-surface candidate. Raw embedded stale labels remain unchanged.',
          'sourceInspection':{'primaryGeometryHitCalls':len(primary_calls),'minimum':0,'closedSubjectNearHit':'invalidCamera','openPanelNearHit':'background','cameraRegressionMethods':5}}

matrix = []
original_manifest = doc('evidence/original/manifest.json')['fixtures']
final_manifest = doc('evidence/final/manifest.json')
assert len(original_manifest) == len(final_manifest) == 12
assert sorted(x['name'] for x in original_manifest) == sorted(x['name'] for x in final_manifest)
for item in final_manifest:
    name = item['name']; original_prefix=BASE+'evidence/original/'+name; final_prefix=BASE+'evidence/final/'+name
    before_ppm=read(original_prefix+'.ppm'); after_ppm=read(final_prefix+'.ppm')
    before_scene=read(original_prefix+'.json'); after_scene=read(final_prefix+'.json')
    w,h,rgb=ppm('evidence/final/'+name+'.ppm'); final_mask=read(final_prefix+'.mask'); rgba=read(final_prefix+'.rgba')
    assert len(final_mask)==w*h and set(final_mask)=={0} and len(rgba)==w*h*4
    assert bytes(c for i,c in enumerate(rgba) if i%4 != 3)==rgb and set(rgba[3::4])=={255}
    assert before_ppm==after_ppm and before_scene==after_scene
    matrix.append({'name':name,'ppmBytesEqual':True,'sceneBytesEqual':True,'finalMaskBytes':len(final_mask),'finalMaskNonzero':0,
                   'originalRawMaskPresent':(WORK/(original_prefix+'.mask')).exists(),'originalRawRGBAPresent':(WORK/(original_prefix+'.rgba')).exists()})
for path in ['evidence/grazing-ray-probe.swift','evidence/portrait-camera-visual.swift','evidence/wave02-original-probes.log',
             'evidence/camera-original-tests.log','evidence/camera-corrected-tests.log','evidence/camera-corrected-tests-v2.log',
             'workers/wave04-evidence/W32-guard-scan.swift','workers/wave04-evidence/W32-review-receipt.json']:
    read(BASE+path)
read(BASE+'workers/W82-geometry.md',ROOT)
read(BASE+'workers/wave09-evidence/W82-geometry-data.json',ROOT)
read(BASE+'HANDOFF.md',ROOT)
assert git('status','--short') == ''
result={'runtimeID':'/root/wave10/w92_geometry','inputSHA':EXPECTED,'inputTree':tree,'privateWorktree':str(WORK),
        'unchangedCPUReference':CPU,'all31FinalManifestCPUFilesMatch':cpu_matches,'host':platform.platform(),'python':sys.version,
        'command':'python3 docs/parallel/03/wave10-evidence/W92-geometry.py','commandWorkingDirectory':str(ROOT),
        'subprocessCommandsExecuted':commands,'scriptSHA256':digest(Path(__file__).read_bytes()),
        'otherExecutedCommands':['python3 scripts/agent_cycle.py check','python3 scripts/agent_cycle.py next'],
        'agentCycleResults':['Structure and references valid; not artifact truth or release readiness.','M03 editing/accessibility/persistence remain outstanding.'],
        'inspectionTools':'git status/HEAD/branch/log; rg inventories and focused matches; cat/sed bounded source/evidence reads; inline Python JSON metadata inspection.',
        'correctedReadErrors':['Aggregate tool output truncated twice; required protocol and relevant source/evidence reread in bounded form.','Broad oracle/log match output truncated; bounded translation/precision reads and exact method-pass extraction replaced it.','First W92 script execution exited 1 at line 194: AssertionError from len(original_manifest) == len(final_manifest) == 12. Original manifest is an object with fixtures[12], while final is a list[12]. Read corrected to original_manifest[fixtures], names checked; no evidence or source changed.'],
        'scriptExecutionHistory':[{'attempt':1,'command':'python3 docs/parallel/03/wave10-evidence/W92-geometry.py','exit':1,'error':'AssertionError: incorrect assumption that original manifest is a top-level list; corrected reader only.'},{'attempt':2,'command':'python3 docs/parallel/03/wave10-evidence/W92-geometry.py','exit':0,'result':'All scoped archive consistency assertions completed.'},{'attempt':3,'command':'python3 docs/parallel/03/wave10-evidence/W92-geometry.py','exit':0,'result':'Metadata label clarified: 25 selected-face solves span six distinct faces; scoped assertions repeated.'},{'attempt':4,'command':'python3 docs/parallel/03/wave10-evidence/W92-geometry.py','exit':0,'result':'Clarified 150 distinct W22 input windows, evaluated by both translated methods; no additive Swift coverage.'}],
        'topology':topology,'grazing':grazing,'retainedTestLogReceipts':log_receipts,'camera':camera,'ordinaryMatrix':matrix,
        'artifactHashes':hashes,'blockers':[],
        'limits':['Only archive/record/byte reconciliation and translated Python topology executed by W92.','No Swift execution, builds, renderer runs, benchmarks, native/device checks or image viewing.','Original ordinary raw masks/RGBA are absent; no equality claim for them.','Zero masks do not prove geometry coverage.','No universal geometry/self-intersection/ray proof; no global M02/M03 or release acceptance.','Exact token counters unavailable; working-budget compliance not certified.']}
OUT.write_text(json.dumps(result,indent=2,sort_keys=True)+'\n')
print(json.dumps({'receipt':str(OUT),'sha256':digest(OUT.read_bytes()),'sourceFiles':len(cpu_matches),'topology':topology,
                  'w22':grazing['w22'],'w30':grazing['w30'],'cameraOutcomes':outcomes,'ordinaryScenes':len(matrix),'artifactHashes':len(hashes)},indent=2))
