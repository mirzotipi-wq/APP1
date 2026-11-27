"""Independent bounded integrity audit of retained attempt-one optics/export evidence.

Reads originals and Git objects; writes only worker 099's separate supplement03.
It does not execute the app, tests, recovery scripts, image viewers or remote tools.
"""
from pathlib import Path, PurePosixPath
import collections
import hashlib
import io
import json
import os
import re
import stat
import struct
import subprocess
import zipfile
import zstandard

ROOT = Path(__file__).resolve().parents[3]
REPO = ROOT / "APP1"
V = REPO / "docs/evidence/beta-campaign-2026-11-27/validation"
OUT = Path(__file__).resolve().parent
SOURCE = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
RUN = 46004241191
EXPECTED = "e9eac458f5b051836d0d22423688e7d3cec90029fdfe0624c5931b8a05b8bb95"
PREVIOUS = {
    "audit-result.json": "c4490e6cf739c214751aa72b80c38336b59aa32ef9c940b3e6ea60d63f742f2e",
    "supplement-01.json": "c4617dc966338d4d6544c5ff1a53066485217587019da550546c302f89ceb664",
    "supplement-02.json": "5ade450a64aa0b67bc9afa4f89f7aeec0d9893ef2f48d14b0c22471f45a10e26",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def file_sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()


def git(*args):
    return subprocess.check_output(["git", "-C", str(REPO), *args], env={
        **os.environ, "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1"})


def safe_zip(path_or_bytes, bound=150_000_000):
    z = zipfile.ZipFile(io.BytesIO(path_or_bytes) if isinstance(path_or_bytes, bytes) else path_or_bytes)
    names = z.namelist()
    assert len(names) == len(set(names)) == len({n.casefold() for n in names})
    assert sum(i.file_size for i in z.infolist()) <= bound
    for i in z.infolist():
        p = PurePosixPath(i.filename)
        assert not p.is_absolute() and ".." not in p.parts
        assert "\\" not in i.filename and ":" not in i.filename
        assert all(ord(c) >= 32 for c in i.filename)
        assert str(p) == i.filename.rstrip("/") and not i.flag_bits & 1
        assert stat.S_IFMT(i.external_attr >> 16) in (0, stat.S_IFREG, stat.S_IFDIR)
    assert z.testzip() is None
    return z


def original_path(name):
    prefix, tail = name.split("/", 1)
    if prefix == "root":
        return ROOT / "campaign" / tail
    if name == "worker061-title/report.md":
        return ROOT / "campaign/reports/061-followup-title.md"
    if prefix == "worker061-title":
        return ROOT / "campaign/evidence/061/followup-title" / tail
    if name == "worker098/report.md":
        return ROOT / "campaign/reports/098.md"
    if prefix == "worker098":
        return ROOT / "campaign/evidence/098" / tail
    assert prefix in ("studio-optics", "studio-export")
    return ROOT / "campaign/evidence/098" / name


def framed_scalar(text, key, start=0):
    """Read a length-framed XCTest scalar without truncating at content delimiters."""
    pattern = r"K" + str(len(key)) + ":" + re.escape(key) + r"\[(?:S\d+:\w+|T\[K2:_nV\d+:\w+\])K2:_vV(\d+):"
    match = re.search(pattern, text[start:])
    assert match, (key, start)
    begin = start + match.end()
    end = begin + int(match.group(1))
    assert text[end] == "]"
    return text[begin:end]


for name, digest in PREVIOUS.items():
    assert file_sha(OUT / name) == digest
index_path = V / "published-03-optics-export-attempt-1-evidence.json"
index = json.loads(index_path.read_bytes())
archive = index["archive"]
archive_path = V / archive["file"]
assert archive_path.stat().st_size == archive["bytes"] == 10_876_806
assert file_sha(archive_path) == archive["sha256"] == EXPECTED
assert index["sourceRevision"] == SOURCE and index["runId"] == RUN and index["runAttempt"] == 1
assert "not a full provider archive" in index["scope"]
assert "not a full provider archive or finalized successful result" in index["scope"]
z = safe_zip(archive_path)
assert len(z.namelist()) == len(index["entries"]) == archive["entryCount"] == 201
assert sum(i.file_size for i in z.infolist()) == archive["rawBytes"] == 87_835_057
assert len({r["path"] for r in index["entries"]}) == 201
assert {r["path"] for r in index["entries"]} == set(z.namelist())
mapping = []
for r in index["entries"]:
    raw = z.read(r["path"])
    original = original_path(r["path"])
    assert len(raw) == r["bytes"] == original.stat().st_size
    assert sha(raw) == r["sha256"] == file_sha(original)
    mapping.append({"entry": r["path"], "original": str(original.relative_to(ROOT)), "sha256": r["sha256"]})


def archived_json(path):
    return json.loads(z.read(path))


# Copied review receipts must be byte-identical to their archived original selections.
copied_dir = V / "published-03-ui-attempt-1-final"
copied = []
for path in sorted(copied_dir.iterdir()):
    matches = [n for n in z.namelist() if n.endswith("/" + path.name)]
    assert len(matches) == 1, (path.name, matches)
    assert path.read_bytes() == z.read(matches[0])
    copied.append({"file": path.name, "entry": matches[0], "sha256": file_sha(path)})
assert len(copied) == 13

# Exclusion declarations identify actual retained originals, not absent evidence.
assert len(index["excluded"]) == 4
for r in index["excluded"]:
    path = ROOT / r["source"]
    assert path.stat().st_size == r["bytes"] and file_sha(path) == r["sha256"]
    assert not any(n.endswith("full-original.zip") or n.endswith("native-results.zip") for n in z.namelist())
    assert r["reason"]
retention = archived_json("worker098/attempt1-retention-manifest.json")
assert retention["source"] == SOURCE and retention["run"] == RUN and retention["attempt"] == 1
for r in retention["files"]:
    path = ROOT / "campaign/evidence/098" / r["file"]
    assert path.stat().st_size == r["bytes"] and file_sha(path) == r["sha256"]
assert "Room first-attempt evidence is already in its separate archive" in index["scope"]

# Full provider ZIPs are excluded from the new ZIP but available for original comparison.
nested = {}
provider_results = {}
diagnostic_results = {}
for shard in ("studio-optics", "studio-export"):
    base = ROOT / "campaign/evidence/098" / shard
    for kind in ("compact", "full"):
        receipt = archived_json(shard + "/" + kind + "-receipt.json")
        meta = archived_json(shard + "/" + kind + "-metadata.json")
        original = base / (kind + "-original.zip")
        assert receipt["artifactID"] == meta["id"]
        assert original.stat().st_size == receipt["bytes"] == meta["size_in_bytes"]
        assert file_sha(original) == receipt["sha256"] == meta["digest"].removeprefix("sha256:")
        assert meta["workflow_run"]["head_sha"] == SOURCE and meta["workflow_run"]["id"] == RUN
        pz = safe_zip(original)
        assert len(receipt["files"]) == len(pz.namelist())
        assert {r["path"] for r in receipt["files"]} == set(pz.namelist())
        for r in receipt["files"]:
            raw = pz.read(r["path"])
            assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
            assert raw == (base / kind / r["path"]).read_bytes()
            selection = shard + "/" + kind + "/" + r["path"]
            if selection in z.namelist():
                assert raw == z.read(selection)
        provider_results[shard + "/" + kind] = {
            "artifactID": meta["id"], "entries": len(pz.namelist()), "sha256": receipt["sha256"]}
        pz.close()
    xc = safe_zip(base / "full/artifacts/native-results.zip")
    nested[shard] = xc
    assert not any(n.endswith("/Info.plist") for n in xc.namelist())
    assert len(xc.namelist()) == (118 if shard == "studio-optics" else 128)
    receipt = archived_json(shard + "/selected-diagnostics-receipt.json")
    records = receipt if isinstance(receipt, list) else receipt["selectedOriginals"]
    if isinstance(receipt, dict):
        assert file_sha(ROOT / receipt["nestedSource"]) == receipt["nestedSha256"]
    total = 0
    for r in records:
        member = r.get("originalMember", r.get("source"))
        path = ROOT / r["file"] if r["file"].startswith("campaign/") else base / r["file"]
        raw = xc.read(member)
        assert len(raw) == r["bytes"] == path.stat().st_size
        assert sha(raw) == r["sha256"] == file_sha(path)
        if "crc32" in r:
            assert f"{xc.getinfo(member).CRC:08x}" == r["crc32"]
        total += len(raw)
    diagnostic_results[shard] = {"selectedOriginals": len(records), "rawBytes": total}

# Bind inventories and expected method names to the historical compiled Git source.
inventory = archived_json("worker098/source-inventory.json")
review = archived_json("studio-export/source-review.json")
assert inventory["source"] == review["source"] == SOURCE
assert inventory["run"] == RUN
assert git("rev-parse", SOURCE + "^{tree}").decode().strip() == inventory["tree"]
source_hashes = {}
for sources in (inventory["sourceFiles"], review["files"]):
    for path, r in sources.items():
        raw = git("show", SOURCE + ":" + path)
        assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
        source_hashes[path] = r["sha256"]
reconciliation = archived_json("worker098/reconciliation.json")
assert reconciliation["source"] == SOURCE and reconciliation["run"] == RUN and reconciliation["runAttempt"] == 1
execution = {}
for shard in ("studio-optics", "studio-export"):
    expected = []
    for cls in inventory["shards"][shard]["classes"]:
        source = git("show", SOURCE + ":UITests/" + cls + ".swift").decode()
        expected.extend(cls + "." + m for m in re.findall(r"\bfunc\s+(test\w+)\s*\(", source))
    expected.sort()
    assert expected == inventory["shards"][shard]["methods"]
    native = z.read(shard + "/full/native-tests.log")
    console = z.read(shard + "/job.log")
    events = collections.defaultdict(list)
    console_events = collections.defaultdict(list)
    for payload, target in ((native, events), (console, console_events)):
        for cls, method, event in re.findall(r"Test Case '-\[KeyAndFillUITests\.(\w+) (\w+)\]' (started|passed|failed|skipped)", payload.decode()):
            target[cls + "." + method].append(event)
    assert dict(events) == dict(console_events)
    assert set(events) <= set(expected)
    ordered = {m: events.get(m, []) for m in expected}
    assert all(e in ([], ["started"], ["started", "passed"], ["started", "failed"]) for e in ordered.values())
    groups = {
        "passed": [m for m, e in ordered.items() if e == ["started", "passed"]],
        "failed": [m for m, e in ordered.items() if e == ["started", "failed"]],
        "incomplete": [m for m, e in ordered.items() if e == ["started"]],
        "unstarted": [m for m, e in ordered.items() if not e], "skipped": [],
    }
    record = reconciliation["shards"][shard]
    counts = {"expected": len(expected), "started": len(events), **{k: len(v) for k, v in groups.items()}}
    assert counts == record["execution"]["counts"]
    for group, methods in groups.items():
        assert methods == sorted(record["execution"][group])
    original_accounting = archived_json(shard + "/full/native-method-accounting.json")
    for group in ("passed", "failed", "unstarted", "skipped"):
        assert sorted(original_accounting[group]) == groups[group]
    assert sha(native) == record["originalNativeLogSHA256"]
    assert sha(console) == record["consoleSHA256"]
    assert record["status"] == "completed" and record["conclusion"] == "failure"
    assert record["finalizedXCResult"]["present"] is False
    assert not record["finalizedXCResult"]["matchingInfoPlists"]
    execution[shard] = {"counts": counts, "groups": groups, "orderedEvents": ordered, "finalizedResult": False}
assert execution["studio-export"]["counts"] == {
    "expected": 19, "started": 14, "passed": 9, "failed": 4, "incomplete": 1, "unstarted": 5, "skipped": 0}
assert execution["studio-optics"]["counts"] == {
    "expected": 10, "started": 0, "passed": 0, "failed": 0, "incomplete": 0, "unstarted": 10, "skipped": 0}

# Recover original length-framed Data independently; do not run worker 098's decoder.
data_receipt = archived_json("studio-export/recovered-data-receipt.json")
assert len(data_receipt) == 53
decoded_objects = {}
payload_by_member = {}
method_metadata = {}
for r in data_receipt:
    raw = nested["studio-export"].read(r["member"])
    assert len(raw) == r["rawBytes"] and sha(raw) == r["rawSHA256"]
    if raw.startswith(b"\x28\xb5\x2f\xfd"):
        assert raw == (ROOT / r["originalCompressedFile"]).read_bytes()
        with zstandard.ZstdDecompressor().stream_reader(io.BytesIO(raw)) as reader:
            decoded = reader.read(2_000_001)
        assert len(decoded) <= 2_000_000
    else:
        decoded = raw
    assert len(decoded) == r["decodedBytes"] and sha(decoded) == r["decodedSHA256"]
    assert decoded == (ROOT / r["decodedFile"]).read_bytes()
    decoded_objects[r["decodedFile"]] = decoded
    payload_by_member[r["member"]] = r
    if r["kind"] == "txt" and decoded.startswith(b"[T[K2:_nV17:ActionTestSummary"):
        txt = decoded.decode()
        method = framed_scalar(txt, "identifier")
        status = framed_scalar(txt, "testStatus")
        assert method not in method_metadata
        simple = method.removesuffix("()").replace("/", ".")
        assert simple in execution["studio-export"]["groups"]["passed" if status == "Success" else "failed"]
        assert status in ("Success", "Failure")
        method_metadata[method] = {"status": status, "metadata": r["decodedFile"], "metadataSHA256": sha(decoded)}
recovered = archived_json("studio-export/recovered-attachment-reconciliation.json")
assert recovered["source"] == SOURCE and recovered["run"] == RUN and recovered["runAttempt"] == 1
assert len(method_metadata) == len(recovered["methods"]) == 13
assert {m["method"]: {k: v for k, v in m.items() if k != "method"} for m in recovered["methods"]} == method_metadata
assert collections.Counter(r["status"] for r in method_metadata.values()) == {"Success": 9, "Failure": 4}
assert method_metadata["StudioSmokeTests/testCorruptProjectBlocksSavingAcrossRelaunch()"]["status"] == "Success"

attachments = []
for method, r in method_metadata.items():
    txt = decoded_objects[r["metadata"]].decode()
    starts = [m.start() for m in re.finditer(r"K8:filename\[", txt)]
    for pos, end in zip(starts, starts[1:] + [len(txt)]):
        section = txt[pos:end]
        ref_start = section.index("K10:payloadRef")
        attachments.append({"method": method, "metadata": r["metadata"],
            "name": framed_scalar(section, "name"), "originalFilename": framed_scalar(section, "filename"),
            "payloadRef": framed_scalar(section, "id", ref_start),
            "payloadBytes": int(framed_scalar(section, "payloadSize")),
            "type": framed_scalar(section, "uniformTypeIdentifier")})
assert len(attachments) == len(recovered["attachments"]) == 91
retained_attachments = []
for expected_attachment, recorded in zip(attachments, recovered["attachments"]):
    assert all(recorded[k] == value for k, value in expected_attachment.items())
    member = "NativeTests.xcresult/Data/data." + recorded["payloadRef"]
    payload = nested["studio-export"].read(member)
    if "file" in recorded:
        r = payload_by_member[member]
        assert r["decodedFile"] == recorded["file"]
        assert r["decodedSHA256"] == recorded["sha256"]
        assert r["decodedBytes"] == recorded["payloadBytes"]
    else:
        assert recorded["type"] == "public.mpeg-4"
        assert len(payload) == recorded["payloadBytes"]
        retained_attachments.append({"member": member, "bytes": len(payload), "sha256": sha(payload),
            "selectedSeparately": recorded["method"].startswith("BetaAccessibilityUITests/")})
assert len(retained_attachments) == 4
assert len(recovered["originalPNGs"]) == 4
for r in recovered["originalPNGs"]:
    raw = decoded_objects[r["file"]]
    assert raw.startswith(b"\x89PNG\r\n\x1a\n") and raw[12:16] == b"IHDR"
    assert list(struct.unpack(">II", raw[16:24])) == r["dimensions"] == [1206, 2622]
    assert r["type"] == "public.png" and sha(raw) == r["sha256"]
assert recovered["requiredSupplementalPNGs"] == 8 and recovered["recoveredSupplementalPNGs"] == 0
assert len(inventory["expectedSupplementalCaptureSuffixes"]) == len(review["requiredSupplemental"]) == 8
assert not any(r["name"].startswith("Supplemental-") and r["type"] == "public.png" for r in recovered["attachments"])

# Original video and derived frame have separate provenance and are not supplemental screenshots.
video = archived_json("studio-export/beta-recording-receipt.json")
video_raw = nested["studio-export"].read(video["member"])
assert len(video_raw) == video["bytes"] == 1_753_321
assert sha(video_raw) == video["sha256"] == "55348a673f5ac47d4fdc47e2f2889ec186d788f8673b33c34983b001006a047f"
assert video_raw == (ROOT / video["file"]).read_bytes()
assert f"{nested['studio-export'].getinfo(video['member']).CRC:08x}" == video["crc32"]
assert video["isOriginal"] is True and video["notASupplementalPNG"] is True
title = archived_json("worker061-title/receipt.json")
assert title["inputSHA"] == SOURCE and title["run"] == RUN
assert title["originalRecording"]["sha256"] == video["sha256"]
assert file_sha(Path(title["observation"]["path"])) == title["observation"]["sha256"]
assert title["observation"]["text"] in Path(title["observation"]["path"]).read_text()
frame = title["derivedFrame"]
assert frame["kind"] == "video-derived PNG, not an original XCTest screenshot attachment"
assert file_sha(Path(frame["path"])) == frame["sha256"] == "71daee0e49b8120af33cb3c4387da4296e08e91c53e0a15def7505aec420ec93"
assert title["observedTitle"]["observedPixels"] == 587 < 591 == title["observedTitle"]["requiredPixels"]

# Every quoted session/recovery excerpt is an exact original-log slice.
excerpt_count = 0
for name in ("recovery-excerpts.json", "failure-session-excerpts.json"):
    receipt = archived_json("studio-export/" + name)
    for excerpt in receipt["excerpts"]:
        path = ROOT / excerpt.get("file", receipt.get("source", ""))
        assert file_sha(path) == receipt["sourceSHA256"]
        lines = path.read_text().splitlines()
        assert lines[excerpt["fromLine"] - 1:excerpt["toLine"]] == excerpt["lines"]
        excerpt_count += 1

# Current app-wide visual obligation: 14 names in each of two categories, 5 originals emitted.
terminal = archived_json("root/current-source-attempt-1-terminal.json")
assert terminal["sourceRevision"] == SOURCE and terminal["runId"] == RUN and terminal["runAttempt"] == 1
ax_source = git("show", SOURCE + ":UITests/StudioAppAccessibilityUITests.swift").decode()
suffixes = re.findall(r'capture\(name \+ "(-[^"]+)"', ax_source)
assert len(suffixes) == len(set(suffixes)) == 14
ax_evidence = []
for job in terminal["visualReview"]:
    assert job["conclusion"] == "failure"
    for summary in job["summary"]:
        category = summary["category"]
        required = {category + suffix for suffix in suffixes}
        images = job["imageMetadata"]
        emitted = {r["name"] for r in images} & required
        assert summary["images"] == len(images)
        assert summary["requiredImages"] == len(emitted)
        assert set(summary["missing"]) == required - emitted
        assert summary["sourceRevision"] == SOURCE
        assert all(r["sourceRevision"] == SOURCE for r in images)
        ax_evidence.append({"category": category, "required": 14, "requiredOriginals": len(emitted),
            "allOriginalsIncludingFailureCapture": len(images), "missing": sorted(required - emitted)})
assert {r["category"]: r["requiredOriginals"] for r in ax_evidence} == {"Default": 5, "AXXXL": 0}

# Exact historical publication proof; no assertion about today's main or later production changes.
publication = archived_json("root/publish-04.json")
verification = archived_json("root/publish-04-verification.json")
published, local, parent = (publication[k] for k in ("publishedCommit", "localEquivalent", "previousMain"))
assert published == "9e2313cbffb01d66249458c64087cb66c7652cca"
assert local == "7e069deb2395d620aa59555ed00541557f1dd41e" and parent == SOURCE
assert git("rev-parse", published + "^@").decode().splitlines() == [parent]
assert git("rev-parse", published + "^{tree}").decode().strip() == publication["completeTree"]
assert git("rev-parse", local + "^{tree}").decode().strip() == publication["completeTree"]
assert not git("diff", "--name-only", published, local)
changed = git("diff", "--name-only", parent, published).decode().splitlines()
assert len(changed) == len(publication["changedPaths"]) == 129
assert set(changed) == {r["path"] for r in publication["changedPaths"]}
assert all(path.endswith(".md") or path.startswith(("docs/", "agents/")) for path in changed)
for r in publication["changedPaths"]:
    mode, kind, oid, path = git("ls-tree", published, "--", r["path"]).decode().strip().split(None, 3)
    assert (mode, kind, oid, path) == (r["mode"], r["type"], r["sha"], r["path"])
    raw = git("cat-file", "blob", oid)
    assert len(raw) == r["size"]
    assert hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest() == oid
assert publication["compiledSource"] == verification["compiledSource"] == SOURCE
assert publication["actualUpdateRequest"] == {
    "repository_full_name": "mirzotipi-wq/APP1", "branch_name": "main", "sha": published,
    "expected_sha": parent, "force": False}
assert publication["observedUpdateResponse"] == {"success": True}
for key in ("publishedCommit", "localEquivalent", "completeTree"):
    assert verification[key] == publication[key]
assert verification["mainBefore"]["object"]["sha"] == parent
assert verification["mainAfter"]["object"]["sha"] == published
assert verification["sourceRun"] == RUN and verification["sourceRunNotSuperseded"] is True
for name, digest in PREVIOUS.items():
    assert file_sha(OUT / name) == digest

result = {
    "agent": "/root/a099_final_provenance_integrity", "sameIdentityFollowup": True,
    "sourceRevision": SOURCE, "run": RUN, "runAttempt": 1,
    "archive": archive, "indexSHA256": file_sha(index_path),
    "allArchiveEntryHashesCRCSafeUniqueNamesAndScratchOriginalsMatch": True,
    "entrySourceMappings": mapping, "copiedReceipts": copied,
    "excludedOriginalArchivesHashVerified": index["excluded"],
    "retentionManifestFilesVerified": len(retention["files"]),
    "retentionManifestRoomScope": "Room evidence and its explicit large exclusions remain in the separate previously audited archive; this ZIP does not claim to contain them.",
    "originalProviderChecks": provider_results, "originalDiagnostics": diagnostic_results,
    "sourceHashes": source_hashes, "execution": execution,
    "rawDataObjectsDecodedAndVerified": 53,
    "completedOriginalMethodMetadata": method_metadata,
    "attachmentMetadataVerified": 91, "originalPNGsVerifiedWithoutViewing": 4,
    "recordingReferencesOutsideRecoveredDataSelection": retained_attachments,
    "originalTitleRecording": video,
    "derivedTitleFrame": {"sha256": frame["sha256"], "kind": frame["kind"], "newViewingOrRerenderPerformed": False},
    "exactOriginalLogExcerptsVerified": excerpt_count,
    "appAccessibilityVisuals": ax_evidence,
    "supplementalVisuals": {"required": 8, "originals": 0},
    "publish04": {"publishedCommit": published, "localEquivalent": local, "parent": parent,
        "completeTree": publication["completeTree"], "changedPathsAndBlobContentsVerified": len(changed),
        "documentationEvidenceOnly": True, "recordedExpectedSHA": parent, "recordedForce": False,
        "requestEvidence": "Retained exact request and recorded API response; no new remote query or write."},
    "previousReceiptsUnchanged": PREVIOUS,
    "limits": [
        "This audit binds historical f94 attempt1; it does not accept later source3290, complete worker followups, or promote a beta milestone.",
        "No app/test/build execution, new image viewing, source edits, remote queries, remote writes or descendant agents.",
        "Unfinalized optics and export results remain failures/incomplete; successful individual metadata is not whole-shard success.",
        "The corrupt-project smoke method has original Success metadata, narrower than the independently failed recovery workflow.",
        "The video-derived title frame is not an original XCTest screenshot and does not pass the failed587-versus591 threshold.",
        "Worker098/061 visual observations are retained and source-bound; worker099 did not independently view images."
    ],
}
(OUT / "supplement-03.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"entries": 201, "rawBytes": archive["rawBytes"], "copiedReceipts": len(copied),
    "originalDataObjects": 53, "completedMetadata": 13, "originalPNGs": 4,
    "exportCounts": execution["studio-export"]["counts"], "opticsCounts": execution["studio-optics"]["counts"],
    "sourceHashes": len(source_hashes), "publish04ChangedPaths": len(changed),
    "receiptSHA256": file_sha(OUT / "supplement-03.json")}, indent=2))
