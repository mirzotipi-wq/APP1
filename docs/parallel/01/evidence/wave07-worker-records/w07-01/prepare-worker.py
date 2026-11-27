import hashlib,json,subprocess,sys
from pathlib import Path
root=Path('/workspace/scratch/e08d5190f17c/keyfill-01')
manager=Path('/workspace/scratch/e08d5190f17c/workers/w07-01')
role=sys.argv[1]
revision=subprocess.check_output(['git','rev-parse',sys.argv[2] if len(sys.argv)>2 else 'HEAD'],cwd=root,text=True).strip()
roles=json.loads((manager/'roles.json').read_text())
assert role in roles
d=manager.parent/f'w07-{role}'
d.mkdir(exist_ok=True)
t=d/'tree'
assert not t.exists(),t
brief=(manager/'common-brief.md').read_text()+f"\nRole {role}: {roles[role]['role']}. Base {revision}. Worktree {t}; build path {d/'build'} (unused). Output {d/'report.md'}, {d/'receipt.json'}.\n\nTask: "+roles[role]['task']+"\nRoot correction: W07-02 adds one method within existing UITests/StudioSmokeTests.swift; no new test class. Native shard validation must include it. Root alone fixes explicit Double(0.05).nextDown for Swift6.4.2 lexer; historic failed45842239860 remains failure.\n"
(d/'brief.md').write_text(brief)
subprocess.run(['git','worktree','add','--detach','--no-checkout',str(t),revision],cwd=root,check=True)
subprocess.run(['git','sparse-checkout','init','--no-cone'],cwd=t,check=True)
with open('/workspace/scratch/e08d5190f17c/worker-sparse.txt') as spec:
 subprocess.run(['git','sparse-checkout','set','--no-cone','--stdin'],cwd=t,stdin=spec,check=True)
subprocess.run(['git','checkout',revision],cwd=t,check=True)
(d/'creation.json').write_text(json.dumps({'role':role,'baseRevision':revision,'worktree':str(t),'buildPath':str(d/'build'),'briefSHA256':hashlib.sha256(brief.encode()).hexdigest()},indent=2)+'\n')
print(json.dumps({'role':role,'base':revision,'worktree':str(t),'briefCharacters':len(brief)}))
