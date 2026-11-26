#!/usr/bin/env python3
"""Reconcile retained root evidence; does not execute Swift or re-run tests."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path('/tmp/keyfill03-7f4b/workers/W21-acceptance')
INPUT = '1cefc654630a86ab320e58283957f4e91d6cbce6'
EVIDENCE = ROOT / 'docs/parallel/03/evidence'

def git(*args):
    return subprocess.check_output(['git', '-C', str(ROOT), *args], text=True).strip()

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def cases(path):
    text = path.read_text()
    events = re.findall(r"Test Case '([^']+)' (started|passed|failed)", text)
    starts = [name for name, event in events if event == 'started']
    passed = [name for name, event in events if event == 'passed']
    failed = [name for name, event in events if event == 'failed']
    return {
        'log_sha256': digest(path),
        'started_methods': len(starts),
        'passed_methods': len(passed),
        'failed_methods': failed,
        'unique_methods': len(set(starts)),
        'assertion_failure_lines': len(re.findall(r'\.swift:\d+: error: ', text)),
        'terminal_summary': re.findall(r'Executed \d+ tests, with \d+ failures[^\n]*', text)[-1],
        'all_started_are_terminal': sorted(starts) == sorted(passed + failed),
    }

assert git('rev-parse', 'HEAD') == INPUT
manifest = json.loads((EVIDENCE / 'wave03-test-inputs.json').read_text())
hash_checks = {path: digest(ROOT / path) == sha
               for path, sha in manifest['sourceSHA256'].items()}
assert all(hash_checks.values())
production = git('diff', '--name-only', INPUT + '^', INPUT, '--', 'Sources').splitlines()
assert production == ['Sources/LightingCore/PortraitHeadMesh.swift',
                      'Sources/LightingCore/ReferenceStudy.swift']
root_runs = {name: cases(EVIDENCE / f'wave03-{name.lower()}.log')
             for name in ('Debug', 'Release')}
for run in root_runs.values():
    assert run['started_methods'] == run['passed_methods'] == run['unique_methods'] == 380
    assert not run['failed_methods']
    assert run['assertion_failure_lines'] == 0
    assert run['all_started_are_terminal']
original = cases(EVIDENCE / 'wave02-original-probes.log')
assert original['started_methods'] == original['unique_methods'] == 24
assert original['passed_methods'] == 21
assert len(original['failed_methods']) == 3
assert original['assertion_failure_lines'] == 25
assert original['all_started_are_terminal']
added_tests = git('diff', '--name-only', '--diff-filter=A', INPUT + '^', INPUT,
                  '--', 'Tests').splitlines()
report = {
    'worker': 'W21-acceptance',
    'actual_runtime_id': '/root/wave03',
    'input_sha': INPUT,
    'execution_kind': 'Python evidence reconciliation; retained Swift runs executed by root',
    'probe_history': ['Initial broad error substring also counted photometry relative-error diagnostics; corrected to XCTest file/line error syntax. No product failure was inferred.'],
    'source_manifest_entries': len(hash_checks),
    'all_listed_source_hashes_match': all(hash_checks.values()),
    'production_files_changed': production,
    'new_test_files': added_tests,
    'new_test_files_omitted_from_selective_hash_manifest':
        [path for path in added_tests if path not in hash_checks],
    'immutable_input_sha256_for_new_tests': {path: digest(ROOT / path) for path in added_tests},
    'root_retained_runs': root_runs,
    'root_original_failure_run': original,
    'new_swift_executions': 0,
    'private_status': git('status', '--porcelain'),
}
print(json.dumps(report, indent=2))
