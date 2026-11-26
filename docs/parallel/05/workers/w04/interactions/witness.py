"""Pinned-source arithmetic witness, not Swift/UIKit/RealityKit execution."""
import hashlib
import json
import math
import subprocess
from dataclasses import dataclass

SHA = "9725fb1177a5c7afbdf798ffd627e65e604c75b1"
REPO = "/tmp/keyfill05-be879deb/repo"
PATHS = ("App/SpatialViewportGeometry.swift", "App/RealityStudioPreview.swift", "App/SpatialPreview.swift")
sources = {p: subprocess.check_output(["git", "show", f"{SHA}:{p}"], cwd=REPO).decode() for p in PATHS}
flat = {p: " ".join(s.split()) for p, s in sources.items()}
needles = {
    PATHS[0]: [
        "yaw = (yaw - horizontal * 0.008).remainder(dividingBy: 2 * .pi)",
        "pitch = Self.clamp(pitch + vertical * 0.008, to: -1.35...1.35)",
        "let metersPerPoint = 2 * distance * tan(Self.fieldOfViewDegrees * .pi / 360) / min(width, height)",
        "let x = target.x + (-cos(yaw) * horizontal - sin(yaw) * sin(pitch) * vertical) * metersPerPoint",
        "let y = target.y + cos(pitch) * vertical * metersPerPoint",
        "let z = target.z + (sin(yaw) * horizontal - cos(yaw) * sin(pitch) * vertical) * metersPerPoint",
        "distance = Self.clamp(distance / scale, to: Self.distanceRange)",
        "target = bounds.center", "yaw = 0.56", "pitch = 0.36",
        "distance = Self.clamp(max(0.8, bounds.radiusMeters) / sin(24 * .pi / 180) * 1.12, to: Self.distanceRange)",
    ],
    PATHS[1]: [
        "if lastFitRequest != fitRequest { lastFitRequest = fitRequest needsFit = true }",
        "if needsFit, let scene = currentScene, let bounds = try? SpatialViewportBounds(scene: scene) { orbitState.fit(bounds) needsFit = false }",
        "gesture.setTranslation(.zero, in: view) orbitState.orbit(horizontal: Double(movement.x), vertical: Double(movement.y))",
        "gesture.setTranslation(.zero, in: view) orbitState.pan(horizontal: Double(movement.x), vertical: Double(movement.y), width: Double(view.bounds.width), height: Double(view.bounds.height))",
        "let scale = Double(gesture.scale) gesture.scale = 1 orbitState.zoom(scale: scale)",
    ],
    PATHS[2]: [
        "let needsFit = !cameraMode && (modeChanged || coordinator.lastFitRequest != fitRequest)",
        "else if needsFit, let bounds = try? SpatialViewportBounds(scene: scene) { fitOrbit(view, coordinator: coordinator, bounds: bounds) coordinator.lastFitRequest = fitRequest }",
        "var orbit = SpatialOrbitState() orbit.fit(bounds)",
        "view.defaultCameraController.automaticTarget = false view.defaultCameraController.target = vector(center)",
        "pointOfView?.camera?.projectionDirection = bounds.width < bounds.height ? .horizontal : .vertical",
    ],
}
for path, values in needles.items():
    for value in values:
        assert value in flat[path], (path, value)

def add(a, b): return tuple(x+y for x, y in zip(a, b))
def sub(a, b): return tuple(x-y for x, y in zip(a, b))
def scale(a, s): return tuple(x*s for x in a)
def dot(a, b): return sum(x*y for x, y in zip(a, b))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def norm(a): return math.sqrt(dot(a, a))
def unit(a): return scale(a, 1/norm(a))
def clamp(x, lo, hi): return min(hi, max(lo, x))

@dataclass
class Orbit:
    target: tuple = (1., 2., -3.)
    yaw: float = .56
    pitch: float = .36
    distance: float = 7.
    def position(self):
        y, p, d = self.yaw, self.pitch, self.distance
        return add(self.target, (math.sin(y)*math.cos(p)*d, math.sin(p)*d, math.cos(y)*math.cos(p)*d))
    def pan(self, dx, dy, w, h):
        y, p = self.yaw, self.pitch
        k = 2*self.distance*math.tan(math.radians(24))/min(w, h)
        delta = ((-math.cos(y)*dx-math.sin(y)*math.sin(p)*dy)*k,
                 math.cos(p)*dy*k, (math.sin(y)*dx-math.cos(y)*math.sin(p)*dy)*k)
        self.target = tuple(clamp(v, -300, 300) for v in add(self.target, delta))
    def orbit(self, dx, dy):
        self.yaw = math.remainder(self.yaw-dx*.008, 2*math.pi)
        self.pitch = clamp(self.pitch+dy*.008, -1.35, 1.35)
    def zoom(self, factor): self.distance = clamp(self.distance/factor, .45, 1500)
    def fit(self, center, radius):
        self.target, self.yaw, self.pitch = center, .56, .36
        self.distance = clamp(max(.8, radius)/math.sin(math.radians(24))*1.12, .45, 1500)

