from pathlib import Path
import subprocess,json,hashlib,copy,os,sys
import yaml
root=Path(__file__).resolve().parents[1]
repo=Path('/workspace/scratch/73dcd6a65726/APP1')
base=(root/'BASE_REVISION').read_text().strip()
relative='.github/workflows/ios-prototype.yml'
old_text=subprocess.check_output(['git','show',base+':'+relative],cwd=repo,text=True)
new_text=(root/relative).read_text()
old=yaml.safe_load(old_text);new=yaml.safe_load(new_text)
ui=new['jobs']['ui'];matrix=ui['strategy']['matrix'];rows=matrix['include']
expected={'room-precision':(32,85),'library-reference':(32,85),'studio-export':(40,93)}
assert matrix['shard']==list(expected)
assert len(rows)==3 and len({r['shard'] for r in rows})==3
assert {r['shard'] for r in rows}==set(matrix['shard'])
assert ui['timeout-minutes']=='${{ matrix.job_minutes }}'
steps={s.get('name'):s for s in ui['steps'] if 'name' in s}
run=steps['Run selected native UI shard']
assert run['timeout-minutes']=='${{ matrix.ui_test_minutes }}'
assert steps['Verify Metal compiler component']['timeout-minutes']==12
assert steps['Build native UI test bundle']['timeout-minutes']==25
assert ui['strategy']['max-parallel']==2 and ui['strategy']['fail-fast'] is False
resolved=[]
for row in rows:
 assert set(row)=={'shard','ui_test_minutes','job_minutes'}
 assert type(row['ui_test_minutes']) is int and type(row['job_minutes']) is int
 assert (row['ui_test_minutes'],row['job_minutes'])==expected[row['shard']]
 margin=row['job_minutes']-12-25-row['ui_test_minutes']
 assert margin==85-12-25-32==16
 resolved.append({**row,'reserve_minutes':margin})
# Removing only the authorized fields must restore the complete original YAML
# graph, including commands, selectors, artifact handling, concurrency and jobs.
normalized=copy.deepcopy(new)
nui=normalized['jobs']['ui'];nui['timeout-minutes']=old['jobs']['ui']['timeout-minutes']
del nui['strategy']['matrix']['include']
for step in nui['steps']:
 if step.get('name')=='Run selected native UI shard':step['timeout-minutes']=32
assert normalized==old,'Unexpected semantic workflow change'
inputs={}
for folder in ['UITests','scripts']:
 for path in sorted((root/folder).rglob('*')):
  if path.is_file():
   rel=str(path.relative_to(root));old_bytes=subprocess.check_output(['git','show',base+':'+rel],cwd=repo)
   assert path.read_bytes()==old_bytes,'Changed test/selector source: '+rel
   inputs[rel]=hashlib.sha256(path.read_bytes()).hexdigest()
env=os.environ.copy();env['PYTHONDONTWRITEBYTECODE']='1'
commands=[]
for selector in ['check','unit',*matrix['shard']]:
 cmd=[sys.executable,'scripts/native_test_shards.py',selector]
 result=subprocess.run(cmd,cwd=root,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 commands.append({'command':cmd,'exit':result.returncode,'output':result.stdout})
 assert result.returncode==0,result.stdout
 print(selector+': '+result.stdout.strip())
cmd=[sys.executable,'-m','unittest','discover','-s','scripts/tests','-p','test_native_test_shards.py','-v']
result=subprocess.run(cmd,cwd=root,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(root/'evidence/existing-shard-tests.log').write_text(result.stdout)
commands.append({'command':cmd,'exit':result.returncode,'output_file':'evidence/existing-shard-tests.log'})
assert result.returncode==0,result.stdout
for line in result.stdout.splitlines():
 if line.startswith('Ran ') or line=='OK':print(line)
record={'base_revision':base,'workflow_sha256':hashlib.sha256(new_text.encode()).hexdigest(),'yaml_parser':'PyYAML '+yaml.__version__,'yaml_parse':'passed','effective_matrix_rows':resolved,'effective_ui_job_count':3,'only_authorized_semantic_changes':True,'all_test_run_commands_and_selectors_unchanged':True,'unchanged_test_and_selector_sources':inputs,'validation_commands':commands,'limitations':'Static YAML/context/matrix validation and existing Python shard regressions only; no GitHub workflow or native rerun performed'}
(root/'evidence/validation.json').write_text(json.dumps(record,indent=2)+'\n')
print('Validated exact numeric budgets, 16-minute reserve, unchanged commands and test/selector sources.')
