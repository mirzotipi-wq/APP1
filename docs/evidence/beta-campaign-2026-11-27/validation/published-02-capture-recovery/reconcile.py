#!/usr/bin/env python3
"""Audit retained source-specific screenshot evidence without synthesizing pixels."""
import hashlib
import io
import json
import re
import stat
import subprocess
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parent
WORKSPACE = ROOT.parents[2]
REPO = WORKSPACE / "APP1"
SOURCE = "134f9adabe0203b1d6d8ed21abb6aaeb4e19d256"
SUPERSEDING = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
RUN = 45999974158
JOB = 140511739640
ARTIFACT = 15200285895


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git_source(revision, path):
    return subprocess.check_output(["git", "show", revision + ":" + path], cwd=REPO)


def scan(data):
    try:
        data.decode("utf-8")
        utf8 = True
    except UnicodeDecodeError:
        utf8 = False
    return {
        "utf8_text": utf8,
        "raw_png_signatures": data.count(b"\x89PNG\r\n\x1a\n"),
        "base64_png_prefixes": data.count(b"iVBORw0KGgo"),
        "hex_png_signatures": len(re.findall(
            rb"89\s*50\s*4e\s*47\s*0d\s*0a\s*1a\s*0a", data, re.I)),
        "keyfill_review_markers": data.count(b"KEYFILL_REVIEW "),
    }


def inspect_zip(data, max_expanded):
    archive = zipfile.ZipFile(io.BytesIO(data))
    entries = archive.infolist()
    assert len(entries) <= 2000
    assert sum(item.file_size for item in entries) <= max_expanded
    assert len({item.filename for item in entries}) == len(entries)
    files, directories, contents = [], [], {}
    for item in entries:
        p = PurePosixPath(item.filename)
        assert p.parts and not p.is_absolute() and ".." not in p.parts
        assert "\\" not in item.filename and ":" not in p.parts[0]
        assert str(p) == item.filename.rstrip("/")
        assert not (item.flag_bits & 1)
        assert stat.S_IFMT(item.external_attr >> 16) in (0, stat.S_IFREG, stat.S_IFDIR)
        assert not stat.S_ISLNK(item.external_attr >> 16)
        assert item.file_size <= 64 * 1024 * 1024
        if item.is_dir():
            directories.append(item.filename)
            continue
        content = archive.read(item)  # Verifies this member's ZIP CRC.
        contents[item.filename] = content
        files.append({"path": item.filename, "bytes": len(content),
                      "compressed_bytes": item.compress_size,
                      "sha256": sha(content), "crc32": format(item.CRC, "08x"),
                      "scan": scan(content)})
    archive.close()
    return {"entry_count": len(entries), "file_count": len(files),
            "expanded_bytes": sum(item.file_size for item in entries),
            "files": files, "directories": directories,
            "all_file_crcs_verified": True}, contents


metadata_path = ROOT.parent / "081/github-apple-terminal-artifacts.json"
metadata_packet = json.loads(metadata_path.read_text())
metadata = next(item for item in metadata_packet["data"] if item["id"] == ARTIFACT)
assert metadata["workflow_run"]["id"] == RUN
assert metadata["workflow_run"]["head_sha"] == SOURCE
assert not any(item["name"] == "ui-app-accessibility-evidence-compact"
               for item in metadata_packet["data"])
archive_path = ROOT / "app-accessibility-original.zip"
raw = archive_path.read_bytes()
assert len(raw) == metadata["size_in_bytes"] == 5679318
assert metadata["digest"] == "sha256:" + sha(raw)
outer, outer_contents = inspect_zip(raw, 16 * 1024 * 1024)
nested_raw = outer_contents["artifacts/native-results.zip"]
nested, nested_contents = inspect_zip(nested_raw, 64 * 1024 * 1024)
assert len(nested_contents) == 5
assert all(item.endswith((".log", ".txt")) for item in nested_contents)
assert "NativeTests.xcresult/Info.plist" not in nested_contents
assert not any(item.startswith("NativeTests.xcresult/Data/") for item in nested_contents)
assert all(item["scan"]["utf8_text"] for item in nested["files"])
assert all(item["scan"][key] == 0 for item in nested["files"]
           for key in ("raw_png_signatures", "base64_png_prefixes",
                       "hex_png_signatures", "keyfill_review_markers"))

source_path = "UITests/StudioAppAccessibilityUITests.swift"
source = git_source(SOURCE, source_path)
names = ["Default-" + suffix.decode() for suffix in re.findall(
    rb'capture\(name \+ "-([^"\n]+)"', source)]
assert len(names) == len(set(names)) == 14
console_path = ROOT.parent / ("081/job-" + str(JOB) + ".log")
console = console_path.read_bytes()
assert len(console) == 458971
assert scan(console)["keyfill_review_markers"] == 0
emissions = {}
for number, line in enumerate(console.decode("utf-8").splitlines(), 1):
    match = re.search(r"Added attachment named '(Default-[^']+)'", line)
    if match:
        assert match[1] not in emissions
        emissions[match[1]] = {"line": number, "text": line}
