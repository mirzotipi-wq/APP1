import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

repo = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("/workspace/scratch/b25ffdc7aed8/APP1")
out = Path(__file__).resolve().parent
hierarchy = Path(sys.argv[2]) if len(sys.argv) > 2 else repo.parent / "a084-evidence/originals/native-attachments/BCD4C175-2657-4B13-8FD9-FC3FB508BEAC.txt"
identifier = "studioWelcomeTitle"
label = "Start your first portrait"
nodes = []
for line_number, line in enumerate(hierarchy.read_text().splitlines(), 1):
    if "StaticText," in line and "identifier: 'studioWelcomeTitle'" in line:
        match = re.search(r"label: '([^']*)'", line)
        nodes.append({"type": "StaticText", "identifier": identifier,
                      "label": match.group(1) if match else "",
                      "line": line_number, "raw": line.strip()})
assert len(nodes) == 2
assert [node["label"] for node in nodes] == ["", label]

def real_matches(items):
    return [node for node in items if node["type"] == "StaticText"
            and node["identifier"] == identifier and node["label"] == label]

def identities_remain(items):
    return any(node["type"] == "StaticText" and node["identifier"] == identifier
               for node in items)

actual, wrapper = nodes[1], nodes[0]
scenarios = [
    ("captured_original", nodes, 1, True),
    ("wrapper_only", [wrapper], 0, True),
    ("duplicate_real", [wrapper, actual, dict(actual)], 2, True),
    ("wrong_identifier", [dict(actual, identifier="other")], 0, False),
    ("wrong_label", [dict(actual, label="Changed title")], 0, True),
    ("dismissed", [], 0, False),
    ("real_only", [actual], 1, True),
    ("unrelated_extra", [*nodes, dict(actual, identifier="other")], 1, True),
]
rows = []
for name, items, count, remaining in scenarios:
    matches = real_matches(items)
    assert len(matches) == count
    assert identities_remain(items) == remaining
    rows.append({"scenario": name, "qualifiedMatches": len(matches),
                 "uniqueAssertionPasses": len(matches) == 1,
                 "identifierAbsencePasses": not identities_remain(items)})

file = repo / "UITests/BetaAccessibilityUITests.swift"
current = file.read_text()
before = subprocess.check_output(
    ["git", "show", "135d3b4755d97bbb8fcff993d8dfd532a8d48b93:UITests/BetaAccessibilityUITests.swift"],
    cwd=repo, text=True)
old = '        let title = healthy.staticTexts["studioWelcomeTitle"]'
new = """        // The opted-in layout value can expose an empty-label AX wrapper.
        // Select the actual labeled title and reject ambiguous real matches.
        let titles = healthy.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "studioWelcomeTitle", "Start your first portrait"))
        XCTAssertEqual(titles.count, 1, "Expected one actual labeled welcome title")
        let title = titles.firstMatch"""
old_gone = "        expectGone(title)"
new_gone = """        // Dismissal must remove every title identity, including the wrapper.
        expectGone(healthy.staticTexts.matching(NSPredicate(
            format: "identifier == %@", "studioWelcomeTitle")).firstMatch)"""
assert current.replace(new, old).replace(new_gone, old_gone) == before
assert current[current.index("    private func control"):] == before[before.index("    private func control"):]
assert re.findall(r"timeout:\s*[\d.]+", current) == re.findall(r"timeout:\s*[\d.]+", before)
assert re.findall(r"func (test\w+)\(", current) == re.findall(r"func (test\w+)\(", before)
result = {
    "capturedHierarchySHA256": hashlib.sha256(hierarchy.read_bytes()).hexdigest(),
    "nodes": nodes, "scenarios": rows,
    "unchangedAssertionHelpers": True, "unchangedTimeouts": True,
    "unchangedTestIdentities": True, "exactTwoHunkScope": True,
    "limitation": "Python truth-table replay of captured labels and identifiers; not XCTest query or Apple runtime execution.",
}
(out / "query-replay.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps({"capturedTitleNodes": len(nodes),
                  "capturedQualifiedMatches": len(real_matches(nodes)),
                  "scenarioCount": len(rows), "scopeAndInvariantChecks": "passed"}))
