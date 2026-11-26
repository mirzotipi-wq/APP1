#!/usr/bin/env python3
"""Read-only source preservation checks; does not parse or execute Swift."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else '/tmp/keyfill04-2987b1ee980d/workers/w045')
LIVE_RENDERER = Path('/tmp/keyfill04-2987b1ee980d/workers/w044/App/MetalStudyRenderer.swift')
BASE = '88279ba0ee0262ea6c880580c8a85b56342abbff'
TARGET = 'NativeTests/StudyRenderCacheTests.swift'

def command(args):
    result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True)
    entry = dict(argv=args, cwd=str(ROOT), exit=result.returncode,
                 stdout=result.stdout, stderr=result.stderr)
    commands.append(entry)
    return result

commands = []
head = command(['git', 'rev-parse', 'HEAD'])
status = command(['git', 'status', '--short', '--branch'])
diff_check = command(['git', 'diff', '--check'])
changed = command(['git', 'diff', '--name-only'])
cycle_check = command(['python3', 'scripts/agent_cycle.py', 'check'])
cycle_next = command(['python3', 'scripts/agent_cycle.py', 'next'])
base_result = command(['git', 'show', f'{BASE}:{TARGET}'])
original = base_result.stdout
current = (ROOT / TARGET).read_text()
original_prefix = original[:original.rfind('\n}')]
pattern = r'^    func (test\w+)\('
original_methods = re.findall(pattern, original, re.M)
current_methods = re.findall(pattern, current, re.M)
new_methods = [name for name in current_methods if name not in original_methods]
metal_paths = ['NativeTests/StudyRendererTests.swift', 'NativeTests/StudyPrecisionMatrixTests.swift']
unchanged_metal = {}
for name in metal_paths:
    before = command(['git', 'show', f'{BASE}:{name}'])
    unchanged_metal[name] = before.returncode == 0 and (ROOT / name).read_text() == before.stdout
live = LIVE_RENDERER.read_text()
checks = {
    'base_revision_matches': head.stdout.strip() == BASE,
    'only_owned_source_changed': changed.stdout.splitlines() == [TARGET],
    'whitespace_check_passed': diff_check.returncode == 0,
    'original_source_prefix_byte_preserved': current.startswith(original_prefix),
    'original_test_methods_retained': all(name in current_methods for name in original_methods),
    'method_names_unique': len(current_methods) == len(set(current_methods)),
    'eight_new_methods': len(new_methods) == 8,
    'actual_metal_test_sources_unchanged': all(unchanged_metal.values()),
    'live_protocol_present': 'protocol StudyComputeBackend {' in live,
    'live_injected_factory_present': 'makeComputeBackend: @escaping @Sendable () throws -> any StudyComputeBackend' in live,
    'live_cache_usage_present': 'var cacheUsage: (count: Int, pixelBytes: Int, maskBytes: Int)' in live,
    'cycle_structure_check_passed': cycle_check.returncode == 0,
}
report = {
    'worker': 'w045', 'base': BASE,
    'claim': 'Static source checks only; Swift compilation and all native execution unrun.',
    'checks': checks,
    'original_test_method_count': len(original_methods),
    'total_test_method_count': len(current_methods),
    'new_test_methods': new_methods,
    'actual_metal_source_preservation': unchanged_metal,
    'target_sha256': hashlib.sha256((ROOT / TARGET).read_bytes()).hexdigest(),
    'reviewed_renderer_sha256': hashlib.sha256(LIVE_RENDERER.read_bytes()).hexdigest(),
    'commands': commands,
    'environment_limit': 'No compiler, SDK installation, native test, GPU submission, ref update, commit, or push executed by this worker.',
}
print(json.dumps(report, indent=2))
sys.exit(0 if all(checks.values()) else 1)