assert set(emissions) == set(names)
session_path = next(name for name in nested_contents if "/Session-KeyAndFill" in name)
session = nested_contents[session_path]
attachment_pattern = re.compile(
    r"Activity ([0-9A-F-]+) added attachment with name '(Default-[^']+)', "
    r"Uniform Type Identifier 'public.png', lifetime 'keepAlways', "
    r"hasPayload: YES, size \(in bytes\): ([0-9]+)\.")
attachments = {}
metadata_lines = []
launches = []
for number, line in enumerate(session.decode("utf-8").splitlines(), 1):
    if " Launching <XCUIApplicationImpl:" in line and "via Xcode with args:" in line:
        category = re.search(r"-UIPreferredContentSizeCategoryName ([A-Za-z]+)", line)
        if category:
            launches.append({"session_log_line": number, "session_log_text": line,
                             "requested_text_category": category[1]})
    match = attachment_pattern.search(line)
    if match:
        assert match[2] not in attachments
        attachments[match[2]] = {
            "activity_uuid": match[1], "name": match[2],
            "reported_payload_bytes_not_retained_png_size": int(match[3]),
            "session_log_line": number, "session_log_text": line,
            "console_emission": emissions[match[2]],
            "original_png": None, "original_png_sha256": None,
            "original_png_dimensions": None, "recovered": False,
        }
        metadata_lines.append(str(number) + ": " + line)
assert set(attachments) == set(names)
assert [item["requested_text_category"] for item in launches] == [
    "UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"]
assert not re.search(rb"Added attachment named 'AXXXL-", console)
provenance = []
for path in (source_path, ".github/workflows/ios-prototype.yml",
             ".github/workflows/review-xctest-evidence.yml"):
    before, after = git_source(SOURCE, path), git_source(SUPERSEDING, path)
    provenance.append({"path": path, "source_sha256": sha(before),
                       "superseding_source_sha256": sha(after),
                       "byte_identical_between_revisions": before == after})

result = {
    "schema": 1, "task": "/root/a085_default_capture_recovery",
    "source_sha": SOURCE, "superseding_sha_not_validated_by_this_run": SUPERSEDING,
    "run_id": RUN, "job_id": JOB, "artifact": metadata,
    "archive_path": archive_path.name, "archive_sha256": sha(raw),
    "github_digest_matches": True, "outer_zip": outer,
    "nested_archive_path": "artifacts/native-results.zip",
    "nested_archive_bytes": len(nested_raw), "nested_archive_sha256": sha(nested_raw),
    "nested_zip": nested, "artifact_metadata_source": str(metadata_path),
    "artifact_metadata_sha256": sha(metadata_path.read_bytes()),
    "console_path": str(console_path), "console_sha256": sha(console),
    "console_scan": scan(console), "source_files": provenance,
    "session_log_path_in_nested_archive": session_path,
    "session_log_sha256": sha(session),
    "default_capture_emission_count": 14,
    "axxxl_capture_emission_count": 0,
    "observed_launches": launches,
    "largest_size_execution_status": "started_but_no_capture_reached_before_cancellation",
    "session_log_png_metadata_count": 14,
    "session_log_reported_payload_bytes": sum(
        item["reported_payload_bytes_not_retained_png_size"] for item in attachments.values()),
    "captures": [attachments[name] for name in names],
    "recovered_original_png_count": 0, "visually_reviewed_original_png_count": 0,
    "recovery_status": "unavailable_in_retained_console_and_artifact",
    "limitations": [
        "The job was cancelled with one method started and no terminal method event.",
        "Largest-accessibility-size workflow started at 13:06:10.840 with the explicit AXXXL launch argument, but reached zero captures; the 28-capture gate is not passed.",
        "Swift attaches screen captures with keepAlways; it does not print image bytes.",
        "Existing KEYFILL_REVIEW transport requires exported compact attachments; no compact artifact exists here.",
        "The unfinished xcresult has no Info.plist, no Data objects and only five diagnostic text/log files.",
        "hasPayload:YES and reported sizes describe runtime attachment objects, not retained PNG bytes.",
        "No image reconstruction, regeneration, substitution, build, test rerun, CI change or push was performed.",
        "No result at old source 134f9ad establishes current source f94c0e6 acceptance.",
    ],
}
(ROOT / "recovery.json").write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
(ROOT / "session-attachment-metadata.txt").write_text("\n".join(metadata_lines) + "\n")
(ROOT / "session-text-size-launches.txt").write_text(
    "\n".join(str(item["session_log_line"]) + ": " + item["session_log_text"] for item in launches) + "\n")
(ROOT / "console-capture-emissions.txt").write_text(
    "\n".join(str(emissions[name]["line"]) + ": " + emissions[name]["text"] for name in names) + "\n")
print(json.dumps({key: result[key] for key in (
    "source_sha", "archive_sha256", "nested_archive_sha256",
    "default_capture_emission_count", "session_log_png_metadata_count",
    "session_log_reported_payload_bytes", "recovered_original_png_count", "recovery_status"
)}, indent=2))
