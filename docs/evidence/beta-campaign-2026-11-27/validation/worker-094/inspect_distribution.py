from pathlib import Path
import hashlib,json,plistlib,subprocess
root=Path(__file__).resolve().parents[3]
repo=root/'APP1'
rev='f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5'
files=['project.yml','.github/workflows/ios-prototype.yml','App/EntitlementStore.swift','App/ProFeaturesView.swift','App/ARPlacementController.swift','docs/QUALITY.md','docs/PRODUCT.md','docs/ROADMAP.md','docs/acceptance/m02-m03-code.md','Resources/PrivacyInfo.xcprivacy']
def digest(b):return hashlib.sha256(b).hexdigest()
inputs=[]
contents={}
for name in files:
 b=subprocess.check_output(['git','show',f'{rev}:{name}'],cwd=repo)
 contents[name]=b.decode()
 inputs.append({'path':name,'bytes':len(b),'sha256':digest(b),'current_worktree_equal':(repo/name).read_bytes()==b})
assert all(x['current_worktree_equal'] for x in inputs)
project=contents['project.yml']
assert 'PRODUCT_BUNDLE_IDENTIFIER: com.example.keyandfill' in project
assert 'DEVELOPMENT_TEAM' not in project
assert 'KEYFILL_PRO_PRODUCT_ID: ""' in project
assert 'CODE_SIGNING_ALLOWED=NO' in contents['.github/workflows/ios-prototype.yml']
artifacts=[]
for kind,artifact_id in [('debug',15201038035),('release',15201422628)]:
 p=root/'campaign/evidence/089'/f'{kind}-app-receipt.json'; receipt=json.loads(p.read_text())
 archive=root/receipt['archive']; actual=digest(archive.read_bytes()); assert actual==receipt['sha256']
 inner=receipt['nested_archives'][0]; actual_inner=digest((root/inner['archive']).read_bytes());assert actual_inner==inner['sha256']
 bundle=root/receipt['bundles'][0]['bundle']; info_bytes=(bundle/'Info.plist').read_bytes(); info=plistlib.loads(info_bytes)
 assert info['CFBundleIdentifier']=='com.example.keyandfill'
 assert info['MinimumOSVersion']=='17.0'
 assert info['CFBundleSupportedPlatforms']==['iPhoneSimulator']
 assert info['UIDeviceFamily']==[1,2]
 assert info['CFBundleShortVersionString']=='0.1.0' and info['CFBundleVersion']=='2'
 assert 'KEYFILL_PRO_PRODUCT_ID' not in info
 artifacts.append({'kind':kind,'artifact_id':artifact_id,'outer_archive':receipt['archive'],'outer_bytes':archive.stat().st_size,'outer_sha256':actual,'inner_archive':inner['archive'],'inner_bytes':inner['bytes'],'inner_sha256':actual_inner,'source_receipt_sha256':digest(p.read_bytes()),'info_sha256':digest(info_bytes),'info':{k:info[k] for k in ['CFBundleIdentifier','CFBundleDisplayName','CFBundleShortVersionString','CFBundleVersion','CFBundleSupportedPlatforms','UIDeviceFamily','MinimumOSVersion','DTSDKName','DTXcode','NSCameraUsageDescription']},'native_architecture_analysis':'See independently reconciled worker089 bundle receipt; this worker did not reparse Mach-O.'})
report={'worker':'/root/a094_distribution_readiness','source_revision':rev,'run_id':46004241191,'inspection_date':'2026-11-27','inputs':inputs,'artifacts':artifacts,'configuration':{'placeholder_bundle_id':'com.example.keyandfill','version':'0.1.0','build':'2','development_team_in_project':False,'ci_code_signing_allowed':False,'product_id_configured':False,'minimum_ios':'17.0','declared_device_families':['iPhone','iPad']},'limits':['No Apple account, existing app record, signing identity, or prior uploaded build was inspected.','No signing, archive creation, upload, invitation, enrollment, payment, or runtime test performed.','Simulator architecture does not establish iPhoneOS execution.','Native/device acceptance remains tied to worker089 current-source reconciliation.']}
(root/'campaign/evidence/094/distribution-audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'verified_pinned_inputs':len(inputs),'verified_original_archives':len(artifacts),'source':rev,'product_changes':False}))
