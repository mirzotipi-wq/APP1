from pathlib import Path
import datetime, hashlib, platform, shlex, subprocess, sys
work = Path('/tmp/keyfill02-r2-workers/w05r02')
out = work/'private-output'
commands = out/'commands.log'
commands.write_text('W05 R02 executed command record; initial source-discovery reads were interactive. All results below were captured directly during this run.\n')
raw = out/'raw.log'
raw.write_text('W05 R02 actual subprocess output\n')

def run(args, destination=None):
    command = shlex.join(args)
    with commands.open('a') as f:
        f.write('$ '+command+'\n')
    result = subprocess.run(args, cwd=work, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    text = result.stdout.decode(errors='replace')
    block = '$ '+command+'\n'+text+'\n[exit '+str(result.returncode)+']\n'
    with raw.open('a') as f:
        f.write(block)
    if destination:
        with (out/destination).open('a') as f:
            f.write(block)
    with commands.open('a') as f:
        f.write('exit='+str(result.returncode)+'\n')
    return result.returncode, text

(out/'provenance.log').write_text('UTC start: '+datetime.datetime.now(datetime.timezone.utc).isoformat()+'\nPlatform: '+platform.platform()+'\nWorker HEAD and compiled module are intentionally distinct.\n')
provenance_commands = [
    ['git', 'rev-parse', 'HEAD'],
    ['git', 'status', '--short', '--branch'],
    ['git', 'log', '-1', '--format=%H', '--', 'Sources/LightingCore'],
    ['cat', '/tmp/keyfill02-r2-snapshots/v1/READY'],
    ['git', 'diff', '--exit-code', '1b286885cb803ba17e159713651515ab119e17f1', 'HEAD', '--', 'Sources/LightingCore'],
    ['/tmp/keyfill02-r2-toolchain/usr/bin/swiftc', '--version'],
    ['sha256sum', 'Sources/LightingCore/LightOutputAdjustment.swift', 'Sources/LightingCore/Scene.swift', 'Sources/LightingCore/StudioOptics.swift', '/tmp/keyfill02-r2-snapshots/v1/libLightingCore.a', '/tmp/keyfill02-r2-snapshots/v1/Modules/LightingCore.swiftmodule', '/tmp/keyfill02-r2-probe.py', str(out/'probe.swift')]
]
for command in provenance_commands:
    code, text = run(command, 'provenance.log')
    if code:
        print(text)
        sys.exit(code)
(out/'reference.log').write_text('Actual source/contract excerpts read for W05 R02.\n')
references = [
    ['cat', 'Sources/LightingCore/LightOutputAdjustment.swift'],
    ['sed', '-n', '19,89p', 'Sources/LightingCore/Scene.swift'],
    ['sed', '-n', '1,48p', 'Sources/LightingCore/StudioOptics.swift'],
    ['rg', '-n', 'photometry|missing tool|unrun test', 'docs/QUALITY.md'],
    ['sed', '-n', '61,71p', '/tmp/keyfill02-r2/docs/parallel/02/WAVE-TASKS.md'],
    ['cat', '/tmp/keyfill02-r2-brief.md'],
    ['cat', '/tmp/keyfill02-r2-probe.py']
]
for command in references:
    code, text = run(command, 'reference.log')
    if code:
        print(text)
        sys.exit(code)
code, text = run(['python3', '/tmp/keyfill02-r2-probe.py', str(work), str(out/'probe.swift'), 'v1'])
print(text, end='')
run(['git', 'status', '--short', '--branch'], 'provenance.log')
with (out/'provenance.log').open('a') as f:
    f.write('UTC end: '+datetime.datetime.now(datetime.timezone.utc).isoformat()+'\nActual helper exit: '+str(code)+'\n')
sys.exit(code)
