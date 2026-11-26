"""Arithmetic-only contract illustration; does not execute Swift or the mesh."""
import json
import math

witness = (0.08733597770659, 0.2924411459428683, 0.9522870382178139)
witness_norm = math.sqrt(sum(component * component for component in witness))
assert abs(witness_norm - 1.0) <= 1e-12

rows = []
for twice_area in (1e-7, 1e-4):
    for cosine in (1e-8, 1e-6):
        determinant = twice_area * cosine
        old_accepts = determinant > 1e-14
        scaled_accepts = determinant > twice_area * 1e-14
        assert scaled_accepts
        rows.append(dict(twice_area=twice_area, cosine=cosine,
                         determinant=determinant, old_accepts=old_accepts,
                         scaled_accepts=scaled_accepts))

t = 0.125
assert not (t >= 0.0 and t < t)
assert t >= t and t < math.nextafter(t, math.inf)
result = dict(scope=__doc__, witness_direction_norm=witness_norm,
              determinant_examples=rows,
              half_open_binary_exact_endpoint_assertions="passed")
print(json.dumps(result, indent=2, allow_nan=False))
