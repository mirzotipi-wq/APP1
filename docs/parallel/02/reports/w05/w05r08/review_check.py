from pathlib import Path
import datetime
import difflib
import hashlib
import json
import platform
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent
COMMAND = "python3 private-output/review_check.py"
EXPECTED_HEAD = "928ca0eafa6330742114c2e0ac184789c2f17752"
SNAPSHOT = "1b286885cb803ba17e159713651515ab119e17f1"
PRODUCTION_BASE = "58b3ca43943e18d0fc7800189b08365f424d9c9e"
TARGET = "Sources/LightingCore/LightOutputAdjustment.swift"
FILES = [TARGET, "Sources/LightingCore/Scene.swift", "Sources/LightingCore/StudioOptics.swift", "Sources/LightingCore/SurfacePhotometry.swift", "docs/QUALITY.md"]
REPLACEMENTS = {
    "invalidLight": (
        "The light's settings must be valid before adjusting its output.",
        "Use a nonblank light name of at most 80 characters. Check its position and emitter settings, output (0–100,000 cd), and color temperature (1,000–20,000 K), then try again."
    ),
    "unsupportedGeometry": (
        "This scene or light geometry cannot produce the requested illuminance on the camera-facing subject plane.",
        "The model could not calculate this light's contribution. Check the scene settings and all lights. For a positive target in lux, separate the camera from the subject and try moving or re-aiming the light toward the camera-facing subject plane."
    ),
    "outputOutOfRange": (
        "The requested illuminance cannot be represented within the supported candela range and numerical accuracy.",
        "The requested lux could not be achieved within the model's 0–100,000 cd range and numerical accuracy. Try a different positive target or adjust the light's position or aim; enter 0 lux to turn this light off."
    ),
}

log = []
def record(message):
    log.append(message)
    print(message)
    (OUT / "check.log").write_text("\n".join(log) + "\n")

def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)

record("W05 R08 focused source/string check")
record("UTC " + datetime.datetime.now(datetime.timezone.utc).isoformat())
record("COMMAND " + COMMAND)
record("CWD " + str(ROOT))
record("PYTHON " + sys.version.replace("\n", " ") + "; " + platform.platform())
head = git("rev-parse", "HEAD")
assert head.returncode == 0 and head.stdout.strip() == EXPECTED_HEAD
record("HEAD " + head.stdout.strip())
record("MODULE_SNAPSHOT " + SNAPSHOT + " (not executed)")
record("PRODUCTION_BASE " + PRODUCTION_BASE)

sources = {name: (ROOT / name).read_text() for name in FILES}
provenance = {}
for name, text in sources.items():
    item = {"sha256": hashlib.sha256(text.encode()).hexdigest()}
    if name.startswith("Sources/"):
        for label, revision in [("module_snapshot", SNAPSHOT), ("production_base", PRODUCTION_BASE)]:
            prior = git("show", f"{revision}:{name}")
            item[label + "_available"] = prior.returncode == 0
            item[label + "_exact_match"] = prior.returncode == 0 and prior.stdout == text
            assert prior.returncode == 0 and prior.stdout == text, (name, label, prior.stderr)
    provenance[name] = item
