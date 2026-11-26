#!/usr/bin/env python3
"""Independent 90-digit Gaussian elimination; no MT or projected-area oracle."""
import ast
import hashlib
import json
import math
import platform
import re
import shutil
import subprocess
import time
from datetime import datetime, timezone
from decimal import Decimal, localcontext
from pathlib import Path

started = time.perf_counter()
tree = Path('/tmp/keyfill03-7f4b/workers/W30-independent-review')
workers = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03/docs/parallel/03/workers')
w22 = workers / 'wave03-evidence/W22-geometry'
out = Path(__file__).parent
expected_sha = '1cefc654630a86ab320e58283957f4e91d6cbce6'
def git(*args):
    return subprocess.check_output(['git', '-C', str(tree), *args], text=True).strip()
assert git('rev-parse', 'HEAD') == expected_sha
assert git('status', '--short') == ''
source = tree / 'Sources/LightingCore/PortraitHeadMesh.swift'
profile = [tuple(map(float, match)) for match in re.findall(
    r'\.init\(y:\s*([-\d.]+), width:\s*([-\d.]+), front:\s*([-\d.]+), back:\s*([-\d.]+)\)', source.read_text())]
assert len(profile) == 12
# Reuse ONLY W22 prescribed-vertex definitions, not its intersection/expectation code.
module = ast.parse((w22 / 'probe.py').read_text())
geometry = [n for n in module.body if isinstance(n, ast.FunctionDef) and n.name in {'profile', 'vertex'}]
assert len(geometry) == 2
ns = {'PROFILE': profile, 'ROWS': 42, 'COLS': 64, 'math': math}
exec(compile(ast.Module(body=geometry, type_ignores=[]), 'w22_vertex_inputs_only', 'exec'), ns)
vertex = ns['vertex']
raw_rays = json.loads((w22 / 'results.json').read_text())['rays']
rays = [{k:r[k] for k in ['name','face','origin','direction']} for r in raw_rays if r['name'].endswith('/forward')]
assert len(rays) == 25
faces = [(0,0,True),(0,16,True),(41,32,False),(10,7,False),(20,19,True),(30,37,False)]
assert set(tuple(r['face']) for r in rays) == set(faces)
vertices = {}
for row,col,second in faces:
    a,b,c,d = vertex(row,col),vertex(row,col+1),vertex(row+1,col),vertex(row+1,col+1)
    vertices[str((row,col,second))] = [b,d,c] if second else [a,b,c]
inputs = {'label':'W22 raw binary64 ray inputs and prescribed vertices only', 'vertices':vertices, 'rays':rays}
(out / 'inputs.json').write_text(json.dumps(inputs, indent=2)+'\n')

def solve(matrix, rhs):
    """Partial-pivot Gaussian elimination; determinant is signed pivot product."""
    original = [row[:] for row in matrix]
    aug = [row[:] + [value] for row,value in zip(matrix,rhs)]
    determinant = Decimal(1)
    for col in range(3):
        pivot = max(range(col,3), key=lambda r: abs(aug[r][col]))
        assert aug[pivot][col] != 0
        if pivot != col:
            aug[pivot],aug[col] = aug[col],aug[pivot]
            determinant = -determinant
        determinant *= aug[col][col]
        for row in range(col+1,3):
            scale = aug[row][col] / aug[col][col]
            for k in range(col,4): aug[row][k] -= scale * aug[col][k]
    x = [Decimal(0)] * 3
    for row in range(2,-1,-1):
        x[row] = (aug[row][3]-sum(aug[row][j]*x[j] for j in range(row+1,3))) / aug[row][row]
    residual = max(abs(sum(original[i][j]*x[j] for j in range(3))-rhs[i]) for i in range(3))
    assert residual < Decimal('1e-80')
    return x,determinant,residual

records=[]
with localcontext() as ctx:
    ctx.prec=90
    for ray in rays:
        a,b,c = [[Decimal.from_float(x) for x in v] for v in vertices[str(tuple(ray['face']))]]
        origin,direction = [[Decimal.from_float(x) for x in ray[k]] for k in ['origin','direction']]
        matrix = [[b[i]-a[i],c[i]-a[i],-direction[i]] for i in range(3)]
        (u,v,t),det,residual = solve(matrix,[origin[i]-a[i] for i in range(3)])
        weights=[1-u-v,u,v]
        windows = [Decimal(lo) <= t < Decimal(hi) for lo,hi in [('1e-6','4e-5'),('1e-6','1e-4'),('6e-5','1e-4')]]
        assert windows == [False,True,False], ray['name']
        assert abs(t-Decimal('5e-5')) < Decimal('1e-8'), ray['name']
        assert all(Decimal('.30') < w < Decimal('.37') for w in weights), ray['name']
        records.append({'name':ray['name'],'face':ray['face'],'t':str(t),'weights':list(map(str,weights)),
                        'determinantFromPivots':str(det),'oldCutoffRejects':abs(det)<=Decimal.from_float(1e-14),
                        'selectedFaceWindows':windows,'residual':str(residual)})
    summary = {'inputSHA':expected_sha,'runtimeTaskID':'/root/wave03/independent_review',
               'utc':datetime.now(timezone.utc).isoformat(),'host':platform.platform(),'python':platform.python_version(),
               'label':'Independent high-precision linear solve; not Swift/BVH execution',
               'decimalPrecision':90,'rayCount':len(records),'windowChecks':3*len(records),
               'maxCentroidDistanceErrorMeters':str(max(abs(Decimal(r['t'])-Decimal('5e-5')) for r in records)),
               'minWeight':str(min(Decimal(w) for r in records for w in r['weights'])),
               'maxWeight':str(max(Decimal(w) for r in records for w in r['weights'])),
               'oldCutoffRejectedRayCount':sum(r['oldCutoffRejects'] for r in records),
               'oldCutoffRejectedRayNames':[r['name'] for r in records if r['oldCutoffRejects']],
               'preserved':records[0], 'probeSeconds':time.perf_counter()-started,
               'sha256':{str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in [source,tree/'Tests/LightingCoreTests/PortraitHeadMeshTests.swift',w22/'probe.py',w22/'results.json']}}
