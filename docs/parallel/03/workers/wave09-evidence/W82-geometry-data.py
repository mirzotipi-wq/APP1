#!/usr/bin/env python3
"""Read-only archive/topology audit. No renderer, Swift build, or benchmark.

Uses W22's disclosed Python surface translation for prescribed vertex data;
new checks weld coincident vertices and inspect directed edge incidences.
This is not an independent implementation of the Swift surface function.
"""
from collections import Counter, defaultdict
from hashlib import sha256
import json
from pathlib import Path
import platform
import subprocess
import sys

WORK = Path('/tmp/keyfill03-7f4b/workers/W82-geometry')
ROOT = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
BASE = WORK / 'docs/parallel/03'
OUT = ROOT / 'docs/parallel/03/workers/wave09-evidence/W82-geometry-data.json'

def digest(data):
    return sha256(data).hexdigest()

def git(*args):
    return subprocess.check_output(['git', *args], cwd=WORK)

def ppm(path):
    raw = path.read_bytes()
    magic, dimensions, maximum, rgb = raw.split(b'\n', 3)
    assert magic == b'P6' and maximum == b'255'
    width, height = map(int, dimensions.split())
    assert len(rgb) == width * height * 3
    return width, height, rgb

result = {
    'runtimeID': '/root/wave09/w82_geometry',
    'inputSHA': git('rev-parse', 'HEAD').decode().strip(),
    'inputTree': git('rev-parse', 'HEAD^{tree}').decode().strip(),
    'host': platform.platform(), 'python': sys.version,
    'command': 'python3 docs/parallel/03/workers/wave09-evidence/W82-geometry-data.py',
    'boundary': 'Read-only Python archive/combinatorial data checks. Reuses W22 surface translation; no Swift, BVH, renderer, build, benchmark, or native execution.',
    'scriptSHA256': digest(Path(__file__).read_bytes()),
}
files = [
    'Sources/LightingCore/PortraitHeadMesh.swift',
    'Sources/LightingCore/PortraitStudy.swift',
    'Sources/LightingCore/ReferenceStudy.swift',
    'Tests/LightingCoreTests/PortraitHeadMeshTests.swift',
    'Tests/LightingCoreTests/PortraitCameraDepthTests.swift',
    'docs/parallel/03/evidence/grazing-original.json',
    'docs/parallel/03/evidence/grazing-ray-probe.swift',
    'docs/parallel/03/evidence/final-source-manifest.json',
    'docs/parallel/03/evidence/original/manifest.json',
    'docs/parallel/03/evidence/final/manifest.json',
    'docs/parallel/03/evidence/camera-original/result.json',
    'docs/parallel/03/evidence/camera-corrected/result.json',
    'docs/parallel/03/workers/wave03-evidence/W22-geometry/probe.py',
]
result['inputSHA256'] = {name: digest((WORK/name).read_bytes()) for name in files}
result['inputSHA256']['root:docs/parallel/03/IMAGE_REVIEW.md'] = digest((ROOT/'docs/parallel/03/IMAGE_REVIEW.md').read_bytes())
manifest = json.loads((BASE/'evidence/final-source-manifest.json').read_text())
cpu = {name: expected for name, expected in manifest['sourceSHA256'].items() if name.startswith('Sources/')}
result['finalManifestCPUHashes'] = {name: digest((WORK/name).read_bytes()) == expected for name, expected in cpu.items()}
assert all(result['finalManifestCPUHashes'].values())

mesh_path = 'Sources/LightingCore/PortraitHeadMesh.swift'
original = git('show', 'f150f98e35dd735927075aac4d2f8b02295c6a67:' + mesh_path).decode()
current = (WORK/mesh_path).read_text()
def geometry_blocks(text):
    return [text[text.index('    static let latitudeSegments'):text.index('    private struct Profile')],
            text[text.index('    static func ringY'):text.index('    var triangleCount')]]
result['originalGeometryBlocksByteEqual'] = geometry_blocks(original) == geometry_blocks(current)
result['geometryBlockSHA256'] = [digest(s.encode()) for s in geometry_blocks(current)]
assert result['originalGeometryBlocksByteEqual']

helper = (BASE/'workers/wave03-evidence/W22-geometry/probe.py').read_text()
prefix = helper.split('\norigin = (', 1)[0]
prefix = prefix.replace("ROOT = Path('/tmp/keyfill03-7f4b/workers/W22-geometry')", 'ROOT = Path(' + repr(str(WORK)) + ')')
namespace = {'__file__': str(BASE/'workers/wave03-evidence/W22-geometry/probe.py')}
exec(compile(prefix, '<retained-W22-surface-data-prefix>', 'exec'), namespace)
triangles = namespace['triangles']
vertex_ids = {}
edges = Counter()
directions = Counter()
neighbors = defaultdict(set)
def vid(position):
    return vertex_ids.setdefault(tuple(position), len(vertex_ids))
for triangle in triangles:
    ids = [vid(p) for p in [triangle.a, triangle.b, triangle.c]]
    assert len(set(ids)) == 3
    for a, b in zip(ids, ids[1:] + ids[:1]):
        edges[tuple(sorted((a,b)))] += 1
        directions[(a,b)] += 1
        neighbors[a].add(b)
        neighbors[b].add(a)
seen = set()
pending = [0]
while pending:
    item = pending.pop()
    if item not in seen:
        seen.add(item)
        pending.extend(neighbors[item] - seen)
