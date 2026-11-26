#!/usr/bin/env python3
"""Independent scalar reference; no production geometry, normals or result reuse."""
import csv, math, pathlib, sys
raw = pathlib.Path(sys.argv[1]); output = pathlib.Path(sys.argv[2])
rows = list(csv.DictReader(raw.open(), delimiter="\t"))
assert len(rows) == 12
results = []
for row in rows:
    f = {k: float(v) for k, v in row.items() if k not in ("id", "kind")}
    dx, dy, dz = f["sx"]-f["rx"], f["sy"]-f["ry"], f["sz"]-f["rz"]
    nx, ny, nz = f["cx"]-f["rx"], f["cy"]-f["ry"], f["cz"]-f["rz"]
    ax, ay, az = f["ax"]-f["sx"], f["ay"]-f["sy"], f["az"]-f["sz"]
    r2 = dx*dx + dy*dy + dz*dz
    n2 = nx*nx + ny*ny + nz*nz
    a2 = ax*ax + ay*ay + az*az
    cr = max(0.0, min(1.0, (dx*nx + dy*ny + dz*nz) / math.sqrt(r2*n2)))
    ce = max(0.0, min(1.0, -(dx*ax + dy*ay + dz*az) / math.sqrt(r2*a2)))
    point = f["cd"] * cr / r2
    studio = point * ce if row["kind"] == "directional" else point
    assert point > 0 and studio > 0
    ep = abs(f["point_lux"]-point); es = abs(f["studio_lux"]-studio)
    rp, rs = 100*ep/point, 100*es/studio
    assert all(math.isfinite(v) for v in (point, studio, rp, rs))
    assert rp <= 1 and rs <= 1, row["id"]
    results.append(dict(id=row["id"], kind=row["kind"], r2_m2=r2, receiver_cosine=cr,
                        emitter_cosine=ce, point_ref_lux=point, point_actual_lux=f["point_lux"],
                        point_abs_error_lux=ep, point_rel_error_pct=rp,
                        studio_ref_lux=studio, studio_actual_lux=f["studio_lux"],
                        studio_abs_error_lux=es, studio_rel_error_pct=rs))
with output.open("w", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=results[0].keys(), delimiter="\t")
    writer.writeheader()
    for row in results:
        writer.writerow({k: format(v, ".17g") if isinstance(v, float) else v for k, v in row.items()})
print("id point_denominator_lux studio_denominator_lux worst_relative_error_pct")
for row in results:
    print(row["id"], format(row["point_ref_lux"], ".12g"), format(row["studio_ref_lux"], ".12g"),
          format(max(row["point_rel_error_pct"],row["studio_rel_error_pct"]), ".6g"))
print("PASS: 12 fixtures; 24 comparisons; <=1% each")
print("maximum_relative_error_pct", max(max(r["point_rel_error_pct"], r["studio_rel_error_pct"]) for r in results))
print("distance_range_m", min(math.sqrt(r["r2_m2"]) for r in results), max(math.sqrt(r["r2_m2"]) for r in results))
