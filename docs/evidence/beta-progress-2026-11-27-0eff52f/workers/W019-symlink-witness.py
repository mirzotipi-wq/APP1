#!/usr/bin/env python3
"""Bounded actual-collector symlink regression witness; Linux only."""
import hashlib,json,os,subprocess,tempfile
from pathlib import Path
import yaml
root=Path(__file__).resolve().parents[4]
workers=Path(__file__).resolve().parent
current=(root/'.github/workflows/ios-prototype.yml').read_bytes()
initial=(workers/'W019-initial-workflow.yml').read_bytes()
results=[]
base=Path(tempfile.mkdtemp(prefix='APP1-W019-recheck-'))
for version,raw in [('initial',initial),('corrected',current)]:
 document=yaml.safe_load(raw)
 for job in ('simulator','ui'):
  collector=next(step['run'] for step in document['jobs'][job]['steps'] if step.get('name')=='Collect original test output after the command')
  for case in ('dangling-log-destination','dangling-bundle-destination','source-log-symlink'):
   cwd=base/version/job/case;cwd.mkdir(parents=True)
   temp=cwd/'runner-temp';src=temp/'keyfill-test-output';src.mkdir(parents=True)
   if case=='dangling-bundle-destination':
    source=src/'NativeTests.xcresult';source.mkdir();(source/'Info.plist').write_text('original')
    dest=cwd/'NativeTests.xcresult';dest.symlink_to(cwd/'missing',target_is_directory=True)
   else:
    source=src/'native-tests.log';dest=cwd/'native-tests.log'
    if case=='source-log-symlink':
     external=cwd/'external.txt';external.write_text('not an original log');source.symlink_to(external)
    else:
     source.write_text('original');dest.symlink_to(cwd/'missing')
   proc=subprocess.run(['bash','-euo','pipefail','-c',collector],cwd=cwd,env={**os.environ,'RUNNER_TEMP':str(temp)},text=True,capture_output=True)
   results.append({'version':version,'job':job,'case':case,'exit':proc.returncode,'source_retained':source.exists() or source.is_symlink(),'destination_symlink':dest.is_symlink(),'stderr':proc.stderr})
   if version=='corrected':
    assert proc.returncode!=0 and (source.exists() or source.is_symlink()),results[-1]
    if case!='source-log-symlink':assert dest.is_symlink(),results[-1]
   elif case in ('dangling-log-destination','source-log-symlink'):
    assert proc.returncode==0,results[-1]
receipt={'platform':'Linux; exact YAML collector Bash only, not macOS/Xcode','initial_sha256':hashlib.sha256(initial).hexdigest(),'corrected_sha256':hashlib.sha256(current).hexdigest(),'scratch':str(base),'results':results}
(workers/'W019-symlink-recheck.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
