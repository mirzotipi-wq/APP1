from pathlib import Path
import json, sys, subprocess, hashlib, datetime
root=Path('/workspace/scratch/e08d5190f17c'); repo=root/'keyfill-01'; records=root/'workers'; lp=records/'w10-01/ledger.json'; d=json.loads(lp.read_text()); mode=sys.argv[1]; n=int(sys.argv[2]); p=records/f'w10-{n:02d}'
if mode=='start':
 agent=sys.argv[3]; tokens=int(sys.argv[4]); c=json.loads((p/'creation.json').read_text()); c['agent_id']=agent;(p/'creation.json').write_text(json.dumps(c,indent=2)+'\n'); assert not any(w['number']==f'W10-{n:02d}' for w in d['workers']);assert tokens<=2000
 d['workers'].append({'number':f'W10-{n:02d}','global_context_number':c['global_context_number'],'role':c['role'],'agent_id':agent,'status':'running','input_sha':c['input_sha'],'tree':c['tree'],'build':c['build'],'brief':c['brief'],'brief_sha256':c['brief_sha256'],'brief_tool_token_estimate':tokens,'report':str(p/'report.md'),'receipt':str(p/'receipt.json'),'commit':None,'working_tokens_requested':12000,'working_tokens_measured':None})
 d['fresh_count']=len(d['workers']);d['fresh_peers_created']=len(d['workers'])-1;assert d['fresh_peers_created']<=9
elif mode=='finish':
 tokens=int(sys.argv[3]); w=next(w for w in d['workers'] if w['number']==f'W10-{n:02d}'); tree=Path(w['tree']); txt=(p/'report.md').read_text(); receipt=json.loads((p/'receipt.json').read_text()); words=len(txt.split()); chars=len(txt);assert tokens<=800,(tokens,words,chars)
 status=subprocess.run(['git','status','--porcelain=v1'],cwd=tree,text=True,capture_output=True,check=True).stdout;assert not status,status
 head=subprocess.run(['git','rev-parse','HEAD'],cwd=tree,text=True,capture_output=True,check=True).stdout.strip(); changes=subprocess.run(['git','diff','--name-only',d['base'],head],cwd=tree,text=True,capture_output=True,check=True).stdout.splitlines()
 allowed={2:['NativeTests/StudioAdaptiveLayoutTests.swift'],4:['App/StudioView.swift','App/StudioAdaptiveLayout.swift'],7:['docs/parallel/01/INTEGRATION_REQUESTS.md']}.get(n,[]);assert all(f in allowed for f in changes),changes
 patch=subprocess.run(['git','diff','--binary',d['base'],head],cwd=tree,capture_output=True,check=True).stdout;saved=p/'source.patch'
 if saved.exists():assert saved.read_bytes()==patch,'source.patch differs from committed diff'
 else:saved.write_bytes(patch)
 if changes:subprocess.run(['git','update-ref',f'refs/worker/w10-{n:02d}',head],cwd=repo,check=True,capture_output=True)
 w.update(status='completed',report_sha256=hashlib.sha256(txt.encode()).hexdigest(),receipt_sha256=hashlib.sha256((p/'receipt.json').read_bytes()).hexdigest(),report_tool_token_estimate=tokens,report_words=words,report_characters=chars,report_budget_independently_verified=True,commit=head if changes else None,preserved_head=head,completed_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
 w['artifacts']=[{'path':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size} for f in sorted(p.iterdir()) if f.is_file() and f.name!='ledger.json']
 subprocess.run(['git','worktree','remove',str(tree)],cwd=repo,check=True,capture_output=True)
 w['cleanup']={'clean_status_verified':True,'reports_receipt_source_preserved':True,'removed':True,'preserved_head':head}
 d['completed_fresh_count']=sum(w['status']=='completed' for w in d['workers'])
else:raise ValueError(mode)
d['updated_utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();lp.write_text(json.dumps(d,indent=2)+'\n');print(json.dumps({'mode':mode,'role':n,'created':d['fresh_count'],'completed':d.get('completed_fresh_count',0)}))
