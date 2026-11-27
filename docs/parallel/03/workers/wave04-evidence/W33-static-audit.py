from pathlib import Path
import hashlib, json, re, subprocess
root=Path('/tmp/keyfill03-7f4b/workers/W33-api')
expected='ace9f2eba068bc31dd04bb2f1e2028af315d6bdb'
head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip()
assert head==expected
files=['Sources/LightingCore/PortraitStudy.swift','Sources/LightingCore/ReferenceStudy.swift','App/MetalStudyRenderer.swift','App/ReferenceStudyPreview.swift','Tests/LightingCoreTests/PortraitCameraDepthTests.swift','Tests/LightingCoreTests/PortraitStudyTests.swift','Tests/LightingCoreTests/StudyCancellationTests.swift','Tests/LightingCoreTests/StudyInputBoundaryTests.swift']
texts={f:(root/f).read_text() for f in files}
def positions(file,tokens):
    source=texts[file]
    hits=[source.index(token) for token in tokens]
    assert hits==sorted(hits), (file,hits)
    return [{"token":token,"line":source[:offset].count(chr(10))+1} for token,offset in zip(tokens,hits)]
order=positions(files[0],['guard (24...maximumWidth)','guard !isCancelled()','guard let camera = CameraFraming','let lighting = try StudyLighting','guard portraitDot(hit.geometricNormal, -ray) >= 0','do {','let signal = try lighting.evaluate','catch StudyError.invalidSurface','return .init(width: width'])
lighting=positions(files[1],['guard (try? scene.validated()) != nil','for light in scene.lights where light.candela > 0','guard let frame = StudioPhotometry.frame','if areaGuards.contains(where:','guard r2 >= 0.0025'])
source=texts[files[0]]
assert source.count('catch StudyError.invalidSurface')==1
assert 'catch StudyError.invalidCamera' not in source
engine=texts[files[2]]
bust=engine[engine.index('if subject == .bust {'):engine.index('if case .unchecked = state {')]
assert 'try PortraitStudyRenderer.render' in bust and 'catch' not in bust
inventory={file:re.findall(r'func (test\w+)\(',texts[file]) for file in files[4:]}
assert [len(inventory[file]) for file in files[4:]]==[3,7,7,5]
result={"worker":"W33-api","canonical_runtime_id":"/root/wave04/api","identity_observation":"collaboration.list_agents returned /root/wave04/api running","input_sha":head,"private_tree":str(root),"execution":"Python source-order assertions and exact test declaration inventory only; no Swift build/test/runtime execution","source_order":order,"lighting_order":lighting,"single_invalidSurface_catch":True,"bust_errors_propagate":True,"inventory":inventory,"test_declarations":sum(map(len,inventory.values())),"sha256":{f:hashlib.sha256((root/f).read_bytes()).hexdigest() for f in files},"limitations":["String-position assertions complement manual control-flow review; they are not Swift compilation or runtime tests.","Combined clipped-camera/malformed-light inputs are source predictions; no new runtime counterexample was needed.","Initial guessed wrapper paths were absent (rg exit 2); actual wrapper recovered via rg -l in App and Sources.","Broad read output was truncated by tool display; focused retained source slices resolved the relevant branches."]}
print(json.dumps(result,indent=2))
