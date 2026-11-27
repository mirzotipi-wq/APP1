from pathlib import Path
import datetime
import hashlib
import json
import platform
import shutil
import subprocess

work = Path('/tmp/keyfill02-r2-workers/w05r05')
out = work / 'private-output'
snapshot = Path('/tmp/keyfill02-r2-snapshots/v1')
production = '58b3ca43943e18d0fc7800189b08365f424d9c9e'
module = (snapshot / 'READY').read_text().strip()
commands = []

def run(args):
    result = subprocess.run(args, cwd=work, text=True, capture_output=True)
    commands.append({'argv': args, 'returncode': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr})
    return result

head = run(['git', 'rev-parse', 'HEAD']).stdout.strip()
status = run(['git', 'status', '--short']).stdout
version = run(['/tmp/keyfill02-r2-toolchain/usr/bin/swiftc', '--version']).stdout
for revision in [module, head]:
    run(['git', 'diff', '--exit-code', production, revision, '--', 'Sources/LightingCore'])

references = [
    work / 'AGENTS.md', work / 'docs/QUALITY.md',
    Path('/tmp/keyfill02-r2/docs/parallel/02/WAVE-TASKS.md'),
    Path('/tmp/keyfill02-r2-brief.md'), Path('/tmp/keyfill02-r2-probe.py'),
    work / 'Sources/LightingCore/LightOutputAdjustment.swift',
    work / 'Sources/LightingCore/Scene.swift',
    work / 'Sources/LightingCore/StudioOptics.swift',
    work / 'Sources/LightingCore/SurfacePhotometry.swift',
    work / 'Tests/LightingCoreTests/LightOutputBoundaryTests.swift'
]
hashes = {}
for path in references:
    shutil.copy2(path, out / 'references' / path.name)
    hashes[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()
for path in [snapshot / 'READY', snapshot / 'Modules/LightingCore.swiftmodule', snapshot / 'libLightingCore.a',
             out / 'probe.swift', out / 'probe', out / 'probe.log', out / 'compile.log']:
    hashes[str(path)] = hashlib.sha256(path.read_bytes()).hexdigest()

probe_command = ['python3', '/tmp/keyfill02-r2-probe.py', str(work), str(out / 'probe.swift'), 'v1']
compile_command = ['flock', '/tmp/keyfill02-r2-build.lock', '/tmp/keyfill02-r2-toolchain/usr/bin/swiftc',
                   '-I', str(snapshot / 'Modules'), str(out / 'probe.swift'), str(snapshot / 'libLightingCore.a'),
                   '-o', str(out / 'probe')]
provenance = {
    'worker': 'W05 R05', 'worktree_head': head, 'module_revision_from_READY': module,
    'production_revision': production, 'platform': platform.platform(), 'swift_version': version,
    'recorded_at_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'probe_log_modified_at_utc': datetime.datetime.fromtimestamp((out / 'probe.log').stat().st_mtime, datetime.timezone.utc).isoformat(),
    'execution_origin': 'Fresh actual execution in this worker context; these are not recovered earlier logs.',
    'probe_command': probe_command, 'probe_exit_code_observed': 0,
    'compile_command_used_by_helper': compile_command, 'metadata_commands': commands,
    'sha256': hashes,
    'limits': 'One finite host Swift concurrency comparison, 12 fixtures, 24 solver calls; no exhaustive sweep, package build, device test, physical calibration, race detector, or schedule-independent proof.',
    'gates_preserved': {'target_relative_error': 1e-9, 'point_model_error': 0.01, 'area_model_error': 0.05}
}
(out / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
(out / 'commands.txt').write_text(
    'Executed probe (exit 0):\n' + ' '.join(probe_command) + '\n\n'
    'Serial compile invoked by helper (exit 0):\n' + ' '.join(compile_command) + '\n\n'
    'Executable invoked by helper (exit 0):\n' + str(out / 'probe') + '\n\n'
    'Reference reads: AGENTS.md; docs/QUALITY.md; WAVE-TASKS.md W05 R05; LightOutputAdjustment.swift; Scene.swift; StudioOptics.swift; LightOutputBoundaryTests.swift.\n'
    'Evidence metadata commands and exact outputs are recorded in provenance.json.\n'
)
raw = (out / 'probe.log').read_text()
(out / 'raw-results.tsv').write_text('\n'.join(line for line in raw.splitlines() if not line.startswith('SUMMARY ')) + '\n')
(out / 'report.md').write_text('''# W05 R05 — immutable-input solver concurrency

**PASS — no defect observed.** One actual Swift probe evaluated 12 fixed inputs serially, then submitted independent immutable value copies in reverse order to a task group. Child tasks returned owned results; only the parent collected them. There was no shared mutable test state.

Point, directional and rolled rectangle sources each covered zero, ordinary adjustment from off, an already achieved target, and `maximumLux.nextUp` rejection. All 12 concurrent outcomes matched serial outcomes exactly, including full adjusted lights, candela/lux bit patterns and errors. All input-preservation and output-validity checks passed. Execution intervals overlapped for 38 task pairs. Total: 24 solver calls; zero mismatches or invariant failures. Maximum positive-target relative error was **6.661338147750939e-16**, within the unchanged **1e-9** gate. The 1% point and 5% area contracts remain unchanged; this is not an independent accuracy validation of those models.

Worktree HEAD: `928ca0eafa6330742114c2e0ac184789c2f17752`. Frozen module: `1b286885cb803ba17e159713651515ab119e17f1`. Production reference: `58b3ca43943e18d0fc7800189b08365f424d9c9e`. `Sources/LightingCore` has no diff from that production reference at either tested source revision; worktree docs/tests may be newer.

Command (exit 0):
`python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w05r05 /tmp/keyfill02-r2-workers/w05r05/private-output/probe.swift v1`

Evidence: `probe.swift`, `probe.log`, `raw-results.tsv`, `compile.log`, `commands.txt`, `provenance.json`, and copied references. This is fresh actual execution, not recovered earlier logs. One host scheduling sample establishes observed agreement only; no race-detector, exhaustive, device, or physical-calibration claim.
''')
print(json.dumps({'report': str(out / 'report.md'), 'production_source_diffs': [c['returncode'] for c in commands if c['argv'][:3] == ['git', 'diff', '--exit-code']], 'swift_version': version.strip(), 'sha256_count': len(hashes)}, indent=2))
