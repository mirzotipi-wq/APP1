import math
from pathlib import Path
root = Path(__import__('sys').argv[1])
source = (root / 'Sources/LightingCore/PortraitHeadMesh.swift').read_text()
assert 'static let latitudeSegments = 42' in source
assert 'static let longitudeSegments = 64' in source
assert 0 < 24 < 25 < 42 and 0 < 3 < 4 < 64
assert 'func hit(origin: SIMD3<Double>, direction: SIMD3<Double>,' in source
oracle = (root / 'Tests/LightingCoreTests/PortraitHeadMeshTests.swift').read_text()
assert 'OracleTriangle(a, b, c)' in oracle
print('SOURCE: chosen interior indices and mesh hit interface/topology present')
for angle in (0.002, 0.02, 0.2):
    n = (math.sin(angle), 0.0, math.cos(angle))
    g = (0.0, 0.0, 1.0)
    difference = tuple(a - b for a, b in zip(n, g))
    length = math.sqrt(sum(v*v for v in difference))
    d = tuple(v / length for v in difference)
    smooth_cosine = sum(a*b for a,b in zip(n,d))
    geometric_cosine = d[2]
    wrong_offset_tangent = 1e-5 * abs(n[0])
    assert smooth_cosine > 0 and geometric_cosine < 0
    assert wrong_offset_tangent > 1e-12
    print(f'angle={angle:.3g} smooth.dot(d)={smooth_cosine:.12g} geometric.dot(d)={geometric_cosine:.12g} wrong_offset_tangent={wrong_offset_tangent:.12g}')
print('ARITHMETIC: PASS; Swift mesh fixture/evaluator execution UNRUN')
