from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[3]
REPO = ROOT / "APP1"
OUT = Path(__file__).resolve().parent
SHA = "f94c0e6cb9cd072286d6e4414eb2c1f8974d4ce5"
paths = [
    "App/StudioTextField.swift", "App/PrecisionValueButton.swift",
    "App/ProjectLibraryView.swift", "App/StudioTextLayoutDiagnostics.swift",
    "Sources/LightingCore/StudioNumericInput.swift",
    "NativeTests/StudioTextFieldTests.swift", "NativeTests/ProjectNameEditorTests.swift",
    "UITests/StudioAppAccessibilityUITests.swift", "UITests/StudioContentReachability.swift",
]
inputs = []
for path in paths:
    data = subprocess.check_output(["git", "show", f"{SHA}:{path}"], cwd=REPO)
    actual = (REPO / path).read_bytes()
    assert actual == data, path
    inputs.append({"path": path, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
                   "workingSourceEqualsAssignedRevision": True})

observed = []
originals = ROOT / "campaign/evidence/095/originals/native-attachments"
for name in ["7D29BB1D-4B7B-402D-87DF-1B6920DE3904.txt",
             "863BB9B5-6308-4509-B75D-14D34B6EF9D2.txt",
             "0DD7F6EF-E1C7-49CA-8632-52A898F5B029.txt",
             "CA594E31-7CE4-48BF-85BC-D10288518091.png"]:
    p = originals / name
    observed.append({"path": str(p.relative_to(ROOT)), "bytes": p.stat().st_size,
                     "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                     "review": "Actually viewed original PNG" if p.suffix == ".png" else "Read actual original text"})

diagnostics = ROOT / "campaign/evidence/095/diagnostics"
excerpts = []
for name in ["app-stdout.log", "xctest-session.log"]:
    p = diagnostics / name
    lines = p.read_text(errors="replace").splitlines()
    picked = []
    for number, line in enumerate(lines, 1):
        if ("Keyboard queue task timeout detected" in line or
            "doesn't have keyboard focus" in line or
            ("13:33:26." in line and ("MT responded in time" in line or "Sending main run loop idle reply" in line))):
            picked.append({"line": number, "text": line})
    excerpts.append({"path": str(p.relative_to(ROOT)), "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                     "excerpts": picked})

report = {
    "worker": "/root/a096_numeric_entry_causal_review", "sourceRevision": SHA,
    "sourceInputs": inputs, "originalEvidenceReadOrViewed": observed, "diagnosticExcerpts": excerpts,
    "originalRecoveryProviderVerification": "Worker095 owns the original archive recovery and provider digest/CRC receipt;096 independently hashes and reads/views the listed extracted original payloads.",
    "finding": "No causal source repair established. Unchanged900 after synthesis is a failed exact-value workflow, not a pass or a proven product/host diagnosis.",
    "nativeExecutionByThisWorker": False, "buildOrProbeExecuted": False,
}
(OUT / "source-review.json").write_text(json.dumps(report, indent=2) + "\n")
print(f"Verified {len(inputs)} pinned source files and {len(observed)} original payloads; retained {sum(len(x['excerpts']) for x in excerpts)} diagnostic lines.")
