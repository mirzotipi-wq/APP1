"""Read-only consumer source/retained-byte checks; no Swift or kernel execution."""
import hashlib
import json
import math
import os
from pathlib import Path
import struct
import subprocess

ROOT = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
PRIVATE = Path('/tmp/keyfill03-7f4b/workers/W87-consumer')
SOURCE03 = 'a7c93be58a04154748c951b3d485b05300e9692c'
SOURCE04 = '69eb9c5096c863e9c8be1c5e53d9faff0d9c3014'
SOURCE02 = 'b5c1f008446f8b33f3ee97f8fefe6675058ef347'
SOURCE36 = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
commands, fingerprints = [], []
sha = lambda data: hashlib.sha256(data).hexdigest()

def git(*args, cwd=ROOT):
    argv = ['git', '-C', str(cwd), *args]
    run = subprocess.run(argv, env={**os.environ, 'GIT_NO_LAZY_FETCH': '1'}, capture_output=True)
    commands.append({'argv': argv, 'GIT_NO_LAZY_FETCH': '1', 'exit': run.returncode,
                     'stdout_sha256': sha(run.stdout), 'stderr': run.stderr.decode()})
    return run

def source(rev, path):
    identity = git('rev-parse', f'{rev}:{path}').stdout.decode().strip()
    run = git('show', f'{rev}:{path}')
    fingerprints.append({'revision': rev, 'path': path, 'blob': identity,
                         'available': run.returncode == 0,
                         'sha256': sha(run.stdout) if run.returncode == 0 else None})
    return run.stdout.decode() if run.returncode == 0 else None

assert git('rev-parse', 'HEAD', cwd=PRIVATE).stdout.decode().strip() == SOURCE03
assert git('status', '--porcelain', cwd=PRIVATE).stdout == b''
s03 = source(SOURCE03, 'Sources/LightingCore/ReferenceStudy.swift')
s04 = source(SOURCE04, 'Sources/LightingCore/ReferenceStudy.swift')
k03 = source(SOURCE03, 'App/StudyKernel.h')
k04 = source(SOURCE04, 'App/StudyKernel.h')
k36 = source(SOURCE36, 'App/StudyKernel.h')
eligibility = source(SOURCE04, 'Sources/LightingCore/StudyFloat32Eligibility.swift')
engine = source(SOURCE04, 'App/MetalStudyRenderer.swift')
engine_git_available = engine is not None
supplied_engine = Path('/tmp/keyfill03-7f4b/latest04/MetalStudyRenderer.swift')
supplied_bytes = supplied_engine.read_bytes()
supplied_blob = hashlib.sha1(f'blob {len(supplied_bytes)}\0'.encode() + supplied_bytes).hexdigest()
assert supplied_blob == '8c1acd852d85cd99671feaba883db1808bbb5e68'
engine = supplied_bytes.decode()
fingerprints.append({'revision': SOURCE04, 'path': str(supplied_engine),
                     'blob': supplied_blob, 'available': True, 'sha256': sha(supplied_bytes),
                     'provenance': 'Root supplied exact engine after local no-fetch git failure; independently blob-hashed here.'})
request04 = source(SOURCE04, 'docs/parallel/04/OWNER_REQUESTS.md')
source(SOURCE02, 'docs/parallel/02/CONSUMER-REQUESTS.md')
source(SOURCE03, 'App/ReferenceStudyPreview.swift')
source(SOURCE03, 'Tests/LightingCoreTests/StudyTinyOutputTests.swift')
copy = ROOT / 'docs/parallel/03/evidence/lane04-preview-proposal/OWNER_REQUESTS-69eb9c.md'
copy_matches = request04 is not None and copy.read_bytes() == request04.encode()

def block(text, start, end):
    return text[text.index(start):text.index(end)]

checks = {
    'packed_public_input_definition_identical_03_04': block(s03, 'public struct StudyComputeInput', '\nprivate struct StudySetup') == block(s04, 'public struct StudyComputeInput', '\nprivate struct StudySetup'),
    'compute_decoder_definition_identical_03_04': block(s03, 'public struct StudyImage', '/// Optional GPU backend') == block(s04, 'public struct StudyImage', '/// Optional GPU backend'),
    'source36_kernel_equals_03': k36 == k03,
    'source36_kernel_differs_04': k36 != k04,
    '04_owner_copy_equals_exact_blob': copy_matches,
    '04_has_actual_width_helper': 'supports(_ scene: LightingScene, width: Int)' in eligibility,
    '04_has_no_intensity_normality_check': all(term not in eligibility for term in ('leastNormalMagnitude', 'leastNonzeroMagnitude', 'Float(light.candela)', 'outputScale')),
    '03_restores_private_scale_before_float_packing': 'pack(s.position - center, s.candela * s.outputScale)' in s03,
    '04_cpu_lacks_03_private_scale': 'outputScale' not in s04,
    '04_distance_guard_before_zero_lux': k04.index('if (r2 < 0.0025f)') < k04.index('if (!incident.valid)') < k04.index('if (incident.lux == 0.0f)'),
    '04_area_guards_before_sample_loop': k04.index('if (dot(separation,separation) < center.w*center.w)') < k04.index('for (uint i=0; i<sampleCount;)'),
    '04_engine_forwards_actual_width': 'StudyFloat32Eligibility.supports(scene, width: width)' in engine and 'let supportsMetal = MetalStudyRenderer.supports(scene, width: width)' in engine,
    '04_engine_decodes_fresh_compute_bytes': 'let bytes = Data(bytes: output.contents(), count: input.width * input.height * 4)' in engine and 'StudyImage.fromComputeRGBA(width: input.width, height: input.height, data: bytes)' in engine,
}
assert all(checks.values()), checks

