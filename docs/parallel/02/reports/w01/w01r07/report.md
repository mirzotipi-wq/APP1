# W01R07 — plan consumer trace

Assigned revision: `f150f98e35dd735927075aac4d2f8b02295c6a67` (not independently rechecked).

Result: source inspection supports correct candela labeling. `Sources/LightingCore/LightingPlan.swift:220` copies `light.candela`; line 125 appends `cd`. The complete file contains no meter call or `lx` text. Its plain-text composition (303–318) includes equipment settings and the ideal-source disclaimer, without any meter-to-zero conversion.

The plan's only `StudioPhotometry` calls are `frame` (224, 339). The corresponding entry, `Sources/LightingCore/StudioOptics.swift:107–110`, returns an optional emitter frame; invalid/non-aimed inputs return nil. It is not a meter entry.

Limitation: actual meter-consumer unsupported-versus-zero and lux-label semantics were not checked here because this file does not consume a meter. No runtime, build, numerical, or export-display verification performed; source unchanged.

Actual inspection commands, all from `/tmp/keyfill02-workers/w01r07`:

```bash
rg --files --hidden -g AGENTS.md -g '!\.git/**' -g '!private-output/**' /tmp/keyfill02-workers/w01r07
cat AGENTS.md
python3 - <<'PY'
from pathlib import Path
import re
plan_path = Path('Sources/LightingCore/LightingPlan.swift')
plan = plan_path.read_text().splitlines()
print(f'--- {plan_path} ---')
for number, line in enumerate(plan, 1):
    print(f'{number:4}: {line}')
optics_path = Path('Sources/LightingCore/StudioOptics.swift')
optics = optics_path.read_text().splitlines()
refs = set(re.findall(r'\b(?:Studio\w+)\.([A-Za-z_]\w*)\s*\(', '\n'.join(plan)))
print(f'--- {optics_path}: called entry points {sorted(refs)} ---')
for start, line in enumerate(optics):
    if any(re.search(r'\bfunc\s+' + re.escape(name) + r'\s*\(', line) for name in refs):
        end, depth, opened = start, 0, False
        while end < len(optics):
            depth += optics[end].count('{') - optics[end].count('}')
            opened = opened or '{' in optics[end]
            end += 1
            if opened and depth == 0:
                break
        for index in range(max(0, start - 5), end):
            print(f'{index + 1:4}: {optics[index]}')
PY
```
