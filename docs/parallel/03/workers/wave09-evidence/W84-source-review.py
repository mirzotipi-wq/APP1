"""Source/hash checks only; does not execute Swift, SwiftUI, or a model of the view."""
from pathlib import Path
import hashlib
import json
import subprocess

tree = Path('/tmp/keyfill03-7f4b/workers/W84-implementation')
out = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03/docs/parallel/03/workers')
commands = []

def run(*args):
    result = subprocess.run(args, cwd=tree, capture_output=True, check=False)
    commands.append({'argv': list(args), 'cwd': str(tree), 'exit': result.returncode,
                     'stdout_sha256': hashlib.sha256(result.stdout).hexdigest(),
                     'stderr': result.stderr.decode()})
    if result.returncode:
        raise RuntimeError(commands[-1])
    return result.stdout

def sha(data):
    return hashlib.sha256(data).hexdigest()

base = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
cpu_base = 'db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5'
preview_path = 'App/ReferenceStudyPreview.swift'
tests_path = 'NativeTests/StudyPreviewPipelineTests.swift'
cpu_path = 'Sources/LightingCore/ReferenceStudy.swift'
preview = (tree / preview_path).read_bytes()
old_preview = run('git', 'show', f'{base}:{preview_path}')
tests = (tree / tests_path).read_bytes()
old_tests = run('git', 'show', f'{base}:{tests_path}')
cpu = (tree / cpu_path).read_bytes()
old_cpu = run('git', 'show', f'{cpu_base}:{cpu_path}')
head, tree_id = run('git', 'rev-parse', 'HEAD', 'HEAD^{tree}').decode().splitlines()
status = run('git', 'status', '--short').decode()
core_diff = run('git', 'diff', '--name-only', cpu_base, 'HEAD', '--', 'Sources/LightingCore').decode()
run('git', 'diff', '--check', base, 'HEAD', '--', preview_path, tests_path)
pipeline_boundary = b'\n#if canImport(SwiftUI) && canImport(CoreGraphics)\n\n/// The bounded'
task_boundary = b'        .onDisappear'
pipeline = preview.split(pipeline_boundary)[0]
old_pipeline = old_preview.split(pipeline_boundary)[0]
task_and_conversion = preview.split(task_boundary)[1]
old_task_and_conversion = old_preview.split(task_boundary)[1]
checks = {
    'expected_head': head == 'a7c93be58a04154748c951b3d485b05300e9692c',
    'expected_tree': tree_id == 'dda4e04f7c732ddad4167ccbda0e5f98a1b9d838',
    'expected_preview_sha256': sha(preview) == '612e922e16a900bf69cbc1bf13d9995912db535703a4b0bd85f372de1f1d44a5',
    'private_tree_clean': status == '',
    'pipeline_bytes_unchanged_since_36': pipeline == old_pipeline,
    'task_and_conversion_bytes_unchanged_since_36': task_and_conversion == old_task_and_conversion,
    'pipeline_tests_bytes_unchanged_since_36': tests == old_tests,
    'cpu_file_bytes_unchanged_since_db7': cpu == old_cpu,
    'all_lighting_core_paths_unchanged_since_db7': core_diff == '',
}
if not all(checks.values()):
    raise AssertionError(checks)

