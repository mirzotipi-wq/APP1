#!/usr/bin/env python3
"""Check the declared local-only prototype policy and actual iOS bundle resource.

This is a package integrity check, not an App Store Connect privacy report or
an audit of SDK-linked symbols and runtime network behavior.
"""
import argparse
from pathlib import Path
import plistlib

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Resources" / "PrivacyInfo.xcprivacy"
EXPECTED = {
    "NSPrivacyTracking": False,
    "NSPrivacyTrackingDomains": [],
    "NSPrivacyCollectedDataTypes": [],
    "NSPrivacyAccessedAPITypes": [
        {
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
            "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
        },
        {
            "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryFileTimestamp",
            "NSPrivacyAccessedAPITypeReasons": ["C617.1", "3B52.1"],
        }
    ],
}


def read(path):
    with path.open("rb") as stream:
        return plistlib.load(stream)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bundle", type=Path)
    args = parser.parse_args()
    source = read(SOURCE)
    if source != EXPECTED or source["NSPrivacyTracking"] is not False:
        raise SystemExit("Privacy manifest does not match the documented prototype policy; review changes.")
    print("Source privacy manifest: no declared tracking or collection; app preferences and scoped file metadata reasons")
    if args.bundle:
        path = args.bundle / "PrivacyInfo.xcprivacy"
        if not path.is_file() or read(path) != source:
            raise SystemExit(f"Missing or inconsistent packaged privacy manifest: {path}")
        print(f"Verified app bundle privacy manifest: {path}")


if __name__ == "__main__":
    main()
