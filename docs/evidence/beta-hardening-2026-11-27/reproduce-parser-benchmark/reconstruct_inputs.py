#!/usr/bin/env python3
"""Recreate A023's nine inputs only; never execute its snapshot-writing prepare.py."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

EVIDENCE = Path(__file__).resolve().parent.parent
MAX_BYTES = 8 * 1024 * 1024
FROZEN_HASHES = {
    "unicode-performance-before/prepare.py":
        "1f8206634c079cb8f4beaee3fe27bccbaa7fca771b66bc51f8ef0f0b15acf149",
    "unicode-performance-before/manifest.json":
        "9970a8c3864c4a46049d97f88e1ecfd1827bc5bc335dd08fae9adc40d1be540d",
    "unicode-performance-after/manifest.json":
        "9dd1059b14e81859ca3c1d72a68f99d453c8455e0583e17aeaf4966f47a62a73",
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_checked(path: Path, expected_hash: str) -> bytes:
    data = path.read_bytes()
    if digest(data) != expected_hash:
        raise ValueError(f"SHA-256 mismatch: {path}")
    return data


def load_manifests() -> tuple[dict, dict]:
    pinned = {name: read_checked(EVIDENCE / name, sha)
              for name, sha in FROZEN_HASHES.items()}
    before = json.loads(pinned["unicode-performance-before/manifest.json"])
    after = json.loads(pinned["unicode-performance-after/manifest.json"])
    if (before["fixtures"] != after["fixtures"] or len(before["fixtures"]) != 9
            or before["maximum_document_bytes"] != MAX_BYTES
            or after["maximum_document_bytes"] != MAX_BYTES):
        raise ValueError("Frozen fixture manifests disagree")
    return before, after


def new_output_directory(requested: Path) -> Path:
    candidate = requested.expanduser()
    if candidate.exists() or candidate.is_symlink():
        raise ValueError(f"Output already exists; choose a fresh directory: {candidate}")
    output = candidate.resolve()
    if output == EVIDENCE or EVIDENCE in output.parents:
        raise ValueError("Output must be outside the preserved evidence tree")
    if not output.parent.is_dir():
        raise ValueError(f"Output parent must already exist: {output.parent}")
    output.mkdir(mode=0o700, exist_ok=False)
    return output


def write_new(path: Path, data: bytes) -> None:
    with path.open("xb") as stream:
        stream.write(data)


def write_json(path: Path, value: dict) -> None:
    write_new(path, (json.dumps(value, indent=2) + "\n").encode("utf-8"))


def generated_fixtures():
    # Fixture-only extraction of the pinned A023 prepare.py logic. Its source-copy,
    # git-show and manifest-writing operations are deliberately not invoked.
    prefix = (b'{"schemaVersion":1,"name":"Benchmark","scene":'
              b'{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},'
              b'"camera":{"x":0,"y":1.5,"z":3},"lights":[],"metadata":')
    suffix = b"}}"
    control = prefix.split(b',"metadata":')[0] + suffix
    yield "ordinary", "ordinary", control, 0, 0, 0
    for size in (1024 * 1024, MAX_BYTES):
        budget = size - len(prefix) - len(suffix)
        for shape in ("long_string", "empty_strings", "escaped_strings", "wide_object"):
            if shape == "long_string":
                body = b'"' + b"a" * (budget - 2) + b'"'
                members = metadata_strings = 1
            elif shape in ("empty_strings", "escaped_strings"):
                token = (b'""' if shape == "empty_strings" else
                         b'"\\uD83D\\uDCA1\\n\\t\\\\\\\"\\/\\u0000"')
                members = (budget - 1) // (len(token) + 1)
                body = b"[" + b",".join([token] * members) + b"]"
                metadata_strings = members
            else:
                members = (budget - 1) // 15
                body = b"{" + b",".join(
                    f'"k{i:08d}":""'.encode("ascii") for i in range(members)
                ) + b"}"
                metadata_strings = 2 * members
            padding = budget - len(body)
            data = prefix + body + b" " * padding + suffix
            if padding < 0 or len(data) != size:
                raise ValueError(f"Wrong generated size: {shape}/{size}")
            yield (f"{shape}_{size // (1024 * 1024)}mib", shape, data,
                   members, metadata_strings, padding)


def verify_inputs(root: Path, fixtures: list[dict]) -> list[dict]:
    records = []
    for fixture in fixtures:
        data = read_checked(root / fixture["path"], fixture["sha256"])
        if len(data) != fixture["bytes"]:
            raise ValueError(f"Wrong fixture size: {fixture['id']}")
        records.append({"path": fixture["path"], "bytes": len(data), "sha256": digest(data)})
    return records


def reconstruct(requested: Path) -> dict:
    before, _ = load_manifests()
    expected = {fixture["id"]: fixture for fixture in before["fixtures"]}
    output = new_output_directory(requested)
    (output / "inputs").mkdir()
    actual = []
    for fixture_id, shape, data, members, strings, padding in generated_fixtures():
        record = {
            "id": fixture_id, "shape": shape, "path": f"inputs/{fixture_id}.json",
            "bytes": len(data), "sha256": digest(data), "metadata_members": members,
            "metadata_string_tokens": strings, "padding_bytes": padding,
        }
        if record != expected.get(fixture_id):
            raise ValueError(f"Generated fixture does not match frozen manifest: {fixture_id}")
        decoded = json.loads(data)
        if (set(decoded) != {"schemaVersion", "name", "scene"}
                or decoded["name"] != "Benchmark" or decoded["scene"]["lights"] != []):
            raise ValueError(f"Unexpected decoded fixture: {fixture_id}")
        write_new(output / record["path"], data)
        actual.append(record)
    if actual != before["fixtures"]:
        raise ValueError("Generated fixture inventory differs from the frozen manifest")
    verify_inputs(output, actual)
    receipt = {
        "schema": 1, "scope": "Fixture reconstruction only; no Swift execution",
        "frozen_files_sha256": FROZEN_HASHES,
        "fixture_count": len(actual), "total_input_bytes": sum(f["bytes"] for f in actual),
        "all_expected_hashes_match": True, "fixtures": actual,
    }
    write_json(output / "verification.json", receipt)
    return receipt


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, required=True,
                        help="New directory, outside preserved evidence; parent must exist")
    args = parser.parse_args()
    try:
        print(json.dumps(reconstruct(args.output_dir), indent=2))
    except (OSError, ValueError) as error:
        parser.exit(1, f"error: {error}\n")


if __name__ == "__main__":
    main()