inspection_commands = [
    "pwd && rg --files -g AGENTS.md -g WORKER_PROTOCOL.md -g '*W74*' -g '*W80*' -g '*m02-m03-code*' -g '*ReferenceStudyPreview*' -g '*Pipeline*' -g '*pipeline*' -g '*architecture*' -g '*design*' -g '*quality*' -g '*W81*'",
    'cat AGENTS.md docs/parallel/03/WORKER_PROTOCOL.md docs/parallel/03/workers/W74-implementation.md docs/parallel/03/workers/W74-implementation-followup.md docs/parallel/03/workers/W80-independent-review.md docs/acceptance/m02-m03-code.md',
    "git rev-parse HEAD HEAD^{tree} && git status --short && sha256sum App/ReferenceStudyPreview.swift && sed -n '1,280p' App/ReferenceStudyPreview.swift && rg --files docs | rg -i '(architecture|design|quality|w81)'",
    'wc -l agents/OPERATING_PROTOCOL.md agents/HANDOFF.md agents/state.json docs/PRODUCT.md docs/ARCHITECTURE.md docs/ROADMAP.md docs/QUALITY.md docs/DESIGN.md NativeTests/StudyPreviewPipelineTests.swift && cat agents/OPERATING_PROTOCOL.md docs/ARCHITECTURE.md docs/DESIGN.md docs/QUALITY.md && cat docs/parallel/03/workers/wave08-evidence/W74-previous-frame-warning.patch',
    "cat NativeTests/StudyPreviewPipelineTests.swift && rg -n 'studyPreviousPreview|studyWarning|studyUpdating|studyPaused|unsupported pixels|Light study paused|Showing the previous' App NativeTests UITests Tests && git log -3 --oneline",
    'cat agents/HANDOFF.md agents/state.json docs/PRODUCT.md docs/ROADMAP.md docs/acceptance/m02-m03-code.md && python3 scripts/agent_cycle.py check && python3 scripts/agent_cycle.py next',
    "git diff --check 36ed6a1455dee7ca52b55f46d1a47262f5c98cc1 HEAD -- App/ReferenceStudyPreview.swift NativeTests/StudyPreviewPipelineTests.swift && git diff 36ed6a1455dee7ca52b55f46d1a47262f5c98cc1 HEAD -- App/ReferenceStudyPreview.swift NativeTests/StudyPreviewPipelineTests.swift && rg --files Sources | rg 'Study|CPU' && rg --files /workspace/scratch/13a77d3f98df/toolchain/usr/lib/swift | rg 'Swift.swiftmodule/.+\\.swiftinterface$'",
    "git diff --name-only db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5 HEAD -- Sources/LightingCore && rg -n -A8 '^precedencegroup (TernaryPrecedence|NilCoalescingPrecedence|ComparisonPrecedence|AdditionPrecedence)|^infix operator \\+ :' /workspace/scratch/13a77d3f98df/toolchain/usr/lib/swift/linux/Swift.swiftmodule/x86_64-unknown-linux-gnu.swiftinterface && rg -n 'struct StudyImage|unsupportedPixels|unsupportedMask|invalidMask' Sources/LightingCore/ReferenceStudy.swift",
]
receipt = {
    'canonical_runtime_id': '/root/wave09/w84_implementation',
    'parent': '/root/wave09', 'head': head, 'tree': tree_id,
    'private_worktree': str(tree), 'status': 'completed source review only',
    'file_sha256': {preview_path: sha(preview), tests_path: sha(tests), cpu_path: sha(cpu)},
    'slice_sha256': {'pipeline_prefix': sha(pipeline), 'task_and_conversion_suffix': sha(task_and_conversion)},
    'checks': checks,
    'source_review_matrix_not_runtime_results': [
        ['current image, positive count, active or inactive', 'Existing studyWarning; no previous warning. Current request is unaffected by activeRequest nil.'],
        ['same-subject previous image, positive count, active', 'Previous-qualified count in image label and single updating VStack.'],
        ['same-subject previous image, positive count, inactive', 'Same count retained; status changes to paused.'],
        ['same-subject previous image, zero count', 'Previous status only; optional map appends empty string.'],
        ['other-subject frame', 'Outer guard rejects it; loading or paused placeholder.'],
        ['no frame', 'Loading or paused placeholder.'],
        ['current error or conversion failure', 'Image nil; unavailable/retry branch. Pipeline zeroes count and backend.'],
        ['previous error or conversion failure', 'Outer guard rejects noncurrent nil-image frame.'],
    ],
    'observations': [
        'Warning count is read only from the retained frame that supplies the image. It cannot come from the new request.',
        'Current warning/backend and previous status are mutually exclusive in source. No stale move-lights advice/backend is added to the retained previous frame.',
        'Local Swift standard-library interface declares AdditionPrecedence above TernaryPrecedence; concatenation belongs to the previous-label branch. No Swift compiler executed.',
        'The visible previous warning shares one VStack/background with updating/paused status. Source introduces no second bottom-leading warning overlay.',
        'Child caption2 font is explicit inside the parent caption style. Accessibility label override on the status container and repeated count exposure need native semantics review; the Image has its own explicit full previous-count label.',
        'Image initializer label and accessibilityLabel use the same string. This does not prove actual announcement count, VoiceOver traversal, Dynamic Type fit, or overlay coverage.',
        'All ten pipeline test methods inspected; none was run. They cover publication/error seams, not actual SwiftUI warning presentation.',
    ],
    'inspection_shell_commands': [{'cwd': str(tree), 'command': c, 'exit': 0} for c in inspection_commands],
    'check_subprocess_commands': commands,
    'receipt_command': 'python3 ' + str(Path(__file__).resolve()),
    'receipt_script_sha256': sha(Path(__file__).read_bytes()),
    'limits': ['No native typecheck/build, test execution, render, benchmark, UI/VoiceOver session, model simulation, or physical/device claim.', 'No production edits, commits, pushes, or cleanup.'],
    'recommendation': 'No source blocker found. Native compilation and observed SwiftUI semantics/layout remain root-owned pending verification.',
}
target = out / 'wave09-evidence/W84-source-review.json'
target.write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps({'receipt': str(target), 'receipt_sha256': sha(target.read_bytes()), 'checks': checks}, indent=2))
