#!/usr/bin/env bash
set -euo pipefail

# Xcode 26 can be installed without its optional Metal component. Finding the
# xcrun wrapper is insufficient: compile and link a real simulator shader.
probe_dir=$(mktemp -d /tmp/keyfill-metal.XXXXXX)
trap 'rm -rf "$probe_dir"' EXIT
cat > "$probe_dir/probe.metal" <<'METAL'
#include <metal_stdlib>
using namespace metal;
kernel void keyfill_toolchain_probe(uint index [[thread_position_in_grid]]) {}
METAL

compile_probe() {
  xcrun --sdk iphonesimulator metal -c "$probe_dir/probe.metal" -o "$probe_dir/probe.air" &&
    xcrun --sdk iphonesimulator metal "$probe_dir/probe.air" -o "$probe_dir/probe.metallib" &&
    test -s "$probe_dir/probe.metallib"
}

if ! compile_probe; then
  echo "Metal compiler probe failed; installing the selected Xcode Metal component."
  xcodebuild -downloadComponent metalToolchain
  compile_probe
fi
echo "Metal simulator compile and link probe passed."
