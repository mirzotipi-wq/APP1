import collections, hashlib, json, re
from pathlib import Path
ROOT = Path(__file__).parent
raw = (ROOT / "simulator-job.log").read_text()
lines = raw.splitlines()
native_expected = set(json.loads((ROOT / "source-inventory.json").read_text())["nativeMethods"])
package_expected = set(json.loads((ROOT / "package-source-inventory.json").read_text())["allSyntacticMethods"])
pattern = re.compile(r"^Test Case '-\[(?P<target>[^.\s\[\]]+)\.(?P<class>\w+) (?P<method>\w+)\]' (?P<event>started|passed|failed|skipped)(?: \(\d+(?:\.\d+)? seconds\))?\.?$")
# A command echo is ANSI-colored. Require timestamped lines and an exact event body.
events = {"native": collections.defaultdict(list), "package": collections.defaultdict(list)}
unrecognized = []
rows = []
for n,line in enumerate(lines,1):
    if not re.match(r"^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+Z ",line): continue
    stamp,body=line.split(' ',1)
    if '\x1b' in body: continue
    m=pattern.fullmatch(body)
    if m:
        key=m['class']+'.'+m['method']
        if m['target'] not in ['KeyAndFillTests','LightingCoreTests','StudioCompositionTests']:
            unrecognized.append({'line':n,'text':body,'reason':'unexpected XCTest target'}); continue
        group='native' if m['target']=='KeyAndFillTests' else 'package'
        rec={'line':n,'utc':stamp,'target':m['target'],'method':key,'event':m['event']}
        events[group][key].append(rec); rows.append(rec)
    elif body.startswith('Test Case '): unrecognized.append({'line':n,'text':body})

def report(group,expected):
    obs=events[group]; out={'expectedCount':len(expected),'observedMethods':len(obs),'started':[],'passed':[],'failed':[],'skipped':[],'incomplete':[],'unstarted':[],'invalidSequences':[],'unexpected':sorted(set(obs)-expected)}
    for key in sorted(expected):
        seq=[r['event'] for r in obs.get(key,[])]
        if not seq: out['unstarted'].append(key)
        if 'started' in seq: out['started'].append(key)
        if seq==['started','passed']: out['passed'].append(key)
        if 'failed' in seq: out['failed'].append(key)
        if 'skipped' in seq: out['skipped'].append(key)
        if seq and seq[-1]=='started': out['incomplete'].append(key)
        if seq and seq not in [['started','passed'],['started','failed'],['started','skipped']]: out['invalidSequences'].append({'method':key,'events':obs[key]})
    out['allExpectedPassedExactlyOnce']=len(out['passed'])==len(expected) and not out['unexpected'] and not out['invalidSequences']
    return out
result={'decodedLog':{'sha256':hashlib.sha256(raw.encode()).hexdigest(),'bytes':len(raw.encode()),'lines':len(lines)},'package':report('package',package_expected),'native':report('native',native_expected),'unrecognized':unrecognized,'events':rows}
(ROOT/'method-accounting.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({g:{k:(len(v) if isinstance(v,list) else v) for k,v in result[g].items()} for g in ['package','native']},indent=2))
