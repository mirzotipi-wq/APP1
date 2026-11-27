#!/usr/bin/env python3
"""Prepare a host-only, bounded JSON decode comparison without running Swift."""
from __future__ import annotations

import hashlib
import json
import pathlib
import platform
import re
import shutil
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent
REPO = ROOT.parent / "APP1"
BASE = "9e2313cbffb01d66249458c64087cb66c7652cca"
MAX_BYTES = 8 * 1024 * 1024


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    inputs = ROOT / "inputs"
    sources = ROOT / "sources"
    inputs.mkdir(exist_ok=True)
    sources.mkdir(exist_ok=True)
    source_records = []
    for path in sorted((REPO / "Sources" / "LightingCore").glob("*.swift")):
        data = path.read_bytes()
        (sources / path.name).write_bytes(data)
        source_records.append({"path": str(path.relative_to(REPO)), "sha256": digest(data)})

    baseline = subprocess.check_output([
        "git", "show", f"{BASE}:Sources/LightingCore/LightingProjectDocument.swift"
    ], cwd=REPO)
    (ROOT / "baseline-original.swift").write_bytes(baseline)
    renamed = baseline.replace(b"LightingProjectDocument", b"BaselineProjectDocument")
    assert baseline.count(b"LightingProjectDocument") == 2
    (sources / "BaselineProjectDocument.swift").write_bytes(renamed)

    # Exactly the ordinary supported scene shape used in the Unicode tests.
    prefix = (b'{"schemaVersion":1,"name":"Benchmark","scene":'
              b'{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},'
              b'"camera":{"x":0,"y":1.5,"z":3},"lights":[],"metadata":')
    suffix = b"}}"
    fixtures = []
    for size in (1024 * 1024, MAX_BYTES):
        budget = size - len(prefix) - len(suffix)
        for shape in ("long_string", "empty_strings", "escaped_strings", "wide_object"):
            if shape == "long_string":
                body = b'"' + b"a" * (budget - 2) + b'"'
                members = 1
                metadata_strings = 1
            elif shape in ("empty_strings", "escaped_strings"):
                token = (b'""' if shape == "empty_strings" else
                         b'"\\uD83D\\uDCA1\\n\\t\\\\\\\"\\/\\u0000"')
                members = (budget - 1) // (len(token) + 1)
                body = b"[" + b",".join([token] * members) + b"]"
                metadata_strings = members
            else:
                # Fixed-width unique ASCII keys ensure identical size per member.
                members = (budget - 1) // 15
                body = b"{" + b",".join(
                    f'"k{i:08d}":""'.encode("ascii") for i in range(members)
                ) + b"}"
                metadata_strings = 2 * members
            assert len(body) <= budget
            padding = budget - len(body)
            data = prefix + body + b" " * padding + suffix
            assert len(data) == size <= MAX_BYTES
            decoded = json.loads(data)
            assert set(decoded) == {"schemaVersion", "name", "scene"}
            assert decoded["name"] == "Benchmark"
            assert decoded["scene"]["lights"] == []
            fixture_id = f"{shape}_{size // (1024 * 1024)}mib"
            path = inputs / f"{fixture_id}.json"
            path.write_bytes(data)
            fixtures.append({
                "id": fixture_id, "shape": shape, "path": str(path.relative_to(ROOT)),
                "bytes": len(data), "sha256": digest(data),
                "metadata_members": members, "metadata_string_tokens": metadata_strings,
                "padding_bytes": padding,
            })

    control = prefix.split(b',"metadata":')[0] + suffix
    json.loads(control)
    (inputs / "ordinary.json").write_bytes(control)
    fixtures.insert(0, {
        "id": "ordinary", "shape": "ordinary", "path": "inputs/ordinary.json",
        "bytes": len(control), "sha256": digest(control), "metadata_members": 0,
        "metadata_string_tokens": 0, "padding_bytes": 0,
    })
    cpu = pathlib.Path("/proc/cpuinfo").read_text()
    model = re.search(r"^model name\s*:\s*(.+)$", cpu, re.MULTILINE)
    manifest = {
        "baseline_revision": BASE,
        "repo_head_at_snapshot": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=REPO, text=True).strip(),
        "baseline_parser_sha256": digest(baseline),
        "baseline_renamed_parser_sha256": digest(renamed),
        "current_parser_sha256": digest((sources / "LightingProjectDocument.swift").read_bytes()),
        "baseline_adaptation": "Only replace the two occurrences of LightingProjectDocument with BaselineProjectDocument so both versions coexist in one binary.",
        "platform": platform.platform(), "cpu_model": model.group(1) if model else None,
        "maximum_document_bytes": MAX_BYTES, "sources": source_records,
        "fixtures": fixtures,
        "scope": "Full LightingProjectDocument.decode with unchanged LightingCore dependencies; host observation only, no new gate or device claim.",
    }
    (ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"prepared": len(fixtures), "source_files": len(source_records) + 1,
                      "current_parser_sha256": manifest["current_parser_sha256"],
                      "total_input_bytes": sum(f["bytes"] for f in fixtures)}, indent=2))


if __name__ == "__main__":
    main()
