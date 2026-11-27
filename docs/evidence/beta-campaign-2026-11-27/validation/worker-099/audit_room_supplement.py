"""Bounded room-failure selection audit; preserves earlier audit receipts."""
from pathlib import Path, PurePosixPath
import collections
import hashlib
import io
import json
import os
import re
import stat
import subprocess
import zipfile
import zstandard

ROOT = Path(__file__).resolve().parents[3]
REPO = ROOT / "APP1"
V = REPO / "docs/evidence/beta-campaign-2026-11-27/validation"
OUT = Path(__file__).resolve().parent
ORIGINALS = ROOT / "campaign/evidence/098/room-precision"
SOURCE = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
EXPECTED = "8b819fc40049a44afb0511e4d0aec35bd11d15c255f418e135e3b6395a60b9f7"
PREVIOUS = {"audit-result.json": "c4490e6cf739c214751aa72b80c38336b59aa32ef9c940b3e6ea60d63f742f2e",
    "supplement-01.json": "c4617dc966338d4d6544c5ff1a53066485217587019da550546c302f89ceb664"}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def file_sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def safe_zip(data):
    z = zipfile.ZipFile(io.BytesIO(data))
    assert len(z.namelist()) == len(set(z.namelist()))
    assert sum(i.file_size for i in z.infolist()) <= 10_000_000
    for i in z.infolist():
        p = PurePosixPath(i.filename)
        assert not p.is_absolute() and ".." not in p.parts and "\\" not in i.filename
        assert str(p) == i.filename.rstrip("/") and not i.flag_bits & 1
        assert stat.S_IFMT(i.external_attr >> 16) in (0, stat.S_IFREG, stat.S_IFDIR)
    assert z.testzip() is None
    return z


for name, digest in PREVIOUS.items():
    assert file_sha(OUT / name) == digest
