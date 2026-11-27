#!/usr/bin/env python3
"""Eight-temperature independent CIE/Planck comparison; Python standard library.

The official table is fetched into memory, hash-checked, and never redistributed.
reference_xy uses SI Planck radiance and tabulated CMFs, independently of Swift.
The analytic diagnostic intentionally repeats the documented production CMFs;
it is not used as the independent reference. Derived tables: CC BY-SA 4.0.
"""

import argparse
import csv
import hashlib
import io
import json
import math
from pathlib import Path
import platform
import sys
import urllib.request

TEMPERATURES = [1000, 2000, 2856, 3200, 5600, 6500, 10000, 20000]
SOURCE_COMMIT = "1b286885cb803ba17e159713651515ab119e17f1"
DATA_URL = "https://files.cie.co.at/Publications-datasets/CIE_xyz_1931_2deg.csv"
METADATA_URL = DATA_URL + "_metadata.json"
MD5 = "17cca777db64b17170f06f67ce9d3ab7"
SHA256 = "fa663e3535a7e0763a745993a1f0a192eb0275ac46ad2d1befd7626841e713c1"
LICENSE = "https://creativecommons.org/licenses/by-sa/4.0/"
ATTRIBUTION = (
    "CIE 2019, Colour-matching functions of CIE 1931 standard colorimetric "
    "observer, International Commission on Illumination (CIE), Vienna, AT, "
    "DOI: 10.25039/CIE.DS.xvudnb9b."
)
H = 6.62607015e-34
C = 299792458.0
K = 1.380649e-23
C2_SI = H * C / K * 1e9  # nm K; exact defining SI constants, binary64 evaluation
C2_PRODUCTION = 1.438776877e7


def reference_xy(cmf_rows, kelvin, c2=C2_SI):
    """Trapezoidal integration of physical Planck radiance, no production code."""
    channels = [[], [], []]
    for index, (nm, *cmf) in enumerate(cmf_rows):
        wavelength_m = nm * 1e-9
        radiance = (2 * H * C * C) / (
            wavelength_m**5 * math.expm1(c2 / (nm * kelvin))
        )
        # Nonuniform-grid trapezoid nodal weights (all supplied grids are uniform).
        left = nm - cmf_rows[index - 1][0] if index else 0.0
        right = cmf_rows[index + 1][0] - nm if index + 1 < len(cmf_rows) else 0.0
        weight = (left + right) / 2
        for channel, sensitivity in zip(channels, cmf):
            channel.append(radiance * sensitivity * weight)
    xyz = [math.fsum(channel) for channel in channels]
    total = math.fsum(xyz)
    return xyz[0] / total, xyz[1] / total


def analytic_cmf(nm):
    """Wyman/Sloan/Shirley Eq. 4 coefficients from production, diagnostic only."""
    def lobe(center, left, right):
        t = (nm - center) * (left if nm < center else right)
        return math.exp(-0.5 * t * t)
    x = (1.056 * lobe(599.8, 0.0264, 0.0323)
         + 0.362 * lobe(442.0, 0.0624, 0.0374)
         - 0.065 * lobe(501.1, 0.0490, 0.0382))
    y = 0.821 * lobe(568.8, 0.0213, 0.0247) + 0.286 * lobe(530.9, 0.0613, 0.0322)
    z = 1.217 * lobe(437.0, 0.0845, 0.0278) + 0.681 * lobe(459.0, 0.0385, 0.0725)
    return max(0, x), max(0, y), max(0, z)


def norm(delta):
    return math.hypot(*delta)


