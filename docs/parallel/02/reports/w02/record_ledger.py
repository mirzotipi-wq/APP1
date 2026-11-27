"""Coordinator ledger utility. Agent IDs must be actual collaboration spawn results."""
import datetime
import hashlib
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent
PATH = ROOT / 'ledger.json'
ledger = json.loads(PATH.read_text())
operation, number = sys.argv[1:3]
role = 'W02R' + number
now = datetime.datetime.now(datetime.timezone.utc).isoformat()
if operation == 'spawn':
    agent_id, task = sys.argv[3:5]
    assert not any(x['worker'] == role for x in ledger['workers'])
    ledger['workers'].append({'worker': role, 'agent_id': agent_id,
        'worktree': '/tmp/keyfill02-workers/w02r'+number,
        'input_sha': ledger['input_sha'], 'task': task, 'status': 'running',
        'artifact_directory': str(ROOT/('w02r'+number)), 'artifact': str(ROOT/('w02r'+number)/'report.md'), 'spawned_utc': now})
    ledger['events'].append({'time_utc': now, 'event': 'Actual spawn returned '+agent_id})
elif operation == 'complete':
    row = next(x for x in ledger['workers'] if x['worker'] == role)
    assert row['status'] == 'running'
    row.update(status='completed', outcome=sys.argv[3], completed_utc=now)
    artifact_dir = pathlib.Path(row['artifact_directory'])
    row['artifacts'] = [str(f) for f in sorted(artifact_dir.rglob('*')) if f.is_file()]
    row['artifact_sha256'] = {str(f.relative_to(ROOT)): hashlib.sha256(f.read_bytes()).hexdigest()
                              for f in sorted(artifact_dir.rglob('*')) if f.is_file()}
    ledger['events'].append({'time_utc': now, 'event': role+' returned actual completed work.'})
else:
    raise ValueError(operation)
ledger['completed_count'] = sum(x['status'] == 'completed' for x in ledger['workers'])
ledger['actual_spawned_children'] = len(ledger['workers'])-1
ledger['actual_returned_children'] = ledger['completed_count']-1
ledger['active_children'] = sum(x['status'] == 'running' for x in ledger['workers'][1:])
assert ledger['active_children'] <= 2
PATH.write_text(json.dumps(ledger, indent=2)+'\n')
if ledger['completed_count'] == 6 and not (ROOT/'checkpoint-six.json').exists():
    checkpoint = dict(ledger)
    checkpoint['checkpoint'] = '6/10 actual completed role tasks; R01 coordination remains active.'
    checkpoint['created_utc'] = now
    (ROOT/'checkpoint-six.json').write_text(json.dumps(checkpoint, indent=2)+'\n')
print(json.dumps({k:ledger[k] for k in ['completed_count', 'actual_spawned_children', 'active_children']}))