indexpath = V / "published-03-room-attempt-1-evidence.json"
index = json.loads(indexpath.read_bytes())
data = (V / index["archive"]).read_bytes()
assert len(data) == index["bytes"] == 3468071 and sha(data) == index["sha256"] == EXPECTED
z = safe_zip(data)
assert len(index["files"]) == len(z.infolist()) == 22
assert {r["path"] for r in index["files"]} == set(z.namelist())
for r in index["files"]:
    raw = z.read(r["path"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
    assert raw == (ORIGINALS / r["path"]).read_bytes()

compact = json.loads(z.read("compact-receipt.json"))
meta = json.loads(z.read("compact-metadata.json"))
data = z.read("compact-original.zip")
assert len(data) == compact["bytes"] == meta["size_in_bytes"]
assert sha(data) == compact["sha256"] == meta["digest"].removeprefix("sha256:")
assert meta["workflow_run"]["head_sha"] == SOURCE and meta["workflow_run"]["id"] == 46004241191
cz = safe_zip(data)
assert len(cz.namelist()) == len(compact["files"]) == 8
for r in compact["files"]:
    raw = cz.read(r["path"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]

# Verify the explicit excluded provider/recording references against available originals.
full = json.loads(z.read("full-receipt.json"))
fullmeta = json.loads(z.read("full-metadata.json"))
assert full["bytes"] == fullmeta["size_in_bytes"] == 146079730
assert full["sha256"] == fullmeta["digest"].removeprefix("sha256:")
assert fullmeta["workflow_run"]["head_sha"] == SOURCE
assert file_sha(ORIGINALS / "full-original.zip") == full["sha256"]
assert "full-original.zip" not in z.namelist() and not any(n.endswith((".mp4", ".mov")) for n in z.namelist())
recordings = [r for r in full["files"] if r["path"].endswith((".mp4", ".mov"))]
assert len(recordings) == 1
for r in recordings:
    p = ORIGINALS / "full" / r["path"]
    assert p.stat().st_size == r["bytes"] and file_sha(p) == r["sha256"]
inner = ORIGINALS / "full/artifacts/native-results.zip"
inner_meta = next(r for r in full["files"] if r["path"] == "artifacts/native-results.zip")
assert inner.stat().st_size == inner_meta["bytes"] and file_sha(inner) == inner_meta["sha256"]

decoded = {}
diagnostics = json.loads(z.read("diagnostics-receipt.json"))
with zipfile.ZipFile(inner) as xc:
    for r in diagnostics:
        raw = z.read(r["compressedFile"])
        assert len(raw) == r["compressedBytes"] and sha(raw) == r["compressedSHA256"]
        assert raw == xc.read(r["source"])
        with zstandard.ZstdDecompressor().stream_reader(io.BytesIO(raw)) as reader:
            payload = reader.read(30_000_001)
        assert len(payload) == r["decodedBytes"] and sha(payload) == r["decodedSHA256"]
        decoded[r["label"]] = payload.decode().splitlines()
for r in json.loads(z.read("input-timeline-excerpts.json")):
    assert decoded[r["log"]][r["line"] - 1] == r["text"]

sources = json.loads(z.read("source-review.json"))
assert sources["source"] == SOURCE and sources["causalConclusion"] is None
for path, r in sources["files"].items():
    raw = subprocess.check_output(["git", "-C", str(REPO), "show", SOURCE + ":" + path],
        env={**os.environ, "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1"})
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
accounting = json.loads(z.read("full/native-method-accounting.json"))
events = collections.defaultdict(list)
for cls, method, event in re.findall(r"Test Case '-\[KeyAndFillUITests\.(\w+) (\w+)\]' (started|passed|failed|skipped)", z.read("full/native-tests.log").decode()):
    events[cls + "." + method].append(event)
assert set(events) == set(accounting["expected"]) and len(events) == 5
passed = sorted(k for k, v in events.items() if v == ["started", "passed"])
failed = sorted(k for k, v in events.items() if v == ["started", "failed"])
assert passed == sorted(accounting["passed"]) and len(passed) == 4
assert failed == accounting["failed"] and len(failed) == 1
assert "later keyboard-queue timeout does not establish" in index["scope"]
for name, digest in PREVIOUS.items():
    assert file_sha(OUT / name) == digest

result = {"agent": "/root/a099_final_provenance_integrity", "sameIdentityFollowup": True,
    "sourceRevision": SOURCE, "archive": index["archive"], "indexSHA256": file_sha(indexpath),
    "archiveSHA256": EXPECTED, "bytes": index["bytes"], "entries": 22,
    "rawBytes": sum(r["bytes"] for r in index["files"]), "allIndexEntryHashesCRCSafeNamesAndOriginalBytesMatch": True,
    "compactOriginal": {"sha256": compact["sha256"], "payloadsIncludingManifest": 8,
        "pngs": len([n for n in cz.namelist() if n.endswith(".png")]),
        "texts": len([n for n in cz.namelist() if n.endswith(".txt")])},
    "originalCompressedDiagnosticsVerifiedAgainstFullResultBundle": diagnostics,
    "allTimelineExcerptsMatchDecodedOriginalLine": True, "sourceHashesVerified": len(sources["files"]),
    "orderedMethodEvents": {"passed": passed, "failed": failed, "unstarted": [], "skipped": []},
    "excludedFullProvider": {"bytes": full["bytes"], "sha256": full["sha256"], "availableOriginalHashVerified": True},
    "excludedRecordings": recordings, "previousReceiptsUnchanged": PREVIOUS,
    "limits": ["No app/test/build execution, new image viewing or source/remote changes.",
        "The later keyboard timeout is retained evidence, not an established cause of the earlier input failure.",
        "Selected archives intentionally exclude large provider/result archives and recording payloads, with exact hashes retained."]}
(OUT / "supplement-02.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"entries": 22, "rawBytes": result["rawBytes"], "compactPNGs": result["compactOriginal"]["pngs"],
    "compactTexts": result["compactOriginal"]["texts"], "passed": len(passed), "failed": len(failed),
    "diagnosticDecodedBytes": sum(r["decodedBytes"] for r in diagnostics)}, indent=2))
