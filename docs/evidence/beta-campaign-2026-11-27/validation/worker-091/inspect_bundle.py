#!/usr/bin/env python3
"""Read-only packaging evidence from the real current Release simulator bundle."""
from pathlib import Path
import hashlib, json, plistlib, struct, subprocess, zipfile

ROOT = Path('/workspace/scratch/4633a14a0d5b')
REPO = ROOT / 'APP1'
OUT = ROOT / 'campaign/evidence/091'
REV = 'f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5'
BUNDLE = ROOT / 'campaign/evidence/089/release-app/KeyAndFill-simulator-release-contents/KeyAndFill.app'
ARCHIVE = ROOT / 'campaign/evidence/089/downloads/15201422628-release.zip'
EXPECTED_ARCHIVE = '1cac448734926e7685151a9df92eda3219118e080872ebebf4a19222ea8275e1'
sha = lambda data: hashlib.sha256(data).hexdigest()
source_paths = [
    'project.yml', 'Package.swift', 'Resources/PrivacyInfo.xcprivacy',
    'App/Assets.xcassets/AppIcon.appiconset/AppIcon.png',
    'App/Assets.xcassets/AppIcon.appiconset/Contents.json',
    'scripts/verify_privacy_manifest.py', 'scripts/verify_app_icon.py',
    'App/StudioSettingsView.swift', 'App/ReferencePhoto.swift',
    'App/ReferenceComparisonView.swift', 'App/PhotoComparisonView.swift',
    'App/ReferenceAnalysisService.swift', 'App/BoundedFileReader.swift',
    'App/ARPlacementController.swift', 'App/ARPlacementView.swift',
    'App/ProjectDocumentIO.swift', 'App/ProjectBackupView.swift',
    'Sources/LightingCore/LightingProjectDocument.swift',
    'App/LightingPlanExportView.swift', 'App/LightingPlanPDF.swift',
    'App/BetaFeedbackView.swift', 'Sources/LightingCore/BetaFeedbackReport.swift',
    'App/StudioPreferences.swift', 'App/EntitlementStore.swift', 'App/ProFeaturesView.swift'
]
sources = []
for name in source_paths:
    data = subprocess.check_output(['git', 'show', f'{REV}:{name}'], cwd=REPO)
    assert (REPO / name).read_bytes() == data, name
    sources.append({'path': name, 'bytes': len(data), 'sha256': sha(data)})

assert sha(ARCHIVE.read_bytes()) == EXPECTED_ARCHIVE
with zipfile.ZipFile(ARCHIVE) as archive:
    assert archive.testzip() is None
info = plistlib.loads((BUNDLE / 'Info.plist').read_bytes())
privacy = plistlib.loads((BUNDLE / 'PrivacyInfo.xcprivacy').read_bytes())
assert privacy == plistlib.loads((REPO / 'Resources/PrivacyInfo.xcprivacy').read_bytes())
camera = 'Camera access lets you place your lighting plan in the room with AR. Camera frames stay on your device.'
expectations = {
    'CFBundleIdentifier': 'com.example.keyandfill',
    'CFBundleDisplayName': 'Key & Fill',
    'CFBundleShortVersionString': '0.1.0',
    'CFBundleVersion': '2',
    'CFBundleSupportedPlatforms': ['iPhoneSimulator'],
    'DTPlatformName': 'iphonesimulator',
    'MinimumOSVersion': '17.0',
    'UIDeviceFamily': [1, 2],
    'NSCameraUsageDescription': camera,
}
for key, expected in expectations.items():
    assert info.get(key) == expected, (key, info.get(key))
assert 'KEYFILL_PRO_PRODUCT_ID' not in info
assert 'NSAppTransportSecurity' not in info
assert 'NSPhotoLibraryUsageDescription' not in info
assert 'NSPhotoLibraryAddUsageDescription' not in info
assert not (BUNDLE / 'embedded.mobileprovision').exists()
assert not (BUNDLE / '_CodeSignature/CodeResources').exists()
for key in ['CFBundleIcons', 'CFBundleIcons~ipad']:
    assert info[key]['CFBundlePrimaryIcon']['CFBundleIconName'] == 'AppIcon'
