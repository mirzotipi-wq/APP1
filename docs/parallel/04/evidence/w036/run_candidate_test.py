"""Reproduce worker036's fixed candidate-only test; every compile holds flock."""
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess

here=Path(__file__).resolve().parent
build=Path('/tmp/keyfill04-builds-2987b1ee980d/w036')
build.mkdir(parents=True,exist_ok=True)
lock=Path('/tmp/keyfill04-2987b1ee980d/build.lock')
binary=build/'candidate-metadata-test'
header=here/'candidate-StudyKernel.h'
source=here/'candidate_metadata_test.cpp'
expected='5bdba47a2620807b9fa61f899c2c6d8ed2cc534f5a3e26693cbdbfbc786ef628'
records=[]
def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()
assert sha(header)==expected,'candidate bytes differ from assigned header'
def run(name,argv,extra_env=None):
    env=os.environ.copy(); env.update(extra_env or {})
    argv=[str(x) for x in argv]
    result=subprocess.run(argv,cwd=here,env=env,text=True,capture_output=True,timeout=60)
    command=''.join(f'{k}={shlex.quote(v)} ' for k,v in (extra_env or {}).items())+shlex.join(argv)
    record={'name':name,'cwd':str(here),'command':command,'exitcode':result.returncode,
            'sanitizer_diagnostics':result.stderr.count('runtime error:'),
            'stdout':result.stdout,'stderr':result.stderr}
    records.append(record)
    return record

run('compiler-version',['g++','--version'])
run('compiler-target',['g++','-dumpmachine'])
run('platform',['uname','-a'])
compiled=run('compile',['flock',lock,'g++','-std=c++17','-O1','-g','-Wall','-Wextra','-Wpedantic','-Werror',
    '-ffp-contract=off','-fno-omit-frame-pointer','-fsanitize=float-cast-overflow',
    '-fno-sanitize-recover=all',source,'-o',binary])
if compiled['exitcode']==0:
    run('test',[binary],{'UBSAN_OPTIONS':'halt_on_error=1:print_stacktrace=0'})
hashes={'candidate_header_sha256':sha(header),'test_source_sha256':sha(source),
        'runner_sha256':sha(__file__),'compiler_binary_sha256':sha(Path(shutil.which('g++')).resolve())}
if binary.exists(): hashes['test_binary_sha256']=sha(binary)
receipt={'actual_worker_id':'/root/w031/w036','base':'c08cd0be2548467add169c3594207cf489760787',
    'candidate_git_blob':'f60258402a96f58b62607d5cefec5e41c7ec4137',
    'hashes':hashes,'commands':records,'case_results':[],
    'limits':'Candidate-only host C++; no baseline execution, parser execution, Swift, actual Metal, CPU-oracle parity or cache-lifetime acceptance.'}
if records[-1]['name']=='test':
    receipt['case_results']=[line for line in records[-1]['stdout'].splitlines() if 'result=' in line]
(here/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
raw=[]
for record in records:
    raw.extend([record['name'],record['command'],f"exitcode={record['exitcode']} sanitizer_diagnostics={record['sanitizer_diagnostics']}",
                'STDOUT:',record['stdout'],'STDERR:',record['stderr']])
(here/'execution.log').write_text('\n'.join(raw)+'\n')
print(json.dumps({'hashes':hashes,'commands':[{k:r[k] for k in ['name','exitcode','sanitizer_diagnostics']} for r in records],
                  'case_results':receipt['case_results']},indent=2))
raise SystemExit(records[-1]['exitcode'])
