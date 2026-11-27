"""Independent scalar reference for one point/directional rigid-transform fixture."""
from decimal import Decimal, getcontext
from fractions import Fraction as F
import json
from pathlib import Path

getcontext().prec = 70
R = [[F(x, 15) for x in row] for row in [(-10, 2, 11), (10, -5, 10), (5, 14, 2)]]
t = [F(7), F(-11), F(13)]
positions = {
    "subject": [F(1, 2), F(-1, 4), F(3, 4)],
    "camera": [F(2), F(1), F(4)],
    "point": [F(-1), F(2), F(3)],
    "directional": [F(3), F(-1), F(5, 2)],
    "aim": [F(3, 2), F(2), F(-1)],
}

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def sub(a, b):
    return [x - y for x, y in zip(a, b)]

def dec(x):
    return Decimal(x.numerator) / Decimal(x.denominator)

def transform(p):
    return [dot(row, p) + offset for row, offset in zip(R, t)]

assert [[dot(a, b) for b in R] for a in R] == [[F(int(i == j)) for j in range(3)] for i in range(3)]
det = sum(R[0][j] * (R[1][(j+1) % 3] * R[2][(j+2) % 3] - R[1][(j+2) % 3] * R[2][(j+1) % 3]) for j in range(3))
assert det == 1

def scalars(p):
    n = sub(p["camera"], p["subject"])
    point = sub(p["point"], p["subject"])
    directional = sub(p["directional"], p["subject"])
    aim = sub(p["aim"], p["directional"])
    return {"normal_squared": dot(n,n), "point_distance_squared": dot(point,point),
            "point_receiver_dot": dot(n,point), "directional_distance_squared": dot(directional,directional),
            "directional_receiver_dot": dot(n,directional), "emitter_axis_squared": dot(aim,aim),
            "directional_emitter_dot": -dot(aim,directional)}

moved = {key: transform(value) for key, value in positions.items()}
s = scalars(positions)
assert scalars(moved) == s
v = {key: dec(value) for key, value in s.items()}
point_cos = v["point_receiver_dot"] / (v["normal_squared"].sqrt() * v["point_distance_squared"].sqrt())
receiver_cos = v["directional_receiver_dot"] / (v["normal_squared"].sqrt() * v["directional_distance_squared"].sqrt())
emitter_cos = v["directional_emitter_dot"] / (v["emitter_axis_squared"].sqrt() * v["directional_distance_squared"].sqrt())
point_lux = Decimal(1375) * point_cos / v["point_distance_squared"]
directional_lux = Decimal(863) * receiver_cos * emitter_cos / v["directional_distance_squared"]
result = {
    "snapshot": "v1", "source_sha": "1b286885cb803ba17e159713651515ab119e17f1",
    "rotation": [[str(x) for x in row] for row in R], "determinant": str(det),
    "translation_m": [str(x) for x in t],
    "positions_m": {key: [str(x) for x in value] for key, value in positions.items()},
    "transformed_positions_m": {key: [str(x) for x in value] for key, value in moved.items()},
    "exact_scalars_before_and_after": {key: str(value) for key, value in s.items()},
    "point_receiver_cosine": str(point_cos), "directional_receiver_cosine": str(receiver_cos),
    "directional_emitter_cosine": str(emitter_cos),
    "point_lux": str(point_lux), "directional_lux": str(directional_lux),
    "formula": "point=I*(n dot d)/(|n|*|d|^3); directional=point*cos(emitter)",
    "reference_precision_decimal_digits": 70,
}
Path(__file__).with_name("scalar_references.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"point_lux": str(point_lux), "directional_lux": str(directional_lux), "exact_transform_invariants": "PASS"}))
