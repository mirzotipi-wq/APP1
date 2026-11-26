#!/usr/bin/env python3
"""Wave4 source-scope and frozen-acceptance inventory; not runtime evidence."""
from pathlib import Path
import hashlib, json, re, subprocess
BASE = Path("/tmp/keyfill04-2987b1ee980d")
SHA = "c08cd0be2548467add169c3594207cf489760787"
RESULTS = BASE / "results/w031"
freeze = json.loads((RESULTS / "acceptance-freeze.json").read_text())
owners = {"w034": "App/StudyKernel.h",
          "w037": "NativeTests/StudyRendererTests.swift",
          "w039": "NativeTests/StudyPrecisionMatrixTests.swift"}
def git(root, *args):
    return subprocess.run(["git", "-C", str(root), *args], text=True,
                          capture_output=True, check=False)
def digest(data):
    return hashlib.sha256(data).hexdigest()
receipt = {"worker": "/root/w031", "input_sha": SHA,
           "scope": "Source/ownership/contract inventory only; no numerical/runtime/Metal result",
           "frozen_acceptance": freeze["frozen"], "owners": {}, "failures": []}
for owner, owned in owners.items():
    root = BASE / "workers" / owner
    head = git(root, "rev-parse", "HEAD")
    status = git(root, "status", "--porcelain", "--untracked-files=all")
    changed = [line[3:] for line in status.stdout.splitlines()]
    whitespace = git(root, "diff", "--check")
    owned_data = (root / owned).read_bytes()
    protected = {}
    for path, expected in freeze["source_sha256"].items():
        if path == owned:
            continue
        actual = digest((root / path).read_bytes())
        protected[path] = {"sha256": actual, "matches_frozen": actual == expected}
    entry = {"owned_path": owned, "head": head.stdout.strip(),
             "changed_paths": changed, "owned_sha256": digest(owned_data),
             "diff_check_exit": whitespace.returncode, "protected_sources": protected}
    receipt["owners"][owner] = entry
    if head.returncode or entry["head"] != SHA:
        receipt["failures"].append(owner + ": input HEAD mismatch")
    if status.returncode or set(changed) != {owned}:
        receipt["failures"].append(owner + ": ownership changes mismatch")
    if whitespace.returncode:
        receipt["failures"].append(owner + ": diff whitespace check failed")
    if any(not value["matches_frozen"] for value in protected.values()):
        receipt["failures"].append(owner + ": protected source changed")
    if any(line.rstrip() != line for line in owned_data.decode().splitlines()):
        receipt["failures"].append(owner + ": trailing whitespace")
native_root = BASE / "workers/w037"
baseline = git(native_root, "show", SHA + ":NativeTests/StudyRendererTests.swift").stdout
candidate = (native_root / "NativeTests/StudyRendererTests.swift").read_text()
prefix = baseline[:baseline.rfind("\n}")]
old_names = re.findall(r"^    func (test\w+)\(", baseline, re.M)
new_names = re.findall(r"^    func (test\w+)\(", candidate, re.M)
old_prefix_retained = candidate.startswith(prefix)
required = ["testMetalMatchesCPUOnAvailableDevice",
            "testNearFieldRoutingDoesNotPermanentlyDowngradeValidatedMetal",
            "testCancelledInitialParityValidationCanRetryMetalOnSameEngine"]
receipt["native_preservation"] = {"old_prefix_byte_identical": old_prefix_retained,
    "old_methods": old_names, "new_methods": sorted(set(new_names)-set(old_names)),
    "required_metal_methods_preserved": all(name in new_names for name in required)}
if not old_prefix_retained or not set(old_names).issubset(new_names):
    receipt["failures"].append("w037: original method source not fully preserved")
if not receipt["native_preservation"]["required_metal_methods_preserved"]:
    receipt["failures"].append("w037: required actualMetal method missing")
precision = (BASE / "workers/w039/NativeTests/StudyPrecisionMatrixTests.swift").read_text()
receipt["precision_new_methods"] = re.findall(r"^    func (test\w+)\(", precision, re.M)
receipt["executed"] = ["Python SHA256 and protected-source equality",
    "git rev-parse/status/diff --check for three owned worktrees",
    "Byte-identical baseline native prefix and required-method inventory"]
receipt["unrun"] = ["Swift compilation and tests", "actual Metal dispatch",
    "six-fixture parity and eight strict precision numerical matrix",
    "runtime cache/cancellation acceptance"]
receipt["passed"] = not receipt["failures"]
output = RESULTS / "acceptance-audit.json"
output.write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps({"passed": receipt["passed"], "failures": receipt["failures"],
                 "source_sha256": {k:v["owned_sha256"] for k,v in receipt["owners"].items()},
                 "native_preservation": receipt["native_preservation"],
                 "precision_new_methods": receipt["precision_new_methods"]}, indent=2))
raise SystemExit(0 if receipt["passed"] else 1)
