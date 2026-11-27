"""Bounded supplement04: incremental follow-up source and preserved review provenance.

Read-only for APP1 and other workers. No builds, test execution, ref mutation,
network access or full historical-baseline traversal. Parses all new bundle pack
objects directly rather than importing into or repairing any repository.
"""
from pathlib import Path, PurePosixPath
import collections
import hashlib
import io
import json
import os
import re
import stat
import subprocess
import zlib
import zipfile

ROOT = Path(__file__).resolve().parents[3]
REPO = ROOT / "APP1"
V = REPO / "docs/evidence/beta-campaign-2026-11-27/validation"
OUT = Path(__file__).resolve().parent
SOURCE = "2fc7647314d3ae6fa22d95284e778c6c5badbe4a"
LOCAL = "b79ff3294ef6743a660c27e372fe4cab798f1e1a"
CHECKPOINT = "15c0e6e60d35ff263a5014c4dd74998cd9e5a70f"
PARENT = "9e2313cbffb01d66249458c64087cb66c7652cca"
F94 = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
TITLE = "84ade7af5f8563d43d31b1e83931f58af4644821"
TRACE = "85f428e4395a2435f639c60fe4ab8c88300af62d"
TRACE_FIRST = "52fbadd55ff67ef2e9eabbf8ef7e103228536c11"
PREVIOUS = {
    "audit-result.json": "c4490e6cf739c214751aa72b80c38336b59aa32ef9c940b3e6ea60d63f742f2e",
    "supplement-01.json": "c4617dc966338d4d6544c5ff1a53066485217587019da550546c302f89ceb664",
    "supplement-02.json": "5ade450a64aa0b67bc9afa4f89f7aeec0d9893ef2f48d14b0c22471f45a10e26",
    "supplement-03.json": "f2255d9e83f5a628e10f71d26e23f6a510d85c162f1d35a070bd3ba84dab4c8a",
}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def git(*args):
    return subprocess.check_output(["git", "-C", str(REPO), *args], env={
        **os.environ, "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1"})


def git_object_id(kind, raw):
    return hashlib.sha1(kind.encode() + b" " + str(len(raw)).encode() + b"\0" + raw).hexdigest()


def safe_zip(path):
    z = zipfile.ZipFile(path)
    names = z.namelist()
    assert len(names) == len(set(names)) == len({n.casefold() for n in names})
    assert sum(i.file_size for i in z.infolist()) <= 200_000
    for i in z.infolist():
        p = PurePosixPath(i.filename)
        assert not p.is_absolute() and ".." not in p.parts
        assert "\\" not in i.filename and ":" not in i.filename
        assert all(ord(c) >= 32 for c in i.filename)
        assert str(p) == i.filename.rstrip("/") and not i.flag_bits & 1
        assert stat.S_IFMT(i.external_attr >> 16) in (0, stat.S_IFREG, stat.S_IFDIR)
    assert z.testzip() is None
    return z


for name, digest in PREVIOUS.items():
    assert sha((OUT / name).read_bytes()) == digest

# Verify the 22 selections against index, original scratch sources and primary copies.
index_path = V / "published-05-source-review.json"
index = json.loads(index_path.read_bytes())
archive = index["archive"]
archive_path = V / archive["file"]
assert index["sourceRevision"] == SOURCE
assert len(archive_path.read_bytes()) == archive["bytes"] == 41418
assert sha(archive_path.read_bytes()) == archive["sha256"] == "c51772956d0aa7189cf4e86f9a0251e6cababff091795a657b700430d54a1088"
z = safe_zip(archive_path)
assert len(z.namelist()) == len(index["entries"]) == archive["entries"] == 22
assert sum(i.file_size for i in z.infolist()) == archive["rawBytes"] == 127257
assert len({r["path"] for r in index["entries"]}) == 22
assert set(z.namelist()) == {r["path"] for r in index["entries"]}
special = {
    "root/tooling-104.log": "campaign/followup-tooling.log",
    "worker001/report.md": "campaign/reports/001-followup.md",
    "worker002/report.md": "campaign/reports/002-followup.md",
    "worker002/receipt.json": "campaign/evidence/002/followup-review-receipt.json",
}
mapping = []
for r in index["entries"]:
    prefix, name = r["path"].split("/", 1)
    original = special.get(r["path"])
    if original is None:
        worker = prefix.removeprefix("worker")
        original = "campaign/evidence/" + worker + ("/followup/" if worker == "001" else "/") + name
    raw = z.read(r["path"])
    assert len(raw) == r["bytes"] and sha(raw) == r["sha256"]
    assert raw == (ROOT / original).read_bytes()
    mapping.append({"entry": r["path"], "original": original, "sha256": r["sha256"]})
