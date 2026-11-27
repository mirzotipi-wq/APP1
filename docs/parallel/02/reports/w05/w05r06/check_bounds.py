#!/usr/bin/env python3
"""One static source-bound check; no Swift execution or timing measurement."""
import hashlib
import itertools
import json
import pathlib
import platform
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / 'private-output'
SNAPSHOT = '1b286885cb803ba17e159713651515ab119e17f1'
PRODUCTION = '58b3ca43943e18d0fc7800189b08365f424d9c9e'
EXPECTED_HEAD = '928ca0eafa6330742114c2e0ac184789c2f17752'

def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args])

def body(text, marker):
    start = text.index(marker)
    brace = text.index('{', start)
    depth = 1
    end = brace + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[brace + 1:end - 1]

def code(text):
    return re.sub(r'//[^\n]*', '', text)

checks = []

def check(condition, label):
    if not condition:
        raise AssertionError(label)
    checks.append(label)

paths = [
    'Sources/LightingCore/LightOutputAdjustment.swift',
    'Sources/LightingCore/StudioOptics.swift',
    'Sources/LightingCore/SurfacePhotometry.swift',
    'Sources/LightingCore/Scene.swift',
    'Sources/LightingCore/CameraFraming.swift',
    'Sources/LightingCore/Colorimetry.swift',
    'Sources/LightingCore/RoomPlacement.swift',
]
sources = {p: (ROOT / p).read_text() for p in paths}
head = git('rev-parse', 'HEAD').decode().strip()
check(head == EXPECTED_HEAD, 'worktree HEAD matches assigned revision')
hashes = {}
for p, text in sources.items():
    raw = (ROOT / p).read_bytes()
    check(raw == git('show', f'{SNAPSHOT}:{p}') == git('show', f'{PRODUCTION}:{p}'),
          f'source bytes match frozen snapshot and production: {p}')
    hashes[p] = hashlib.sha256(raw).hexdigest()
check(not git('diff', PRODUCTION, 'HEAD', '--', 'Sources/LightingCore'),
      'all LightingCore production source unchanged since production revision')

solver = code(body(sources[paths[0]], 'public static func light('))
calls = re.findall(r'StudioPhotometry\.illuminance\(for: (\w+), in: scene\)', solver)
check(calls == ['adjusted', 'maximum', 'source', 'adjusted'],
      'exactly four ordered photometry callsites: unit, maximum, existing, achieved')
check(not re.search(r'\b(for|while|repeat)\b(?!\s*:)', solver),
      'solver contains no loop (argument label for: excluded)')
check(not re.search(r'(?:LightOutputAdjustment\.)?\blight\s*\(', solver),
      'solver contains no self recursion')
check(solver.index('if targetLux == 0') < solver.index('StudioPhotometry.illuminance'),
      'zero-target return precedes all photometry')
check('adjusted.candela = 0\n            return adjusted' in solver,
      'zero-target branch returns immediately')
check('if source.candela > 0,\n           StudioPhotometry.illuminance(for: source, in: scene) == targetLux' in solver,
      'existing-source evaluation is conditional on positive source intensity')
check('abs(achievedLux / targetLux - 1) <= 1e-9' in solver and
      'maximum.candela = 100_000' in solver,
      '1e-9 forward acceptance and 100000 cd cap remain present')

surface = sources[paths[2]]
rectangle = code(body(surface, 'public static func rectangularIlluminance('))
midpoint = code(body(surface, 'private static func fullRectangleMidpoint('))
samples = int(re.search(r'let samples = (\d+)', midpoint).group(1))
check(len(re.findall(r'for \w+ in 0..<samples', midpoint)) == 2,
      'full-face midpoint loop has two fixed sample axes')
gauss_body = surface.split('private let gauss12:', 1)[1].split('= [', 1)[1].split(']', 1)[0]
nodes = len(re.findall(r'\(0\.', gauss_body))
check(nodes == 12 and rectangle.count(' in gauss12 {') == 2,
      'clipped-face quadrature has two 12-node axes')
check('nx * p.x + ny * p.y - offset' in rectangle,
      'four rectangle incidences come from one affine half-plane')
check('for i in vertices.indices' in rectangle and 'polygon.reserveCapacity(5)' in rectangle,
      'clipping visits initial rectangle once; reserve is not treated as a cap')

