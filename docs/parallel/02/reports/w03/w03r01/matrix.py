import csv, json, math, pathlib, sys
out = pathlib.Path(__file__).resolve().parent
cases = []
def add(name, kind, distance=2.0, candela=400.0, receiver_cos=1.0, emitter_cos=1.0, unsupported=None):
    camera = [2*math.sqrt(max(0, 1-receiver_cos**2)), 0.0, 2*receiver_cos]
    source = [0.0, 0.0, distance]
    aim = [math.sqrt(max(0, 1-emitter_cos**2)), 0.0, distance-emitter_cos] if kind == 'directional' else None
    if unsupported == 'camera': camera = [0.0, 0.0, 0.0]
    if unsupported == 'aim': aim = list(source)
    expected = None if unsupported else candela/(distance*distance)*max(0,receiver_cos)*(max(0,emitter_cos) if kind == 'directional' else 1)
    cases.append(dict(name=name, kind=kind, source=source, camera=camera, aim=aim, candela=candela, receiver_cos=receiver_cos, emitter_cos=emitter_cos, expected_lux=expected))
add('point_front', 'point')
add('point_receiver_60', 'point', receiver_cos=0.5)
add('point_near_grazing', 'point', receiver_cos=0.01)
add('point_distance_4m', 'point', distance=4)
add('point_max_candela', 'point', distance=0.5, candela=100000)
add('point_zero_candela', 'point', candela=0)
add('point_receiver_tangent', 'point', receiver_cos=0)
add('point_receiver_back', 'point', receiver_cos=-1)
add('directional_front', 'directional')
add('directional_emitter_60', 'directional', emitter_cos=0.5)
add('directional_both_60', 'directional', receiver_cos=0.5, emitter_cos=0.5)
add('directional_near_grazing', 'directional', receiver_cos=0.01, emitter_cos=0.25)
add('directional_emitter_back', 'directional', emitter_cos=-1)
add('directional_emitter_tangent', 'directional', emitter_cos=0)
add('unsupported_under_5cm', 'point', distance=0.049, unsupported='distance')
add('unsupported_camera_coincident', 'point', unsupported='camera')
add('unsupported_directional_aim', 'directional', unsupported='aim')
add('unsupported_candela', 'point', candela=100001, unsupported='candela')
(out/'references.json').write_text(json.dumps({'formula': 'E = I/r^2 * max(0, cos_receiver) * (max(0, cos_emitter) for directional, otherwise 1)', 'distance_unit':'m','intensity_unit':'cd','output_unit':'lux','cases':cases},indent=2)+'\n')
def pos(v): return '.init(x: %s, y: %s, z: %s)' % tuple(repr(float(x)) for x in v)
rows=[]
for c in cases:
    aim = 'nil' if c['aim'] is None else pos(c['aim'])
    rows.append('    Row(name: "%s", kind: .%s, source: %s, camera: %s, aim: %s, candela: %s)' % (c['name'],c['kind'],pos(c['source']),pos(c['camera']),aim,repr(float(c['candela']))))
swift='''import Foundation
import LightingCore
struct Row {
    let name: String
    let kind: EmitterKind
    let source: Position
    let camera: Position
    let aim: Position?
    let candela: Double
}
let rows: [Row] = [
'''+',\n'.join(rows)+'''
]
print("name,actual_lux")
for row in rows {
    let light = StudioLight(name: "Matrix", position: row.source, candela: row.candela,
                            kelvin: 5600, optics: .init(kind: row.kind, aimTarget: row.aim))
    let scene = LightingScene(subject: .init(x: 0, y: 0, z: 0), camera: row.camera, lights: [light])
    let actual = StudioPhotometry.illuminance(for: light, in: scene)
    print(row.name + "," + (actual.map { String(format: "%.17g", $0) } ?? "nil"))
}
'''
(out/'probe.swift').write_text(swift)
if '--verify' in sys.argv:
    actual={r['name']:None if r['actual_lux']=='nil' else float(r['actual_lux']) for r in csv.DictReader((out/'probe.log').read_text().splitlines())}
    result=[]
    for c in cases:
        a,e=actual[c['name']],c['expected_lux']
        error=None if e is None or e==0 or a is None else abs(a-e)/abs(e)
        ok=(a is None) if e is None else ((a==0) if e==0 else a is not None and math.isfinite(a) and error<=0.01)
        result.append(dict(name=c['name'],expected_lux=e,actual_lux=a,relative_error=error,pass_=ok))
    with (out/'results.csv').open('w') as f:
        writer=csv.DictWriter(f,fieldnames=result[0].keys()); writer.writeheader(); writer.writerows(result)
    summary={'cases':len(result),'positive_cases':sum(c['expected_lux'] is not None and c['expected_lux']>0 for c in cases),'zero_cases':sum(c['expected_lux']==0 for c in cases),'nil_cases':sum(c['expected_lux'] is None for c in cases),'passed':sum(r['pass_'] for r in result),'max_relative_error':max(r['relative_error'] or 0 for r in result),'point_gate_relative':0.01,'area_gate_relative_preserved_not_evaluated':0.05}
    (out/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
    print(json.dumps(summary,indent=2))
    if not all(r['pass_'] for r in result): sys.exit(1)