assert "not UIKit execution or fresh Apple acceptance" in index["scope"]
assert "executable/module cache are excluded reproducible build products" in index["scope"]
assert "separate optics/export attempt1 archive" in index["scope"]
assert not any("module-cache" in n or n == "worker001/recorder-witness" for n in z.namelist())
copies = {
    "worker001.json": "campaign/evidence/001/followup/followup-review-receipt.json",
    "worker002.json": "campaign/evidence/002/followup-review-receipt.json",
    "worker096.json": "campaign/evidence/096/followup-receipt.json",
    "worker100-title.json": "campaign/evidence/100/title-probe-review.json",
    "worker100-followup.json": "campaign/evidence/100/followup-review.json",
    "publish-05.json": "campaign/publish-05.json",
    "publication-verification.json": "campaign/publish-05-verification.json",
}
copy_records = []
assert {p.name for p in (V / "published-05-source-review").iterdir()} == set(copies)
for name, original in copies.items():
    raw = (V / "published-05-source-review" / name).read_bytes()
    assert raw == (ROOT / original).read_bytes()
    copy_records.append({"name": name, "original": original, "sha256": sha(raw)})

# Exact publication data, including reconstructed UTF-8 transport and binary blob.
publication = json.loads((ROOT / "campaign/publish-05.json").read_bytes())
manifest = json.loads((ROOT / "campaign/publish-05-manifest.json").read_bytes())
verification = json.loads((ROOT / "campaign/publish-05-verification.json").read_bytes())
summary = publication["summary"]
assert summary == json.loads((ROOT / "campaign/publish-05-summary.json").read_bytes())
for key in ("old", "local", "tree", "baseTree"):
    assert manifest[key] == summary[key]
assert summary["old"] == PARENT and summary["local"] == LOCAL
assert publication["published"]["sha"] == SOURCE
assert git("rev-parse", SOURCE + "^@").decode().splitlines() == [PARENT]
assert git("rev-parse", LOCAL + "^@").decode().splitlines() == [CHECKPOINT]
assert git("rev-parse", "refs/heads/campaign/local-fifth-checkpoint").decode().strip() == LOCAL
tree = "22d3beb8cc672dba4227ca8dbe0a7aa7499ad206"
assert git("rev-parse", SOURCE + "^{tree}").decode().strip() == tree == summary["tree"] == publication["createdTree"]["sha"]
assert git("rev-parse", LOCAL + "^{tree}").decode().strip() == tree
assert git("rev-parse", PARENT + "^{tree}").decode().strip() == summary["baseTree"]
assert not git("diff", "--name-only", SOURCE, LOCAL)
changed = git("diff", "--name-only", PARENT, SOURCE).decode().splitlines()
assert len(changed) == len(manifest["paths"]) == summary["changedPaths"] == 15
assert set(changed) == {r["path"] for r in manifest["paths"]}
assert sum(r["size"] for r in manifest["paths"]) == summary["bytes"] == 300281
for r in manifest["paths"]:
    actual = git("ls-tree", SOURCE, "--", r["path"]).decode().strip().split(None, 3)
    assert actual == [r["mode"], r["type"], r["sha"], r["path"]]
    raw = git("cat-file", "blob", r["sha"])
    assert len(raw) == r["size"] and git_object_id("blob", raw) == r["sha"]
