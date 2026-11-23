#!/usr/bin/env python3
"""Original Key & Fill geometric app mark, and source/bundle verification.
No external libraries, licensed images or network resources. The committed
opaque PNG is authoritative for builds; --generate recreates its pixels.
"""
import argparse
import json
import math
import pathlib
import plistlib
import struct
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
CATALOG = ROOT / "App" / "Assets.xcassets" / "AppIcon.appiconset"
ICON = CATALOG / "AppIcon.png"
SIG = b"\x89PNG\r\n\x1a\n"
SIZE = 1024
BACKGROUND = (19, 26, 34)
KEY = (244, 173, 89)
MID = (216, 135, 57)
FILL = (101, 118, 132)
NEUTRAL = (196, 205, 208)


def distance(x, y, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - ax - t * dx, y - ay - t * dy)


def corner(x, y):
    if x > 385 or y > 385 or x < 140 or y < 140:
        return False
    return (
        distance(x, y, 172, 211, 172, 362) <= 18
        or distance(x, y, 211, 172, 362, 172) <= 18
        or (x <= 211 and y <= 211 and abs(math.hypot(x - 211, y - 211) - 39) <= 18)
        or distance(x, y, 211, 211, 283, 283) <= 12.5
    )


def sample(x, y):
    dx, dy = x - 512, y - 512
    if dx * dx + dy * dy <= 254 * 254:
        wave = math.sqrt(max(0, 1 - dy * dy / (254 * 254)))
        return KEY if x < 512 - 97 * wave else MID if x < 512 + 73 * wave else FILL
    if corner(x, y):
        return KEY
    if corner(1024 - x, 1024 - y):
        return NEUTRAL
    return BACKGROUND


def render():
    """Four subsamples per pixel, opaque RGB8 with PNG Sub row filter."""
    rows = bytearray()
    for y in range(SIZE):
        rows.append(1)
        previous = (0, 0, 0)
        for x in range(SIZE):
            a = sample(x + .25, y + .25)
            b = sample(x + .75, y + .25)
            c = sample(x + .25, y + .75)
            d = sample(x + .75, y + .75)
            pixel = tuple((a[i] + b[i] + c[i] + d[i] + 2) // 4 for i in range(3))
            rows.extend((pixel[i] - previous[i]) & 255 for i in range(3))
            previous = pixel
    return bytes(rows)


def chunk(name, data):
    return struct.pack(">I", len(data)) + name + data + struct.pack(">I", zlib.crc32(name + data) & 0xffffffff)


def png(raw):
    return (
        SIG + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
        + chunk(b"sRGB", b"\x00") + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def verify_source():
    catalog = json.loads((CATALOG / "Contents.json").read_text())
    require(catalog["images"] == [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}], "Unexpected AppIcon catalog entry")
    data = ICON.read_bytes()
    require(data.startswith(SIG), "Invalid PNG signature")
    position = len(SIG)
    chunks = {}
    while position < len(data):
        require(position + 12 <= len(data), "Truncated PNG chunk")
        size = struct.unpack_from(">I", data, position)[0]
        kind = data[position + 4:position + 8]
        end = position + 8 + size
        require(end + 4 <= len(data), "Truncated PNG payload")
        payload = data[position + 8:end]
        crc = struct.unpack_from(">I", data, end)[0]
        require(crc == zlib.crc32(kind + payload) & 0xffffffff, "PNG checksum mismatch")
        chunks.setdefault(kind, []).append(payload)
        position = end + 4
        if kind == b"IEND":
            break
    require(position == len(data) and chunks.get(b"IEND") == [b""], "Invalid PNG terminator")
    require(chunks.get(b"IHDR") == [struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)], "AppIcon must be a 1024 x 1024 opaque RGB8 PNG")
    require(chunks.get(b"sRGB") == [b"\x00"] and b"tRNS" not in chunks, "AppIcon must use sRGB without transparency")
    raw = zlib.decompress(b"".join(chunks.get(b"IDAT", [])))
    stride = SIZE * 3 + 1
    require(len(raw) == SIZE * stride and all(raw[i] == 1 for i in range(0, len(raw), stride)), "Invalid AppIcon scanlines")
    print(f"Source AppIcon: {SIZE}x{SIZE}, opaque RGB8 sRGB, valid PNG checksums and decoded scanlines, {len(data)} bytes")
    return raw


def verify_bundle(bundle):
    require(bundle.is_dir(), f"Missing app bundle: {bundle}")
    require((bundle / "Assets.car").is_file(), "Compiled asset catalog missing")
    with (bundle / "Info.plist").open("rb") as stream:
        info = plistlib.load(stream)
    primary = info.get("CFBundleIcons", {}).get("CFBundlePrimaryIcon", {})
    require(primary.get("CFBundleIconName") == "AppIcon" or any(name.startswith("AppIcon") for name in primary.get("CFBundleIconFiles", [])), "Primary AppIcon missing from generated Info.plist")
    print(f"Bundle AppIcon metadata and Assets.car present: {bundle.name}; {info.get('CFBundleSupportedPlatforms')}; iOS {info.get('MinimumOSVersion')}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--generate", action="store_true", help="Regenerate source pixels as a PNG")
    parser.add_argument("--verify-design", action="store_true", help="Compare decoded scanlines to original procedural design")
    parser.add_argument("--bundle", type=pathlib.Path)
    args = parser.parse_args()
    if args.generate:
        ICON.write_bytes(png(render()))
    raw = verify_source()
    if args.verify_design:
        require(raw == render(), "Icon pixels differ from original geometric design")
        print("Original procedural design matches committed decoded pixels")
    if args.bundle:
        verify_bundle(args.bundle)


if __name__ == "__main__":
    main()
