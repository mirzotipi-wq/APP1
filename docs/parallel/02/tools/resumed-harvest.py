import json,sys,pathlib,subprocess
wave=int(sys.argv[1]);r=pathlib.Path('/tmp/keyfill02-r2');c=pathlib.Path(f'/tmp/keyfill02-r2-workers/w{wave:02d}r01');d=json.loads((c/'private-output/team-ledger.json').read_text());g=r/f'docs/parallel/02/reports/w{wave:02d}/ledger.json';existing=json.loads(g.read_text())['workers'] if g.exists() else []
for w in d['workers']:
 role=w['role'];work=c.parent/f'w{wave:02d}r{role:02d}';head=subprocess.check_output(['git','-C',str(work),'rev-parse','HEAD'],text=True).strip();old=next((s for s in existing if s['agent_id']==w['agent_id']),None)
 if not old:subprocess.run(['python3','/tmp/keyfill02-r2-state.py','start',str(wave),str(role),w['agent_id'],head],check=True)
 if w['status']=='completed' and (not old or old['status']!='completed'):subprocess.run(['python3','/tmp/keyfill02-r2-state.py','finish',str(wave),str(role)],check=True)