parts = []
for i in range(summary["textParts"]):
    part = json.loads((ROOT / f"campaign/publish-05-text-{i:03}.json").read_bytes())
    assert part["index"] == i
    parts.append(part["text"])
text_objects = json.loads("".join(parts))
assert len(text_objects) == summary["textFiles"] == 14
assert {r["path"] for r in text_objects} == {r["path"] for r in manifest["paths"] if r["utf8"]}
for r in text_objects:
    assert r["content"].encode() == git("show", SOURCE + ":" + r["path"])
assert publication["updateRequest"] == {
    "repository_full_name": "mirzotipi-wq/APP1", "branch_name": "main", "sha": SOURCE,
    "expected_sha": PARENT, "force": False}
assert publication["updateResponse"] == {"success": True}
assert publication["remoteBefore"]["object"]["sha"] == PARENT
assert verification["publishedCommit"] == SOURCE and verification["localEquivalent"] == LOCAL
assert verification["completeTree"] == tree
assert verification["mainBefore"]["object"]["sha"] == PARENT and verification["mainAfter"]["object"]["sha"] == SOURCE
assert verification["sourceRun"] == 46019722045
assert all(r["head_sha"] == SOURCE for r in verification["workflowObservations"])

# Bundle header and checksum identify a small incremental pack with explicit prerequisites.
bundle_path = V / "local-ui-followup-source.bundle"
bundle_receipt_path = V / "local-ui-followup-source.json"
bundle_receipt = json.loads(bundle_receipt_path.read_bytes())
bundle_raw = bundle_path.read_bytes()
assert len(bundle_raw) == bundle_receipt["bytes"] == 30625
assert sha(bundle_raw) == bundle_receipt["sha256"] == "3112861c945cd20d53e03a42420547c0e4db99dda9da34ff571f1d1346d2ef6f"
assert bundle_raw == git("show", SOURCE + ":" + str(bundle_path.relative_to(REPO)))
assert bundle_receipt_path.read_bytes() == git("show", SOURCE + ":" + str(bundle_receipt_path.relative_to(REPO)))
assert "Not a full historical-baseline object-integrity claim" in bundle_receipt["scope"]
header_raw, pack = bundle_raw.split(b"\n\n", 1)
header = header_raw.decode().splitlines()
assert header[0] == "# v2 git bundle"
prerequisites = {line[1:].split(" ", 1)[0] for line in header[1:] if line.startswith("-")}
heads = [line for line in header[1:] if not line.startswith("-")]
assert prerequisites == {PARENT, F94}
assert heads == bundle_receipt["heads"] == git("bundle", "list-heads", str(bundle_path)).decode().splitlines()
assert heads == [CHECKPOINT + " refs/heads/main", TITLE + " refs/campaign/worker-061-followup-title",
    TRACE + " refs/campaign/worker-096-followup-trace"]
verification_process = subprocess.run(["git", "-C", str(REPO), "bundle", "verify", str(bundle_path)],
    env={**os.environ, "GIT_NO_LAZY_FETCH": "1", "GIT_NO_REPLACE_OBJECTS": "1"}, capture_output=True, check=True)
assert verification_process.stdout.decode() == bundle_receipt["verifyStdout"]
assert verification_process.stderr.decode() == bundle_receipt["verifyStderr"]
assert pack[:4] == b"PACK" and int.from_bytes(pack[4:8], "big") == 2
assert hashlib.sha1(pack[:-20]).digest() == pack[-20:]
count = int.from_bytes(pack[8:12], "big")
assert count == 51

