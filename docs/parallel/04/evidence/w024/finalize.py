import hashlib
import json
import subprocess
from pathlib import Path

worktree = Path('/tmp/keyfill04-2987b1ee980d/workers/w024')
results = Path('/tmp/keyfill04-2987b1ee980d/results/w024')
owned = 'Sources/LightingCore/StudyFloat32Eligibility.swift'
baseline = 'c76e176fa60d29f8ebd49845d7e8ea883c11b64f'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=worktree, text=True)

assert git('rev-parse', 'HEAD').strip() == baseline
assert git('diff', '--name-only').splitlines() == [owned]
original = git('show', f'{baseline}:{owned}')
current = (worktree / owned).read_text()
start = '        let panel = visiblePanelBounds(geometry: geometry, camera: camera)'
assert original[original.index(start):original.index('\n    private struct Bounds')] == current[current.index(start):current.index('\n    /// The distance-scaled margin')]
assert original[original.index('    private struct Bounds'):] == current[current.index('    private struct Bounds'):]
patch = git('diff', '--', owned)
(results / 'change.patch').write_text(patch)

report = '''# Worker 024 — eligibility implementation

Outcome: complete within assigned source ownership; ready for coordinator integration and Swift validation.

Baseline: `c76e176fa60d29f8ebd49845d7e8ea883c11b64f`. Canonical worker: `/root/w021/w024`.

## Changes

- Added `supports(_:width:)`; the existing overload forwards width 192. Width validation precedes arithmetic and permits only multiples of 3 in 24...192.
- Matched StudySetup’s strict camera-height and sphere-depth checks. Zero-candela emitters no longer enforce the 20 m emitter-distance limit.
- Added an O(height) analytic annular shell count using `32 * Double(Float.ulpOfOne) * distance`, projected `q(R)`, clipped pixel-center ranges, and integer-range union. CPU routing begins above `pixelCount / 510` potential pixels.
- Documented the shell as an engineering margin and a reserved half-level mean-error budget, not a GPU correctness proof. Separate Double-roundoff allowances protect inverse index conversion and tangent-row subtraction. No acceptance threshold, source equation, packed ABI, UI, or CI change.

## Executed checks

- `git status --short && git rev-parse HEAD`: initially clean at the baseline.
- `python3 /tmp/keyfill04-2987b1ee980d/results/w024/math_check.py`: first run exposed an endpoint undercount (width 27, distance 1.1314814252261085, focal 50: 6 versus 8); corrected using a Double-roundoff allowance. Intermediate rerun passed. Final run passed 945 configurations, including all supported widths, solved shell-boundary cases and neighboring Doubles: no analytic undercounts versus direct enumeration, 679 conservative extra counts, and 216 duplicated center contributions removed. Integer budget comparison matched the exact ratio. The requested width-24, distance-3, focal-161.27198111190464 consumer fixture exceeded the shell budget.
- `git diff --check`: passed after the final source edit.
- `python3 /tmp/keyfill04-2987b1ee980d/results/w024/finalize.py`: asserted HEAD/ownership and byte-identical existing near-field, frustum, and helper code; saved the scoped patch and identity.

## Unrun and limitations

Swift builds, type checks, unit tests, native Metal/GPU comparisons, SDK installation, and device performance checks were not run, as instructed. Python validates the geometry/counting model only; it does not establish Swift compilation, strict maximum-channel error, or exact unsupported-mask parity. No commits or ref writes were performed.

Artifacts: `change.patch`, `identity.json`, `math_check.py`, `finalize.py`, and this report in the worker results directory.
'''
(results / 'report.md').write_text(report)
identity = {
    'canonicalAgentID': '/root/w021/w024',
    'workerNumber': 24,
    'exactTask': 'Own ONLY Sources/LightingCore/StudyFloat32Eligibility.swift. Add supports(scene,width:) with old overload forwarding192, width24...192 divisible3 guard before arithmetic. Match StudySetup camera.y>panelY+0.01 and distance>radius+minimumDepthMeters; ignore zero-output emitters for20m relative limit. Add conservative resolution-aware silhouette-shell count: margin=32*Double(Float.ulpOfOne)*distance; CPU when potential pixels>pixelCount/510. Use O(height) analytic annular intervals: q(R)=R²/(D²-R²), per-row subtract py², convert signed px intervals to clipped pixel-center index ranges; union overlapping integer ranges to avoid counting odd-width center twice. Keep near-field/frustum guards unchanged. Document numerical margin and reserved budget, not proof. Source equations/packed input untouched. Save diff, no commits.',
    'inputSHA': baseline,
    'ownership': [owned],
    'outcome': 'Completed; focused Python geometry checks and scope/diff checks passed; Swift/Metal checks intentionally unrun.',
    'reportPath': str(results / 'report.md'),
    'patchPath': str(results / 'change.patch'),
    'changedFiles': [owned],
    'sourceSHA256': hashlib.sha256(current.encode()).hexdigest(),
}
(results / 'identity.json').write_text(json.dumps(identity, indent=2) + '\n')
print('PASS: baseline and source ownership verified; existing near-field/frustum code unchanged; change.patch, report.md, and identity.json saved.')
