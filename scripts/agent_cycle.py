#!/usr/bin/env python3
"""Validate the repository's agent queue and select an eligible milestone. No AI or network calls."""
import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = ("AGENTS.md", "agents/OPERATING_PROTOCOL.md", "agents/HANDOFF.md",
            "agents/LEARNINGS.md", "docs/PRODUCT.md", "docs/QUALITY.md",
            "docs/ROADMAP.md", "docs/ARCHITECTURE.md", "docs/DESIGN.md")

def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def validate():
    for path in REQUIRED:
        if not (ROOT / path).is_file():
            raise ValueError(f"Missing contract: {path}")
    state, evidence = read("agents/state.json"), read("agents/evidence.json")
    if state["schema"] != 1 or evidence["schema"] != 1:
        raise ValueError("Unsupported state or evidence schema")
    milestones = state["milestones"]
    ids = [m["id"] for m in milestones]
    if not ids or len(set(ids)) != len(ids):
        raise ValueError("Invalid/duplicate milestone IDs")
    known = {}
    gates = set()
    for m in milestones:
        if m["status"] not in ("pending", "active", "blocked", "complete"):
            raise ValueError(f"Invalid status: {m['id']}")
        if not m["gates"] or len(set(m["gates"])) != len(m["gates"]) or gates.intersection(m["gates"]):
            raise ValueError(f"Missing or duplicate gates: {m['id']}")
        if not set(m["depends"]).issubset(known):
            raise ValueError(f"Unknown, forward or cyclic dependency: {m['id']}")
        gates.update(m["gates"])
        known[m["id"]] = m
    # Last observation for each gate is authoritative; older observations are retained.
    latest = {}
    for entry in evidence["entries"]:
        gate = entry["gate"]
        if gate not in gates or entry["result"] not in ("pass", "fail", "unverified"):
            raise ValueError(f"Invalid evidence gate/result: {gate}")
        for key in ("revision", "date", "method", "environment", "artifact", "reviewer", "notes"):
            if not isinstance(entry.get(key), str) or not entry[key].strip():
                raise ValueError(f"Missing evidence field {key}: {gate}")
        if entry["result"] == "pass" and not re.fullmatch(r"[0-9a-f]{40}", entry["revision"]):
            raise ValueError(f"Pass requires exact tested commit SHA: {gate}")
        latest[gate] = entry["result"]
    for m in milestones:
        deps_pass = all(known[d]["status"] == "complete" for d in m["depends"])
        if m["status"] in ("active", "complete") and not deps_pass:
            raise ValueError(f"Unmet dependencies: {m['id']}")
        if m["status"] == "complete" and any(latest.get(g) != "pass" for g in m["gates"]):
            raise ValueError(f"Completion lacks passing evidence: {m['id']}")
    return milestones, known, latest

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("check", "next", "status"))
    args = parser.parse_args()
    try:
        milestones, known, latest = validate()
        if args.command == "check":
            print("State structure and evidence references valid; this does NOT verify test truth or release readiness.")
        elif args.command == "status":
            for m in milestones:
                print(f"{m['id']} {m['status']}: {m['name']}")
                for gate in m["gates"]:
                    print(f"  {gate}: {latest.get(gate, 'unverified')}")
        else:
            eligible = [m for m in milestones if m["status"] in ("pending", "active")
                        and all(known[d]["status"] == "complete" for d in m["depends"])]
            if eligible:
                m = eligible[0]
                print(f"{m['id']}: {m['name']}")
                print("Outstanding gates: " + ", ".join(g for g in m["gates"] if latest.get(g) != "pass"))
                print("Read agents/HANDOFF.md and docs/QUALITY.md before implementing.")
            else:
                print("No eligible unblocked milestone. Inspect blockers or seek owner release review.")
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"State check failed: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
