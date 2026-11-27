#!/usr/bin/env python3
"""One bounded static audit of unsupported receiver orientation text propagation.

This checks immutable source structure and records analytic fixture expectations.
It does not execute Swift, SwiftUI, VoiceOver, or device behavior.
"""
import hashlib
import json
from pathlib import Path
import subprocess

REV = "1b286885cb803ba17e159713651515ab119e17f1"
ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent
RANGES = {
    "Sources/LightingCore/SurfacePhotometry.swift": [(3, 18), (87, 99)],
    "Sources/LightingCore/StudioOptics.swift": [(97, 137)],
    "Sources/LightingCore/LightOutputAdjustment.swift": [(3, 20), (28, 55)],
    "App/StudioView.swift": [(973, 981), (989, 1006)],
    "App/StudioMeterReadout.swift": [(1, 30)],
    "App/LightTargetLuxView.swift": [(27, 72), (86, 90), (112, 126)],
    "Sources/LightingCore/StudioNumericInput.swift": [(22, 37)],
}
source = {
    path: subprocess.check_output(["git", "show", f"{REV}:{path}"], cwd=ROOT).decode()
    for path in RANGES
}
checks = []

def require(name, predicate, refs):
    checks.append({"name": name, "passed": bool(predicate), "references": refs})

surface = source["Sources/LightingCore/SurfacePhotometry.swift"]
optics = source["Sources/LightingCore/StudioOptics.swift"]
solver = source["Sources/LightingCore/LightOutputAdjustment.swift"]
meter = source["App/StudioView.swift"]
compact = source["App/StudioMeterReadout.swift"]
editor = source["App/LightTargetLuxView.swift"]

require("Coincident receiver/camera yields nil normal before point sampling",
    "guard scale > 0 else { return nil }" in surface
    and "return UnitDirection(x: scene.camera.x - scene.subject.x," in optics
    and "guard light.isValid, let normal = receiverNormal(in: scene) else { return nil }" in optics,
    ["SurfacePhotometry.swift:9-15", "StudioOptics.swift:100-118"])
require("Supported nonpositive incidence is clamped to exact zero",
    "return normalLux * min(1, max(0, dot(delta / distance, receiverNormal.vector)))" in surface,
    ["SurfacePhotometry.swift:92-98"])
require("Meter has separate numeric and textual unavailable branches",
    'if let lux = StudioPhotometry.illuminance(for: light, in: scene) {' in meter
    and 'Text(StudioMeterReadout.lux(lux, locale: locale))' in meter
    and '.accessibilityValue(StudioNumericInput.formattedValue(lux, unit: "lx", locale: locale))' in meter
    and 'Label("Estimate unavailable", systemImage: "exclamationmark.triangle")' in meter
    and 'Check the aim and separation of the emitter, subject and camera.' in meter,
    ["StudioView.swift:989-1004"])
require("Compact exact zero and positive sub-resolution values remain distinct",
    'formattedValue(value, unit: "lx", fractionDigits: 1, quantum: 0.1, locale: locale)' in compact
    and 'if value > 0, value < quantum {' in compact
    and 'let displayValue = value == 0 ? 0.0 : value' in compact,
    ["StudioMeterReadout.swift:9-29"])
require("Target positive unsupported sample throws human-readable geometry error",
    'unitLux.isFinite, unitLux > 0 else {\n            throw LightOutputAdjustmentError.unsupportedGeometry' in solver
    and 'This scene or light geometry cannot produce the requested illuminance on the camera-facing subject plane.' in solver,
    ["LightOutputAdjustment.swift:15-16", "LightOutputAdjustment.swift:50-54"])
require("Target zero turns source off before sampling",
    solver.index('if targetLux == 0 {') < solver.index('guard let unitLux = StudioPhotometry.illuminance')
    and 'if targetLux == 0 {\n            adjusted.candela = 0\n            return adjusted\n        }' in solver,
    ["LightOutputAdjustment.swift:42-54"])
