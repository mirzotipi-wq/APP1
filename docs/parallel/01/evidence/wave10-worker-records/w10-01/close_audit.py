from pathlib import Path
import datetime, hashlib, json, subprocess

root = Path('/workspace/scratch/e08d5190f17c')
repo = root / 'keyfill-01'
records = root / 'workers'
p = records / 'w10-01'
ledger_path = p / 'ledger.json'
ledger = json.loads(ledger_path.read_text())
prior = json.loads((repo / 'docs/parallel/01/WORKER_LEDGER.json').read_text())
prior = [e for e in prior['entries'] if not e['worker'].startswith('W10-')]
assert len(prior) == 90
all_ids = [e['agent_id'] for e in prior] + [e['agent_id'] for e in ledger['workers']]
assert len(all_ids) == len(set(all_ids)) == 100
assert ledger['fresh_count'] == 10 and ledger['fresh_peers_created'] == 9
assert ledger['completed_fresh_count'] == 10
assert sorted(w['global_context_number'] for w in ledger['workers']) == list(range(91, 101))
for e in prior:
    actual = hashlib.sha256((repo / e['report_path']).read_bytes()).hexdigest()
    assert actual == e['report_sha256'], e['worker']
checks = 90
for w in ledger['workers']:
    assert w['status'] == 'completed'
    assert w['brief_tool_token_estimate'] <= 2000
    assert w['report_tool_token_estimate'] <= 800
    for key in ['brief', 'report', 'receipt']:
        assert hashlib.sha256(Path(w[key]).read_bytes()).hexdigest() == w[key+'_sha256']
        checks += 1
    assert w['cleanup']['removed'] and w['cleanup']['clean_status_verified']
    assert not Path(w['tree']).exists()
    expected = subprocess.check_output(['git', 'diff', '--binary', ledger['base'], w['preserved_head']], cwd=repo)
    assert expected == (records / w['number'].lower() / 'source.patch').read_bytes()
    if w['number'] != 'W10-01':
        for item in w['artifacts']:
            assert hashlib.sha256(Path(item['path']).read_bytes()).hexdigest() == item['sha256']
            checks += 1
audit = {
    'created_total': 100,
    'completed_total': 100,
    'distinct_actual_ids': 100,
    'prior90_reports_verified': 90,
    'w10_reports_verified': 10,
    'w10_fresh_contexts': 10,
    'w10_fresh_peers': 9,
    'scheduler_counted_once': True,
    'additional_or_nested_spawns': 0,
    'same_context_followups': len(ledger.get('same_context_followup_events', [])),
    'followup_fresh_context_credit': 0,
    'all_final_reports_within_800_tool_estimated_tokens': True,
    'all_briefs_within_2000_tool_estimated_tokens': True,
    'all_w10_committed_diffs_match_preserved_patches': True,
    'all_w10_worktrees_clean_before_removal_and_removed': True,
    'hash_checks': checks,
    'source_code': 'ce9f7aabd2de935c933468a00f007604ed7ea6ca',
    'code_tree': '7e02b41c9df248f84207afb5599cb2cdf76ded7d',
    'native_acceptance': 'unverified',
    'created_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'scope': 'Scheduler closure after all nine peer finals. Ledger itself excluded from artifact hashes to avoid a self-hash cycle; root must publish final docs and verify remote.'
}
(p / 'final-audit.json').write_text(json.dumps(audit, indent=2)+'\n')
own = next(w for w in ledger['workers'] if w['number'] == 'W10-01')
own['artifacts'] = [{'path':str(f), 'sha256':hashlib.sha256(f.read_bytes()).hexdigest(), 'bytes':f.stat().st_size} for f in sorted(p.iterdir()) if f.is_file() and f.name != 'ledger.json']
ledger['final_audit'] = {'path':str(p/'final-audit.json'), 'sha256':hashlib.sha256((p/'final-audit.json').read_bytes()).hexdigest()}
ledger_path.write_text(json.dumps(ledger, indent=2)+'\n')
print(json.dumps({'created_total':100, 'completed_total':100, 'ledger_sha256':hashlib.sha256(ledger_path.read_bytes()).hexdigest(), 'final_audit':ledger['final_audit']}))
