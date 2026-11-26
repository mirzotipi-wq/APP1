"""Independent 60-digit scalar reference; no production imports or normal helpers."""
from decimal import Decimal, getcontext
import json
from pathlib import Path

getcontext().prec = 60
D = Decimal
output = Path(__file__).resolve().parent
# All coordinates are exact quarters; vectors are recorded in probe.swift.
r2 = D(219) / 16
emitter_dot = D(39) / 4
receiver_dot = D(9)
emitter_cos = emitter_dot / (D(11) * r2).sqrt()
receiver_cos = receiver_dot / (D(14) * r2).sqrt()
expected = D(1739) * emitter_cos * receiver_cos / r2
actual_json = json.loads((output / 'probe.log').read_text())
actual = D.from_float(actual_json['actual_lux'])
relative = abs(actual - expected) / expected
result = {
    'precision_decimal_digits': 60,
    'r_squared_m2': str(r2),
    'emitter_raw_vector': [-1, 3, -1],
    'receiver_raw_vector': [3, 1, 2],
    'receiver_to_source_vector': ['7/4', '-7/4', '11/4'],
    'emitter_dot_to_receiver': str(emitter_dot),
    'receiver_dot_to_source': str(receiver_dot),
    'emitter_cosine': str(emitter_cos),
    'receiver_cosine': str(receiver_cos),
    'inverse_square_m_minus2': str(1 / r2),
    'expected_lux': str(expected),
    'swift_actual_lux_printed': actual_json['actual_lux'],
    'swift_actual_lux_exact_decimal': str(actual),
    'relative_error': str(relative),
    'relative_error_percent': str(relative * 100),
    'point_gate_fraction': '0.01',
    'passes_point_gate': relative <= D('0.01'),
}
(output / 'scalar-reference.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
assert relative <= D('0.01')
