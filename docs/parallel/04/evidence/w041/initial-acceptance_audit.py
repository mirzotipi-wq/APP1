#!/usr/bin/env python3
"""Read-only source/inventory receipt. This does not execute Swift or Metal."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path('/tmp/keyfill04-2987b1ee980d')
BASE = '88279ba0ee0262ea6c880580c8a85b56342abbff'
REFERENCE = ROOT / 'workers/w041'
OWNERS = {
    'App/MetalStudyRenderer.swift': ROOT / 'workers/w044',
    'NativeTests/StudyRenderCacheTests.swift': ROOT / 'workers/w045',
}


def git(directory, *arguments):
    return subprocess.check_output(['git', '-C', str(directory), *arguments])


def digest(data):
    return {
        'sha256': hashlib.sha256(data).hexdigest(),
        'git_blob_sha': hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest(),
        'bytes': len(data),
    }


def methods(data):
    return sorted(re.findall(rb'\bfunc\s+(test\w*)\s*\(', data))


def main():
    receipt = {
        'base': BASE,
        'command': 'python3 /tmp/keyfill04-2987b1ee980d/results/w041/acceptance_audit.py',
        'kind': 'source identity and declaration inventory only',
        'native_methods_executed': 0,
        'swift_compilation_executed': False,
        'actual_metal_executed': False,
        'owners': {},
        'protected_files': [],
        'native_inventory': {},
        'findings': [],
    }
    for target, worktree in OWNERS.items():
        changed = git(worktree, 'diff', '--name-only', BASE).decode().splitlines()
        untracked = git(worktree, 'ls-files', '--others', '--exclude-standard').decode().splitlines()
        diff_check = subprocess.run(['git', '-C', str(worktree), 'diff', '--check', BASE], capture_output=True, text=True)
        content = (worktree / target).read_bytes()
        receipt['owners'][target] = {
            'worktree': str(worktree),
            'changed_paths': changed,
            'untracked_paths': untracked,
            'diff_check_exit': diff_check.returncode,
            'diff_check_output': diff_check.stdout + diff_check.stderr,
            **digest(content),
        }
        if changed != [target] or untracked or diff_check.returncode:
            receipt['findings'].append(f'Unexpected scope or patch formatting in {worktree}')

    protected = git(REFERENCE, 'ls-tree', '-r', '--name-only', BASE, 'App', 'Sources', 'Tests', 'NativeTests', 'Resources', 'scripts', '.github', 'project.yml', 'Package.swift').decode().splitlines()
    for relative in protected:
        before = git(REFERENCE, 'show', f'{BASE}:{relative}')
        if relative not in OWNERS:
            copies = [REFERENCE / relative] + [owner / relative for owner in OWNERS.values()]
            same = all(copy.read_bytes() == before for copy in copies)
            receipt['protected_files'].append({'path': relative, 'unchanged_in_reference_and_writer_trees': same, **digest(before)})
            if not same:
                receipt['findings'].append(f'Protected file changed: {relative}')
        if relative.startswith('NativeTests/') and relative.endswith('.swift'):
            after = ((OWNERS.get(relative, REFERENCE)) / relative).read_bytes()
            old = methods(before)
            new = methods(after)
            if not old and not new:
                continue
            removed = sorted(set(old) - set(new))
            receipt['native_inventory'][relative] = {
                'before': len(old), 'after': len(new),
                'added_methods': [name.decode() for name in sorted(set(new) - set(old))],
                'removed_methods': [name.decode() for name in removed],
            }
            if removed:
                receipt['findings'].append(f'Native test declarations removed: {relative}')

    receipt['native_method_count_before'] = sum(row['before'] for row in receipt['native_inventory'].values())
    receipt['native_method_count_after'] = sum(row['after'] for row in receipt['native_inventory'].values())
    receipt['protected_file_count'] = len(receipt['protected_files'])
    receipt['result'] = 'source-scope-and-inventory-checks-passed' if not receipt['findings'] else 'failed'
    output = ROOT / 'results/w041/acceptance-audit.json'
    output.write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({key: receipt[key] for key in ['result', 'native_method_count_before', 'native_method_count_after', 'protected_file_count', 'findings']}))
    return 0 if not receipt['findings'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