assert (BUNDLE / 'Assets.car').stat().st_size > 0
assert (BUNDLE / 'default.metallib').stat().st_size > 0

binary = (BUNDLE / 'KeyAndFill').read_bytes()
assert struct.unpack_from('>I', binary)[0] == 0xcafebabe
arches = []
for i in range(struct.unpack_from('>I', binary, 4)[0]):
    cpu, subtype, offset, size, align = struct.unpack_from('>IIIII', binary, 8 + 20*i)
    image = binary[offset:offset+size]
    assert struct.unpack_from('<I', image)[0] == 0xfeedfacf
    commands = struct.unpack_from('<I', image, 16)[0]
    pos, frameworks = 32, []
    for j in range(commands):
        command, length = struct.unpack_from('<II', image, pos)
        assert length >= 8 and pos+length <= len(image)
        if command in [0xc, 0x18, 0x80000018, 0x8000001f, 0x80000023]:
            name_offset = struct.unpack_from('<I', image, pos+8)[0]
            name = image[pos+name_offset:pos+length].split(b'\0', 1)[0].decode()
            frameworks.append(name)
        pos += length
    assert all(name.startswith(('/System/Library/', '/usr/lib/')) for name in frameworks)
    arches.append({'cpu_type': cpu, 'cpu_subtype': subtype, 'direct_dynamic_dependencies': frameworks})

commands = []
for script in ['scripts/verify_privacy_manifest.py', 'scripts/verify_app_icon.py']:
    command = ['python3', script, '--bundle', str(BUNDLE)]
    proc = subprocess.run(command, cwd=REPO, capture_output=True, text=True)
    assert proc.returncode == 0, proc.stdout+proc.stderr
    commands.append({'command': command, 'exit_code': proc.returncode, 'stdout': proc.stdout, 'stderr': proc.stderr})
files = [{'path': str(p.relative_to(BUNDLE)), 'bytes': p.stat().st_size, 'sha256': sha(p.read_bytes())}
         for p in sorted(BUNDLE.rglob('*')) if p.is_file()]
receipt = {
    'worker': '/root/a091_release_bundle_privacy', 'source': REV,
    'run_id': 46004241191, 'artifact_id': 15201422628,
    'archive_sha256': sha(ARCHIVE.read_bytes()), 'archive_crc_valid': True,
    'bundle': str(BUNDLE), 'bundle_info': info, 'privacy_manifest': privacy,
    'bundle_files': files, 'source_files': sources,
    'direct_dynamic_dependencies': arches, 'verification_commands': commands,
    'observations': {
        'packaged_privacy_equals_source': True,
        'expected_camera_purpose_string_present': True,
        'compiled_iPhone_and_iPad_icons_present': True,
        'blank_product_setting_omitted_from_generated_info': True,
        'external_dynamic_frameworks_observed': False,
        'embedded_distribution_profile_or_code_resources_present': False,
    },
    'limits': [
        'Static bundle/source inspection; no app launch, permission interaction or runtime network capture.',
        'System frameworks can perform network operations; a static network API search is not a runtime network audit.',
        'Simulator bundle, not an iPhoneOS installable or distribution-signed beta.',
        'No App Store privacy submission, name clearance, signing identity or device entitlement verification.'
    ]
}
(OUT / 'bundle-audit.json').write_text(json.dumps(receipt, indent=2, sort_keys=True)+'\n')
print(json.dumps({'source': REV, 'artifact_sha256': receipt['archive_sha256'],
                  'bundle_files': len(files), 'source_files': len(sources),
                  'architectures': len(arches), 'receipt_sha256': sha((OUT/'bundle-audit.json').read_bytes())}, indent=2))