# Parse all pack entries, including Git deltas. No files/objects are imported.
packed = {}
pos = 12
for _ in range(count):
    offset = pos
    byte = pack[pos]
    pos += 1
    kind, size, shift = (byte >> 4) & 7, byte & 15, 4
    while byte & 128:
        byte = pack[pos]
        pos += 1
        size |= (byte & 127) << shift
        shift += 7
    base = None
    if kind == 6:
        byte = pack[pos]
        pos += 1
        distance = byte & 127
        while byte & 128:
            byte = pack[pos]
            pos += 1
            distance = ((distance + 1) << 7) | (byte & 127)
        base = offset - distance
        assert base in packed
    elif kind == 7:
        base = pack[pos:pos + 20].hex()
        pos += 20
    else:
        assert kind in (1, 2, 3, 4)
    decoder = zlib.decompressobj()
    encoded = pack[pos:-20]
    raw = decoder.decompress(encoded)
    assert decoder.eof and len(raw) == size
    pos += len(encoded) - len(decoder.unused_data)
    packed[offset] = {"kind": kind, "base": base, "raw": raw}
assert pos == len(pack) - 20


def delta_integer(delta, position):
    value, shift = 0, 0
    while True:
        byte = delta[position]
        position += 1
        value |= (byte & 127) << shift
        if not byte & 128:
            return value, position
        shift += 7


def apply_delta(base, delta):
    before, at = delta_integer(delta, 0)
    after, at = delta_integer(delta, at)
    assert len(base) == before and after < 1_000_000
    result = bytearray()
    while at < len(delta):
        command = delta[at]
        at += 1
        assert command
        if command & 128:
            start, length = 0, 0
            for bit in range(4):
                if command & (1 << bit):
                    start |= delta[at] << (8 * bit)
                    at += 1
            for bit in range(3):
                if command & (1 << (bit + 4)):
                    length |= delta[at] << (8 * bit)
                    at += 1
            length = length or 0x10000
            assert start + length <= len(base)
            result.extend(base[start:start + length])
        else:
            assert at + command <= len(delta)
            result.extend(delta[at:at + command])
            at += command
    assert len(result) == after
    return bytes(result)


resolved = {}
objects = {}
reference_bases = {}


def resolve(offset):
    if offset in resolved:
        return resolved[offset]
    entry = packed[offset]
    if entry["kind"] in (6, 7):
        if entry["kind"] == 6:
            kind, base = resolve(entry["base"])
        else:
            oid = entry["base"]
            kind = git("cat-file", "-t", oid).decode().strip()
            base = git("cat-file", kind, oid)
            assert git_object_id(kind, base) == oid
            reference_bases[oid] = {"kind": kind, "bytes": len(base)}
        raw = apply_delta(base, entry["raw"])
    else:
        kind = {1: "commit", 2: "tree", 3: "blob", 4: "tag"}[entry["kind"]]
        raw = entry["raw"]
    oid = git_object_id(kind, raw)
    assert raw == git("cat-file", kind, oid)
    assert oid not in objects
    objects[oid] = (kind, raw)
    resolved[offset] = (kind, raw)
    return kind, raw


for offset in packed:
    resolve(offset)
assert len(objects) == count
new_commits = set()


def walk_new_commits(oid):
    if oid in prerequisites or oid in new_commits:
        return
    assert oid in objects and objects[oid][0] == "commit"
    new_commits.add(oid)
    parents = re.findall(rb"^parent ([0-9a-f]{40})$", objects[oid][1], re.M)
    assert parents
    for parent in parents:
        walk_new_commits(parent.decode())


for line in heads:
    walk_new_commits(line.split()[0])
assert {oid for oid, (kind, _) in objects.items() if kind == "commit"} == new_commits
assert {TITLE, TRACE_FIRST, TRACE, CHECKPOINT} <= new_commits
assert git("rev-parse", TRACE + "^@").decode().splitlines() == [TRACE_FIRST]
assert git("rev-parse", TRACE_FIRST + "^@").decode().splitlines() == [F94]
assert git("rev-parse", TITLE + "^@").decode().splitlines() == [F94]
bundle_delta = git("diff", "--name-only", CHECKPOINT, LOCAL).decode().splitlines()
assert set(bundle_delta) == {str(bundle_path.relative_to(REPO)), str(bundle_receipt_path.relative_to(REPO))}
source_paths = [p for p in changed if not (p.endswith(".md") or p.startswith("docs/"))]
for path in source_paths:
    raw = git("show", SOURCE + ":" + path)
    assert raw == git("show", CHECKPOINT + ":" + path)
    assert git_object_id("blob", raw) in objects

