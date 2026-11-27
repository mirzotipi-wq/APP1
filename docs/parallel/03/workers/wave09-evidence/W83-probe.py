"""W83 read-only source/artifact probe. This does not execute Swift or Metal."""
import datetime
import hashlib
import json
import math
import pathlib
import struct
import subprocess
import sys

source = pathlib.Path('/tmp/keyfill03-7f4b/workers/W83-api')
out = pathlib.Path(__file__).with_name('W83-api.json')
receipts = []

def git(*args):
    command = ['git', '-C', str(source), *args]
    run = subprocess.run(command, capture_output=True, text=True, check=True)
    receipts.append({'argv': command, 'exit_code': run.returncode, 'stdout': run.stdout})
    return run.stdout.strip()

def sha(data):
    return hashlib.sha256(data).hexdigest()

head = git('rev-parse', 'HEAD')
cpu = 'db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5'
preview = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
files = [
    'Sources/LightingCore/ReferenceStudy.swift',
    'Sources/LightingCore/PortraitStudy.swift',
    'Sources/LightingCore/StudyValidationFixtures.swift',
    'Sources/LightingCore/StudyFloat32Eligibility.swift',
    'Sources/LightingCore/StudyFrameCache.swift',
    'Tests/LightingCoreTests/StudyComputeInputTests.swift',
    'Tests/LightingCoreTests/StudyParityMetricsTests.swift',
    'App/StudyKernel.h', 'App/ReferenceStudy.metal',
    'App/MetalStudyRenderer.swift', 'App/ReferenceStudyPreview.swift',
    'NativeTests/StudyRendererTests.swift', 'scripts/prepare-kernel-fixtures.swift',
]
fingerprints = []
for path in files:
    data = (source / path).read_bytes()
    blob = git('rev-parse', f'{head}:{path}')
    calculated = hashlib.sha1(f'blob {len(data)}\0'.encode() + data).hexdigest()
    assert blob == calculated
    fingerprints.append({'path': path, 'sha256': sha(data), 'git_blob': blob, 'bytes': len(data),
                         'matches_cpu_source': blob == git('rev-parse', f'{cpu}:{path}'),
                         'matches_preview_source': blob == git('rev-parse', f'{preview}:{path}')})