topology = {
    'verticesAfterExactPositionWelding': len(vertex_ids),
    'triangles': len(triangles), 'edges': len(edges),
    'eulerCharacteristic': len(vertex_ids) - len(edges) + len(triangles),
    'edgeIncidenceHistogram': dict(Counter(edges.values())),
    'edgesWithoutOpposingDirections': sum(directions[(a,b)] != 1 or directions[(b,a)] != 1 for a,b in edges),
    'connectedVertices': len(seen),
    'coincidentPoleTrianglesExcluded': namespace['degenerate'],
    'minTwiceArea': min(t.twice for t in triangles),
    'excludedNonzeroTriangles': 0,
    'limit': 'Connectivity does not test self-intersection or prove all camera rays valid.',
}
assert topology['triangles'] == 5248 and topology['eulerCharacteristic'] == 2
assert topology['edgeIncidenceHistogram'] == {2:7872}
assert topology['edgesWithoutOpposingDirections'] == 0 and len(seen) == len(vertex_ids)
result['topology'] = topology
result['crownRings'] = [{'row': row, 'yMeters': vertices[0][1],
    'xSpanMeters': max(p[0] for p in vertices) - min(p[0] for p in vertices)}
    for row, vertices in enumerate(namespace['vertices']) if row >= 38]

original_manifest = json.loads((BASE/'evidence/original/manifest.json').read_text())['fixtures']
final_manifest = json.loads((BASE/'evidence/final/manifest.json').read_text())
assert len(original_manifest) == len(final_manifest) == 12
assert {f['name'] for f in original_manifest} == {f['name'] for f in final_manifest}
matrix = []
for fixture in original_manifest:
    name = fixture['name']
    a, b = BASE/'evidence/original'/name, BASE/'evidence/final'/name
    width, height, rgb = ppm(b.with_suffix('.ppm'))
    mask = b.with_suffix('.mask').read_bytes()
    rgba = b.with_suffix('.rgba').read_bytes()
    rec = {'name': name, 'ppmSHA256': digest(b.with_suffix('.ppm').read_bytes()),
        'sceneSHA256': digest(b.with_suffix('.json').read_bytes()),
        'ppmByteEqual': a.with_suffix('.ppm').read_bytes() == b.with_suffix('.ppm').read_bytes(),
        'sceneByteEqual': a.with_suffix('.json').read_bytes() == b.with_suffix('.json').read_bytes(),
        'originalMaskPresent': a.with_suffix('.mask').exists(),
        'originalRGBAPresent': a.with_suffix('.rgba').exists(),
        'originalManifestUnsupported': fixture['unsupportedPixels'],
        'finalMaskBytes': len(mask), 'finalNonzeroMask': sum(x != 0 for x in mask),
        'finalNonopaqueAlpha': sum(x != 255 for x in rgba[3::4]),
        'finalMagentaPixels': sum(rgb[i:i+3] == b'\xff\x00\xff' for i in range(0,len(rgb),3)),
        'finalMaskSHA256': digest(mask)}
    assert len(mask) == width*height and len(rgba) == width*height*4
    assert rec['ppmByteEqual'] and rec['sceneByteEqual']
    assert rec['finalNonzeroMask'] == rec['finalNonopaqueAlpha'] == rec['finalMagentaPixels'] == 0
    assert bytes(c for i,c in enumerate(rgba) if i%4 != 3) == rgb
    if name.startswith('bust-'):
        rows=[]
        for y in range(height):
            xs=[x for x in range(width) if rgb[3*(y*width+x):3*(y*width+x)+3] != b'\x12\x14\x18']
            if xs:
                rows.append({'y':y,'left':min(xs),'right':max(xs),'pixels':len(xs),
                    'internalBackgroundPixels':max(xs)-min(xs)+1-len(xs)})
            if len(rows)==5: break
        rec['firstFiveNonbackgroundRowSpans'] = rows
    matrix.append(rec)
result['matrix'] = matrix
result['originalMaskEquality'] = 'Unprovable: no original standard-fixture raw mask files. Manifest zero counts are retained evidence only.'

camera = BASE/'evidence/camera-original'
w,h,rgb = ppm(camera/'overhead-clipped.ppm')
mask = (camera/'overhead-clipped.mask').read_bytes()
assert len(mask) == w*h and set(mask) <= {0,1}
magenta = {i for i in range(w*h) if rgb[3*i:3*i+3] == b'\xff\x00\xff'}
marked = {i for i,value in enumerate(mask) if value}
assert magenta == marked and len(marked) == 11708
corrected = BASE/'evidence/camera-corrected'
result['camera'] = {'originalClippedMaskOnes':len(marked),
    'originalMaskMagentaPositionsEqual':magenta == marked,
    'originalMaskSHA256':digest(mask),
    'clearFilesEqual':{ext:(camera/('overhead-clear.'+ext)).read_bytes() == (corrected/('overhead-clear.'+ext)).read_bytes() for ext in ['png','ppm','mask']},
    'correctedClippedResult':json.loads((corrected/'result.json').read_text())[0],
    'correctedClippedFrameFilesPresent':[ext for ext in ['png','ppm','rgba','mask'] if (corrected/('overhead-clipped.'+ext)).exists()]}
assert all(result['camera']['clearFilesEqual'].values())
assert result['camera']['correctedClippedResult']['error'] == 'invalidCamera'
assert not result['camera']['correctedClippedFrameFilesPresent']
result['inspectionFailuresRetained'] = [
    'Initial aggregate cat output truncated; applicable source/docs re-read in bounded chunks.',
    'Initial rg command exited 2 because evidence/*mesh* glob matched no files; source matches returned; replaced by rg --files inventory.'
]
OUT.write_text(json.dumps(result, indent=2, sort_keys=True)+'\n')
print(json.dumps({'result':str(OUT),'topology':topology,'fixtures':len(matrix),
    'cameraMaskOnes':len(marked),'cpuSourceHashesMatched':len(cpu)},indent=2))
