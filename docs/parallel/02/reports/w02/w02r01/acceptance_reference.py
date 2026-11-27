"""Independent scalar/closed-form/Simpson references for W02R01, no source transcription.

Run in the retained evidence directory. The Swift probe exercises frozen LightingCore.
The finite-patch references integrate ray cosines directly, without clipping or Gaussian nodes.
"""
import json
import math
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
SHA = "f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b"

def dot(a, b): return sum(x*y for x, y in zip(a, b))
def add(a, b): return [x+y for x, y in zip(a, b)]
def sub(a, b): return [x-y for x, y in zip(a, b)]
def mul(a, t): return [x*t for x in a]
def unit(a): return mul(a, 1/math.sqrt(dot(a, a)))

def centered(width, height, depth, intensity):
    a, b = width/2, height/2
    h1, h2 = math.hypot(depth, a), math.hypot(depth, b)
    return 2*intensity/(width*height)*(a/h1*math.atan(b/h1)+b/h2*math.atan(a/h2))

def simpson(f, n):
    r, u, ne = f['right'], f['up'], f['emissionNormal']
    nr = unit(f['receiverNormal'])
    w, h = f['width'], f['height']
    def weight(i): return 1 if i in (0, n) else (4 if i % 2 else 2)
    total = 0.0
    for j in range(n+1):
        y = -h/2+h*j/n
        # This held-out partial patch has x + 0.3*y > 0.29.
        xmin = 0.29-0.3*y if f.get('partial') else -w/2
        dx = (w/2-xmin)/n
        row = 0.0
        for i in range(n+1):
            x = xmin+dx*i
            source = add(f['center'], add(mul(r, x), mul(u, y)))
            ray = sub(f['receiver'], source)
            r2 = dot(ray, ray)
            ray = mul(ray, 1/math.sqrt(r2))
            row += weight(i)*max(0, dot(ne, ray))*max(0, -dot(nr, ray))/r2
        total += weight(j)*row*dx/3
    return f['candela']/(w*h)*total*(h/n)/3

fixtures = [
    dict(name='point_diagonal', kind='point', source=[2, 0, 2], receiver=[0, 0, 0], receiverNormal=[0, 0, 1], candela=1200),
    dict(name='point_three_axis', kind='point', source=[-1, 2, 2], receiver=[0, 0, 0], receiverNormal=[0, 0, 1], candela=300),
    dict(name='rectangle_centered', kind='rectangle', center=[0, 0, 0], right=[1, 0, 0], up=[0, 1, 0], emissionNormal=[0, 0, 1], receiver=[0, 0, 0.9], receiverNormal=[0, 0, -1], width=1.2, height=0.6, candela=1000, analyticDepth=0.9),
    dict(name='rectangle_minimum_depth', kind='rectangle', center=[0, 0, 0], right=[1, 0, 0], up=[0, 1, 0], emissionNormal=[0, 0, 1], receiver=[0, 0, 0.5], receiverNormal=[0, 0, -1], width=2.0, height=0.5, candela=1000, analyticDepth=0.5),
]
center, r, u, ne = [0.2, -0.4, 0.6], [0.8, 0, -0.6], [0, 1, 0], [0.6, 0, 0.8]
fixtures.append(dict(name='rectangle_oblique', kind='rectangle', center=center, right=r, up=u, emissionNormal=ne,
    receiver=add(center, add(mul(ne, 1.1), add(mul(r, 0.35), mul(u, -0.15)))),
    receiverNormal=add(mul(ne, -1), add(mul(r, -0.2), mul(u, 0.1))), width=0.7, height=1.0, candela=850))
fixtures.append(dict(name='rectangle_partial', kind='rectangle', center=[0, 0, 0], right=[1, 0, 0], up=[0, 1, 0], emissionNormal=[0, 0, 1], receiver=[0.2, -0.1, 0.6], receiverNormal=[1, 0.3, 0.2], width=1.2, height=0.6, candela=950, partial=True))