# Each review retains its actual review revision. Compare hashes there, then identify
# exact integrated matches without promoting candidate review to runtime acceptance.
receipts = {name: json.loads(z.read(path)) for name, path in {
    "001": "worker001/followup-review-receipt.json", "002": "worker002/receipt.json",
    "096": "worker096/followup-receipt.json", "100-title": "worker100/title-probe-review.json",
    "100-interim": "worker100/followup-review.json"}.items()}
bindings = []
review_specs = [
    ("001", receipts["001"]["reviewedRevision"], receipts["001"]["filesSHA256"]),
    ("002", receipts["002"]["reviewedCandidateCommit"], receipts["002"]["reviewedFilesSHA256"]),
    ("096", receipts["096"]["commits"][-1], {r["path"]: r["sha256"] for r in receipts["096"]["files"]}),
    ("100-title", receipts["100-title"]["candidate"], receipts["100-title"]["candidateSourceHashes"]),
]
for worker, revision, hashes in review_specs:
    for path, digest in hashes.items():
        raw = git("show", revision + ":" + path)
        assert sha(raw) == digest
        bindings.append({"reviewer": worker, "reviewedRevision": revision, "path": path,
            "sha256": digest, "identicalInPublishedSource": raw == git("show", SOURCE + ":" + path)})
addendum = receipts["002"]["addendum"]
assert sha(git("show", receipts["002"]["reviewedAddendumCommit"] + ":" + addendum["file"])) == addendum["sha256"]
assert sha(git("show", SOURCE + ":" + addendum["file"])) == addendum["sha256"]
assert receipts["001"]["baselineRevision"] == receipts["096"]["base"] == F94
assert receipts["001"]["reviewedRevision"] == TRACE
assert receipts["096"]["commits"] == [TRACE_FIRST, TRACE]
assert receipts["096"]["nativeExecution"] is False and receipts["096"]["portableOrNativeBuild"] is False
assert receipts["096"]["checks"][0]["outcome"].startswith("failed invocation")
assert receipts["096"]["checks"][0]["combinedShellExitCode"] == 0
assert receipts["100-title"]["candidate"] == TITLE
assert receipts["100-interim"]["sourceRevision"] == F94
assert receipts["100-interim"]["documentationHead"] == PARENT
assert "final runtime" in receipts["100-interim"]["status"]
assert "pending actual Apple" in receipts["100-title"]["recommendation"]

# Derived recorder extraction and Release-stripped source match their pinned source.
trace_source = git("show", TRACE + ":App/StudioTextField.swift").decode()
start = trace_source.index("#if DEBUG\n/// Opt-in process diagnostics")
assert z.read("worker001/recorder-extracted.swift") == ("import Foundation\n\n" + trace_source[start:]).encode()
stripped, depth = [], 0
for line in trace_source.splitlines():
    if line.strip() == "#if DEBUG":
        depth += 1
    elif depth and line.strip() == "#endif":
        depth -= 1
    elif not depth:
        stripped.append(line)
    else:
        assert not line.lstrip().startswith(("#if ", "#else", "#elseif"))
assert depth == 0 and z.read("worker001/release-stripped.swift") == "\n".join(stripped).encode()
assert z.read("worker001/recorder-witness.log").decode().startswith("PASS: exact recorder compiled;")
tooling = z.read("root/tooling-104.log").decode()
starts = list(re.finditer(r"^test_", tooling, re.M))
assert len(starts) == 104 and re.search(r"^Ran 104 tests in [\d.]+s\n\nOK\s*$", tooling, re.M)
for match, stop in zip(starts, [m.start() for m in starts[1:]] + [len(tooling)]):
    chunk = tooling[match.start():stop]
    assert re.search(r"(?:\.\.\. |\n)ok(?:\n|$)", chunk)
