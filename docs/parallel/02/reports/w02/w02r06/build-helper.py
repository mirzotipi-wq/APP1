import sys,pathlib,subprocess
root=pathlib.Path(sys.argv[1]).resolve(); src=pathlib.Path(sys.argv[2]).resolve(); snap=pathlib.Path('/tmp/keyfill02-swift-snapshot/v1')
assert str(root).startswith('/tmp/keyfill02-workers/') and src.is_relative_to(root)
out=root/'private-output';out.mkdir(exist_ok=True)
cmd=['flock','/tmp/keyfill02-build.lock','/tmp/keyfill02-toolchain/usr/bin/swiftc','-I',str(snap/'Modules'),str(src),str(snap/'libLightingCore.a'),'-o',str(out/'probe')]
r=subprocess.run(cmd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/'compile.log').write_text(r.stdout)
if r.returncode: print(r.stdout);sys.exit(r.returncode)
r=subprocess.run([str(out/'probe')],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT);(out/'probe.log').write_text(r.stdout);print(r.stdout);sys.exit(r.returncode)