fixtures = []
for path in sorted((PRIVATE / 'docs/parallel/03/evidence/final-parity/kernel').glob('*.bin')):
    data = path.read_bytes()
    width, height, pn, sn, an, invalid = struct.unpack_from('<6I', data)
    rows = [struct.unpack_from('<4f', data, 24 + i * 16) for i in range(pn + sn + an)]
    sample_count, area_count, _, grid = rows[5]
    samples = rows[pn:pn + sn]
    tags = [samples[i + 2][3] for i in range(0, sn, 3)]
    assert pn == 6 and sn == 3 * sample_count and an == 3 * area_count
    assert 0 <= sample_count <= 768 and sample_count.is_integer()
    assert 0 <= area_count <= 12 and area_count.is_integer() and grid == 8
    index, groups = 0, 0
    while index < sample_count:
        tag = tags[index]
        assert math.isfinite(tag) and tag.is_integer() and 0 <= tag <= area_count
        if tag == 0:
            index += 1
        else:
            assert index + 64 <= sample_count and tags[index:index + 64] == [tag] * 64
            index += 64
            groups += 1
    assert groups == area_count
    fixtures.append({'path': str(path.relative_to(PRIVATE)), 'sha256': sha(data),
                     'sample_count': sample_count, 'area_count': area_count,
                     'grid': grid, 'contiguous_area_groups': groups})
assert len(fixtures) == 6

report = {'canonical_id': '/root/wave09/w87_consumer', 'worker': 'W87 consumer',
          'private_worktree': str(PRIVATE), 'input_sha': SOURCE03,
          'input_tree': git('rev-parse', f'{SOURCE03}^{{tree}}').stdout.decode().strip(),
          'command': f'python3 {Path(__file__)}', 'script_sha256': sha(Path(__file__).read_bytes()),
          'commands': commands, 'fingerprints': fingerprints, 'source_checks': checks,
          'retained_packed_metadata': fixtures,
          'exact04_engine_git_available': engine_git_available,
          'exact04_engine_supplied_and_verified': True,
          'findings': [
              'Current03 ABI and decoder are compatible in source with pinned04; six retained fixtures satisfy added04 count/grid/tag limits and contiguous64 area groups. These are byte/source checks, not executing04.',
              'Preserve03 CPU tiny-emitter scaling and preallocation cancellation during integration;04 CPU file is older. The public input struct and decoder nevertheless match exactly.',
              'Positive-tiny Float normality routing requested by02 remains open; packing intentionally retains geometry with Float-zero output. No new RGB or mask failure was demonstrated.',
              'Current04 distance/validity and area guards precede zero-light short circuits; no guard-skipping mask defect established.',
              'W057 is the independently confirmed03 adoption/status defect; W84 owns implementation and hosted regression. No competing change here.',
              'Source36 native evidence has an identical03 kernel but a different04 kernel; cannot transfer native validation to changed04.'
          ],
          'limits': [
              'Exact04 engine git show failed without lazy fetch; failure preserved above. Root subsequently supplied exact blob8c1acd852d85cd99671feaba883db1808bbb5e68, independently hash-verified. Paired-width forwarding reviewed in source only; no current04 execution or integration verified.',
              'Width24 silhouette original failure retained: fraction>4=0.00520833, limit0.005; exact mask mismatch0. No rerender.',
              'No Swift build/test, kernel/render/benchmark, production edit, commit, push, or external-owner acknowledgement.',
              'Checks are source/retained-byte evidence only; source-string assertions are not runtime passes.',
              'Qualitative checkpoint sent; token counters unavailable.'
          ]}
out = Path(__file__).with_name('W87-consumer-receipt.json')
out.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'checks': checks, 'retained_fixtures': len(fixtures), 'engine_available': engine is not None, 'receipt': str(out)}))
