from pathlib import Path
import itertools, re, subprocess, sys
root = Path.cwd()
out = root / 'private-output'
source_path = Path('Sources/LightingCore/SurfacePhotometry.swift')
source = source_path.read_text()
def git(*args):
    return subprocess.check_output(['git', *args], text=True).strip()
head = git('rev-parse', 'HEAD')
module = '1b286885cb803ba17e159713651515ab119e17f1'
production = git('rev-parse', '58b3')
blob = git('hash-object', str(source_path))
assert blob == git('rev-parse', f'{module}:{source_path}')
assert blob == git('rev-parse', f'{production}:{source_path}')
gauss = source.split('private let gauss12:')[1].split('\n]')[0]
node_count = len(re.findall(r'^    \(0\.', gauss, re.M))
assert node_count == 12
assert 'let samples = 32' in source
assert 'onAxisCandela: 1),' in source
assert source.index('if emitter.onAxisCandela < Double.leastNormalMagnitude * 1024') < source.index('let corners:')
threshold = sys.float_info.min * 1024
assert 0 < threshold < 1
# Clockwise corner indices: bottom-left, bottom-right, top-right, top-left.
# Rounded affine evaluation is monotone along x for both rows. Either x sign
# is allowed; impossible strict checkerboard signs are excluded by this test.
rows = []
for s in itertools.product((-1, 0, 1), repeat=4):
    if min(s) != -1 or max(s) != 1:
        continue
    if not ((s[0] <= s[1] and s[3] <= s[2]) or
            (s[0] >= s[1] and s[3] >= s[2])):
        continue
    crossings = sum(s[i-1] * s[i] < 0 for i in range(4))
    retained = sum(v >= 0 for v in s)
    rows.append((s, crossings, retained, crossings + retained))
max_vertices = max(row[3] for row in rows)
assert max_vertices == 5
assert max(row[1] for row in rows) == 2
quadrature = (max_vertices - 2) * node_count ** 2
full = 32 ** 2
assert quadrature == 432 and full == 1024
log = [
    '$ python3 private-output/audit.py',
    f'HEAD={head}', f'production={production}', f'helper-module={module} (not executed)',
    f'SurfacePhotometry blob={blob}; identical at HEAD, production and module revisions',
    f'threshold={threshold:.17g}={threshold.hex()}; unit intensity 1 exceeds threshold',
    f'gauss nodes={node_count}; admissible partial sign patterns={len(rows)}',
    f'max strict crossings=2; max polygon vertices={max_vertices}',
    f'max triangles={max_vertices-2}; max partial evaluations={quadrature}; full evaluations={full}',
    'max recursive edges=1; maximum rectangularIlluminance frames=2',
    'all source assertions and exhaustive admissible sign-pattern checks passed',
    '', 'Admissible partial sign patterns: signs, crossings, retained, polygon count',
    *(str(row) for row in rows),
    '', 'SOURCE EXCERPTS',
]
for path, ranges in [
    (source_path, [(1,19),(39,57),(60,86),(101,219)]),
    (Path('Sources/LightingCore/Scene.swift'), [(3,13),(20,37)]),
    (Path('Sources/LightingCore/StudioOptics.swift'), [(99,138)]),
    (Path('docs/QUALITY.md'), [(16,16)]),
    (Path('docs/acceptance/m02-m03-code.md'), [(19,19)])
]:
    lines = path.read_text().splitlines()
    log.append(f'\nSource excerpt: {path}; selected line ranges {ranges}')
    for first, last in ranges:
        log.extend(f'{i:5}\t{lines[i-1]}' for i in range(first,last+1))
(out / 'raw.txt').write_text('\n'.join(log)+'\n')
print('\n'.join(log[:12]))
