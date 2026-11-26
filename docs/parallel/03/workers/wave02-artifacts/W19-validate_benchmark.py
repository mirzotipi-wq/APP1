#!/usr/bin/env python3
"""Recompute archived benchmark arithmetic; never invoke Swift or rerender."""
import collections
import hashlib
import json
import math
from pathlib import Path
import re
import sys

repo = Path(sys.argv[1])
artifact = repo / 'docs/parallel/03/evidence/baseline-benchmark.json'
raw = artifact.read_bytes()
data = json.loads(raw)
assert data['sourceRevision'] == 'f150f98e35dd735927075aac4d2f8b02295c6a67'
assert data['measuredSamplesPerWorkload'] == 7
assert data['optimizedBuild'] is True  # Archived metadata, not a fresh build check.
assert math.isfinite(data['totalWorkloadMilliseconds']) and data['totalWorkloadMilliseconds'] > 0
assert len(data['frames']) == 8
assert len(data['cancellation']) == 12
assert len(data['visibility']) == 4

expected_frames = {
    f'{subject}-{kind}-{width}'
    for subject in ('sphere', 'bust')
    for kind in ('point3', 'area3')
    for width in (72, 144)
}
assert {row['name'] for row in data['frames']} == expected_frames
expected_visibility = {
    (f'bust-{kind}-receivers', enabled)
    for kind in ('point3', 'area3') for enabled in (False, True)
}
assert {(row['name'], row['visibilityEnabled']) for row in data['visibility']} == expected_visibility

timing_checks = []
for group in ('frames', 'visibility'):
    for row in data[group]:
        values = row['timing']['samplesMilliseconds']
        assert len(values) == 7
        assert all(math.isfinite(value) and value > 0 for value in values)
        ordered = sorted(values)
        # For n=7, nearest-rank p50 is the fourth value and p95 the seventh.
        p50, p95 = ordered[3], ordered[6]
        assert row['timing']['p50Milliseconds'] == p50
        assert row['timing']['p95Milliseconds'] == p95
        expected_samples = 3 if 'point3' in row['name'] else 3 * 8 * 8
        assert row['lightSamplesPerSurface'] == expected_samples
        timing_checks.append({
            'group': group, 'name': row['name'],
            'visibilityEnabled': row.get('visibilityEnabled'),
            'samples': len(values), 'recomputedP50Milliseconds': p50,
            'recomputedP95Milliseconds': p95, 'matches': True,
        })
        if group == 'frames':
            assert row['width'] in (72, 144)
            assert row['height'] == row['width'] * 2 // 3
            assert row['unsupportedPixels'] == 0
            assert math.isfinite(row['warmupMilliseconds']) and row['warmupMilliseconds'] > 0
            assert re.fullmatch('[0-9a-f]{16}', row['rgbaFNV1a64'])
        else:
            assert row['receivers'] == 34
            assert row['evaluationsPerSample'] == 1000
            assert math.isfinite(row['signalComponentSum']) and row['signalComponentSum'] > 0

groups = collections.Counter((row['name'], row['requestedAfterMilliseconds']) for row in data['cancellation'])
assert groups == {
    ('bust-area3-144', 5): 3, ('bust-area3-144', 25): 3,
    ('bust-area12-144', 5): 3, ('bust-area12-144', 25): 3,
}
deadlines = []
observed_to_return = []
for row in data['cancellation']:
    assert row['cancelled'] is True
    assert isinstance(row['checks'], int) and row['checks'] > 0
    before = row['precedingCheckAtMilliseconds']
    requested = row['requestedAfterMilliseconds']
    observed = row['observedAtMilliseconds']
    finished = row['finishedAfterMilliseconds']
    assert all(math.isfinite(value) for value in (before, requested, observed, finished))
    assert 0 <= before < requested <= observed <= finished
    assert math.isclose(row['deadlineToReturnMilliseconds'], finished - requested,
                        rel_tol=0, abs_tol=1e-12)
    deadlines.append(finished - requested)
    observed_to_return.append(finished - observed)

result = {
    'runtime_id': '/root/wave02/platform_performance',
    'input_sha': '9c172d3e2d0c3f18636d84e8f31150236c63cbaa',
    'benchmark_recorded_source_sha': data['sourceRevision'],
    'benchmark_sha256': hashlib.sha256(raw).hexdigest(),
    'artifact': str(artifact),
    'frame_rows': len(data['frames']), 'cancellation_rows': len(data['cancellation']),
    'visibility_rows': len(data['visibility']), 'timed_samples_checked': 84,
    'timing_checks': timing_checks,
    'all_raw_percentiles_match': True,
    'frame_warmup_fields_finite_positive': 8,
    'visibility_warmup': 'one unmeasured operation call in source; duration/count not separately recorded in JSON',
    'all_cancellation_flags_and_timestamp_order_valid': True,
    'deadline_to_return_ms_range': [min(deadlines), max(deadlines)],
    'observed_to_return_ms_range': [min(observed_to_return), max(observed_to_return)],
    'source_derived_bounds': {
        'evidence': 'static inspection of Scene validation and ReferenceStudy sample/column/row loops; no Swift invocation',
        'maximum_scene_lights': 12, 'point_or_directional_samples_per_active_light': 1,
        'rectangle_samples_interactive': 64, 'rectangle_samples_reference': 1024,
        'maximum_interactive_samples': 768, 'maximum_reference_samples': 12288,
        'benchmark_point3': 3, 'benchmark_area3': 192, 'cancellation_area12': 768,
        'clipped_rectangles': 'at most grid columns times grid rows, so no larger callback budget than full rectangles',
    },
    'limitations': [
        'Archived FNV strings have valid syntax only; frame bytes and repeat determinism were not replayed.',
        'Archived optimizedBuild flag is consistent with the source guard; no new optimized compilation was performed.',
        'No new timing, Swift test/build/render/benchmark, native/Metal, device, RSS, thermal or sustained-FPS measurement.',
    ],
}
output = Path(__file__).with_name('benchmark-checks.json')
output.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({
    'rows': [8, 12, 4], 'timed_samples_checked': 84,
    'percentile_pairs_matched': len(timing_checks),
    'cancellation_flags_and_order_matched': 12,
    'deadline_to_return_ms_range': result['deadline_to_return_ms_range'],
    'artifact': str(output),
}, indent=2))
