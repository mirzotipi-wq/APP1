"""Private, bounded evidence runner; every compilation holds the shared build lock."""
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess

root = Path('/tmp/keyfill04-2987b1ee980d')
repo = root / 'workers/w016'
results = root / 'results/w016'
build = Path('/workspace/scratch/2987b1ee980d/build04/w016')
binary = build / 'malformed-metadata-probe'
lock = root / 'build.lock'
records = []

def run(name, command, env_overrides=None):
    environment = os.environ.copy()
    environment.update(env_overrides or {})
    completed = subprocess.run(command, cwd=repo, env=environment, text=True, capture_output=True)
    prefix = ''.join(f'{key}={shlex.quote(value)} ' for key, value in (env_overrides or {}).items())
    exact = prefix + shlex.join([str(item) for item in command])
    record = {'name': name, 'cwd': str(repo), 'command': exact,
              'exit': completed.returncode, 'stdout': completed.stdout, 'stderr': completed.stderr}
    records.append(record)
    (results / f'{name}.stdout').write_text(completed.stdout)
    (results / f'{name}.stderr').write_text(completed.stderr)
    (results / f'{name}.command').write_text(exact + '\n')
    (results / f'{name}.exit').write_text(str(completed.returncode) + '\n')
    (results / 'commands.json').write_text(json.dumps(records, indent=2) + '\n')
    print(f'{name}: exit={completed.returncode}', flush=True)
    return completed

run('compiler-version', ['g++', '--version'])
run('baseline-head', ['git', 'rev-parse', 'HEAD'])
run('baseline-status', ['git', 'status', '--short', '--branch'])
run('source-product-diff', ['git', 'diff', 'f150f98e35dd735927075aac4d2f8b02295c6a67', '--',
    'scripts/verify-kernel-host.cpp', 'App/StudyKernel.h', 'Sources/LightingCore/ReferenceStudy.swift',
    'Sources/LightingCore/Scene.swift', 'App/MetalStudyRenderer.swift'])
compile_result = run('compile', ['flock', str(lock), 'g++', '-std=c++17', '-O1', '-g',
    '-fno-omit-frame-pointer', '-ffp-contract=off', '-fsanitize=undefined,float-cast-overflow',
    '-fno-sanitize-recover=all', str(results / 'malformed-metadata-probe.cpp'), '-o', str(binary)])
if compile_result.returncode != 0:
    raise SystemExit(compile_result.returncode)

# One fixed 24x16, 64-sample, one-area fixture and fixed single-field mutations;
# not a fuzzer. The first case is the canonical unmutated metadata control.
cases = [
    ('valid-control', 'grid', '8'),
    ('grid-huge', 'grid', '4294967296'),
    ('tag-huge', 'tag', '4294967296'),
    ('grid-negative', 'grid', '-1'),
    ('tag-negative', 'tag', '-1'),
    ('grid-fractional', 'grid', '8.5'),
    ('tag-fractional', 'tag', '1.5'),
    ('count-huge-rejected', 'area-count', '4294967296'),
    ('nonfinite-rejected', 'grid', 'nan'),
]
for name, field, value in cases:
    run(name, [str(binary), field, value, str(results / f'{name}.bin')],
        {'UBSAN_OPTIONS': 'halt_on_error=1:print_stacktrace=1'})

run('final-status', ['git', 'status', '--short', '--branch'])
source_files = [results / 'malformed-metadata-probe.cpp', results / 'run_probe.py',
    repo / 'scripts/verify-kernel-host.cpp', repo / 'App/StudyKernel.h',
    repo / 'Sources/LightingCore/ReferenceStudy.swift', repo / 'Sources/LightingCore/Scene.swift',
    repo / 'App/MetalStudyRenderer.swift', binary]
source_files += sorted(results.glob('*.bin'))
digests = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in source_files}
(results / 'sha256.json').write_text(json.dumps(digests, indent=2) + '\n')
print('Evidence captured in ' + str(results), flush=True)
