"""Recover hash-verified, unmodified PNGs from actual KEYFILL_REVIEW JSON records."""
from pathlib import Path
import base64
import hashlib
import io
import json
import re
import struct
from datetime import datetime, timezone
from PIL import Image

ROOT = Path("/workspace/scratch/b25ffdc7aed8/a033-evidence")
LOG = ROOT / "original-job-140564742446.log"
SOURCE = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
EXPECTED = {
    "Default-Inspector",
    "Default-Plan-choices",
    "Default-Plan-selection",
    "Default-Precision-instructions",
    "Default-Workspace-header",
}
returned_characters = 1878475
text = LOG.read_text(encoding="utf-8")
# apply_patch adds one newline after the supplied, already newline-terminated log.
if len(text) == returned_characters + 1 and text.endswith("\n\n"):
    text = text[:-1]
    LOG.write_bytes(text.encode("utf-8"))
assert len(text) == returned_characters, "Decoded log character count changed"
records = []
ignored = []
for line_number, line in enumerate(text.splitlines(), 1):
    marker = "KEYFILL_REVIEW"
    if marker not in line:
        continue
    payload = line.partition(marker)[2].strip()
    if not payload.startswith("{"):
        ignored.append({"line": line_number, "reason": "echoed script, not a JSON record"})
        continue
    record = json.loads(payload)
    assert isinstance(record, dict)
    assert record.get("type") in {"image", "chunk", "summary"}, record.get("type")
    records.append({"line": line_number, "record": record})

image_records = [row for row in records if row["record"]["type"] == "image"]
summary_records = [row for row in records if row["record"]["type"] == "summary"]
assert len(summary_records) == 1
summary = summary_records[0]["record"]
assert summary["sourceRevision"] == SOURCE
assert summary["category"] == "Default"
assert summary["images"] == len(image_records) == 6
assert summary["requiredImages"] == len(EXPECTED)
assert {row["record"]["name"] for row in image_records} == EXPECTED | {"Accessibility-workflow-failure"}
chunks_by_name = {}
for row in records:
    record = row["record"]
    if record["type"] != "chunk":
        continue
    chunks_by_name.setdefault(record["name"], []).append(row)

verified = []
pending_bytes = []
for row in image_records:
    metadata = row["record"]
    name = metadata["name"]
    assert metadata["sourceRevision"] == SOURCE
    filename = metadata["file"]
    assert Path(filename).name == filename and filename.endswith(".png")
    chunks = chunks_by_name.pop(name)
    assert len(chunks) == metadata["chunks"], (name, "chunk count")
    assert {chunk["record"]["index"] for chunk in chunks} == set(range(metadata["chunks"])), (name, "chunk indices")
    ordered = sorted(chunks, key=lambda chunk: chunk["record"]["index"])
    encoded = "".join(chunk["record"]["data"] for chunk in ordered)
    payload = base64.b64decode(encoded, validate=True)
    assert len(payload) == metadata["bytes"], (name, "byte count", len(payload))
    digest = hashlib.sha256(payload).hexdigest()
    assert digest == metadata["sha256"], (name, "SHA256", digest)
    assert payload[:8] == b"\x89PNG\r\n\x1a\n", (name, "PNG signature")
    assert payload[12:16] == b"IHDR", (name, "IHDR")
    width, height = struct.unpack(">II", payload[16:24])
    with Image.open(io.BytesIO(payload)) as image:
        assert image.format == "PNG"
        assert image.size == (width, height)
        mode = image.mode
        image.verify()
    relative_path = "originals/" + filename
    pending_bytes.append((ROOT / relative_path, payload))
    verified.append({
        "name": name,
        "path": relative_path,
        "returnedMetadata": metadata,
        "metadataLogLine": row["line"],
        "chunkLogLines": [chunk["line"] for chunk in ordered],
        "observedBytes": len(payload),
        "observedSHA256": digest,
        "bytesMatch": True,
        "sha256Match": True,
        "completeChunks": True,
        "pngVerified": True,
        "width": width,
        "height": height,
        "mode": mode,
        "viewed": False,
    })
assert not chunks_by_name, "Orphan chunk records"
assert sum(item["observedBytes"] for item in verified) == summary["bytes"]
assert len(pending_bytes) == len({path for path, _ in pending_bytes})
(ROOT / "originals").mkdir(exist_ok=True)
# No originals are written or viewed until every image has passed byte/hash checks.
for path, payload in pending_bytes:
    path.write_bytes(payload)
    assert hashlib.sha256(path.read_bytes()).hexdigest() == hashlib.sha256(payload).hexdigest()

log_bytes = LOG.read_bytes()
manifest = {
    "task": "A033 original capture recovery and visual review",
    "recoveredAtUTC": datetime.now(timezone.utc).isoformat(),
    "sourceRevision": SOURCE,
    "sourceRunID": 46004241191,
    "sourceRunURL": "https://github.com/mirzotipi-wq/APP1/actions/runs/46004241191",
    "reviewJobID": 140564742446,
    "reviewJobAPIURL": "https://api.github.com/repos/mirzotipi-wq/APP1/actions/jobs/140564742446",
    "reviewJobURL": None,
    "reviewJobURLNote": "Canonical review-run URL pending parent provenance; source-run ID comes directly from download-artifact log and is not asserted as the review-run ID.",
    "retrieval": {
        "tool": "mcp__codex_apps__github_fetch_workflow_job_logs",
        "arguments": {"job_id": 140564742446, "link_id": "link_6b0496ede3088191ad7f6c85f178a8a8", "repo_full_name": "mirzotipi-wq/APP1"},
        "returnedKeys": ["content", "structuredContent", "isError"],
        "returnedStructuredContentKeys": ["content"],
        "returnedContentTypes": ["text"],
        "isError": False,
        "decodedLogCharacters": returned_characters,
    },
    "decodedLog": {
        "path": LOG.name,
        "encoding": "UTF-8",
        "bytes": len(log_bytes),
        "sha256": hashlib.sha256(log_bytes).hexdigest(),
        "recordCount": len(records),
        "ignoredScriptOccurrences": ignored,
    },
    "sourceArtifactDownloadLogLines": [
        {"line": i, "text": line}
        for i, line in enumerate(text.splitlines(), 1)
        if any(phrase in line for phrase in ["run-id: ", "Name: ", "SHA256 digest of downloaded artifact", "Total of 1 artifact(s)"])
    ],
    "returnedSummary": summary,
    "summaryLogLine": summary_records[0]["line"],
    "images": verified,
    "preservation": {
        "unalteredOriginalPNGBytes": True,
        "originalFilenamesRetained": True,
        "editingOrImageGenerationUsed": False,
        "derivedMontageUsed": False,
        "UIJobFallbackNeeded": False,
        "repositoryFilesModifiedByThisTask": False,
        "buildsOrWorkersLaunchedByThisTask": False,
    },
    "limits": [
        "Five required Default captures plus one failure attachment only.",
        "No AXXXL captures were present in this Default review-job payload.",
        "Recovery verifies transmitted bytes and metadata, not current-tree visual acceptance.",
        "This source-specific evidence does not establish acceptance of later source changes or physical-device behavior.",
    ],
}
(ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps({
    "manifest": str(ROOT / "manifest.json"),
    "imageCount": len(verified),
    "requiredDefaultOriginals": sum(item["name"] in EXPECTED for item in verified),
    "bytes": sum(item["observedBytes"] for item in verified),
    "allByteCountsMatch": True,
    "allSHA256Match": True,
    "images": [{k: item[k] for k in ["name", "path", "observedBytes", "observedSHA256", "width", "height"]} for item in verified],
}, indent=2))