for f in fixtures:
    if f['kind'] == 'point':
        delta = sub(f['source'], f['receiver'])
        f['referenceMethod'] = 'independent scalar inverse square and receiver cosine'
        f['referenceLux'] = f['candela'] / dot(delta, delta) * max(0, dot(unit(delta), unit(f['receiverNormal'])))
        f['contractRelativeLimit'] = 0.01
    elif 'analyticDepth' in f:
        f['referenceMethod'] = 'closed-form centered rectangular irradiance'
        f['referenceLux'] = centered(f['width'], f['height'], f['analyticDepth'], f['candela'])
        f['contractRelativeLimit'] = 0.05
    else:
        f['referenceMethod'] = 'direct world-space double Simpson ray-cosine integral, n=160 per axis'
        low, high = simpson(f, 80), simpson(f, 160)
        f['referenceLux'] = high
        f['reference80Lux'] = low
        f['referenceConvergenceRelative'] = abs(low-high)/abs(high)
        assert f['referenceConvergenceRelative'] < 1e-6
        f['contractRelativeLimit'] = 0.05

def swift_vec(v, constructor):
    return constructor+'(x: '+repr(v[0])+', y: '+repr(v[1])+', z: '+repr(v[2])+')'

lines = ['import Foundation', 'import LightingCore', 'var output: [String: Double] = [:]']
for f in fixtures:
    receiver = swift_vec(f['receiver'], 'Position')
    normal = swift_vec(f['receiverNormal'], 'UnitDirection')+'!'
    if f['kind'] == 'point':
        expr = 'Photometry.pointIlluminance(candela: '+repr(f['candela'])+', source: '+swift_vec(f['source'], 'Position')+', receiver: '+receiver+', receiverNormal: '+normal+')!'
    else:
        emitter = 'LambertianRectangle(center: '+swift_vec(f['center'], 'Position')+', right: '+swift_vec(f['right'], 'UnitDirection')+'!, up: '+swift_vec(f['up'], 'UnitDirection')+'!, widthMeters: '+repr(f['width'])+', heightMeters: '+repr(f['height'])+', onAxisCandela: '+repr(f['candela'])+')!'
        expr = 'Photometry.rectangularIlluminance(emitter: '+emitter+', receiver: '+receiver+', receiverNormal: '+normal+')!'
    lines.append('output["'+f['name']+'"] = '+expr)
lines += ['let bytes = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys, .prettyPrinted])', 'print(String(data: bytes, encoding: .utf8)!)']
(HERE/'probe.swift').write_text('\n'.join(lines)+'\n')
(HERE/'reference.json').write_text(json.dumps({'input_sha': SHA, 'fixtures': fixtures}, indent=2)+'\n')

if len(sys.argv) > 1:
    actual = json.loads(pathlib.Path(sys.argv[1]).read_text())
    rows = []
    for f in fixtures:
        expected, value = f['referenceLux'], actual[f['name']]
        error = abs(value-expected)/abs(expected)
        row = dict(name=f['name'], method=f['referenceMethod'], reference_lux=expected, swift_lux=value,
                   denominator=abs(expected), relative_error=error, relative_limit=f['contractRelativeLimit'], passed=error <= f['contractRelativeLimit'])
        rows.append(row)
    result = {'input_sha': SHA, 'rows': rows, 'all_passed': all(r['passed'] for r in rows),
        'max_point_relative_error': max(r['relative_error'] for r in rows if r['relative_limit']==0.01),
        'max_rectangle_relative_error': max(r['relative_error'] for r in rows if r['relative_limit']==0.05),
        'scope': 'Six fixed ideal-model fixtures; software acceptance evidence, no physical calibration.'}
    (HERE/'results.json').write_text(json.dumps(result, indent=2)+'\n')
    print(json.dumps(result, indent=2))
    assert result['all_passed']
