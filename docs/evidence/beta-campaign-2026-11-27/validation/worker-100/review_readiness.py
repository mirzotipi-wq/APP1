"""Read-only gate review of existing evidence; executes no app or test suite."""
from collections import defaultdict
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
REPO = ROOT / "APP1"
E = ROOT / "campaign/evidence"
OUT = Path(__file__).resolve().parent
REVISION = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text())


def method_sequences(path):
    results = defaultdict(list)
    for identity, event in re.findall(r"Test Case '([^']+)' (started|passed|failed|skipped)\b", path.read_text()):
        if identity.startswith("-["):
            identity = identity[2:-1].replace(" ", ".")
        results[identity].append(event)
    assert results and all(v == ["started", "passed"] for v in results.values())
    return results


assert subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip() == REVISION
inventory = read(E / "089/source-inventory.json")
assert inventory["source_revision"] == REVISION
verified = []
for entry in inventory["manifest"]:
    path = REPO / entry["path"]
    assert path.stat().st_size == entry["bytes"] and digest(path) == entry["sha256"], entry["path"]
    verified.append(entry["path"])

core = read(E / "published-core-03/reconciliation.json")
assert core["sourceRevision"] == REVISION
core_counts = {}
for configuration, filename in [("debug", "core-tests.log"), ("release", "core-release-tests.log")]:
    path = E / "published-core-03" / filename
    assert digest(path) == core["tests"][configuration]["sourceLogSHA256"]
    sequences = method_sequences(path)
    assert len(sequences) == 588
    core_counts[configuration] = len(sequences)

native = read(E / "089/native-reconciliation.json")
native_log = ROOT / native["native"]["log"]
assert native["source_revision"] == REVISION
assert digest(native_log) == native["native"]["log_sha256"]
native_sequences = method_sequences(native_log)
assert set(native_sequences) == {"KeyAndFillTests." + name for name in inventory["native"]["methods"]}
assert len(native_sequences) == 323
cache_methods = sorted(k for k in native_sequences if ".StudyRenderCacheTests." in k)
assert cache_methods
macos_log = ROOT / native["portable_macos"]["log"]
assert digest(macos_log) == native["portable_macos"]["log_sha256"]
assert len(method_sequences(macos_log)) == 591

prior_review = read(REPO / "docs/evidence/beta-campaign-2026-11-27/validation/published-02-core-visual-review.json")
reviewed = {Path(x["image"]).stem: x for x in prior_review["originals"]}
images = []
for fixture in core["renderedImages"]["fixtures"]:
    name = fixture["name"]
    image = E / "published-core-03/study-artifacts" / (name + ".ppm")
    scene = image.with_suffix(".json")
    assert digest(image) == fixture["ppmSHA256"] == reviewed[name]["imageSHA256"]
    assert digest(scene) == fixture["sceneJSONSHA256"] == reviewed[name]["sceneSHA256"]
    assert fixture["reportedUnsupportedPixels"] == 0
    images.append(name)
assert len(images) == 12 and prior_review["actualImagesViewed"] == 12

library = read(E / "097/reconciliation.json")
assert library["revision"] == REVISION and library["counts"]["passed"] == 9
assert library["normalCommandCompletion"]["exitCode"] == 0
failure = read(E / "095/reconciliation.json")
assert failure["sourceRevision"] == REVISION and failure["failed"] == 1

doc_paths = ["docs/PRIVACY.md", "docs/BETA_TESTER_GUIDE.md"]
local_links = []
for relative in doc_paths:
    path = REPO / relative
    for target in re.findall(r"\]\(([^)]+)\)", path.read_text()):
        if target.startswith(("http:", "https:", "#")):
            continue
        assert (path.parent / target.split("#")[0]).exists(), (relative, target)
        local_links.append({"source": relative, "target": target})

receipt = {
    "worker": "/root/a100_independent_beta_readiness", "sourceRevision": REVISION,
    "scope": "Independent source and existing-evidence review; no build, suite, native execution, rerun or new image viewing.",
    "verifiedSourceInputCount": len(verified), "verifiedSourcePaths": verified,
    "sourceManifestSHA256": digest(E / "089/source-inventory.json"),
    "rawLogCountsIndependentlyReparsed": {"portable": core_counts, "native": len(native_sequences), "macOS": 591},
    "nativeCacheMethodsPassed": cache_methods,
    "twelveCurrentImagesAndScenesMatchActualPriorReview": images,
    "visualReviewLimitation": "This worker verified exact byte identity to root's earlier actual review, not a fresh visual review or calibration.",
    "reviewedReceipts": {str(p.relative_to(ROOT)): digest(p) for p in [
        E / "published-core-03/reconciliation.json", E / "089/native-reconciliation.json",
        E / "097/reconciliation.json", E / "095/reconciliation.json", E / "093/source-review.json",
        E / "094/distribution-audit.json"]},
    "workingDocumentation": {p: digest(REPO / p) for p in doc_paths},
    "localLinksChecked": local_links,
    "initialGateDisposition": {
        "core_tests": "pass supported", "native_build": "pass supported by actual simulator builds and recorded toolchain",
        "persistence_smoke": "pending current studio-export corrupt-file UI smoke; normal library save/relaunch passed",
        "photometry": "pass supported by current Debug/Release analytic and invariant methods",
        "rendering": "pass supported by12 current images/JSON with zero unsupported pixels, actual prior byte-identical review,6 parity and8 precision records; native final shell evidence tracked separately by089",
        "performance": "current cancellation/cache methods and optimized host benchmark support code acceptance; finalize089 native command receipt",
        "M01": "await the existing corrupt-file UI smoke disposition",
        "M02": "gate evidence can be accepted once finalized; promote only after M01 dependency",
        "M03": "no-go: required app accessibility failed; other required UI outcomes pending",
        "M04-M07": "unchanged external and release obligations; no beta/distribution acceptance"
    },
    "documentationReview": {"privacyChanges": "Consistent with093 traced behavior; unsanitized recovery retention and no app cleanup correctly disclosed.",
        "testerGuide": "Target-lux instructions match controls and locale-bound behavior; no distribution pass claimed. Narrow broad native-acceptance-pending sentence after089 finalizes."},
    "followup": "Recheck current terminal UI, native/device final receipts and final root readiness/state summary on this same identity."
}
(OUT / "readiness-review.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps({"sourceInputs": len(verified), "portableDebug": 588, "portableRelease": 588, "native": 323, "macOS": 591, "images": len(images), "localLinks": len(local_links), "result": "Initial gate review completed; M01/M02 dependency disposition and M03 required failures remain explicit."}))
