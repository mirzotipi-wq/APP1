#!/bin/sh
exec /workspace/scratch/13a77d3f98df/toolchain/usr/bin/swiftc -Xfrontend -solver-expression-time-threshold=120 -Xfrontend -solver-scope-threshold=10000000 -Xfrontend -solver-memory-threshold -Xfrontend 1073741824 "$@"
