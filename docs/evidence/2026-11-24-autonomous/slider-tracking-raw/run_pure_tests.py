from pathlib import Path
import subprocess, re, json, hashlib, sys
root=Path(__file__).resolve().parents[1]
out=root/'verification'
swift=Path('/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc')
inputs=[root/'NativeTests/StudioSliderEditingTests.swift',root/'Tests/LightingCoreTests/SceneEditHistoryTests.swift',root/'NativeTests/StudioSliderTrackingTests.swift']
entries=[]
for path in inputs:
    text=path.read_text()
    cls=re.search(r'final class (\w+): XCTestCase',text).group(1)
    names=re.findall(r'^    func (test\w+)\(',text,re.M)
    entries.append((cls,names))
runner='import XCTest\n\nXCTMain([\n'+',\n'.join('    testCase([\n'+',\n'.join('        ("'+name+'", '+cls+'.'+name+')' for name in names)+'\n    ])' for cls,names in entries)+'\n])\n'
(out/'main.swift').write_text(runner)
records=[]
for mode,flags in [('debug',['-Onone','-DDEBUG']),('release',['-O'])]:
    build=out/('build-'+mode);build.mkdir(exist_ok=True)
    commands=[
        [str(swift),'-swift-version','5',*flags,'-enable-testing','-module-name','LightingCore','-emit-library','-emit-module','-emit-module-path',str(build/'LightingCore.swiftmodule'),*map(str,sorted((root/'Sources/LightingCore').glob('*.swift'))),'-o',str(build/'libLightingCore.so')],
        [str(swift),'-swift-version','5',*flags,'-enable-testing','-module-name','KeyAndFill','-emit-library','-emit-module','-emit-module-path',str(build/'KeyAndFill.swiftmodule'),str(root/'App/StudioSliderEditing.swift'),str(root/'App/StudioSliderTracking.swift'),'-o',str(build/'libKeyAndFill.so')],
        [str(swift),'-swift-version','5',*flags,'-I',str(build),'-L',str(build),'-lLightingCore','-lKeyAndFill','-Xlinker','-rpath','-Xlinker',str(build),*map(str,inputs),str(out/'main.swift'),'-o',str(build/'slider-tests')]
    ]
    with (out/(mode+'-build.log')).open('w') as log:
        for command in commands:
            result=subprocess.run(command,cwd=root,stdout=log,stderr=subprocess.STDOUT)
            records.append({'mode':mode,'command':command,'exit':result.returncode})
            if result.returncode:
                (out/'commands.json').write_text(json.dumps(records,indent=2)+'\n')
                print((out/(mode+'-build.log')).read_text(),flush=True)
                raise SystemExit(result.returncode)
    with (out/(mode+'-tests.log')).open('w') as log:
        result=subprocess.run([str(build/'slider-tests')],cwd=root,stdout=log,stderr=subprocess.STDOUT)
    records.append({'mode':mode,'command':[str(build/'slider-tests')],'exit':result.returncode})
    (out/'commands.json').write_text(json.dumps(records,indent=2)+'\n')
    log=(out/(mode+'-tests.log')).read_text()
    print(mode+': '+str(result.returncode),flush=True)
    for line in log.splitlines():
        if 'Executed ' in line or 'error:' in line:print(line,flush=True)
    if result.returncode: raise SystemExit(result.returncode)
source_paths=sorted((root/'Sources/LightingCore').glob('*.swift'))+[root/'App/StudioSliderEditing.swift',root/'App/StudioSliderTracking.swift',*inputs]
manifest={'base_revision':(root/'BASE_REVISION').read_text().strip(),'test_count':sum(len(names) for _,names in entries),'test_classes':{cls:names for cls,names in entries},'sources':{str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}}
(out/'pure-inputs.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Manual harness complete; UIKit/SwiftUI not compiled or executed.',flush=True)
