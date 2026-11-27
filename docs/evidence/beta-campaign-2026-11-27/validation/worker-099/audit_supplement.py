"""Supplemental read-only selection/provenance audit; preserves first receipt."""
from pathlib import Path, PurePosixPath
import collections
import hashlib
import io
import json
import os
import plistlib
import re
import stat
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[3]
REPO = ROOT / "APP1"
V = REPO / "docs/evidence/beta-campaign-2026-11-27/validation"
OUT = Path(__file__).resolve().parent
SOURCE = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
BASE_RECEIPT_SHA = "c4490e6cf739c214751aa72b80c38336b59aa32ef9c940b3e6ea60d63f742f2e"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def safe_zip(data):
    z = zipfile.ZipFile(io.BytesIO(data))
    names = z.namelist()
    assert len(names) == len(set(names))
    assert sum(i.file_size for i in z.infolist()) <= 30_000_000
    for i in z.infolist():
        p = PurePosixPath(i.filename)
        assert not p.is_absolute() and ".." not in p.parts and "\\" not in i.filename
        assert str(p) == i.filename.rstrip("/") and not i.flag_bits & 1
        assert stat.S_IFMT(i.external_attr >> 16) in (0, stat.S_IFREG, stat.S_IFDIR)
    assert z.testzip() is None
    return z


def git_blob(path):
    return subprocess.check_output(["git", "-C", str(REPO), "show", SOURCE + ":" + path],
        env={**os.environ, "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1"})


def check_events(log, expected):
    events = collections.defaultdict(list)
    for name, event in re.findall(r"Test Case '([^']+)' (started|passed|failed|skipped)\b", log):
        if name.startswith("-["):
            cls, method = name[2:-1].split(" ")
            name = cls.split(".")[-1] + "." + method
        else:
            name = ".".join(name.split(".")[-2:])
        events[name].append(event)
    assert set(events) == set(expected)
    assert all(v == ["started", "passed"] for v in events.values())
    return len(events)


initial = OUT / "audit-result.json"
assert sha(initial.read_bytes()) == BASE_RECEIPT_SHA
selections = []
opened = {}
for name, worker, count, digest in [
    ("published-03-native-build-evidence", "089", 78, "537c68c3d5ec3609bcb7dc2c308854307f9778d2d590463045ee692b0c26f81e"),
    ("published-03-library-evidence", "097", 21, "ffe9e31956d4b035181e9491d7e69f259f53f18bb2cdd35bc7d4298945428c1d"),
]:
    indexpath = V / (name + ".json")
    index = json.loads(indexpath.read_bytes())
    data = (V / index["archive"]).read_bytes()
    assert len(data) == index["bytes"] and sha(data) == index["sha256"] == digest
    z = safe_zip(data)
    assert len(z.infolist()) == len(index["files"]) == count
    assert {r["path"] for r in index["files"]} == set(z.namelist())
    for r in index["files"]:
        raw = z.read(r["path"])
        assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
        assert raw == (ROOT / "campaign/evidence" / worker / r["path"]).read_bytes()
    selections.append({"archive": index["archive"], "sha256": digest, "bytes": len(data),
        "indexSHA256": sha(indexpath.read_bytes()), "entries": count,
        "rawBytes": sum(r["bytes"] for r in index["files"]), "scope": index["scope"],
        "allHashesCRCNamesTypesAndOriginalBytesMatch": True})
    opened[worker] = z

