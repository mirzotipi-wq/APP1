"""Restore the pinned portable test compiler after a temporary-runtime reset.

This is evidence tooling, not app code or CI configuration. It writes only the
specified temporary destination and evidence directory. No Apple SDK is present.
"""
from pathlib import Path
import argparse
import gzip
import hashlib
import json
import shutil
import subprocess
import tarfile
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument("--destination", type=Path, required=True)
parser.add_argument("--evidence", type=Path, required=True)
args = parser.parse_args()
scratch = args.destination.with_name(args.destination.name + "-download")
scratch.mkdir(parents=True, exist_ok=True)
args.evidence.mkdir(parents=True, exist_ok=True)
url = "https://download.swift.org/swift-6.0.3-release/debian12/swift-6.0.3-RELEASE/swift-6.0.3-RELEASE-debian12.tar.gz"
expected = "6f78203e4b0037c8ecfae89096433eb0ef198d20ae4b2ebfadf3c04209d2cde2"
for name, source in [("swift.tar.gz", url), ("swift.tar.gz.sig", url + ".sig"),
                     ("keys.asc", "https://www.swift.org/keys/all-keys.asc")]:
    data = urllib.request.urlopen(source).read()
    if name != "swift.tar.gz" and data[:2] == b"\x1f\x8b":
        data = gzip.decompress(data)
    (scratch / name).write_bytes(data)
    print("Downloaded", name, len(data), flush=True)
with (scratch / "swift.tar.gz").open("rb") as archive:
    digest = hashlib.file_digest(archive, "sha256").hexdigest()
if digest != expected:
    raise RuntimeError("Archive differs from the previously verified Swift release")
keyring = scratch / "gnupg"
keyring.mkdir(mode=0o700, exist_ok=True)
gpg = ["gpg", "--homedir", str(keyring), "--no-autostart", "--batch"]
imported = subprocess.run(gpg + ["--import", str(scratch / "keys.asc")],
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
(args.evidence / "key-import.log").write_text(imported.stdout)
# Public-key import can report an unavailable gpg-agent. Verification itself
# must succeed, independently of that optional agent startup.
verified = subprocess.run(gpg + ["--verify", str(scratch / "swift.tar.gz.sig"),
                                  str(scratch / "swift.tar.gz")],
                          stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
(args.evidence / "signature.log").write_text(verified.stdout)
verified.check_returncode()
bins = set("swift swiftc swift-driver swift-frontend swift-build swift-test swift-package "
           "swift-package-collection swift-package-registry swift-help swift-autolink-extract "
           "swift-symbolgraph-extract clang clang++ clang-17 ld.lld lld llvm-ar llvm-ranlib "
           "swift-api-digester swift-demangle".split())


def selected(name):
    _, _, name = name.partition("/")
    return (name.startswith(("usr/lib/swift/", "usr/lib/clang/", "usr/include/", "usr/share/swift/"))
            or (name.startswith("usr/bin/") and name.split("/")[-1] in bins)
            or (name.startswith("usr/lib/") and name.count("/") == 2 and ".so" in name
                and not any(part in name for part in ["liblldb", "libsourcekitd"])))


with tarfile.open(scratch / "swift.tar.gz", "r:gz") as archive:
    members = [member for member in archive.getmembers() if selected(member.name)]
    size = sum(member.size for member in members)
    if size + 200_000_000 > shutil.disk_usage(scratch).free:
        raise RuntimeError("Insufficient temporary disk space for compiler extraction")
    for member in members:
        member.name = member.name.split("/", 1)[1]
        archive.extract(member, args.destination, filter="data")
provenance = {"source_url": url, "archive_sha256": digest,
              "selected_bytes": size, "signature_exit_code": verified.returncode,
              "key_import_exit_code": imported.returncode}
for binary in ["swift", "swiftc", "swift-package"]:
    path = args.destination / "usr/bin" / binary
    result = subprocess.run([str(path), "--version"], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    (args.evidence / (binary + "-version.log")).write_text(result.stdout)
    result.check_returncode()
    print(result.stdout, flush=True)
for binary in ["swift-frontend", "swift-package"]:
    with (args.destination / "usr/bin" / binary).open("rb") as source:
        provenance[binary + "_sha256"] = hashlib.file_digest(source, "sha256").hexdigest()
(args.evidence / "provenance.json").write_text(json.dumps(provenance, indent=2) + "\n")
(scratch / "swift.tar.gz").unlink()
