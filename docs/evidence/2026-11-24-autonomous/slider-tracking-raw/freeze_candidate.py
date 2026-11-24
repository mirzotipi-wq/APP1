from pathlib import Path
import subprocess, hashlib, json, difflib, shutil
root=Path(__file__).resolve().parents[1]
repo=Path('/workspace/scratch/73dcd6a65726/APP1')
out=root/'verification'
base=(root/'BASE_REVISION').read_text().strip()
changed=['App/StudioSlider.swift','App/StudioSliderTracking.swift','App/CameraInspector.swift','App/NeutralCardInspector.swift','App/OpticsInspector.swift','App/StudioView.swift','NativeTests/StudioSliderTrackingTests.swift','NativeTests/StudioTrackingSliderTests.swift','UITests/StudioSmokeTests.swift']
parsed=changed+['App/StudioSliderEditing.swift']
command=['/workspace/scratch/73dcd6a65726/toolchains/swift-6.4.3-RELEASE-debian13/usr/bin/swiftc','-frontend','-parse',*parsed]
with (out/'native-syntax.log').open('w') as log: result=subprocess.run(command,cwd=root,stdout=log,stderr=subprocess.STDOUT)
syntax={'command':command,'exit':result.returncode,'limitation':'Syntax only; no Apple SDK type checking or native execution','sources':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in parsed}}
(out/'native-syntax.json').write_text(json.dumps(syntax,indent=2)+'\n')
if result.returncode: raise SystemExit('Syntax failed: '+(out/'native-syntax.log').read_text())
pure=json.loads((out/'pure-inputs.json').read_text())
for path,digest in pure['sources'].items():
 if hashlib.sha256((root/path).read_bytes()).hexdigest()!=digest:raise SystemExit('Pure input changed after tests: '+path)
print('All',len(pure['sources']),'pure-run inputs still match tested hashes.')
base_paths=subprocess.check_output(['git','ls-tree','-r','--name-only',base,'--','App','Sources','NativeTests','UITests','Tests','Package.swift','project.yml'],cwd=repo,text=True).splitlines()
base_data={p:subprocess.check_output(['git','show',base+':'+p],cwd=repo) for p in base_paths}
actual=[]
for path,old in base_data.items():
 p=root/path
 if not p.exists() or p.read_bytes()!=old:actual.append(path)
for area in ['App','Sources','NativeTests','UITests','Tests']:
 for p in (root/area).rglob('*'):
  if p.is_file() and str(p.relative_to(root)) not in base_data:actual.append(str(p.relative_to(root)))
if set(actual)!=set(changed):raise SystemExit('Unexpected diff: '+repr(actual))
reconstruction=out/'reconstruction'
if reconstruction.exists():raise SystemExit('Reconstruction path exists; inspect first')
reconstruction.mkdir()
parts=[]
for p in changed:
 new=(root/p).read_text();old=base_data.get(p,b'').decode()
 parts.append('diff --git a/'+p+' b/'+p+'\n')
 if p not in base_data:parts.append('new file mode 100644\n')
 parts.extend(difflib.unified_diff(old.splitlines(keepends=True),new.splitlines(keepends=True),fromfile='a/'+p if p in base_data else '/dev/null',tofile='b/'+p,n=3))
 if p in base_data:
  target=reconstruction/p;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(base_data[p])
patch=out/'slider-tracking-candidate.patch';patch.write_text(''.join(parts))
checks=[]
for cmd,cwd in [(['git','apply','--check',str(patch)],reconstruction),(['git','apply',str(patch)],reconstruction),(['git','apply','--check',str(patch)],repo)]:
 result=subprocess.run(cmd,cwd=cwd,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 checks.append({'command':cmd,'cwd':str(cwd),'exit':result.returncode,'output':result.stdout})
 if result.returncode:raise SystemExit('Patch check failed: '+result.stdout)
for p in changed:
 if (reconstruction/p).read_bytes()!=(root/p).read_bytes():raise SystemExit('Reconstruction mismatch: '+p)
(out/'reconstruction.json').write_text(json.dumps({'checks':checks,'verified_files':changed,'reconstructed_files_match':True,'live_check_only':True},indent=2)+'\n')
shutil.rmtree(reconstruction)
event=Path('/workspace/scratch/73dcd6a65726/verification/source9-studio-visual/optics-failure/B26619A3-98D3-435F-9813-0FE3BEF6C171')
shutil.copyfile(event,out/'source9-width-synthesized-event.bplist')
files={p:{'bytes':(root/p).stat().st_size,'sha256':hashlib.sha256((root/p).read_bytes()).hexdigest(),'status':'modified' if p in base_data else 'new'} for p in changed}
artifacts={str(p.relative_to(root)):{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.rglob('*')) if p.is_file() and p.name!='slider-tracking-manifest.json'}
manifest={'base_revision':base,'base_tree':subprocess.check_output(['git','rev-parse',base+'^{tree}'],cwd=repo,text=True).strip(),'decision':'Ready for source integration review; Apple SDK build, actual native gesture and AX acceptance pending','candidate_sources':files,'unchanged_contracts':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in ['App/StudioSliderEditing.swift','NativeTests/StudioSliderEditingTests.swift','Sources/LightingCore/SceneEditHistory.swift','Tests/LightingCoreTests/SceneEditHistoryTests.swift']},'artifacts':artifacts,'pure_tests':{'debug':38,'release':38,'failures':0,'initial_new_fixture_failure_preserved':True},'native_only_methods_unexecuted':3,'new_native_methods_total':18,'live_production_modified_by_this_task':False}
path=out/'slider-tracking-manifest.json';path.write_text(json.dumps(manifest,indent=2)+'\n')
print('Patch checks/reconstruction passed; live check was read-only.')
print('Candidate files:',len(files),'artifact files:',len(artifacts))
for p in [patch,out/'slider-tracking-report.md',path]:print(p.name,p.stat().st_size,hashlib.sha256(p.read_bytes()).hexdigest())
