"""Source/retained-receipt reconciliation only; no build, render or native test."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
PRIVATE = Path('/tmp/keyfill03-7f4b/workers/W97-consumer')
S03 = '342e3280e3eb077d55e122c8bfb88b4062b431ed'
DOC = '92dc7a69c0032141ee49de0b96940fccab83a33e'
S04 = '69eb9c5096c863e9c8be1c5e53d9faff0d9c3014'
S02 = 'b5c1f008446f8b33f3ee97f8fefe6675058ef347'
S36 = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
sha = lambda b: hashlib.sha256(b).hexdigest()
commands, fingerprints = [], []

def git(*args, cwd=ROOT):
    argv = ['git', '-C', str(cwd), *args]
    r = subprocess.run(argv, env={**os.environ, 'GIT_NO_LAZY_FETCH': '1'}, capture_output=True)
    commands.append(dict(argv=argv, GIT_NO_LAZY_FETCH='1', exit=r.returncode,
                         stdout_sha256=sha(r.stdout), stderr=r.stderr.decode()))
    return r

def source(rev, path, fallback=None):
    identity = git('rev-parse', f'{rev}:{path}')
    assert identity.returncode == 0
    blob = identity.stdout.decode().strip()
    r = git('show', f'{rev}:{path}')
    data, origin = r.stdout, 'local Git object'
    if r.returncode:
        assert fallback is not None, (rev, path)
        data, origin = Path(fallback).read_bytes(), str(fallback)
    actual = hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest()
    assert actual == blob, (path, actual, blob)
    fingerprints.append(dict(revision=rev, path=path, blob=blob, sha256=sha(data),
                             git_object_available=r.returncode == 0, bytes_origin=origin))
    return data.decode()

assert git('rev-parse', 'HEAD', cwd=PRIVATE).stdout.decode().strip() == S03
assert git('status', '--porcelain', cwd=PRIVATE).stdout == b''
preview = source(S03, 'App/ReferenceStudyPreview.swift')
preview36 = source(S36, 'App/ReferenceStudyPreview.swift')
adoption = source(S03, 'NativeTests/StudyPreviewAdoptionTests.swift')
pipeline = source(S03, 'NativeTests/StudyPreviewPipelineTests.swift')
pipeline36 = source(S36, 'NativeTests/StudyPreviewPipelineTests.swift')
cpu03 = source(S03, 'Sources/LightingCore/ReferenceStudy.swift')
cpu04 = source(S04, 'Sources/LightingCore/ReferenceStudy.swift')
kernel03 = source(S03, 'App/StudyKernel.h')
kernel04 = source(S04, 'App/StudyKernel.h')
kernel36 = source(S36, 'App/StudyKernel.h')
eligibility = source(S04, 'Sources/LightingCore/StudyFloat32Eligibility.swift')
engine = source(S04, 'App/MetalStudyRenderer.swift',
                '/tmp/keyfill03-7f4b/latest04/MetalStudyRenderer.swift')
cache03 = source(S03, 'Sources/LightingCore/StudyFrameCache.swift')
cache04 = source(S04, 'Sources/LightingCore/StudyFrameCache.swift')
request02 = source(S02, 'docs/parallel/02/CONSUMER-REQUESTS.md')
request04 = source(S04, 'docs/parallel/04/OWNER_REQUESTS.md')
old_routes = source(DOC, 'docs/parallel/03/OWNER_REQUESTS.md')
routes_path = ROOT / 'docs/parallel/03/OWNER_REQUESTS.md'
routes = routes_path.read_text()

def block(text, start, end):
    a = text.index(start)
    return text[a:text.index(end, a)]

checks = {
    'private_source_clean_and_exact': True,
    'historical_wave07_and_wave09_sections_preserved_byte_for_byte':
        old_routes[old_routes.index('## Immutable wave 07'):]
        == routes[routes.index('## Immutable wave 07'):],
    'root_W89_reference_comparison_correction_already_in_documentation_input':
        'both ReferenceComparisonUITests methods passed' in old_routes,
    '04_request_copy_matches_pinned_blob': request04 == (ROOT / 'docs/parallel/03/evidence/lane04-preview-proposal/OWNER_REQUESTS-69eb9c.md').read_text(),
    '04_engine_forwards_actual_width': 'StudyFloat32Eligibility.supports(scene, width: width)' in engine
        and 'let supportsMetal = MetalStudyRenderer.supports(scene, width: width)' in engine,
    '04_helper_has_actual_width_silhouette_guard': 'supports(_ scene: LightingScene, width: Int)' in eligibility
        and 'silhouetteShellFitsBudget(geometry: geometry, camera: camera, width: width)' in eligibility,
    '04_helper_no_requested_intensity_normality_policy_in_inspected_source':
        all(s not in eligibility for s in ['leastNormalMagnitude', 'leastNonzeroMagnitude', 'Float(light.candela)', 'outputScale']),
    '04_engine_evicts_metal_cache_entries_on_select_cpu': 'frameCache.removeAll { $0.backend == .metal }' in engine,
    '03_04_frame_cache_source_identical': cache03 == cache04,
    '03_04_public_packing_definition_identical':
        block(cpu03, 'public struct StudyComputeInput', '\nprivate struct StudySetup')
        == block(cpu04, 'public struct StudyComputeInput', '\nprivate struct StudySetup'),
    '03_restores_private_scale_before_float_packing': 'pack(s.position - center, s.candela * s.outputScale)' in cpu03,
    '04_cpu_lacks_03_private_scale': 'outputScale' not in cpu04,
    'both_kernels_guard_validity_before_zero_lux': all(
        k.index('if (r2 < 0.0025f)') < k.index('if (!incident.valid)') < k.index('if (incident.lux == 0.0f)')
        for k in [kernel03, kernel04]),
    'both_kernels_guard_rectangle_before_sample_loop': all(
        k.index('if (dot(separation,separation) < center.w*center.w)') < k.index('for (uint i=0; i<sampleCount;)')
        for k in [kernel03, kernel04]),
    'source36_kernel_equals_current03_but_differs04': kernel36 == kernel03 and kernel36 != kernel04,
    'current03_request_and_ticket_define_currentness': 'frame.request == request && frame.ticket == activeTicket' in preview,
    'current03_activation_calls_render_hook': 'try await renderStudy(snapshot.scene, snapshot.subject)' in preview,
    'current03_scene_request_excludes_placement_room': 'renderScene.placementRoom = nil' in preview,
    'pipeline_implementation_byte_identical_to_source36':
        block(preview, '@MainActor final class StudyPreviewPipeline', '\n#if canImport(SwiftUI)')
        == block(preview36, '@MainActor final class StudyPreviewPipeline', '\n#if canImport(SwiftUI)'),
    'ten_pipeline_test_file_byte_identical_to_source36': pipeline == pipeline36,
    'hosted_test_one_host_identity_and_explicit_continuations': adoption.count('UIHostingController(rootView:') == 1
        and 'withCheckedThrowingContinuation' in adoption and '.id(scene)' not in adoption,
    'hosted_test_uses_synthetic_outputs_and_positive_observations':
        'Both outputs are synthetic fixtures' in adoption
        and 'elements.contains { $0.identifier == "studyPreviousPreview"' in adoption
        and 'elements.contains { $0.identifier == "studyPreview" }' in adoption,
}
assert all(checks.values()), [k for k, v in checks.items() if not v]

evidence = ROOT / 'docs/parallel/03/evidence'
receipts = {}
for name in ['ci-core-342.json', 'ci-apple-build-342.json', 'ci-native-36.json',
             'ci-ui-failures-36.json', 'preview-adoption-inputs.json']:
    data = (evidence / name).read_bytes()
    receipts[name] = dict(sha256=sha(data), data=json.loads(data))
ui = receipts['ci-ui-failures-36.json']['data']
raw_log_hashes = []
for item in ui['logs']:
    actual = sha((ROOT / item['path']).read_bytes())
    assert actual == item['sha256']
    raw_log_hashes.append(dict(path=item['path'], sha256=actual, matches_retained_receipt=True))
core = receipts['ci-core-342.json']['data']
assert sha((ROOT / core['raw_log']).read_bytes()) == core['raw_log_sha256']
assert core['source'] == S03 and core['debug']['tests'] == 391 and core['debug']['failures'] == 0
assert core['standard_release']['tests'] == 391 and core['standard_release']['failures'] == 0
assert len(core['gate_results']) == 14
apple = receipts['ci-apple-build-342.json']['data']
assert apple['source'] == S03 and apple['build_step']['conclusion'] == 'success'

result = dict(
    schema=1, worker='W97-consumer', runtime_identity='/root/wave10/w97_consumer',
    parent='/root/wave10', recorded_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    private_worktree=str(PRIVATE), executable_source=S03, documentation_input=DOC,
    command=f'python3 {Path(__file__)}', script_sha256=sha(Path(__file__).read_bytes()),
    scope='Read-only source and retained-artifact verification; lane03 route documentation only.',
    commands=commands, fingerprints=fingerprints, source_checks=checks,
    receipt_inputs=receipts, retained_ui_log_hashes=raw_log_hashes,
    owner_requests=dict(path=str(routes_path.relative_to(ROOT)), sha256=sha(routes_path.read_bytes())),
    historical_silhouette=dict(path='docs/parallel/03/evidence/gpu-silhouette-host.log',
        sha256=sha((evidence / 'gpu-silhouette-host.log').read_bytes()), width=24,
        focal_mm=161.27198111190464, mean=0.107639, maximum=24,
        fraction_above_4=0.00520833, unchanged_fraction_limit=0.005,
        invalid_mask_mismatches=0, status='Retained actual-Swift/shared-host counterexample; not rerun.'),
    owner_routes={
        '02': 'Review scoped CPU tiny-emitter response; positive per-cell Float subnormal/zero routing remains requested, without demonstrated guard-skipping mask bug.',
        '04': 'Integrate exact actual-width helper/engine pair; preserve lane03 CPU changes, packed ABI, original silhouette failure and exact masks; execute integrated native checks.',
        '01': 'Keep app-internal scene:subject: call and request semantics; own light-name byte-bound decision and investigate two original ProjectLibrary UI failures without asserted root cause.',
        '19': 'Review missing compact artifact and host parser; account for 165 current-source native methods separately from prior164 and from successful Apple build step.',
        '20': 'Integrate paired owners, preserve source-specific original failures and inherited main correction; own global milestone promotion.'},
    limits=[
        'Source-string and byte checks are not runtime tests or external-owner acknowledgments.',
        'No owner refresh, build, render, benchmark, Swift/native test, production edit, cleanup, commit or push was executed by W97.',
        'Current-source165 execution is pending in retained run45857561126/job140042273149; successful Apple Debug build is not a runtime result.',
        'Source36 native164 and unchanged ten pipeline methods do not execute the new synthetic hosted method or lane04 changed engine/kernel.',
        'Original hook-only before/fail unrun; real engine downgrade integration unrun; no manual VoiceOver/device/release/global M02/M03 claim.',
        'Runtime/token counters unavailable; qualitative checkpoint was sent.'
    ])
out = Path(__file__).with_name('W97-consumer.json')
out.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(dict(receipt=str(out), source_checks=len(checks), all_checks=True,
                     engine_blob='8c1acd852d85cd99671feaba883db1808bbb5e68',
                     owner_requests_sha256=result['owner_requests']['sha256'])))