require("Target editor surfaces caught error as a text-bearing label",
    'self.error = error.localizedDescription' in editor
    and 'Label(error, systemImage: "exclamationmark.triangle")' in editor
    and '.accessibilityIdentifier("targetLuxError")' in editor,
    ["LightTargetLuxView.swift:56-60", "LightTargetLuxView.swift:112-125"])
require("Target editor omits current row when unavailable; does not substitute zero",
    'if let current = StudioPhotometry.illuminance(for: light, in: scene) {\n                        LabeledContent("Current ideal illuminance",\n                                       value: StudioNumericInput.formattedValue(current, unit: "lx", locale: locale))\n                    }\n                    HStack {' in editor
    and 'if draft.isEmpty, let current = StudioPhotometry.illuminance(for: light, in: scene)' in editor
    and '.disabled(target == nil || rejectedOversizedDraft || didApply)' in editor,
    ["LightTargetLuxView.swift:30-38", "LightTargetLuxView.swift:63-70", "LightTargetLuxView.swift:86-90"])

# Independent scalar fixtures: no production normal helper or Swift code runs.
subject = (0.0, 1.5, 0.0)
light = (0.0, 1.5, -1.0)
camera = (0.0, 1.5, 3.0)
camera_delta = [a-b for a, b in zip(camera, subject)]
light_delta = [a-b for a, b in zip(light, subject)]
normal = [v / sum(t*t for t in camera_delta)**0.5 for v in camera_delta]
distance = sum(v*v for v in light_delta)**0.5
incidence = sum(a*b/distance for a, b in zip(normal, light_delta))
fixtures = {
    "basis": "Independent scalar expectations, NOT runtime observations",
    "shared": {"subject_m": subject, "point_source_m": light, "candela": 1000},
    "coincident_camera": {
        "camera_m": subject, "receiver_vector": [0, 0, 0], "expected_lux": None,
        "meter_source_branch": "Estimate unavailable", "target_positive": "unsupportedGeometry",
        "target_zero": "candela=0; receiver orientation remains unsupported",
    },
    "supported_back_facing": {
        "camera_m": camera, "receiver_normal": normal, "distance_m": distance,
        "receiver_incidence": incidence, "expected_lux": 1000 / distance**2 * max(0, incidence),
        "meter_en_US_source_expectation": "0.0 lx", "target_positive": "unsupportedGeometry",
        "target_zero": "candela=0; supported zero readout",
    },
}
manifest = {
    "revision": REV,
    "sha256": {path: hashlib.sha256(text.encode()).hexdigest() for path, text in source.items()},
}
excerpts = []
for path, ranges in RANGES.items():
    lines = source[path].splitlines()
    excerpts.append(f"\n{REV}:{path}\n")
    for first, last in ranges:
        excerpts.extend(f"{i}: {lines[i-1]}\n" for i in range(first, min(last, len(lines))+1))
(OUT / "source-excerpts.txt").write_text("".join(excerpts))
(OUT / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
(OUT / "scalar-references.json").write_text(json.dumps(fixtures, indent=2) + "\n")
result = {
    "check": "Unsupported receiver orientation through meter and target editing",
    "revision": REV, "kind": "static source audit; no compilation or UI execution",
    "passed": all(check["passed"] for check in checks), "checks": checks,
    "observation": "No explicit current-unavailable row in target editor before Apply; positive Apply shows generic geometry error. No orientation-specific reason is carried by Double?.",
    "limits": "Source structure only; no UI layout, VoiceOver, device, physical calibration, privacy-system audit, or numerical-gate claim.",
}
(OUT / "results.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"revision": REV, "kind": result["kind"], "passed": result["passed"], "source_assertions": len(checks), "scalar_back_facing_lux": fixtures["supported_back_facing"]["expected_lux"]}, indent=2))
raise SystemExit(0 if result["passed"] else 1)
