import sys,json,pathlib,hashlib,shutil
repo=pathlib.Path('/tmp/keyfill02-r2');action=sys.argv[1];wave=int(sys.argv[2]);folder=repo/f'docs/parallel/02/reports/w{wave:02d}';folder.mkdir(parents=True,exist_ok=True);path=folder/'ledger.json'
roles=['acceptance','invariants','interfaces','implementation','concurrency','resources','consumers','accessibility/privacy','platform/performance','independent verification']
d=json.loads(path.read_text()) if path.exists() else {'wave':wave,'lane':'02','requested_workers':10,'workers':[]}
if action=='start':
 role=int(sys.argv[3]);aid=sys.argv[4];sha=sys.argv[5];name=f'w{wave:02d}r{role:02d}'
 assert not any(w['worker']==name.upper() or w['agent_id']==aid for w in d['workers'])
 d['workers'].append(dict(worker=name.upper(),agent_id=aid,task=f'W{wave:02d}R{role:02d} {roles[role-1]}: bounded assignment in WAVE-TASKS.md',status='running',input_sha=sha,worktree=f'/tmp/keyfill02-r2-workers/{name}',artifact=f'{name}/report.md'))
elif action in ['finish','preserve']:
 role=int(sys.argv[3]);name=f'w{wave:02d}r{role:02d}';w=next(w for w in d['workers'] if w['worker']==name.upper());source=pathlib.Path(w['worktree'])/'private-output';dest=folder/name;dest.mkdir(exist_ok=True);assert (source/'report.md').exists();files=[];hashes={}
 for f in sorted(source.rglob('*')):
  if not f.is_file() or f.suffix not in ['.md','.json','.py','.swift','.log','.txt','.csv','.tsv','.patch']:continue
  if f.name=='CIE_xyz_1931_2deg.csv':continue
  out=dest/f.relative_to(source);out.parent.mkdir(exist_ok=True,parents=True);shutil.copyfile(f,out);rel=str(out.relative_to(folder));files.append(rel);hashes[rel]=hashlib.sha256(out.read_bytes()).hexdigest()
 w.update(status=('completed' if action=='finish' else w['status']),artifacts=files,artifact_sha256=hashes,outcome=(dest/'report.md').read_text().splitlines()[0])
for key in ['actual_spawned_children','actual_returned_children','active_children','not_created','closure_note']:d.pop(key,None)
d.update(coordinator='/root',completed_count=sum(w['status']=='completed' for w in d['workers']),actual_created_count=len(d['workers']))
d['status']='complete' if d['completed_count']==10 else 'active';d['wave_complete']=d['completed_count']==10;path.write_text(json.dumps(d,indent=2)+'\n')
if d['completed_count']==6:(folder/'resume-checkpoint-six.json').write_text(json.dumps(d,indent=2)+'\n')
gpath=repo/'docs/parallel/02/worker-ledger.json';g=json.loads(gpath.read_text());allworkers=[];waves=[]
for n in range(1,11):
 p=repo/f'docs/parallel/02/reports/w{n:02d}/ledger.json';z=json.loads(p.read_text()) if p.exists() else {'workers':[]};ws=z['workers'];complete=sum(w['status']=='completed' for w in ws);waves.append(dict(wave=n,requested=10,created=len(ws),completed=complete,status='complete' if complete==10 else 'active' if ws else 'not_started'));allworkers.extend(dict(wave=n,**w) for w in ws)
assert len({w['agent_id'] for w in allworkers})==len(allworkers)
g.update(actual_created_contexts=len(allworkers),completed_role_assignments=sum(w['status']=='completed' for w in allworkers),not_created_contexts=100-len(allworkers),status='active_resumed',waves=waves,workers=allworkers,reason='Execution restored; reset evidence retained.',next='Continue next incomplete wave/role; no planned identity counted.')
g['fresh_contexts']=f'All {len(allworkers)} initial role contexts use fork_turns:none; followups do not increase counts.';g['concurrency']='Four slots: root plus at most three workers, or root/coordinator plus two children.'
gpath.write_text(json.dumps(g,indent=2)+'\n');print(f'W{wave:02d}: {d["completed_count"]}/{len(d["workers"])} complete; campaign {g["completed_role_assignments"]}/{g["actual_created_contexts"]} actual.')
