from fractions import Fraction
from math import nextafter, inf

F = Fraction.from_float
cases = [
    ('valid_false_rejection', 1.0, 0.0, 2.0, 2.0, -100.0, 48.0),
    ('rounded_false_acceptance', 0.0, 0.0, 1.0, 2.0, -81.0, nextafter(64.25, inf)),
]
for name, cx, cz, camera_x, camera_z, px, pz in cases:
    dx, dz = camera_x - cx, camera_z - cz
    squared = dx * dx + dz * dz
    diagonal, cross = (dx * dx - dz * dz) / squared, 2 * (dx * dz) / squared
    x = F(cx) + F(diagonal) * (F(px) - F(cx)) + F(cross) * (F(pz) - F(cz))
    z = F(cz) + F(cross) * (F(px) - F(cx)) - F(diagonal) * (F(pz) - F(cz))
    old_x = px + ((diagonal - 1) * (px - cx) + cross * (pz - cz))
    old_z = pz + (cross * (px - cx) - (diagonal + 1) * (pz - cz))
    print(name)
    print('coefficients:', diagonal.hex(), cross.hex())
    print('exact x - 100:', x - F(100.0))
    print('exact z + 52:', z + F(52.0))
    print('rounded oracle:', float(x).hex(), float(z).hex())
    print('old formula:', old_x.hex(), old_z.hex())
    if name == 'valid_false_rejection':
        assert x == F(100.0) - Fraction(1, 2**53)
        assert abs(x) <= 100 and abs(z) <= 100
        assert float(x) == 100.0 and old_x > 100
    else:
        assert float(x) == nextafter(100.0, inf) and old_x == 100
axis_exact = F(100.0) + F(float.fromhex('0x1p-1074'))
assert float(axis_exact) == 100.0
print('axis control: exact 100 + 2^-1074 rounds to 100; acceptance is contractual')
