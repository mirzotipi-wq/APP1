#!/usr/bin/env python3
"""Read-only checks of the preserved original Study artifacts; no rendering."""
import hashlib
import json
import math
from pathlib import Path

WORKTREE = Path('/tmp/keyfill03-7f4b/workers/W17-consumer')
EVIDENCE = WORKTREE / 'docs/parallel/03/evidence'
ORIGINAL = EVIDENCE / 'original'
OUTPUT = Path('/tmp/keyfill03-7f4b/builds/W17-consumer/original-fixture-checks.json')
EXPECTED = {
    'soft', 'hard', 'warm', 'bust-soft', 'bust-hard', 'bust-side',
    'key-only-hard', 'fill-only-soft', 'bust-rim-only', 'bust-roll-90',
    'exposure-minus-two', 'white-balance-3200',
}


def reject_constant(value):
    raise ValueError(f'Nonstandard JSON constant: {value}')


def read_json(path):
    return json.loads(path.read_text(), parse_constant=reject_constant)


def assert_finite(value):
    if isinstance(value, float):
        assert math.isfinite(value)
    elif isinstance(value, dict):
        for nested in value.values():
            assert_finite(nested)
    elif isinstance(value, list):
        for nested in value:
            assert_finite(nested)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_ppm(path):
    magic, dimensions, maximum, payload = path.read_bytes().split(b'\n', 3)
    assert magic == b'P6' and maximum == b'255', path.name
    width, height = map(int, dimensions.split())
    assert width > 0 and height > 0
    assert len(payload) == width * height * 3, path.name
    return width, height, payload


manifest = read_json(ORIGINAL / 'manifest.json')
fixtures = manifest['fixtures']
assert manifest['expectedFixtureCount'] == len(fixtures) == len(EXPECTED) == 12
assert {fixture['name'] for fixture in fixtures} == EXPECTED
assert len({fixture['name'] for fixture in fixtures}) == len(fixtures)
assert manifest['softwareValidationPassed'] is True
assert manifest['syntheticOnly'] is True
assert {path.stem for path in ORIGINAL.glob('*.json')} == EXPECTED | {'manifest'}
assert {path.stem for path in ORIGINAL.glob('*.ppm')} == EXPECTED
assert {path.stem for path in ORIGINAL.glob('*.png')} == EXPECTED

before = {path.name: sha256(path) for path in ORIGINAL.iterdir() if path.is_file()}
baseline_hashes = read_json(EVIDENCE / 'baseline.json')['originalSHA256']
hash_checks = []
for relative, expected_hash in baseline_hashes.items():
    actual_hash = sha256(EVIDENCE / relative)
    assert actual_hash == expected_hash, relative
    hash_checks.append({'path': relative, 'sha256': actual_hash, 'matches': True})

images = {}
rows = []
for fixture in fixtures:
    name = fixture['name']
    assert fixture['sceneFile'] == name + '.json'
    assert fixture['ppmFile'] == name + '.ppm'
    scene = read_json(ORIGINAL / fixture['sceneFile'])
    assert isinstance(scene, dict) and scene['schemaVersion'] == 5
    assert_finite(scene)
    assert all(set(('x', 'y', 'z')) <= scene[key].keys() for key in ['subject', 'camera'])
    lights = scene['lights']
    assert len(lights) <= 12 and len({light['id'] for light in lights}) == len(lights)
    width, height, rgb = read_ppm(ORIGINAL / fixture['ppmFile'])
    assert (width, height) == (fixture['width'], fixture['height'])
    assert (width, height) == (fixture['expectedWidth'], fixture['expectedHeight'])
    assert height * 3 == width * 2
    assert fixture['rgbaByteCount'] == width * height * 4
    assert fixture['unsupportedMaskByteCount'] == width * height
    assert fixture['unsupportedPixels'] == 0
    assert fixture['passed'] is True and fixture['validationErrors'] == []
    magenta = sum(rgb[index:index + 3] == b'\xff\x00\xff' for index in range(0, len(rgb), 3))
    assert magenta == 0, name
    images[name] = rgb
    rows.append({
        'name': name, 'scene_schema': scene['schemaVersion'], 'lights': len(lights),
        'width': width, 'height': height, 'rgb_payload_bytes': len(rgb),
        'rgb_minimum': min(rgb), 'rgb_maximum': max(rgb), 'pure_magenta_pixels': magenta,
        'recorded_unsupported_pixels': fixture['unsupportedPixels'],
        'recorded_mask_byte_count': fixture['unsupportedMaskByteCount'],
        'ppm_sha256': sha256(ORIGINAL / fixture['ppmFile']),
    })

comparisons = []
for fixture in fixtures:
    if 'comparisonFixture' not in fixture:
        continue
    name, reference = fixture['name'], fixture['comparisonFixture']
    actual, previous = images[name], images[reference]
    assert len(actual) == len(previous)
    changed = sum(actual[index:index + 3] != previous[index:index + 3]
                  for index in range(0, len(actual), 3))
    assert changed == fixture['differentPixelsFromComparison'] and changed > 0
    comparisons.append({'name': name, 'reference': reference, 'changed_rgb_pixels': changed,
                        'matches_recorded_count': True})

assert len(comparisons) == 10
after = {path.name: sha256(path) for path in ORIGINAL.iterdir() if path.is_file()}
assert before == after
raw_mask_candidates = sorted(path.name for path in ORIGINAL.iterdir()
                             if 'mask' in path.name.lower() or path.suffix in ('.rgba', '.bin', '.mask'))
assert not raw_mask_candidates
result = {
    'worker': 'W17-consumer', 'runtime_id': '/root/wave02/consumer',
    'input_sha': '9c172d3e2d0c3f18636d84e8f31150236c63cbaa',
    'private_worktree': str(WORKTREE), 'status': 'passed_artifact_checks_only',
    'fixtures_checked': len(rows), 'pixels_checked': sum(row['width'] * row['height'] for row in rows),
    'json_ppm_manifest_hashes_checked': len(hash_checks), 'original_files_unchanged': before == after,
    'raw_mask_files_available': raw_mask_candidates,
    'limitations': [
        'PPM stores RGB only: no independent alpha-byte or raw validity-mask-location check is possible.',
        'Mask counts and sizes are retained manifest claims; zero pure-magenta RGB pixels was directly checked.',
        'Image coverage and nonzero pixel changes are not independent geometry, visibility or photometric proof.',
        'No Swift validation, rerender, native/Metal run or physical calibration was performed.',
    ],
    'fixtures': rows, 'comparisons': comparisons, 'hash_checks': hash_checks,
}
OUTPUT.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({key: result[key] for key in ['status', 'fixtures_checked', 'pixels_checked',
    'json_ppm_manifest_hashes_checked', 'original_files_unchanged', 'raw_mask_files_available', 'comparisons']}, indent=2))
