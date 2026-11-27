from pathlib import Path
import datetime
import hashlib
import json
import shlex
import subprocess

root = Path('/tmp/keyfill02-r2-workers/w03r06')
out = root / 'private-output'
out.mkdir(exist_ok=True)
sources = [root / 'Sources/LightingCore' / p for p in
           ('Scene.swift', 'StudioOptics.swift', 'SurfacePhotometry.swift')]
commands = [
    ['git', 'rev-parse', 'HEAD'],
    ['git', 'status', '--short'],
    ['sha256sum', *[str(p) for p in sources]],
    ['nl', '-ba', str(sources[0])],
    ['nl', '-ba', str(sources[1])],
    ['sed', '-n', '1,103p', str(sources[2])],
    ['du', '-s', '-B1', str(root), str(out)],
    ['du', '-s', '-b', str(root), str(out)],
    ['df', '-B1', str(root)],
    ['free', '-b'],
    ['cat', '/proc/meminfo'],
    ['cat', '/sys/fs/cgroup/memory.max', '/sys/fs/cgroup/memory.current'],
]
with (out / 'commands-and-output.log').open('w') as log:
    log.write('UTC: ' + datetime.datetime.now(datetime.timezone.utc).isoformat() + '\n')
    log.write('CWD: ' + str(root) + '\n')
    for cmd in commands:
        result = subprocess.run(cmd, cwd=root, text=True, capture_output=True)
        log.write('\n$ ' + shlex.join(cmd) + '\n')
        log.write(result.stdout + result.stderr)
        log.write('exit=' + str(result.returncode) + '\n')
    swift_sources = sorted((root / 'Sources/LightingCore').glob('*.swift'))
    source_counts = {str(p.relative_to(root)): len(p.read_text().splitlines()) for p in sources}
    log.write('\nSOURCE INVENTORY (Path.glob, splitlines):\n')
    log.write(json.dumps({'swift_files': len(swift_sources),
                          'swift_lines': sum(len(p.read_text().splitlines()) for p in swift_sources),
                          'reviewed_source_lines': source_counts}, indent=2) + '\n')

def du(path, apparent=False):
    cmd = ['du', '-s', '-b' if apparent else '-B1', str(path)]
    return int(subprocess.check_output(cmd, text=True).split()[0])

mem = {row.split(':', 1)[0]: row.split(':', 1)[1].strip()
       for row in Path('/proc/meminfo').read_text().splitlines()}
def read_optional(path):
    try:
        return Path(path).read_text().strip()
    except OSError as error:
        return 'UNAVAILABLE: ' + str(error)

snapshot = {
    'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
    'worktree_allocated_bytes': du(root),
    'worktree_apparent_bytes': du(root, True),
    'private_output_allocated_bytes': du(out),
    'private_output_apparent_bytes': du(out, True),
    'host_mem_available_kib': int(mem['MemAvailable'].split()[0]),
    'host_mem_total_kib': int(mem['MemTotal'].split()[0]),
    'cgroup_memory_max': read_optional('/sys/fs/cgroup/memory.max'),
    'cgroup_memory_current': read_optional('/sys/fs/cgroup/memory.current'),
    'source_counts': source_counts,
    'swift_files': len(swift_sources),
    'swift_lines': sum(len(p.read_text().splitlines()) for p in swift_sources),
    'checks': {
        'numeric_point_path': 'PASS: no loops/recursion; fixed scalar/SIMD values',
        'numeric_directional_path': 'PASS: no loops/recursion; at most seven UnitDirection constructions',
        'whole_wrapper_constant_bound': 'NOT ESTABLISHED: name trim/count scales with string input bytes',
        'point_wrapper_work': {'normalizations': 1, 'square_roots': 2,
                               'light_validation_calls': 1, 'position_validation_calls_max': 6},
        'directional_wrapper_work': {'normalizations_max': 7, 'square_roots_max': 8,
                                     'hypot_calls': 1, 'sin_calls_max': 1, 'cos_calls_max': 1,
                                     'light_validation_calls': 2, 'position_validation_calls_max': 10},
        'build_or_benchmark': 'NOT RUN: source/resource inspection only',
    },
}
(out / 'resource-snapshot.json').write_text(json.dumps(snapshot, indent=2) + '\n')
print(json.dumps(snapshot, indent=2))