def basis(o):
    back = unit(sub(o.position(), o.target))
    right = unit(cross((0., 1., 0.), back))
    return right, cross(back, right), back

def project(o, world, w, h):
    right, up, back = basis(o)
    delta = sub(world, o.position())
    depth = -dot(delta, back)
    assert depth > 0
    focal = min(w, h)/(2*math.tan(math.radians(24)))
    return (w/2+dot(delta, right)*focal/depth, h/2-dot(delta, up)*focal/depth)

angles = [(-2.8, -1.2), (-1.3, -.4), (0., 0.), (.56, .36), (1.7, .8), (3., 1.2)]
pan_count, error = 0, 0.
for yaw, pitch in angles:
    for w, h in [(360, 240), (240, 600), (600, 120)]:
        for dx, dy in [(12, 0), (0, 9), (12, 9), (-7, -11)]:
            for off_center in [False, True]:
                o = Orbit(yaw=yaw, pitch=pitch)
                right, up, _ = basis(o)
                subject = add(o.target, add(scale(right, .3), scale(up, .2))) if off_center else o.target
                before = project(o, subject, w, h)
                o.pan(dx, dy, w, h)
                after = project(o, subject, w, h)
                err = max(abs(after[0]-before[0]-dx), abs(after[1]-before[1]-dy))
                error = max(error, err)
                assert err < 1e-9 and o.distance == 7
                pan_count += 1
for yaw, pitch in angles:
    o = Orbit(yaw=yaw, pitch=pitch)
    original_target = o.target
    o.orbit(15, -13)
    assert math.isclose(o.yaw, yaw-.12, abs_tol=1e-12)
    assert math.isclose(o.pitch, pitch-.104, abs_tol=1e-12)
    assert o.target == original_target and math.isclose(norm(sub(o.position(), o.target)), 7)
    assert max(abs(a-b) for a, b in zip(project(o, original_target, 360, 240), (180, 120))) < 1e-9
for dy, expected in [(1000, 1.35), (-1000, -1.35)]:
    o = Orbit(); o.orbit(0, dy); assert o.pitch == expected
zoom_results = []
for factor in [1.2, 2., .5, 1e-8, 1e8]:
    o = Orbit(); o.zoom(factor)
    assert o.distance == clamp(7/factor, .45, 1500)
    assert o.distance < 7 if factor > 1 else o.distance > 7
    zoom_results.append([factor, o.distance])
o = Orbit()
for factor in [1.05, 1.1, 1.2]: o.zoom(factor)
assert math.isclose(o.distance, 7/(1.05*1.1*1.2))
o.zoom(1); assert math.isclose(o.distance, 7/(1.05*1.1*1.2))
o.orbit(31, 17); o.pan(11, -8, 360, 240); o.fit((8., -3., 2.), 5.)
assert (o.target, o.yaw, o.pitch) == ((8., -3., 2.), .56, .36)
assert math.isclose(o.distance, 5/math.sin(math.radians(24))*1.12)

# Predicate/state witnesses mirror the reviewed adapters; no adapter runs here.
last, needs, fits = None, True, 0
events = [(41, False, "initial zero layout"), (41, True, "valid layout"),
          (41, True, "metadata change"), (41, True, "portrait layout"),
          (41, True, "landscape layout"), (42, True, "explicit Fit"), (42, True, "repeat")]
counts = []
for token, valid_layout, label in events:
    if token != last: last, needs = token, True
    if valid_layout and needs: fits, needs = fits+1, False
    counts.append(fits)
assert counts == [0, 1, 1, 1, 1, 2, 2]
last = 41
scn = []
for token in [41, 41, 41, 42, 42]:
    needs = not False and (False or last != token)
    scn.append(needs)
    if needs: last = token
assert scn == [False, False, False, True, False]

print(json.dumps({"input": SHA, "source_sha256": {p: hashlib.sha256(s.encode()).hexdigest() for p, s in sources.items()},
    "source_snippet_assertions": sum(map(len, needles.values())), "pan_projection_cases": pan_count,
    "max_point_error": error, "orbit_cases": len(angles), "pitch_clamp_cases": 2,
    "zoom_results": zoom_results, "incremental_zoom": "pass", "fit_reset": "pass",
    "rk_fit_counts": counts, "scn_stable_orbit_fit_flags": scn, "outcome": "PASS (source/math witness only)"}, indent=2))
