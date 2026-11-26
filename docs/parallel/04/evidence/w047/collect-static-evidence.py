#!/usr/bin/env python3
"""Collect read-only consumer-review evidence; no Swift execution or source edits."""
import hashlib
from pathlib import Path
import shlex
import subprocess
import sys

worktree, renderer, tests = (Path(value).resolve() for value in sys.argv[1:4])
preview = worktree / "App/ReferenceStudyPreview.swift"

def command(args):
    print("$ " + shlex.join(map(str, args)), flush=True)
    result = subprocess.run(list(map(str, args)), cwd=worktree, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    print("exit=" + str(result.returncode), flush=True)
    if result.returncode:
        raise SystemExit(result.returncode)

for args in [
    ["git", "status", "--short", "--branch"],
    ["git", "rev-parse", "HEAD"],
    ["git", "log", "-5", "--oneline"],
    ["python3", "scripts/agent_cycle.py", "check"],
    ["python3", "scripts/agent_cycle.py", "next"],
    ["git", "hash-object", preview, renderer, tests],
]:
    command(args)

print("READ-ONLY SOURCE EXCERPTS: not runtime, image, or accessibility acceptance")
for path, ranges in [
    (preview, [(1, 147)]),
    (renderer, [(81, 136), (150, 160), (223, 303)]),
]:
    lines = path.read_text().splitlines()
    print("SOURCE " + str(path))
    for start, end in ranges:
        for number in range(start, min(end, len(lines)) + 1):
            print(str(number) + ": " + lines[number - 1])

print("STARTUP DOCUMENTS READ: provenance hashes, not validation results")
for name in ["AGENTS.md", "agents/OPERATING_PROTOCOL.md", "agents/HANDOFF.md",
             "agents/state.json", "docs/PRODUCT.md", "docs/ARCHITECTURE.md",
             "docs/ROADMAP.md", "docs/QUALITY.md", "docs/DESIGN.md",
             "docs/acceptance/m02-m03-code.md"]:
    data = (worktree / name).read_bytes()
    print(hashlib.sha256(data).hexdigest() + "  " + name)

print("Limits: no Swift compiler, SDK install, test execution, GPU submission, UI run, or screenshot inspection.")
print("Unchanged fixtures, tolerances, equations, packed ABI, CPU oracle, harness, preview, source, global state and handoff.")
print("Final test candidate was hash-verified only; its synthetic lifecycle tests do not establish Metal output.")
