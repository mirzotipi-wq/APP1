#!/usr/bin/env python3
"""Validate owner inputs and print an unsigned iOS archive plan; never execute it.

The argv arrays are the command representation. The shell-quoted text is only a
human-readable rendering. This tool has no build, signing, or upload capability.
"""

import argparse
import hashlib
import json
from pathlib import Path
import platform
import re
import shlex


ROOT = Path(__file__).resolve().parents[1]
MAX_INPUT_PATH = 1024
MAX_SPEC_BYTES = 256 * 1024
LABEL = r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
VERSION_PART = r"(?:0|[1-9][0-9]{0,3})"


def validate_identifiers(bundle_id, team_id, version, build_number):
    """Accept a conservative bounded subset; do not trim or expand input."""
    if (not isinstance(bundle_id, str) or len(bundle_id) > 255
            or re.fullmatch(rf"{LABEL}(?:\.{LABEL})+", bundle_id) is None):
        raise ValueError("bundle ID must be a reverse-DNS identifier of at most 255 ASCII characters")
    lowered = bundle_id.lower()
    if any(lowered == prefix or lowered.startswith(prefix + ".")
           for prefix in ("com.example", "org.example", "net.example")):
        raise ValueError("bundle ID must be owner-provided; example-domain placeholders are not accepted")
    if not isinstance(team_id, str) or re.fullmatch(r"[A-Z0-9]{10}", team_id) is None:
        raise ValueError("team ID must be exactly 10 uppercase ASCII letters or digits")
    if (not isinstance(version, str)
            or re.fullmatch(rf"{VERSION_PART}\.{VERSION_PART}\.{VERSION_PART}", version) is None):
        raise ValueError("version must have three decimal components, each 0–9999, without leading zeroes")
    if not isinstance(build_number, str) or re.fullmatch(r"[1-9][0-9]{0,3}", build_number) is None:
        raise ValueError("build number must be a decimal integer from 1 to 9999, without leading zeroes")


def validate_path_text(value):
    # Deliberately narrower than the host filesystem: Xcode can interpret dollar
    # expressions inside project paths even when no command shell is involved.
    if (not isinstance(value, str) or not 1 <= len(value) <= MAX_INPUT_PATH
            or re.fullmatch(r"[A-Za-z0-9_./ '-]+", value) is None):
        raise ValueError("paths must use 1–1024 ASCII letters, digits, spaces, apostrophes, /, _, -, or .")
    path = Path(value)
    if not path.is_absolute() or ".." in path.parts:
        raise ValueError("output and source paths must be absolute and contain no '..' components")
    if any(len(part) > 255 for part in path.parts):
        raise ValueError("path components must not exceed 255 characters")
    return path


def require_absent(path, label):
    # lstat sees dangling symlinks too; they must never be treated as free output.
    try:
        path.lstat()
    except FileNotFoundError:
        pass
    else:
        raise ValueError(f"{label} already exists; use a fresh path or clean checkout")


def new_output_directory(value, root):
    path = validate_path_text(value)
    require_absent(path, "output")
    parent = path.parent.resolve(strict=True)
    if not parent.is_dir():
        raise ValueError("output parent must be an existing directory")
    path = validate_path_text(str(parent / path.name))
    if path == root or root in path.parents:
        raise ValueError("output must be outside the source checkout")
    return path


def source_hash(path):
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"required source file must be a regular file: {path.name}")
    with path.open("rb") as source:
        content = source.read(MAX_SPEC_BYTES + 1)
    if not content or len(content) > MAX_SPEC_BYTES:
        raise ValueError(f"required source file is empty or exceeds 256 KiB: {path.name}")
    return hashlib.sha256(content).hexdigest()


