"""Finalize only after all nine actual child agents have returned."""
import datetime
import hashlib
import json
import pathlib
import subprocess

ROOT = pathlib.Path(__file__).resolve().parent
path = ROOT/'ledger.json'
ledger = json.loads(path.read_text())
assert ledger['completed_count'] == 10
assert len(ledger['workers']) == 10
assert ledger['actual_spawned_children'] == ledger['actual_returned_children'] == 9
assert ledger['active_children'] == 0
assert len({w['agent_id'] for w in ledger['workers']}) == 10
assert {w['worker'] for w in ledger['workers']} == {f'W02R{n:02d}' for n in range(1, 11)}
for worker in ledger['workers']:
    assert worker['status'] == 'completed'
    worktree = pathlib.Path(worker['worktree'])
    head = subprocess.check_output(['git', '-C', str(worktree), 'rev-parse', 'HEAD'], text=True).strip()
    assert head == ledger['input_sha'], (worker['worker'], head)
    modified = subprocess.check_output(['git', '-C', str(worktree), 'diff', '--name-only', 'HEAD', '--', 'Sources', 'Tests'], text=True)
    assert not modified, (worker['worker'], modified)
    directory = pathlib.Path(worker['artifact_directory'])
    files = [f for f in sorted(directory.rglob('*')) if f.is_file()]
    assert (directory/'report.md').is_file()
    for artifact in files:
        assert artifact.read_bytes()[:4] != b'\x7fELF', str(artifact)
    worker['artifacts'] = [str(f) for f in files]
    worker['artifact_sha256'] = {str(f.relative_to(ROOT)): hashlib.sha256(f.read_bytes()).hexdigest() for f in files}
    worker['worktree_verified_sha'] = head
    worker['production_and_tests_unchanged'] = True
    worker['report_word_count'] = len((directory/'report.md').read_text().split())
    assert worker['report_word_count'] < 450, (worker['worker'], 'review report cap')
ledger['wave_complete'] = True
ledger['completed_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
ledger['checkpoint'] = str(ROOT/'checkpoint-six.json')
ledger['summary_sha256'] = hashlib.sha256((ROOT/'summary.md').read_bytes()).hexdigest()
ledger['verification'] = 'Ten unique actual agent identities, nine returned children, frozen worktree HEADs, unchanged production/tests, and text-only evidence verified. No later wave, commit, push or cleanup performed.'
path.write_text(json.dumps(ledger, indent=2)+'\n')
print(json.dumps({'completed_count': 10, 'actual_returned_children': 9, 'wave_complete': True, 'report_word_counts': {w['worker']: w['report_word_count'] for w in ledger['workers']}}, indent=2))