n = opened["089"]
receipt = json.loads(n.read("receipt.json"))
assert receipt["source_revision"] == SOURCE and receipt["run_id"] == 46004241191
assert receipt["terminal_job_conclusion"] == "success"
inventory = json.loads(n.read("source-inventory.json"))
assert len(inventory["manifest"]) == 255
for r in inventory["manifest"]:
    raw = git_blob(r["path"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
native_count = check_events(n.read("native/native-tests.log").decode(), inventory["native"]["methods"])
mac_expected = [c["class"] + "." + method for c in inventory["portable"]["classes"] for method in c["methods"]]
mac_count = check_events(n.read("native/macos-core-tests.log").decode(), mac_expected)
assert native_count == 323 and mac_count == 591
info_bytes = n.read("native/artifacts/native-results-contents/NativeTests.xcresult/Info.plist")
assert plistlib.loads(info_bytes)["rootId"] and sha(info_bytes) == receipt["finalized_xcresult"]["info_sha256"]
attachments = json.loads(n.read("native-destination-and-attachment-integrity.json"))["attachments"]
assert len(attachments) == 8
for r in attachments:
    raw = n.read("native/artifacts/native-attachments/" + r["file"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
device = json.loads(n.read("device-artifact-receipt.json"))
device_bytes = n.read("downloads/15203886241-device.zip")
assert sha(device_bytes) == device["sha256"] and len(device_bytes) == device["bytes"]
dz = safe_zip(device_bytes)
for r in device["files"]:
    raw = dz.read(r["path"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"] and raw == n.read("device/" + r["path"])
assert not any(".app/" in name or "_CodeSignature" in name for name in dz.namelist())
assert not any(name.startswith("downloads/") and name != "downloads/15203886241-device.zip" for name in n.namelist())

l = opened["097"]
library = json.loads(l.read("reconciliation.json"))
assert library["revision"] == SOURCE and library["runId"] == 46004241191 and library["jobConclusion"] == "success"
expected = library["expected"]
library_count = check_events(l.read("full/native-tests.log").decode(), expected)
assert library_count == 9
sources = json.loads(l.read("source-inventory.json"))
assert len(sources) == 13
for r in sources:
    raw = git_blob(r["path"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
originals = json.loads(l.read("archive-receipts.json"))
compact = next(r for r in originals if r["archive"] == "library-compact-original.zip")
data = l.read(compact["archive"])
assert sha(data) == compact["sha256"] == compact["providerArtifact"]["digest"].removeprefix("sha256:")
assert compact["providerArtifact"]["workflow_run"]["head_sha"] == SOURCE
cz = safe_zip(data)
for r in compact["files"]:
    raw = cz.read(r["path"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
assert len([p for p in cz.namelist() if p.endswith(".png")]) == 4
assert len([p for p in cz.namelist() if p.endswith(".txt")]) == 3
assert "library-full-original.zip" not in l.namelist()
assert "source manifest" in selections[1]["scope"]
assert not any(p.startswith("source/") for p in l.namelist())
assert sha(initial.read_bytes()) == BASE_RECEIPT_SHA

result = {"agent": "/root/a099_final_provenance_integrity", "sameIdentityFollowup": True,
    "sourceRevision": SOURCE, "initialReceiptUnchangedSHA256": BASE_RECEIPT_SHA,
    "archives": selections, "totalEntries": sum(r["entries"] for r in selections),
    "totalRawBytes": sum(r["rawBytes"] for r in selections),
    "native": {"sourceHashes": 255, "nativeOrderedPasses": native_count, "macOSOrderedPasses": mac_count,
        "genuineAttachmentHashes": 8, "finalizedInfoPlistVerified": True,
        "includedDeviceOriginalArchiveAndSevenPayloadsMatch": True, "deviceAppBinaryIncluded": False},
    "library": {"sourceHashes": 13, "orderedPasses": library_count,
        "originalCompactArchiveAndAllPayloadsMatch": True, "originalPNGs": 4, "originalAXTexts": 3,
        "sourceManifestWordingCorrected": True},
    "limits": ["Large full-native, simulator-app and full-library provider archives are intentionally excluded and separately identified.",
        "Artifact-specific full auditors still require those separately identified originals.",
        "No app/test/build execution or new image review; counts are independent parsing of retained original logs.",
        "Current room/accessibility failures and other unfinished UI work are outside this supplement."]}
(OUT / "supplement-01.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"entries": result["totalEntries"], "rawBytes": result["totalRawBytes"],
    "native": result["native"], "library": result["library"]}, indent=2))
