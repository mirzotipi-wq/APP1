from pathlib import Path
import re, subprocess
root=Path.cwd(); swift='/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc'
build=root/'verification/candidate/release'; build.mkdir(exist_ok=True)
def run(name,args):
    log=build/(name+'.log'); print('START',name,flush=True)
    with log.open('w') as out: result=subprocess.run(args,stdout=out,stderr=subprocess.STDOUT)
    print('DONE',name,'exit',result.returncode,flush=True)
    if result.returncode:
        print('\n'.join(log.read_text().splitlines()[-35:]),flush=True);raise SystemExit(result.returncode)
sources=sorted(str(p) for p in (root/'Sources/LightingCore').glob('*.swift'))
run('build-core',[swift,'-O','-whole-module-optimization','-enable-testing','-emit-library','-emit-module','-module-name','LightingCore','-emit-module-path',str(build/'LightingCore.swiftmodule'),*sources,'-o',str(build/'libLightingCore.so')])
tests=sorted((root/'Tests/LightingCoreTests').glob('*.swift')); cases=[]; count=0
for path in tests:
    text=path.read_text(); match=re.search(r'(?:final )?class (\w+)\s*:\s*XCTestCase',text)
    if not match: continue
    methods=re.findall(r'\bfunc (test\w+)\s*\(',text);count+=len(methods)
    cases.append('    testCase(['+', '.join('("'+m+'", '+match.group(1)+'.'+m+')' for m in methods)+'])')
(build/'main.swift').write_text('import XCTest\nXCTMain([\n'+',\n'.join(cases)+'\n])\n')
print('DECLARED_XCTEST_METHODS',count,flush=True)
flags=['-I',str(build),'-L',str(build),'-lLightingCore','-Xlinker','-rpath','-Xlinker',str(build)]
run('build-tests',[swift,'-O',*flags,*map(str,tests),str(build/'main.swift'),'-o',str(build/'core-tests')])
run('tests',[str(build/'core-tests')])
for stem in ['prepare-kernel-fixtures','precision-boundary','benchmark-study','grazing-study-probe']:
    copy=build/(stem+'.swift');copy.write_text('@testable import LightingCore\n'+(root/'scripts'/f'{stem}.swift').read_text())
    run('build-'+stem,[swift,'-O','-parse-as-library',*flags,str(copy),'-o',str(build/stem)])