assert summary['oldCutoffRejectedRayCount']==7
assert records[0]['name']=='preserved/forward' and records[0]['oldCutoffRejects']
assert git('status','--short')==''
summary['finalPrivateGitStatus']='clean'
(out/'results.json').write_text(json.dumps({'summary':summary,'records':records},indent=2)+'\n')
commands = """Initial working directory: /tmp/keyfill03-7f4b/workers/W30-independent-review
Executed: git rev-parse HEAD
Result: 1cefc654630a86ab320e58283957f4e91d6cbce6
Executed: git status --short
Result: empty
Read together using inline Python Path.read_text(): AGENTS.md, agents/OPERATING_PROTOCOL.md, docs/acceptance/m02-m03-code.md, docs/parallel/03/WORKER_PROTOCOL.md.
Executed: rg --files | rg 'PortraitHeadMeshTests.swift$|W22-geometry|W30-independent-review'
Result: Tests/LightingCoreTests/PortraitHeadMeshTests.swift
Read tests, W22 probe.py and JSON metadata, and production determinant lines using inline Python. No Swift compilation/execution.
Exact probe execution command:
python /tmp/keyfill03-7f4b/builds/W30-independent-review/linear_oracle.py
The complete executed script is preserved alongside this log. It performs exact subprocess commands:
git -C /tmp/keyfill03-7f4b/workers/W30-independent-review rev-parse HEAD
git -C /tmp/keyfill03-7f4b/workers/W30-independent-review status --short
Final result: HEAD unchanged; private worktree clean.
"""
(out/'commands.txt').write_text(commands)
saved=workers/'wave03-evidence/W30-independent-review'
saved.mkdir(parents=True,exist_ok=True)
for name in ['linear_oracle.py','inputs.json','results.json','commands.txt']:
    shutil.copyfile(out/name,saved/name)
err=float(summary['maxCentroidDistanceErrorMeters'])
lo=float(summary['minWeight']); hi=float(summary['maxWeight'])
report=f"""# W30 — Independent grazing-test challenge

Actual runtime/task ID: `/root/wave03/independent_review`. Input `{expected_sha}`; private detached tree `/tmp/keyfill03-7f4b/workers/W30-independent-review`. Host {platform.platform()}, Python {platform.python_version()}; 90-digit Decimal probe took {summary['probeSeconds']:.6f} seconds. Mandatory four-file batch and relevant source were read.

## Concrete falsification

Challenge: the near-tangent plane/projection oracle might manufacture a centroid hit through cancellation, leaving the two new tests unable to detect the original absolute-determinant defect. Independently solved `[B−A, C−A, −D] [u,v,t] = O−A` by partial-pivot Gaussian elimination on the exact represented binary64 inputs. Only W22 raw forward rays and prescribed-vertex construction were reused; no W22 intersection expectations, projected-area calculation, MT predicate, or full-mesh enumeration was executed.

All 25 selected-face solves (preserved ray plus 24 prescribed constructions) give interior weights in [{lo:.12f}, {hi:.12f}] and the fixed-window pattern false/true/false: 75 checks. Maximum deviation from 5e-5 m is {err:.12g} m, within 1e-8 m. Preserved t = {float(records[0]['t']):.17g} m. Linear-system residuals are below 1e-80.

The pivot-product determinant independently reproduces the failure mechanism: seven valid crossings have |det| ≤ 1e-14, including the preserved ray and all six generated polar cases at incidence 1e-8. Thus **each new method contains crossings rejected by the original cutoff**. No counterexample to the selected-face expectations was found. This establishes mathematical regression sensitivity; it is not a new actual Swift before/after execution.

## Execution and limits

Executed `git rev-parse HEAD`, `git status --short`, source reads, then `python /tmp/keyfill03-7f4b/builds/W30-independent-review/linear_oracle.py`: exit 0, all assertions passed. Script, exact inputs, results and command log are retained in `wave03-evidence/W30-independent-review/` beside this report. Final private HEAD is unchanged and status is clean; only assigned report/evidence outputs were written outside the build directory.

Geometry and input rounding still share W22's Python translation. Mesh-wide uniqueness, BVH traversal, Swift arithmetic, native execution, exact endpoint semantics, and incidence near 1e-14 were not independently tested. Root's 380 Debug/380 Release results remain external evidence. No source edits, builds, renders or publication occurred.
"""
(workers/'W30-independent-review.md').write_text(report)
print(json.dumps({'summary':summary,'report':str(workers/'W30-independent-review.md'),'artifactDirectory':str(saved)},indent=2))