(OUT / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
record("PASS: four reviewed production files exactly match both supplied production revisions; five SHA-256 source hashes recorded.")

source = sources[TARGET]
candidate = source
for key, (old, new) in REPLACEMENTS.items():
    assert source.count('return "' + old + '"') == 1, key
    assert '\\(' not in new, key
    candidate = candidate.replace('return "' + old + '"', 'return "' + new + '"')
    assert 'cd' in new or 'lux' in new, key
    assert ('Check' in new or 'Try' in new), key
reverse = candidate
for old, new in REPLACEMENTS.values():
    reverse = reverse.replace('return "' + new + '"', 'return "' + old + '"')
assert reverse == source
assert source.split("public enum LightOutputAdjustment {")[1] == candidate.split("public enum LightOutputAdjustment {")[1]
assert 'abs(achievedLux / targetLux - 1) <= 1e-9' in candidate
assert 'maximum.candela = 100_000' in candidate
assert 'guard let scene = try? scene.validated()' in candidate
assert candidate.index('guard let scene = try? scene.validated()') < candidate.index('if targetLux == 0')
assert 'name.count <= 80' in sources["Sources/LightingCore/Scene.swift"]
assert '(0...100_000).contains(candela)' in sources["Sources/LightingCore/Scene.swift"]
assert '(1_000...20_000).contains(kelvin)' in sources["Sources/LightingCore/Scene.swift"]
assert 'max(0.05, max(emitter.widthMeters, emitter.heightMeters) / 4)' in sources["Sources/LightingCore/SurfacePhotometry.swift"]
assert '<= 1%' in sources["docs/QUALITY.md"] and '<= 5%' in sources["docs/QUALITY.md"]
assert 'For a positive target' in REPLACEMENTS["unsupportedGeometry"][1]
assert 'scene settings and all lights' in REPLACEMENTS["unsupportedGeometry"][1]
assert 'different positive target' in REPLACEMENTS["outputOutOfRange"][1]
assert '0 lux' in REPLACEMENTS["outputOutOfRange"][1]
record("PASS: exactly three static strings replaced; no interpolation, signatures, enum cases, algorithm, 100,000 cd cap, 1e-9 solver gate, or 1%/5% quality gate changed.")

patch = ''.join(difflib.unified_diff(source.splitlines(keepends=True), candidate.splitlines(keepends=True), fromfile='a/' + TARGET, tofile='b/' + TARGET))
(OUT / "candidate.patch").write_text(patch)
(OUT / "candidate-wording.md").write_text("# W05 R08 candidate wording\n\n" + "\n\n".join(f"## {key}\n\n{new}" for key, (_, new) in REPLACEMENTS.items()) + "\n\nGeometry advice is conditional on positive targets because scene validation also fails before the zero-target branch. No universal 0.05 m remedy is promised: rectangular emitters require perpendicular depth of at least max(0.05 m, longest side / 4). A different positive target covers both upper-limit and tiny-target failures without prescribing a direction. These messages remain static and describe the model, not measured lamp output or total-rig illuminance.\n")
ranges = {
    TARGET: [(1, 97)],
    "Sources/LightingCore/Scene.swift": [(3, 38), (60, 95)],
    "Sources/LightingCore/StudioOptics.swift": [(16, 46), (97, 143)],
    "Sources/LightingCore/SurfacePhotometry.swift": [(88, 119)],
    "docs/QUALITY.md": [(1, 21)],
}
evidence = []
for name, intervals in ranges.items():
    evidence.append(f"## {name}; SHA256 {provenance[name]['sha256']}")
    lines = sources[name].splitlines()
    for start, end in intervals:
        evidence.extend(f"{i}: {lines[i - 1]}" for i in range(start, min(end, len(lines)) + 1))
(OUT / "source-evidence.txt").write_text("\n".join(evidence) + "\n")
unchanged = git("diff", "--quiet", "HEAD")
assert unchanged.returncode == 0
record("PASS: git diff --quiet HEAD returned 0; tracked production and documentation remain unchanged.")
record("LIMIT: source/string inspection only; no Swift compilation, runtime sweep, UI, device, calibration, or numerical accuracy measurement.")
(OUT / "command.txt").write_text("cd " + str(ROOT) + "\n" + COMMAND + "\n")
(OUT / "report.md").write_text("""# W05 R08 — actionable target-lux errors

Candidate: `candidate.patch` changes only three error-description strings. `candidate-wording.md` supplies the wording and rationale.

Findings: `invalidLight` covers name, position, candela, kelvin and optics, so the candidate checks all five and gives the 80-character, 0–100,000 cd and 1,000–20,000 K limits. `unsupportedGeometry` also catches every failed scene validation before zero-target handling; the candidate includes scene/all-light checks and makes positioning/aim advice conditional on a positive target. It avoids claiming 0.05 m is sufficient for rectangles. `outputOutOfRange` includes upper-range, underflow and numerical-accuracy failures; the candidate offers a different positive target or geometry, plus 0 lux to turn off this light, rather than universally reducing lux.

Evidence: one bounded check, `python3 private-output/review_check.py`, passed. Original output is `check.log`; exact source excerpts are `source-evidence.txt`; SHA-256 and revision comparisons are `provenance.json`. Worktree HEAD: `928ca0eafa6330742114c2e0ac184789c2f17752`. Four reviewed production files exactly match module snapshot `1b286885cb803ba17e159713651515ab119e17f1` and production baseline `58b3ca43943e18d0fc7800189b08365f424d9c9e`. No Swift module was executed.

Static replacement verification preserves enum/signature, solver, 100,000 cd cap, 1e-9 target gate and 1%/5% quality gates. No user data interpolation or measured-output claim is added. `git diff --quiet HEAD` returned 0. Production is unchanged. No runtime, device, calibration or UI validation is claimed. Root owns integration.
""")
record("RESULT PASS; candidate.patch, candidate-wording.md, report.md, source-evidence.txt, provenance.json, command.txt, and this original log saved.")
