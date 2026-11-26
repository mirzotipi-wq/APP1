#!/usr/bin/env python3
"""Reconcile retained primary worker records without manufacturing missing work.

Run from any directory; --final requires 100 completed primary reports. Runtime
canonical IDs are the actual IDs exposed by the collaboration tools. Word and
byte counts are report-size proxies, not token measurements.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
LANE = ROOT / 'docs/parallel/03'
WORKERS = LANE / 'workers'
ROLES = ['acceptance', 'geometry/data', 'API', 'implementation', 'concurrency',
         'resource', 'consumer', 'accessibility/privacy', 'platform/performance',
         'independent review']
ALIASES = {'geometry': 'geometry/data', 'geometry-data': 'geometry/data',
           'api': 'API', 'accessibility-privacy': 'accessibility/privacy',
           'platform-performance': 'platform/performance',
           'independent-review': 'independent review'}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pick(d, *keys):
    return next((d[k] for k in keys if d.get(k) is not None), None)


def resolve_report(raw):
    if raw is None:
        return None
    p = Path(raw)
    candidates = [p] if p.is_absolute() else [ROOT / p, WORKERS / p]
    for q in candidates:
        if q.is_file():
            return q
    return candidates[0]


def relative(path):
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def main(final=False):
    rows, waves, errors, followups = [], [], [], []
    latest = {}
    for ledger in sorted(WORKERS.glob('wave??.json')):
        wave = int(ledger.stem[-2:])
        if not 1 <= wave <= 10:
            continue
        data = json.loads(ledger.read_text())
        if wave == 10:
            latest = data
        records = data['workers']
        wave_rows = []
        for original in records:
            label = original['worker']
            number = int(re.fullmatch(r'W(\d+)(?:-.*)?', label)[1])
            runtime = pick(original, 'actual_runtime_id', 'runtime_id', 'runtimeID')
            canonical = pick(original, 'canonical_task_path', 'canonicalTaskPath')
            role = ALIASES.get(original['role'], original['role'])
            status = pick(original, 'execution_status', 'status', 'executionStatus')
            raw_report = pick(original, 'report', 'output_report')
            report = resolve_report(raw_report)
            exists = report is not None and report.is_file()
            sha = digest(report) if exists else None
            recorded_sha = pick(original, 'report_sha256', 'reportSHA256')
            complete = bool(status and status.startswith('complete')) and exists
            text = report.read_text() if exists else ''
            row = {'worker': f'W{number:02}', 'worker_number': number, 'wave': wave,
                   'role': role, 'actual_runtime_id': runtime,
                   'canonical_task_path': canonical or runtime,
                   'input_sha': pick(original, 'input_sha', 'inputSHA') or
                                pick(data, 'input_sha', 'inputCommit', 'initial_input_sha'),
                   'resumed_input_sha': original.get('resumed_input_sha'),
                   'reviewed_source_sha256': pick(original, 'source_sha256', 'candidate_source_sha256'),
                   'candidate_preview_sha256': pick(original, 'candidatePreviewSHA256', 'candidate_sha256'),
                   'private_worktree': pick(original, 'private_worktree', 'privateWorktree'),
                   'execution_status': status, 'primary_assignment_complete': complete,
                   'primary_report': relative(report) if report else None,
                   'primary_report_exists': exists, 'primary_report_sha256': sha,
                   'report_words': len(text.split()),
                   'report_bytes': report.stat().st_size if exists else None,
                   'recorded_report_sha256': recorded_sha,
                   'recorded_report_hash_matches': sha == recorded_sha if recorded_sha else None,
                   'source_ledger': relative(ledger), 'source_record_worker': label}
            rows.append(row)
            wave_rows.append(row)
            if runtime is None or canonical and canonical != runtime:
                errors.append(f'W{number:02}: missing/conflicting actual runtime identity')
            if role not in ROLES or number != (wave - 1) * 10 + ROLES.index(role) + 1:
                errors.append(f'W{number:02}: role/number/wave mismatch')
            if recorded_sha and sha != recorded_sha:
                errors.append(f'W{number:02}: recorded primary report hash differs')
            if final and (not complete or not row['input_sha'] or not row['private_worktree']):
                errors.append(f'W{number:02}: incomplete report/status/source/worktree')
            secondary = set()
            declared_followup = pick(original, 'followup_report', 'followupReport')
            declared_followup_sha = pick(original, 'followup_report_sha256', 'followupReportSHA256')
            declared_followup_path = resolve_report(declared_followup)
            if declared_followup:
                q = declared_followup_path
                if q and q.is_file():
                    secondary.add(q)
            secondary.update(WORKERS.glob(f'W{number:02}-*followup*.md'))
            for q in sorted(secondary):
                if q != report:
                    followup_sha = digest(q)
                    retained_sha = declared_followup_sha if q == declared_followup_path else None
                    if retained_sha and retained_sha != followup_sha:
                        errors.append(f'W{number:02}: recorded followup report hash differs')
                    followups.append({'worker': f'W{number:02}', 'actual_runtime_id': runtime,
                                      'report': relative(q), 'sha256': followup_sha,
                                      'recorded_sha256': retained_sha,
                                      'recorded_hash_matches': retained_sha == followup_sha if retained_sha else None,
                                      'counted_as_new_worker': False})
        roles = [r['role'] for r in wave_rows]
        if len(roles) != len(set(roles)):
            errors.append(f'Wave {wave}: duplicate role')
        if final and sorted(roles) != sorted(ROLES):
            errors.append(f'Wave {wave}: incomplete ten-role set')
        waves.append({'wave': wave, 'ledger': relative(ledger), 'ledger_sha256': digest(ledger),
                      'actual_contexts': len(records),
                      'completed_primary_assignments': sum(r['primary_assignment_complete'] for r in wave_rows),
                      'distinct_roles': len(set(roles)),
                      'roles_complete': set(roles) == set(ROLES)})
    nums = [r['worker_number'] for r in rows]
    ids = [r['actual_runtime_id'] for r in rows]
    if len(nums) != len(set(nums)) or len(ids) != len(set(ids)):
        errors.append('Duplicate worker number or actual runtime identity')
    if '/root' in ids:
        errors.append('Root integrator was counted')
    if final and (sorted(nums) != list(range(1, 101)) or len(waves) != 10):
        errors.append('Final ledger requires exactly W01-W100 across ten waves')
    prior = LANE / 'evidence/worker-ledger-through-wave06.json'
    prior_data = json.loads(prior.read_text())
    prior_mismatches = []
    indexed = {r['worker_number']: r for r in rows}
    for historical in prior_data['workers']:
        n = int(re.match(r'W(\d+)', historical['worker'])[1])
        row = indexed[n]
        if historical['actualRuntimeID'] != row['actual_runtime_id'] or historical['reportSHA256'] != row['primary_report_sha256']:
            prior_mismatches.append(n)
    if prior_mismatches:
        errors.append(f'Prior six-wave audit differs: {prior_mismatches}')
    complete_count = sum(r['primary_assignment_complete'] for r in rows)
    result = {'schema': 1, 'lane': '03', 'status': 'complete' if final and not errors else 'in_progress',
              'source': 'Ten retained per-wave ledgers; actual tool-returned canonical IDs.',
              'accepted_executable_source': latest.get('input_sha'),
              'cpu_source': latest.get('cpu_source'),
              'preview_sha256': latest.get('preview_sha256'),
              'hosted_test_sha256': latest.get('hosted_test_sha256'),
              'actual_contexts': len(rows), 'unique_worker_numbers': len(set(nums)),
              'unique_actual_runtime_ids': len(set(ids)), 'completed_primary_assignments': complete_count,
              'primary_reports_existing': sum(r['primary_report_exists'] for r in rows),
              'root_counted': False, 'followups_counted': False, 'precreated_trees_counted': False,
              'token_accounting': 'Exact runtime counters unavailable; words/bytes are report-size proxies only.',
              'normalization': 'Accepts role aliases, worker suffixes, relative/full report paths, snake_case/camelCase runtime fields; original ledgers unchanged.',
              'prior_audit': {'path': relative(prior), 'sha256': digest(prior), 'matching_records': 60-len(prior_mismatches)},
              'waves': waves, 'workers': rows, 'followups': followups, 'validation_errors': errors}
    (LANE / 'WORKER_LEDGER.json').write_text(json.dumps(result, indent=2) + '\n')
    md = ['# Lane 03 worker ledger', '',
          f"**Status: {result['status']}.** {len(rows)} actual contexts; {complete_count} completed primary assignments; "
          f"{result['primary_reports_existing']} existing primary reports. Root, followups and unused trees are excluded.", '',
          'Actual runtime IDs are canonical task paths returned by the collaboration tools. '
          'The machine-readable ledger hashes every existing primary report and the original per-wave ledgers. '
          'Original ledgers and historical failures are preserved. Exact token counters were unavailable; '
          'word/byte sizes do not certify token-budget compliance.', '',
          '| Wave | Actual contexts | Completed | Distinct roles | Ledger |',
          '|---|---:|---:|---:|---|']
    for w in waves:
        md.append(f"| {w['wave']:02} | {w['actual_contexts']} | {w['completed_primary_assignments']} | {w['distinct_roles']} | [wave{w['wave']:02}.json](workers/wave{w['wave']:02}.json) |")
    md += ['', '## Primary assignments', '', '| Worker | Role | Actual runtime ID | Primary report | State |', '|---|---|---|---|---|']
    for r in rows:
        report = r['primary_report']
        link = f"[{Path(report).name}]({Path(report).relative_to('docs/parallel/03')})" if report and r['primary_report_exists'] else 'Pending'
        md.append(f"| {r['worker']} | {r['role']} | `{r['actual_runtime_id']}` | {link} | {'Complete' if r['primary_assignment_complete'] else 'Pending'} |")
    md += ['', '## Reused-context followups', '',
           'These reports belong to the same actual identities and add zero workers. Other historical followup actions remain recorded in their original wave ledgers.', '']
    for f in followups:
        md.append(f"- {f['worker']}: [{Path(f['report']).name}]({Path(f['report']).relative_to('docs/parallel/03')})")
    md += ['', '## Validation', '',
           f"The earlier root audit through wave 6 matches {60-len(prior_mismatches)} of 60 primary records and report hashes. "]
    md.append('No normalization errors.' if not errors else '\n'.join('- '+e for e in errors))
    (LANE / 'WORKER_LEDGER.md').write_text('\n'.join(md) + '\n')
    print(json.dumps({k: result[k] for k in ['status', 'actual_contexts', 'completed_primary_assignments', 'primary_reports_existing', 'validation_errors']}))
    return 1 if errors else 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--final', action='store_true')
    raise SystemExit(main(parser.parse_args().final))
