"""Read-only verification of selected campaign evidence; no test/app execution."""
from pathlib import Path, PurePosixPath
import argparse
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
parser = argparse.ArgumentParser()
parser.add_argument("--output", type=Path, default=OUT / "audit-result.json")
args = parser.parse_args()
SOURCE = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
ARCHIVES = {
    "published-03-core-evidence": ROOT / "campaign/evidence/published-core-03",
    "published-02-terminal-evidence": ROOT / "campaign/evidence/081",
    "source-bundle-recovery-evidence": ROOT / "campaign/evidence/083",
    "published-02-library-failure-evidence": ROOT / "campaign/evidence/086",
    "worker-080-probe": ROOT / "campaign/probes/080",
    "published-03-accessibility-attempt-1-evidence": ROOT / "campaign/evidence/095",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def readj(path):
    return json.loads(path.read_bytes())


def git(*args, repo=REPO):
    return subprocess.check_output(["git", "-C", str(repo), *args],
        env={**os.environ, "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1"})


def check_zip(data):
    z = zipfile.ZipFile(io.BytesIO(data))
    info = z.infolist()
    names = [i.filename for i in info]
    assert len(names) == len(set(names)), "duplicate entry"
    assert sum(i.file_size for i in info) <= 50_000_000, "unbounded archive"
    for i in info:
        path = PurePosixPath(i.filename)
        assert i.filename and not path.is_absolute() and ".." not in path.parts
        assert "\\" not in i.filename and str(path) == i.filename.rstrip("/")
        assert not i.flag_bits & 1 and i.file_size <= 20_000_000
        mode = i.external_attr >> 16
        assert not stat.S_ISLNK(mode)
        assert stat.S_IFMT(mode) in (0, stat.S_IFREG, stat.S_IFDIR)
    assert z.testzip() is None
    return z


results = []
for name, source in ARCHIVES.items():
    indexpath = V / (name + ".json")
    index = readj(indexpath)
    p = V / index["archive"]
    data = p.read_bytes()
    assert len(data) == index["bytes"] and sha(data) == index["sha256"]
    z = check_zip(data)
    records = index["files"]
    paths = [r["path"] for r in records]
    assert len(paths) == len(set(paths)) and set(paths) == set(z.namelist())
    for r in records:
        original = z.read(r["path"])
        assert len(original) == r["bytes"] and sha(original) == r["sha256"]
        assert original == (source / r["path"]).read_bytes(), r["path"]
    if "rawBytes" in index:
        assert index["rawBytes"] == sum(r["bytes"] for r in records)
    results.append({"archive": p.name, "indexSHA256": sha(indexpath.read_bytes()),
        "sha256": sha(data), "bytes": len(data), "files": len(records),
        "rawBytes": sum(r["bytes"] for r in records), "everySourceByteMatches": True,
        "safeNamesTypesCRCAndSizes": True, "declaredScope": index["scope"]})

# The current-core provider ZIP and all original payloads are preserved unchanged.
with zipfile.ZipFile(V / "published-03-core-evidence.zip") as z:
    core = json.loads(z.read("artifact-receipt.json"))
    data = z.read(core["archiveFile"])
    assert sha(data) == core["archiveSHA256"] == core["expectedGitHubDigest"].removeprefix("sha256:")
    original = check_zip(data)
    assert core["sourceRevision"] == SOURCE and core["runID"] == 46004241191
    for item in original.infolist():
        if not item.is_dir():
            assert z.read(item.filename) == original.read(item.filename)

# The selected historical library failure set deliberately omits one large video.
with zipfile.ZipFile(V / "published-02-library-failure-evidence.zip") as z:
    recovered = json.loads(z.read("recovered-originals-receipt.json"))
    payloads = {sha(z.read(name)): name for name in z.namelist() if name.startswith("mapped-attachments/")}
    recovered_presence = []
    for item in recovered:
        present = item["sha256"] in payloads
        recovered_presence.append({"name": item["name"], "sha256": item["sha256"], "included": present})
        assert present == (item["bytes"] < 3_000_000)
    assert sum(x["included"] for x in recovered_presence) == 3
    assert not any("library-full-original.zip" == p or "library-raw/" in p for p in z.namelist())

# Verify the current failed accessibility originals and lossless diagnostic logs.
with zipfile.ZipFile(V / "published-03-accessibility-attempt-1-evidence.zip") as z:
    compact = json.loads(z.read("archive-receipt.json"))
    data = z.read(compact["archive"])
    assert sha(data) == compact["sha256"] and len(data) == compact["bytes"]
    original = check_zip(data)
    for r in compact["files"]:
        raw = original.read(r["path"])
        assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
    diagnostic_results = []
    for item in json.loads(z.read("diagnostics-receipt.json")):
        raw = z.read("diagnostics/" + item["decoded"] + ".zstd")
        assert sha(raw) == item["compressedSHA256"] and len(raw) == item["compressedBytes"]
        with zstandard.ZstdDecompressor().stream_reader(io.BytesIO(raw)) as reader:
            decoded = reader.read(20_000_001)
        assert len(decoded) == item["decodedBytes"] and sha(decoded) == item["decodedSHA256"]
        diagnostic_results.append({"name": item["decoded"], "bytes": len(decoded), "sha256": sha(decoded)})
    failed = json.loads(z.read("reconciliation.json"))
    assert failed["sourceRevision"] == SOURCE and failed["run"] == 46004241191
    assert failed["passed"] == 0 and failed["failed"] == 1 and failed["AXXXLStarted"] is False
    assert failed["requiredDefaultPNGs"] == 5 and failed["requiredAXXXLPNGs"] == 0
    assert "current-accessibility-full-original.zip" not in z.namelist()

# Full commit-tree and changed-blob proof, independent of the receipt's wording.
publication = readj(ROOT / "campaign/publish-03.json")
assert (V / "publish-03.json").read_bytes() == (ROOT / "campaign/publish-03.json").read_bytes()
published, local, parent = (publication[k] for k in ["publishedCommit", "localEquivalent", "previousMain"])
assert published == SOURCE
for revision in [published, local]:
    assert git("rev-parse", revision + "^{tree}").decode().strip() == publication["completeTree"]
assert git("show", "-s", "--format=%P", published).decode().strip() == parent
assert git("diff", "--exit-code", local, published) == b""
changed = set(git("diff", "--name-only", parent, published).decode().splitlines())
assert changed == {r["path"] for r in publication["changedBlobs"]}
for item in publication["changedBlobs"]:
    blob = git("show", published + ":" + item["path"])
    assert len(blob) == item["bytes"]
    assert hashlib.sha1(b"blob " + str(len(blob)).encode() + b"\0" + blob).hexdigest() == item["sha"]
    mode = git("ls-tree", published, "--", item["path"]).decode().split()[0]
    assert mode == item["mode"]
request = publication["actualUpdateRequest"]
assert request["sha"] == published and request["expected_sha"] == parent and request["force"] is False
assert request["branch_name"] == "main" and publication["observedUpdateResponse"] == {"success": True}

# The bundle is an increment with a baseline prerequisite, never a full clone.
bundle_record = readj(V / "source-bundle-recovery.json")
bundle = REPO / bundle_record["bundle"]["path"]
assert sha(bundle.read_bytes()) == bundle_record["bundle"]["sha256"]
heads = git("bundle", "list-heads", str(bundle)).decode().splitlines()
assert len(heads) == 29
advertised = {row.split(" ", 1)[1]: row.split(" ", 1)[0] for row in heads}
assert advertised == {r["advertisedRef"]: r["commit"] for r in bundle_record["incrementalRecovery"]["recoveredRefs"]}
header = bundle.read_bytes().split(b"\n\n", 1)[0].decode()
prereq = [s[1:].split(" ", 1)[0] for s in header.splitlines() if s.startswith("-")]
assert prereq == bundle_record["bundle"]["declaredPrerequisites"]
assert bundle_record["isolation"]["excludedHistoricalBaselineBlobsMissing"] == 1305
assert bundle_record["incrementalRecovery"]["newReachableMissingObjects"] == 0
assert bundle_record["incrementalRecovery"]["missingObjectsExactlyUnchangedBaselineSet"] is True
recovery = ROOT / bundle_record["isolation"]["bareRepository"]
for entry in bundle_record["incrementalRecovery"]["recoveredRefs"]:
    assert git("rev-parse", entry["recoveredRef"], repo=recovery).decode().strip() == entry["commit"]

# Ledger identity/path consistency only. Completion authority remains actual worker finals.
ledger_path = ROOT / "campaign/worker-ledger.json"
ledger_bytes = ledger_path.read_bytes()
ledger = json.loads(ledger_bytes)
workers = ledger["workers"]
assert len(workers) == ledger["createdWorkers"]
assert len({r["agentId"] for r in workers}) == len(workers)
assert {r["number"] for r in workers} == set(range(1, len(workers) + 1))
review59 = next(r for r in workers if r["number"] == 59)
assert review59["assignmentRevision"] == review59["inputRevision"] == "2e35eb0d4a9b656c2ce8e0d63ae81d445ba69981"
assert review59["reviewedPatch"]["baseRevision"] == "b6fafbb77d1595e54d091393c9df4a7846be97e6"
assert review59["reviewedPatch"]["commit"] == "462cbf3cf1ba79208d9fe357b6fb20fbfa33a571"
assert "Assigned checkout revision" in review59["inputRevisionMeaning"]
reports = []
original_writer_refs = []
for worker in workers:
    number = worker["number"]
    assert worker["created"] is True and worker["report"] == f"agents/{number:03}.md"
    if "originalCommit" in worker:
        ref = f"refs/campaign/worker-{number:03}"
        assert advertised[ref] == worker["originalCommit"]
        original_writer_refs.append({"number": number, "ref": ref, "commit": advertised[ref]})
    report = ROOT / "campaign/reports" / f"{number:03}.md"
    copied = V.parent / worker["report"]
    item = {"number": number, "agentId": worker["agentId"], "declaredStatus": worker["status"],
        "reportExists": report.exists(), "integratedReportExists": copied.exists()}
    if report.exists():
        raw = report.read_text()
        normalized = "\n".join(s.rstrip() for s in raw.splitlines()).rstrip() + "\n"
        item["reportSHA256"] = sha(report.read_bytes())
        item["identityNamed"] = worker["agentId"] in raw
        item["declaredInputNamed"] = worker["inputRevision"] in raw
        if copied.exists():
            assert copied.read_text() == normalized
            item["copyMatchesAfterWhitespaceNormalization"] = True
    reports.append(item)

result = {"agent": "/root/a099_final_provenance_integrity", "sourceRevision": SOURCE,
    "archives": results, "totalArchiveEntries": sum(r["files"] for r in results),
    "totalRawBytes": sum(r["rawBytes"] for r in results),
    "libraryRecoveredOriginalSelection": recovered_presence,
    "accessibilityOriginalDiagnosticDecoding": diagnostic_results,
    "publication": {"published": published, "local": local, "parent": parent,
        "completeTree": publication["completeTree"], "changedPathsAndBlobs": len(changed),
        "recordedExpectedParentNonForce": True,
        "limit": "Local Git objects plus retained actual API request/response; not a fresh historical server-side lease attestation."},
    "incrementalBundle": {"sha256": sha(bundle.read_bytes()), "refs": len(heads), "prerequisites": prereq,
        "recoveredRefsMatch": True, "baselineMissingHistoricalBlobs": 1305,
        "newMissingObjects": 0, "originalWriterRefs": original_writer_refs, "fullBaselineFsckClaimed": False},
    "ledger": {"sha256": sha(ledger_bytes), "createdWorkers": len(workers),
        "reportedCompletedWorkers": ledger.get("completedWorkers"), "identityAndPathConsistency": True,
        "worker059AssignedVsReviewedSourceClarified": True,
        "completionNotInferredFromReportPresence": True, "reports": reports},
    "limits": ["No build, app, XCTest, benchmark, CI retry, remote mutation or descendant executed.",
               "Unfinished CI/runtime reports and the final100 ledger are outside this bounded checkpoint.",
               "Archive selection deliberately excludes separately identified large originals; original and derived provenance remains explicit."]}
args.output.write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({k: result[k] for k in ["totalArchiveEntries", "totalRawBytes", "publication", "incrementalBundle"]}, indent=2))
print("Ledger/source report consistency observations retained; completion status was not inferred.")
