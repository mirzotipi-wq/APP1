# W05 R03 command record

All commands executed in /tmp/keyfill02-r2-workers/w05r03 unless absolute paths specify the input. Initial source reads used cat and rg. One mistaken read of Optics.swift / StudioPhotometry.swift returned exit 2 (paths absent); rg --files identified StudioOptics.swift, which was then read successfully.

## Inspection commands

```sh
pwd
rg --files -g AGENTS.md -g QUALITY.md -g WAVE-TASKS.md -g LightOutputAdjustment.swift -g '*Light*' -g '*Scene*'
cat /tmp/keyfill02-r2-brief.md
cat AGENTS.md docs/QUALITY.md
rg -n -A 32 -B 12 'W05|R03' /tmp/keyfill02-r2/docs/parallel/02/WAVE-TASKS.md
git status --short
git log -3 --format='%H %s'
cat Sources/LightingCore/LightOutputAdjustment.swift
cat Sources/LightingCore/Scene.swift
cat /tmp/keyfill02-r2-probe.py
cat Tests/LightingCoreTests/LightOutputBoundaryTests.swift
rg -n 'enum EmitterKind|struct LightOptics|enum StudioPhotometry|static func illuminance|minimum|distanceMeters|receiver' Sources/LightingCore/Optics.swift Sources/LightingCore/StudioPhotometry.swift
rg --files Sources/LightingCore | rg 'Optics|Photometry'
git diff 1b286885cb803ba17e159713651515ab119e17f1 HEAD --stat -- Sources/LightingCore
rg --files /tmp/keyfill02-r2-snapshots/v1
cat Sources/LightingCore/StudioOptics.swift
cat /tmp/keyfill02-r2-snapshots/v1/READY
git diff 58b3ca43 HEAD --stat -- Sources/LightingCore
git branch --show-current
rg -n -A 30 -B 8 'func pointIlluminance|distance >=|distanceMeters|minimum' Sources/LightingCore/SurfacePhotometry.swift
```

Additional provenance reads (exact argv, stdout, exit) appear in provenance.json. References are literal copied inputs from this execution. Initial HEAD was detached and clean. private-output is the only write destination.

## Bounded probe (pending)

```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w05r03 /tmp/keyfill02-r2-workers/w05r03/private-output/probe.swift v1
```

The helper serializes swiftc with flock, links the prebuilt immutable library, and writes compile.log and probe.log. No package build is used.

## Probe result and final checks

The recorded bounded probe command above was executed once: exit 0. compile.log is empty (compiler emitted no diagnostics); probe.log contains the original execution output. All 24 expected classifications matched. cases.tsv is a direct extraction of the original header and case rows. No executor reset occurred during this role.

```sh
git diff --exit-code -- Sources/LightingCore
git status --short
```

Results: production diff exit 0 with empty stdout/stderr; status exit 0 and only `?? private-output/`. Evidence-generation Python wrote reference copies, source/module SHA-256 provenance, this command record, probe.swift, cases.tsv, and report.md solely under private-output. The probe helper wrote probe, compile.log and probe.log there. Provenance records toolchain and exact validation argv/output.