def create_plan(bundle_id, team_id, version, build_number, output):
    validate_identifiers(bundle_id, team_id, version, build_number)
    root = validate_path_text(str(ROOT.resolve(strict=True)))
    output_path = new_output_directory(output, root)
    source_hashes = {name: source_hash(root / name) for name in ("project.yml", "Package.swift")}
    project_path = validate_path_text(str(root / "KeyAndFill.xcodeproj"))
    require_absent(project_path, "generated project")
    archive = validate_path_text(str(output_path / "KeyAndFill.xcarchive"))
    derived_data = validate_path_text(str(output_path / "DerivedData"))
    result_bundle = validate_path_text(str(output_path / "Archive.xcresult"))
    commands = [
        {
            "purpose": "Create a new artifact directory (fails if it already exists)",
            "argv": ["mkdir", str(output_path)],
        },
        {
            # XcodeGen preserves the local Swift package's path '.' verbatim.
            # Generate beside its spec so that path still resolves to the source.
            "purpose": "Generate a fresh Xcode project beside its existing source spec",
            "argv": ["xcodegen", "generate", "--spec", str(root / "project.yml"),
                     "--project", str(root), "--project-root", str(root)],
        },
        {
            "purpose": "Archive Release for generic iOS, with signing disabled",
            "argv": [
                "xcodebuild", "-project", str(project_path),
                "-scheme", "KeyAndFill", "-configuration", "Release", "-sdk", "iphoneos",
                "-destination", "generic/platform=iOS", "-archivePath", str(archive),
                "-derivedDataPath", str(derived_data),
                "-resultBundlePath", str(result_bundle),
                "-disableAutomaticPackageResolution", "-skipPackageUpdates",
                f"PRODUCT_BUNDLE_IDENTIFIER={bundle_id}", f"DEVELOPMENT_TEAM={team_id}",
                f"MARKETING_VERSION={version}", f"CURRENT_PROJECT_VERSION={build_number}",
                "CODE_SIGNING_ALLOWED=NO", "CODE_SIGNING_REQUIRED=NO", "CODE_SIGN_IDENTITY=",
                "ARCHS=arm64", "ONLY_ACTIVE_ARCH=NO", "archive",
            ],
        },
    ]
    return {
        "schema": 1,
        "mode": "dry-run",
        "execution_supported": False,
        "archive_kind": "unsigned-iphoneos",
        "host": platform.system(),
        "commands_require_host": "Darwin",
        "working_directory": str(root),
        "output_directory": str(output_path),
        "generated_project_path": str(project_path),
        "archive_path": str(archive),
        "owner_inputs": {"bundle_id": bundle_id, "team_id": team_id,
                         "version": version, "build_number": build_number},
        "source_spec_sha256": source_hashes,
        "commands": commands,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Prepare an unsigned iOS archive plan. Never runs commands or writes files.",
        allow_abbrev=False,
    )
    parser.add_argument("--bundle-id", required=True, help="owner's explicit reverse-DNS bundle ID")
    parser.add_argument("--team-id", required=True, help="owner's 10-character Apple team ID")
    parser.add_argument("--version", required=True, help="marketing version, e.g. 0.1.0")
    parser.add_argument("--build-number", required=True, help="build integer, 1–9999")
    parser.add_argument("--output", required=True, help="new absolute artifact directory outside this checkout")
    parser.add_argument("--dry-run", action="store_true", help="explicitly select the only supported mode")
    parser.add_argument("--json", action="store_true", help="print the structured plan with command argv arrays")
    args = parser.parse_args(argv)
    try:
        plan = create_plan(args.bundle_id, args.team_id, args.version, args.build_number, args.output)
    except (ValueError, OSError, RuntimeError) as error:
        parser.error(str(error))
    if args.json:
        print(json.dumps(plan, indent=2, sort_keys=True))
    else:
        print("PREPARATION ONLY: no commands executed; no files written.")
        print("The commands below require macOS, Xcode with the iPhoneOS SDK, and XcodeGen.")
        print("Expected output: unsigned archive; not installable TestFlight distribution.")
        print(f"Working directory: {plan['working_directory']}")
        for command in plan["commands"]:
            print(f"\n# {command['purpose']}")
            print(shlex.join(command["argv"]))
        print("\nRecheck that the output and generated project are absent immediately before manual execution.")
        print("Stop if any command fails. This plan does not reserve paths or establish release approval.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
