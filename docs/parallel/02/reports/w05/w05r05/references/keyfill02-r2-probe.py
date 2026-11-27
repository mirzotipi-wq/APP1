import pathlib,sys,subprocess
work=pathlib.Path(sys.argv[1]).resolve();source=pathlib.Path(sys.argv[2]).resolve();snap=pathlib.Path('/tmp/keyfill02-r2-snapshots')/(sys.argv[3] if len(sys.argv)>3 else 'v1');out=work/'private-output'
assert work.is_relative_to('/tmp/keyfill02-r2-workers') and source.is_relative_to(work) and (snap/'READY').exists()
cmd=['flock','/tmp/keyfill02-r2-build.lock','/tmp/keyfill02-r2-toolchain/usr/bin/swiftc','-I',str(snap/'Modules'),str(source),str(snap/'libLightingCore.a'),'-o',str(out/'probe')]
with (out/'compile.log').open('w') as f:r=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT)
if r.returncode:print((out/'compile.log').read_text());sys.exit(r.returncode)
with (out/'probe.log').open('w') as f:r=subprocess.run([str(out/'probe')],stdout=f,stderr=subprocess.STDOUT)
print((out/'probe.log').read_text());sys.exit(r.returncode)