fixture_results = []
near = None
for path in sorted((source / 'docs/parallel/03/evidence/final-parity/kernel').glob('*.bin')):
    data = path.read_bytes()
    width, height, params_n, samples_n, areas_n, invalid = struct.unpack_from('<6I', data)
    rows_n = params_n + samples_n + areas_n
    offset = 24 + 16 * rows_n
    rgba = data[offset:]
    rows = [struct.unpack_from('<4f', data, 24 + i * 16) for i in range(rows_n)]
    params = rows[:params_n]
    samples = rows[params_n:params_n + samples_n]
    flags = bytes(1 if alpha == 0 else 0 for alpha in rgba[3::4])
    indices = [i for i, flag in enumerate(flags) if flag]
    group_tags = [samples[i + 2][3] for i in range(0, samples_n, 3)]
    checks = {
        'exact_length': len(data) == offset + width * height * 4,
        'dimensions_in_decoder_domain': 24 <= width <= 192 and width % 3 == 0 and height == width * 2 // 3,
        'six_parameter_rows': params_n == 6,
        'three_rows_per_sample_and_area': samples_n % 3 == 0 and areas_n % 3 == 0,
        'all_rows_finite': all(math.isfinite(value) for row in rows for value in row),
        'sample_count_matches': params[5][0] * 3 == samples_n,
        'area_count_matches': params[5][1] * 3 == areas_n,
        'grid_is_eight': params[5][3] == 8,
        'area_tags_are_integers_in_range': all(v == int(v) and 0 <= v <= areas_n // 3 for v in group_tags),
        'alpha_binary': all(a in (0, 255) for a in rgba[3::4]),
        'flagged_rgb_magenta': all(rgba[i*4:i*4+3] == bytes([255, 0, 255]) for i in indices),
        'header_count_matches_alpha_flags': len(indices) == invalid,
    }
    assert all(checks.values()), (path.name, checks)
    row = {'file': str(path.relative_to(source)), 'sha256': sha(data), 'width': width, 'height': height,
           'parameter_rows': params_n, 'sample_rows': samples_n, 'area_rows': areas_n,
           'invalid_count': invalid, 'mask_sha256': sha(flags), 'checks': checks}
    fixture_results.append(row)
    if path.stem == 'near-field':
        display = bytearray(rgba)
        display[3::4] = bytes([255]) * (width * height)
        near = {'original_flag_count': invalid, 'display_alpha_zero_count': display[3::4].count(0),
                'unchanged_rgb': all(display[i:i+3] == rgba[i:i+3] for i in range(0, len(rgba), 4)),
                'invalid_pixel_indices': indices,
                'conclusion': 'Restoring opaque alpha removes transport flags; reusing display RGBA as compute transport would lose mask metadata. Python byte inspection only; no Swift decoder execution.'}

final_root = source / 'docs/parallel/03/evidence/final'
matrix = []
for row in json.loads((final_root / 'manifest.json').read_text()):
    path = final_root / (row['name'] + '.mask')
    mask = path.read_bytes()
    count = sum(mask)
    assert len(mask) == row['width'] * row['height'] and set(mask) <= {0, 1}
    assert count == row['unsupportedPixels'] == 0
    matrix.append({'name': row['name'], 'bytes': len(mask), 'invalid_count': count, 'sha256': sha(mask)})

result = {
    'runtime_id': '/root/wave09/w83_api', 'canonical_task_path': '/root/wave09/w83_api',
    'role': 'W83 API', 'input_sha': head, 'input_tree': git('rev-parse', 'HEAD^{tree}'),
    'private_worktree': str(source), 'private_status': git('status', '--short'),
    'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'source_fingerprints': fingerprints,
    'source_trees': {path: {'input': git('rev-parse', f'{head}:{path}'), 'cpu': git('rev-parse', f'{cpu}:{path}')}
                     for path in ['Sources', 'Tests', 'scripts']},
    'binary_fixtures': fixture_results,
    'transport_display_boundary': near,
    'final_matrix_masks': matrix,
    'original_matrix_mask_files': len(list((source / 'docs/parallel/03/evidence/original').glob('*.mask'))),
    'findings': [
        'No production caller defect established. Public decoder checks dimensions before products, exact byte length and alpha/RGB sentinel; opaque magenta remains valid.',
        'Parity validates positive dimensions, overflow, byte lengths, binary mask length/count, opacity and exact mask equality. Sparse maximum RGB error alone is intentionally diagnostic, not a failing gate.',
        'Transport/display metadata loss is a caller contract hazard. Production Metal caller supplies fresh raw GPU bytes; fixture writer explicitly restores flags from the mask.',
        'Internal StudyImage initializer can represent mask=1 with non-magenta RGB. Parity does not validate flag-to-RGB implication; identical malformed internal images can pass by source logic. No public construction or current producer violation identified; defense-in-depth only.',
        'Packed kernel assumes trusted six/three/three float4 layout; it does not receive buffer lengths. Current immutable StudyComputeInput and private Metal compute path supply validated packing. Do not expose raw packed buffers without validating row counts and indexes.',
    ],
    'execution': {'python_data_probe': True, 'swift_tests': False, 'builds': False, 'renders': False,
                  'benchmarks': False, 'native_metal': False, 'production_files_modified': False},
    'retained_evidence_only': {'core': '391/0 Debug and Release at db7 (ci-core-db7.json)',
                               'native': '164/0 at source36 (ci-native-36.json)'},
    'limits': [
        'Source review and Python data checks are not executed Swift/native proof or fresh parity renders.',
        'Six binary files contain retained CPU reference transport bytes, not paired newly executed GPU outputs.',
        'Final twelve zero masks do not prove equality to missing original twelve masks; camera diagnostics are separate.',
        'Malformed internal flag/RGB finding follows source logic, not a compiled Swift reproduction.',
        'Canonical task path is the actual runtime identifier exposed by collaboration.list_agents; no separate UUID was exposed.',
        'Working token counters unavailable; checkpoint was qualitative. Broad initial output truncated, then relevant code reread in bounded ranges.',
        'One guessed LightingScene.swift lookup failed; no scene-range conclusion is based on it.',
    ],
    'commands': {'probe': ['python3', str(pathlib.Path(__file__).resolve())], 'git_receipts': receipts},
}
out.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'output': str(out), 'six_fixture_checks': len(fixture_results),
                  'near_field_invalid_count': near['original_flag_count'],
                  'final_mask_checks': len(matrix), 'original_matrix_masks': result['original_matrix_mask_files'],
                  'private_status': result['private_status'], 'file_sha256': sha(out.read_bytes())}, indent=2))
