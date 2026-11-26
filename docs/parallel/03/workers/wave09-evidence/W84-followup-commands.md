# W84 followup command journal

All source commands used `/tmp/keyfill03-7f4b/workers/W84-implementation` unless stated. This records actual source/metadata checks, not native execution. Source writes used `apply_patch` only for the two authorized private files; artifact writes stayed in W84-owned report/evidence paths.

## Reads

Executed from root `/workspace/scratch/7f4be4bbb2d6/APP1-lane03`, exit 0:

```sh
cat docs/parallel/03/evidence/lane04-preview-proposal/OWNER_REQUESTS-69eb9c.md docs/parallel/03/evidence/lane04-preview-proposal/owner-proposal.md docs/parallel/03/evidence/lane04-preview-proposal/owner-preview-adoption.patch
```

Executed from private tree, exit 0:

```sh
git status --short && git rev-parse HEAD && rg -n 'UIHostingController|accessibilityIdentifier|waitUntil|bounded|RunLoop|withCheckedThrowingContinuation|UIWindow' NativeTests | head -n 150 && sed -n '60,265p' App/ReferenceStudyPreview.swift && rg -n 'ReferenceStudyPreview|StudyPreviewPipelineTests|NativeTests' project.yml Package.swift NativeTests
```

Executed from private tree, exit 2: `LightingScene.swift` does not exist; `Scene.swift` and other reads succeeded. This read-only lookup failure is preserved.

```sh
sed -n '1,175p' NativeTests/StudioTextFieldTests.swift && sed -n '420,535p' NativeTests/StudioTextFieldTests.swift && sed -n '1,100p' project.yml && sed -n '1,150p' scripts/native_test_shards.py && sed -n '380,430p' Sources/LightingCore/ReferenceStudy.swift && rg -n 'static func|static let|exposure' Sources/LightingCore/LightingScene.swift Sources/LightingCore/Scene.swift NativeTests/StudyRenderCacheTests.swift
```

Executed from private tree, exit 0:

```sh
rg -n 'accessibilityElements|accessibilityElement\(at|accessibilityElementCount|UIAccessibilityIdentification|accessibilityLabel' NativeTests | head -n 100 && rg -n 'StudyPreview|platform|--check|--list|argparse' scripts/native_test_shards.py Package.swift
```

Apple API reference lookup used search queries `site:developer.apple.com/documentation/uikit/nsobject accessibilityElementCount accessibilityElements` and `site:developer.apple.com/documentation/uikit/uiaccessibilityidentification accessibilityIdentifier`. It informed public API selection; no Apple runtime was available.

## Syntax and diff

Executed from private tree, exit 0:

```sh
/workspace/scratch/13a77d3f98df/toolchain/usr/bin/swiftc -frontend -parse App/ReferenceStudyPreview.swift NativeTests/StudyPreviewAdoptionTests.swift && git diff --check && git diff --stat && sha256sum App/ReferenceStudyPreview.swift NativeTests/StudyPreviewAdoptionTests.swift NativeTests/StudyPreviewPipelineTests.swift && git diff -- App/ReferenceStudyPreview.swift
```

This was parsing only, without SDK/typechecking/linking. At this point the new test was untracked, so the first diff stat covered only the production file.

## Packaging and discovery

Executed private-index preparation `git add -N NativeTests/StudyPreviewAdoptionTests.swift && git diff --check`, exit 0. Then executed `python3 -B -` with this exact stdin, exit 0:

```python
from pathlib import Path
import hashlib, importlib.util, json, subprocess
root = Path.cwd()
out = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03/docs/parallel/03/workers/wave09-evidence')
base = 'a7c93be58a04154748c951b3d485b05300e9692c'
preview = 'App/ReferenceStudyPreview.swift'
new_test = 'NativeTests/StudyPreviewAdoptionTests.swift'
old_tests = 'NativeTests/StudyPreviewPipelineTests.swift'
original = subprocess.check_output(['git', 'show', f'{base}:{old_tests}'])
assert original == Path(old_tests).read_bytes()
source = Path(preview).read_bytes()
old_source = subprocess.check_output(['git', 'show', f'{base}:{preview}'])
boundary = b'\n#if canImport(SwiftUI) && canImport(CoreGraphics)\n\n/// The bounded'
assert source.split(boundary)[0] == old_source.split(boundary)[0]
module_spec = importlib.util.spec_from_file_location('native_inventory', root / 'scripts/native_test_shards.py')
module = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(module)
methods = module.discover_methods('NativeTests')
assert methods['StudyPreviewAdoptionTests'] == {'testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade'}
assert len(methods['StudyPreviewPipelineTests']) == 10
patch = subprocess.check_output(['git', 'diff', '--', preview, new_test])
patch_path = out / 'W84-preview-adoption.patch'
patch_path.write_bytes(patch)
receipt = {
 'runtime_id': '/root/wave09/w84_implementation',
 'followup_not_new_worker': True,
 'base': base,
 'base_tree': subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}']).decode().strip(),
 'private_worktree': str(root),
 'sha256': {path: hashlib.sha256(Path(path).read_bytes()).hexdigest() for path in [preview, new_test, old_tests]},
 'patch': str(patch_path),
 'patch_sha256': hashlib.sha256(patch).hexdigest(),
 'checks': {'unchanged_pipeline_source': True, 'ten_existing_pipeline_tests_byte_identical': True, 'new_hosted_method_discovered': True, 'native_methods_discovered': sum(map(len, methods.values()))},
 'parse_command': '/workspace/scratch/13a77d3f98df/toolchain/usr/bin/swiftc -frontend -parse App/ReferenceStudyPreview.swift NativeTests/StudyPreviewAdoptionTests.swift',
 'parse_exit': 0,
 'native_build_and_execution': 'unrun; root owns Apple execution',
 'baseline_failure': 'Source argument only, unrun: with only the render hook added to a7, the local successful-frame return prevents the second A invocation; deleting only that return leaves request-only current status during the held second A.',
 'coverage': 'One actual mounted ReferenceStudyPreview identity; 2 A/1 B producer handshakes; B mock downgrade held before cancellation; second A held; actual accessibility tree requires previous/updating and excludes current image/backend/warning, then adopts CPU.',
 'fixture_limits': 'Synthetic outputs and scripted backend policy; no actual Metal or engine downgrade execution. Hosted AX traversal and Swift typechecking are unverified until the native run.',
 'public_api_references': ['https://developer.apple.com/documentation/uikit/uiaccessibilityidentification', 'https://developer.apple.com/documentation/uikit/uiaccessibilitycontainer'],
}
(out / 'W84-preview-adoption.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
```

No Swift typecheck/build/test, host render, benchmark, commit/push or cleanup command was executed. Public UIKit accessibility APIs still require the native compiler/runtime check; their use here is not evidence that the hosted method passed.