def subtract(a, b):
    return a[0] - b[0], a[1] - b[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swift-output", type=Path, default=Path(__file__).with_name("probe.log"))
    parser.add_argument("--cie-data", type=Path, help="Optional exact official CSV, checked against both hashes")
    parser.add_argument("--output-dir", type=Path, default=Path(__file__).parent)
    args = parser.parse_args()
    if args.cie_data:
        raw = args.cie_data.read_bytes()
    else:
        with urllib.request.urlopen(DATA_URL, timeout=30) as response:
            raw = response.read(100000)
    observed_md5 = hashlib.md5(raw).hexdigest()
    observed_sha256 = hashlib.sha256(raw).hexdigest()
    assert observed_md5 == MD5, ("MD5 mismatch", observed_md5)
    assert observed_sha256 == SHA256, ("SHA-256 mismatch", observed_sha256)
    cie = [tuple(map(float, row)) for row in csv.reader(io.StringIO(raw.decode("ascii")))]
    assert len(cie) == 471 and [row[0] for row in cie] == list(range(360, 831))
    assert all(len(row) == 4 and all(math.isfinite(v) and v >= 0 for v in row) for row in cie)
    swift_rows = json.loads(args.swift_output.read_text())
    assert [row["kelvin"] for row in swift_rows] == TEMPERATURES
    assert all(row["Y"] == 1 and all(math.isfinite(row[c]) for c in ("X", "Y", "Z", "x", "y"))
               for row in swift_rows)
    cropped = [row for row in cie if 380 <= row[0] <= 780]
    analytic_1nm = [(float(nm), *analytic_cmf(nm)) for nm in range(380, 781)]
    analytic_5nm = analytic_1nm[::5]
    output_rows = []
    stages = ["radiation_constant", "wavelength_crop", "analytic_observer", "five_nm_step", "swift_arithmetic"]
    for actual in swift_rows:
        kelvin = actual["kelvin"]
        reference = reference_xy(cie, kelvin)
        same_constant = reference_xy(cie, kelvin, C2_PRODUCTION)
        crop = reference_xy(cropped, kelvin, C2_PRODUCTION)
        analytic_fine = reference_xy(analytic_1nm, kelvin, C2_PRODUCTION)
        analytic_coarse = reference_xy(analytic_5nm, kelvin, C2_PRODUCTION)
        swift = actual["x"], actual["y"]
        delta = subtract(swift, reference)
        result = {"kelvin": kelvin, "cie_1nm_x": reference[0], "cie_1nm_y": reference[1],
                  "swift_x": swift[0], "swift_y": swift[1], "delta_x": delta[0], "delta_y": delta[1],
                  "delta_xy_euclidean": norm(delta)}
        values = [reference, same_constant, crop, analytic_fine, analytic_coarse, swift]
        for label, previous, following in zip(stages, values, values[1:]):
            component = subtract(following, previous)
            result[label + "_delta_x"] = component[0]
            result[label + "_delta_y"] = component[1]
            result[label + "_delta_xy"] = norm(component)
        for axis in ("x", "y"):
            assert abs(math.fsum(result[s + "_delta_" + axis] for s in stages) - result["delta_" + axis]) < 1e-15
        output_rows.append(result)
    summary = {
        "row_count": len(output_rows),
        "max_abs_delta_x": max(abs(row["delta_x"]) for row in output_rows),
        "max_abs_delta_y": max(abs(row["delta_y"]) for row in output_rows),
        "max_delta_xy": max(row["delta_xy_euclidean"] for row in output_rows),
        "worst_kelvin": max(output_rows, key=lambda row: row["delta_xy_euclidean"])["kelvin"],
        "component_max_delta_xy": {stage: max(row[stage + "_delta_xy"] for row in output_rows) for stage in stages},
    }
    document = {
        "schema": "w02r10-cie-planck-comparison-v1",
        "source_commit": SOURCE_COMMIT,
        "snapshot": "v1",
        "runtime": {"python": sys.version, "platform": platform.platform()},
        "source": {"url": DATA_URL, "metadata_url": METADATA_URL, "bytes": len(raw),
                   "md5": observed_md5, "sha256": observed_sha256, "attribution": ATTRIBUTION,
                   "doi": "https://doi.org/10.25039/CIE.DS.xvudnb9b", "license": LICENSE},
        "derived_table_license": "CC BY-SA 4.0",
        "changes": "Derived eight Planckian xy rows from tabulated CMFs; added actual Swift outputs and diagnostic differences.",
        "method": {
            "reference": "CIE 1931 2-degree CMFs, 360-830 nm inclusive, 1 nm trapezoids, physical Planck radiance, math.fsum, xy normalization",
            "constants": {"h_J_s": H, "c_m_per_s": C, "k_J_per_K": K, "c2_SI_nm_K": C2_SI, "c2_production_nm_K": C2_PRODUCTION},
            "diagnostic_chain": "SI CIE 1nm full -> production-c2 CIE 1nm full -> CIE 1nm 380-780 -> analytic 1nm 380-780 -> analytic 5nm 380-780 -> Swift",
            "delta_convention": "Each signed component is following minus previous; signed components sum to Swift minus official reference. Norms are not additive.",
            "limits": "Eight ideal blackbodies only; 5-to-1 nm difference is a resolution diagnostic, not a rigorous integration error bound. xy Euclidean distance is not perceptual Delta E. No device/calibration validation or color accuracy acceptance threshold. Point 1% / area 5% illuminance gates unchanged and inapplicable here.",
        },
        "summary": summary,
        "rows": output_rows,
    }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "table.json").write_text(json.dumps(document, indent=2) + "\n")
    with (args.output_dir / "table.csv").open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(output_rows[0]))
        writer.writeheader()
        writer.writerows(output_rows)
    print(json.dumps(summary, indent=2))
    print(f"Verified official CIE CSV: {len(raw)} bytes, {len(cie)} rows; MD5 {observed_md5}; SHA-256 {observed_sha256}")


if __name__ == "__main__":
    main()
