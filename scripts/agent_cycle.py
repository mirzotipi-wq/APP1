#!/usr/bin/env python3
"""Validate the repository's agent queue and select an eligible milestone. No AI or network calls."""
import argparse
from datetime import date
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


def text_field(record, key, context):
    value = record.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"Missing or invalid {key}: {context}")
    return value


def string_list(record, key, context, *, allow_empty=False):
    value = record.get(key)
    if not isinstance(value, list) or (not value and not allow_empty):
        raise ValueError(f"Missing or invalid {key} list: {context}")
    if any(not isinstance(item, str) or not item.strip() for item in value):
        raise ValueError(f"Invalid {key} item: {context}")
    if len(value) != len(set(value)):
        raise ValueError(f"Duplicate {key}: {context}")
    return value


def result_for(latest, gate):
    return latest.get(gate, {}).get("result", "unverified")


def validate():
    for path in REQUIRED:
        if not (ROOT / path).is_file():
            raise ValueError(f"Missing contract: {path}")
    state, evidence = read("agents/state.json"), read("agents/evidence.json")
    for name, document in (("state", state), ("evidence", evidence)):
        if not isinstance(document, dict):
            raise ValueError(f"The {name} document must be an object")
        # bool is a subclass of int in Python; true is not a schema version.
        if type(document.get("schema")) is not int or document["schema"] != 1:
            raise ValueError(f"Unsupported {name} schema")
    milestones = state.get("milestones")
    if not isinstance(milestones, list) or not milestones:
        raise ValueError("Missing or invalid milestones list")
    known = {}
    gates = set()
    for m in milestones:
        if not isinstance(m, dict):
            raise ValueError("Each milestone must be an object")
        identifier = text_field(m, "id", "milestone")
        text_field(m, "name", identifier)
        if identifier in known:
            raise ValueError(f"Duplicate milestone ID: {identifier}")
        if m.get("status") not in ("pending", "active", "blocked", "complete"):
            raise ValueError(f"Invalid status: {identifier}")
        milestone_gates = string_list(m, "gates", identifier)
        dependencies = string_list(m, "depends", identifier, allow_empty=True)
        if gates.intersection(milestone_gates):
            raise ValueError(f"Duplicate gates: {identifier}")
        if not set(dependencies).issubset(known):
            raise ValueError(f"Unknown, forward or cyclic dependency: {identifier}")
        gates.update(milestone_gates)
        known[identifier] = m
    entries = evidence.get("entries")
    if not isinstance(entries, list):
        raise ValueError("Missing or invalid evidence entries list")
    # Only current observations control gates. Delayed historical CI results
    # remain in the ledger without overriding a newer revision's invalidation.
    # Retain the whole selected record so status can show its provenance.
    latest = {}
    for entry in entries:
        if not isinstance(entry, dict):
            raise ValueError("Each evidence entry must be an object")
        gate = text_field(entry, "gate", "evidence")
        if gate not in gates or entry.get("result") not in ("pass", "fail", "unverified"):
            raise ValueError(f"Invalid evidence gate/result: {gate}")
        for key in ("revision", "date", "method", "environment", "artifact", "reviewer", "notes"):
            text_field(entry, key, gate)
        if not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", entry["date"]):
            raise ValueError(f"Evidence date must be YYYY-MM-DD: {gate}")
        try:
            date.fromisoformat(entry["date"])
        except ValueError as exc:
            raise ValueError(f"Invalid evidence calendar date: {gate}") from exc
        if entry["result"] == "pass" and not re.fullmatch(r"[0-9a-f]{40}", entry["revision"]):
            raise ValueError(f"Pass requires exact tested commit SHA: {gate}")
        scope = entry.get("scope", "current")
        if scope not in ("current", "historical"):
            raise ValueError(f"Invalid evidence scope: {gate}")
        if scope == "current":
            latest[gate] = entry
    for m in milestones:
        deps_pass = all(known[d]["status"] == "complete" for d in m["depends"])
        if m["status"] in ("active", "complete") and not deps_pass:
            raise ValueError(f"Unmet dependencies: {m['id']}")
        if m["status"] == "complete" and any(result_for(latest, g) != "pass" for g in m["gates"]):
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
                    observation = latest.get(gate)
                    provenance = f" at {observation['revision']}" if observation else " (no current observation)"
                    print(f"  {gate}: {result_for(latest, gate)}{provenance}")
            print("Selected observations are provenance, not proof of freshness or release readiness.")
        else:
            eligible = [m for m in milestones if m["status"] in ("pending", "active")
                        and all(known[d]["status"] == "complete" for d in m["depends"])]
            if eligible:
                m = eligible[0]
                print(f"{m['id']}: {m['name']}")
                print("Outstanding gates: " + ", ".join(g for g in m["gates"] if result_for(latest, g) != "pass"))
                print("Read agents/HANDOFF.md and docs/QUALITY.md before implementing.")
            else:
                print("No eligible unblocked milestone. Inspect blockers or seek owner release review.")
        return 0
    except (OSError, ValueError, KeyError, TypeError) as exc:
        print(f"State check failed: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
