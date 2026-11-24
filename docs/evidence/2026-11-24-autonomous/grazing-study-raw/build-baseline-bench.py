from pathlib import Path
import subprocess
root=Path.cwd(); swift='/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc'
build=root/'verification/baseline/release';build.mkdir(exist_ok=True)
def run(name,args):
    log=build/(name+'.log');print('START',name,flush=True)
    with log.open('w') as f: r=subprocess.run(args,stdout=f,stderr=subprocess.STDOUT)
    print('DONE',name,'exit',r.returncode,flush=True)
    if r.returncode:print(log.read_text()[-6000:],flush=True);raise SystemExit(r.returncode)
sources=[str(p) for p in sorted((root/'Sources/LightingCore').glob('*.swift')) if p.name not in ['ReferenceStudy.swift','StudyAreaClipping.swift']]
sources.append(str(root/'verification/baseline/ReferenceStudy.swift'))
run('build-core',[swift,'-O','-whole-module-optimization','-enable-testing','-emit-library','-emit-module','-module-name','LightingCore','-emit-module-path',str(build/'LightingCore.swiftmodule'),*sources,'-o',str(build/'libLightingCore.so')])
flags=['-I',str(build),'-L',str(build),'-lLightingCore','-Xlinker','-rpath','-Xlinker',str(build)]
for stem in ['benchmark-study','grazing-study-probe']:
    copy=build/(stem+'.swift');copy.write_text('@testable import LightingCore\n'+(root/'scripts'/f'{stem}.swift').read_text())
    run('build-'+stem,[swift,'-O','-parse-as-library',*flags,str(copy),'-o',str(build/stem)])