for name, digest in PREVIOUS.items():
    assert sha((OUT / name).read_bytes()) == digest

result = {
    "agent": "/root/a099_final_provenance_integrity", "sameIdentityFollowup": True,
    "sourceRevision": SOURCE, "archive": archive, "indexSHA256": sha(index_path.read_bytes()),
    "allArchiveEntryHashesCRCSafeUniqueNamesAndOriginalBytesMatch": True,
    "entrySourceMappings": mapping, "readablePrimaryCopies": copy_records,
    "publication05": {"published": SOURCE, "localEquivalent": LOCAL, "parent": PARENT,
        "completeTree": tree, "preservedLocalBranch": "campaign/local-fifth-checkpoint",
        "all15PathsModesBlobsSizesVerified": manifest["paths"], "changedBytes": 300281,
        "utf8TransportPartsReassembled": 11, "utf8FilesVerified": 14,
        "actualRecordedExpectedSHA": PARENT, "actualRecordedForce": False,
        "receiptSHA256": sha((ROOT / "campaign/publish-05.json").read_bytes()),
        "verificationSHA256": sha((ROOT / "campaign/publish-05-verification.json").read_bytes())},
    "incrementalBundle": {"bytes": len(bundle_raw), "sha256": sha(bundle_raw),
        "receiptSHA256": sha(bundle_receipt_path.read_bytes()), "heads": heads,
        "prerequisites": sorted(prerequisites), "packSHA1": pack[-20:].hex(),
        "packObjectCount": count, "packObjectKinds": dict(collections.Counter(k for k, _ in objects.values())),
        "allNewPackObjectsIndependentlyParsedHashedAndCompared": True,
        "newCommitClosureStopsAtDeclaredPrerequisites": sorted(new_commits),
        "referenceDeltaBasesReadFromExistingObjects": reference_bases,
        "sourcePathsIdenticalBetweenBundledCheckpointAndPublishedCommit": source_paths,
        "postBundleLocalCommitChangesOnlyBundleAndReceipt": bundle_delta,
        "scope": "Incremental source history and original writer tips; no full baseline clone/fsck/import or baseline object completeness claim."},
    "reviewedSourceHashBindings": bindings,
    "derivedRecorderExtractionAndReleaseStrippingMatchPinnedSource": True,
    "retainedToolingLog": {"methodStarts": 104, "terminalOKRecords": 104,
        "summary": "Ran 104 tests; OK", "reexecutedBy099": False},
    "historicalInterimReview": {"worker": "100", "sourceRevision": F94, "documentationHead": PARENT,
        "scope": "Retained historical interim review, not source2fc runtime acceptance."},
    "previousReceiptsUnchanged": PREVIOUS,
    "limits": [
        "No previous archives reaudited; only previous receipt digests checked for preservation.",
        "No builds, witness/test execution, new image viewing, production edits, Git ref/object writes, remote operations or descendants.",
        "The compiled Linux witness executable and module cache are explicitly excluded; source and logs remain. Its scope does not include UIKit execution.",
        "The original061 video/measurement/derived frame remain in the separately audited attempt1 archive; this selection makes no complete-artifact claim.",
        "The failed initial096 parse invocation remains recorded; a shell wrapper exit0 is not upgraded to a successful compiler result.",
        "Review/publication evidence does not certify Apple compilation, UI behavior, full source2fc CI, final worker completion or beta readiness."
    ],
}
(OUT / "supplement-04.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"archiveEntries": 22, "archiveRawBytes": 127257, "primaryCopies": 7,
    "publicationChangedPaths": 15, "bundleRefs": 3, "bundlePrerequisites": 2,
    "bundlePackObjects": count, "bundleNewCommits": len(new_commits), "reviewSourceBindings": len(bindings),
    "retainedToolingChecks": 104, "receiptSHA256": sha((OUT / "supplement-04.json").read_bytes())}, indent=2))
