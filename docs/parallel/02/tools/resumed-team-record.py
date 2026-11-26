import sys,json,pathlib
work=pathlib.Path(sys.argv[1]);role=int(sys.argv[2]);agent=sys.argv[3];status=sys.argv[4];p=work/'private-output/team-ledger.json';d=json.loads(p.read_text()) if p.exists() else {'workers':[]};w=next((w for w in d['workers'] if w['role']==role),None)
if w is None:
 assert status=='running';w={'role':role,'agent_id':agent};d['workers'].append(w)
assert w['agent_id']==agent;w['status']=status;assert len({w['agent_id'] for w in d['workers']})==len(d['workers']);p.write_text(json.dumps(d,indent=2)+'\n')
if sum(w['status']=='completed' for w in d['workers'])==6:(p.parent/'checkpoint-60-percent.json').write_text(p.read_text())
print(len(d['workers']),sum(w['status']=='completed' for w in d['workers']))
