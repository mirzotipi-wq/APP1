"""One endpoint transcription of Colorimetry.swift; no Swift/Metal execution."""
import json
import math
from pathlib import Path
import struct


def matching_functions(wavelength):
    def lobe(center, left, right):
        t = (wavelength - center) * (left if wavelength < center else right)
        return math.exp(-0.5 * t * t)
    x = (1.056 * lobe(599.8, 0.0264, 0.0323)
         + 0.362 * lobe(442.0, 0.0624, 0.0374)
         - 0.065 * lobe(501.1, 0.0490, 0.0382))
    y = 0.821 * lobe(568.8, 0.0213, 0.0247) + 0.286 * lobe(530.9, 0.0613, 0.0322)
    z = 1.217 * lobe(437.0, 0.0845, 0.0278) + 0.681 * lobe(459.0, 0.0385, 0.0725)
    return tuple(max(0.0, value) for value in (x, y, z))


def blackbody(kelvin):
    total = [0.0, 0.0, 0.0]
    for nm in range(380, 781, 5):
        wavelength = float(nm)
        spectrum = math.pow(560 / wavelength, 5) / math.expm1(1.438776877e7 / (wavelength * kelvin))
        weight = 0.5 if nm in (380, 780) else 1.0
        for i, component in enumerate(matching_functions(wavelength)):
            total[i] += component * (spectrum * weight)
    assert math.isfinite(total[1]) and total[1] > 0
    return tuple(value / total[1] for value in total)


def bradford(v):
    x, y, z = v
    return (0.8951*x + 0.2664*y - 0.1614*z,
            -0.7502*x + 1.7135*y + 0.0367*z,
            0.0389*x - 0.0685*y + 1.0296*z)


dst = bradford((0.3127 / 0.3290, 1.0, (1 - 0.3127 - 0.3290) / 0.3290))
results = []
for kelvin in (2000.0, 10000.0):
    white = blackbody(kelvin)
    src = bradford(white)
    assert all(math.isfinite(value) and value > 0 for value in src)
    ratios = tuple(d / s for d, s in zip(dst, src))
    for stops in (-6.0, 6.0):
        parameters = ratios + (math.pow(2, stops),)
        narrowed = tuple(struct.unpack('<f', struct.pack('<f', value))[0] for value in parameters)
        assert all(math.isfinite(value) and value > 0 for value in parameters + narrowed)
        results.append(dict(kelvin=kelvin, stops=stops, white_xyz=white,
                            bradford_src=src, parameters_double=parameters,
                            parameters_float32=narrowed))

payload = dict(source_revision='f150f98e35dd735927075aac4d2f8b02295c6a67',
               scope='Four endpoint combinations only; Python double and IEEE binary32 transcription, not Swift/Metal execution.',
               endpoint_parameters_finite=True, endpoints=results)
output = json.dumps(payload, indent=2) + '\n'
Path(__file__).with_suffix('.json').write_text(output)
print(output, end='')