# On a parallelogram, opposite affine corner sums agree: f0+f2=f1+f3.
# Enumerate feasible ternary sign patterns using the possible sign of each sum.
def sum_signs(a, b):
    if a * b < 0:
        return {-1, 0, 1}
    return {a or b}

patterns = []
for signs in itertools.product((-1, 0, 1), repeat=4):
    if min(signs) >= 0 or max(signs) <= 0:
        continue  # earlier allSatisfy branches bypass clipping
    if not (sum_signs(signs[0], signs[2]) & sum_signs(signs[1], signs[3])):
        continue
    crossings = sum(signs[i - 1] * signs[i] < 0 for i in range(4))
    retained = sum(s >= 0 for s in signs)
    patterns.append((signs, crossings, retained + crossings))
max_vertices = max(p[2] for p in patterns)
check(max_vertices == 5 and max(p[1] for p in patterns) == 2,
      'independent affine sign enumeration bounds clipped polygon at five vertices')
check('for i in 1..<(polygon.count - 1)' in rectangle,
      'triangle fan uses at most polygon.count minus two triangles')
check(rectangle.count('rectangularIlluminance(emitter: unit') == 1 and
      'onAxisCandela: 1)' in rectangle and
      'emitter.onAxisCandela < Double.leastNormalMagnitude * 1024' in rectangle and
      sys.float_info.min * 1024 < 1,
      'tiny-output recursion changes intensity to one and cannot recur again')
check(rectangle.index('return unitLux * emitter.onAxisCandela') < rectangle.index('let corners:'),
      'tiny wrapper returns before allocating integration arrays or doing quadrature')

scene = sources[paths[3]]
validation = code(body(scene, 'public func validated()'))
check(validation.index('guard lights.count <= 12') < validation.index('lights.allSatisfy') <
      validation.index('Set(lights.map(\\.id))'),
      'scene rejects more than twelve lights before iteration and UUID map/Set allocation')
check('!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 80' in scene,
      'name trimming/counting is separate input-length-dependent validation')

full = samples ** 2
partial = (max_vertices - 2) * nodes ** 2
result = {
    'kind': 'single static source-bound check; no runtime benchmark',
    'photometry_calls': {'any_solve_max': len(calls), 'zero_target': 0, 'source_off_max': 3},
    'rectangle_leaf_samples': {'full_per_call': full, 'partial_per_call': partial,
                               'full_per_solve_max': 4 * full, 'partial_per_solve_max': 4 * partial},
    'rectangle_call_depth_max': 2,
    'rectangle_entries_per_solve_max': 6,
    'rectangle_entries_rationale': 'unit and maximum cannot recurse; existing and achieved may each add one wrapper',
    'affine_partial_sign_patterns_checked': len(patterns),
    'bounded_geometry_storage': 'four corners, four incidence vertices, at most five clipped vertices; twelve global Gauss tuples; scalar loop accumulators',
    'validation_storage': 'at most twelve UUIDs in map and twelve in Set; light/scene values use normal Swift value semantics',
    'limitation': 'name trimming/counting costs depend on caller-provided encoded string length; 80 Characters does not impose a UTF-8 byte cap. No uniform whole-solver memory/time cap or measured allocation/RSS result is claimed.',
    'checks': checks,
}
provenance = {
    'command': 'python3 /tmp/keyfill02-r2-workers/w05r06/private-output/check_bounds.py > /tmp/keyfill02-r2-workers/w05r06/private-output/check.log 2>&1',
    'worktree_head': head,
    'frozen_snapshot': SNAPSHOT,
    'production_source_revision': PRODUCTION,
    'source_sha256': hashes,
    'host': platform.platform(),
    'python': sys.version,
    'git_latest_production_commit': git('log', '-1', '--format=%H %s', '--', 'Sources/LightingCore').decode().strip(),
    'scope': 'original execution on assigned worktree; not reconstructed prior evidence; production read-only',
}
excerpts = []
limits = {paths[4]: 17, paths[5]: 17, paths[6]: 64}
for p, text in sources.items():
    lines = text.splitlines()[:limits.get(p)]
    excerpts.append(f'===== ORIGINAL SOURCE: {p}; SHA256 {hashes[p]} =====\n' +
                    '\n'.join(f'{i:4d} {line}' for i, line in enumerate(lines, 1)))
(OUT / 'source-excerpts.txt').write_text('\n\n'.join(excerpts) + '\n')
(OUT / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
(OUT / 'bound-result.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'status': 'PASS', **result}, indent=2))
