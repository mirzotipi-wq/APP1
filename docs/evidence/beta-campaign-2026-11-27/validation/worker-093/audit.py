#!/usr/bin/env python3
"""Pin the source reviewed for worker 093; no native/runtime claim."""
import hashlib
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[3]
REPO = ROOT / "APP1"
OUT = pathlib.Path(__file__).resolve().parent
REV = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
PATHS = [
    "App/ReferencePhoto.swift", "App/ReferenceComparisonView.swift",
    "App/PhotoComparisonView.swift", "App/ReferenceAnalysisService.swift",
    "App/ReferenceStudyPreview.swift", "App/LightingPlanExportView.swift",
    "App/LightingPlanPDF.swift", "App/ProjectBackupView.swift",
    "App/ProjectDocumentIO.swift", "App/ManualRoomPlacementView.swift",
    "App/ProjectStore.swift", "App/StudioSession.swift",
    "App/ProjectLibraryOperation.swift", "App/ProjectLibraryView.swift",
    "App/ProjectLibraryRecoveryView.swift", "App/BetaFeedbackView.swift",
    "App/StudioSettingsView.swift", "App/StudioPreferences.swift",
    "App/StudioWelcomeView.swift", "App/StudioView.swift",
    "Sources/LightingCore/ProjectLibrary.swift",
    "Sources/LightingCore/LightingProjectDocument.swift",
    "Sources/LightingCore/Scene.swift", "Sources/LightingCore/SceneCodec.swift",
    "Sources/LightingCore/LightingPlan.swift", "Sources/LightingCore/RoomPlacementText.swift",
    "Sources/LightingCore/ReferencePNG.swift", "Sources/LightingCore/BetaFeedbackReport.swift",
    "docs/PRIVACY.md", "docs/BETA_TESTER_GUIDE.md",
]
sources = {}
for path in PATHS:
    data = subprocess.check_output(["git", "show", REV + ":" + path], cwd=REPO)
    local = REPO / path
    sources[path] = {
        "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
        "git_blob": subprocess.check_output(
            ["git", "rev-parse", REV + ":" + path], cwd=REPO, text=True).strip(),
        "working_copy_matches": local.read_bytes() == data,
    }
manifest = {
    "worker": "/root/a093_beta_data_retention_boundary",
    "source_revision": REV,
    "kind": "Static source and disclosure trace; no device, traffic, share, or deletion execution",
    "sources": sources,
    "source_count": len(sources),
    "reviewed_payload_routes": {
        "recovery": "Application Support/KeyAndFill/Recovery/<UUID>/{projects.json,portrait.json}; original bytes; no automatic cleanup or export route",
        "editable_backup": "LightingProjectDocument.Envelope: schemaVersion, name, scene; fresh project ID on import",
        "pdf": "LightingPlan(scene,title,units,paper) -> LightingPlanPDF.make -> user-initiated ShareLink",
        "text": "LightingPlan.plainText or immutable RoomPlacementText -> user-initiated ShareLink",
        "png": "ReferencePhoto.sanitize generates in-memory derivative; no user-facing PNG export found in current App sources",
        "feedback": "Optional note strings and app/build/OS/device family -> frozen reviewed BetaFeedbackReport.plainText -> ShareLink",
    },
    "findings": [
        {"severity": "P2 documentation", "item": "Privacy draft omits unreadable-library recovery copies and their independent retention"},
        {"severity": "P2 documentation", "item": "Privacy draft omits beta feedback and welcome-dismissal preference"},
    ],
    "limits": [
        "No app data path connecting selected reference pixels to persisted scenes or current export payloads was found in the reviewed source.",
        "Opaque recovery originals are not sanitized; arbitrary bytes already present in unreadable files are preserved locally.",
        "System-provider temporary files, backups, share destinations, memory erasure, permissions and network behavior require actual device validation.",
        "No fresh suites, native build, runtime tests, or legal/privacy certification performed.",
    ],
}
(OUT / "source-review.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps({"source_revision": REV, "pinned_files": len(sources),
                  "working_differences": [p for p, v in sources.items() if not v["working_copy_matches"]],
                  "receipt_sha256": hashlib.sha256((OUT / "source-review.json").read_bytes()).hexdigest()}, indent=2))
