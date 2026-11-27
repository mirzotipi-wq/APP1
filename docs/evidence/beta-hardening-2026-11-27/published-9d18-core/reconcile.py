# Adapted A094 artifact-verification protocol, executed independently by A100 on newly downloaded 9d18 originals.
import collections, hashlib, json, math, pathlib, re

ROOT=pathlib.Path(__file__).parent
SOURCE='9d18d762f204ed060af5309554d97841ea70ea03'
CORE=ROOT/'core-test-log'
load=lambda p:json.loads((ROOT/p).read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
job=load('job-final.json')
assert job['head_sha']==SOURCE and job['conclusion']=='success'
assert all(s['conclusion']=='success' for s in job['steps'])
assert (CORE/'core-environment.log').read_text().splitlines()[-1]==SOURCE
method_counts={}
methods={}
for configuration,name in [('Debug','core-tests.log'),('Release','core-release-tests.log')]:
 text=(CORE/name).read_text()
 events=collections.defaultdict(list)
 unrecognized=[]
 for number,line in enumerate(text.splitlines(),1):
  if not line.startswith('Test Case '):continue
  match=re.match(r"Test Case '([^']+)' (started|passed|failed|skipped)(?: |$)",line)
  if not match:unrecognized.append({'line':number,'text':line});continue
  events[match[1]].append({'event':match[2],'line':number})
 assert not unrecognized
 assert all([e['event'] for e in v]==['started','passed'] for v in events.values())
 summaries=re.findall(r"Test Suite 'All tests' passed[^\n]*\n\s*Executed (\d+) tests?, with (\d+) failures?",text)
 assert summaries and sum(int(n) for n,_ in summaries)==len(events) and all(f=='0' for _,f in summaries)
 methods[configuration]=dict(sorted(events.items()))
 method_counts[configuration]={'distinctMethods':len(events),'started':len(events),'passed':len(events),'failed':0,'skipped':0,'duplicateEvents':0,'unrecognizedEvents':0,'allTestsSuiteTotals':[int(n) for n,_ in summaries],'log':name,'logSHA256':sha(CORE/name)}
assert set(methods['Debug'])==set(methods['Release'])
assert len(methods['Debug'])==594
ignored_unicode=[m for m in methods['Debug'] if m.startswith('ProjectDocumentIgnoredUnicodeTests.')]
assert len(ignored_unicode)==6
(ROOT/'method-accounting.json').write_text(json.dumps({'sourceRevision':SOURCE,'counts':method_counts,'sameMethodsBothConfigurations':True,'ignoredUnicodeMethods':ignored_unicode,'methods':methods},indent=2)+'\n')

full=(ROOT/'core-job.log').read_text()
tooling=re.findall(r'Ran (\d+) tests in ([\d.]+)s',full)
assert tooling==[('120',tooling[0][1])]
assert not re.search(r'FAILED \(failures=',full)
assert re.search(r'^.*Z OK\s*$',full,re.M)
assert 'All 12 UI test classes assigned once across 9 required and 1 opt-in diagnostic shards' in full

render=[]
for line in (CORE/'study-render.log').read_text().splitlines():
 match=re.fullmatch(r'([^:]+): (\d+)×(\d+), unsupported pixels (\d+)',line);assert match
 name,width,height,unsupported=match.groups();assert unsupported=='0'
 render.append({'name':name,'width':int(width),'height':int(height),'unsupportedPixels':0})
assert len(render)==12
image_checks=[]
for line in (CORE/'study-image-sha256.txt').read_text().splitlines():
 digest,path=line.split(None,1);file=CORE/path.strip();assert sha(file)==digest
 image_checks.append({'path':path.strip(),'sha256':digest,'bytes':file.stat().st_size})
assert len(image_checks)==12

parity={}
for key,filename,n in [('sharedKernel','study-kernel.log',6),('strictPrecision','study-precision.log',8)]:
 rows=[]
 for line in (CORE/filename).read_text().splitlines():
  match=re.fullmatch(r'(.+?): mean=([^,]+), max=(\d+), >4 fraction=([^,]+), invalid=(\d+)/(\d+), invalid-mask-mismatches=(\d+)(?:, max-limit=(\d+))?, (PASS|FAIL)',line);assert match
  path,mean,maximum,fraction,invalid_cpu,invalid_kernel,mismatches,limit,result=match.groups()
  assert result=='PASS' and invalid_cpu==invalid_kernel and mismatches=='0'
  assert float(mean)<=1 and float(fraction)<=0.005
  if key=='strictPrecision':assert limit=='1' and int(maximum)<=1
  rows.append({'fixture':pathlib.PurePosixPath(path).name,'meanChannelError':float(mean),'maximumChannelError':int(maximum),'fractionAbove4':float(fraction),'invalidCPU':int(invalid_cpu),'invalidKernel':int(invalid_kernel),'invalidMaskMismatches':int(mismatches),'maximumLimit':int(limit) if limit else None,'result':result})
 assert len(rows)==n
 parity[key]=rows

benchmark=json.loads((CORE/'study-benchmark.json').read_text())
assert benchmark['sourceRevision']==SOURCE and benchmark['optimizedBuild'] is True
assert benchmark['measuredSamplesPerWorkload']==7
assert len(benchmark['frames'])==8 and len(benchmark['cancellation'])==12 and len(benchmark['visibility'])==4
assert all(f['unsupportedPixels']==0 for f in benchmark['frames'])
assert all(c['cancelled'] for c in benchmark['cancellation'])
for w in benchmark['frames']+benchmark['visibility']:
 values=w['timing']['samplesMilliseconds'];assert len(values)==7 and all(math.isfinite(v) and v>=0 for v in values)
 ordered=sorted(values)
 for percentile,fraction in [('p50Milliseconds',0.5),('p95Milliseconds',0.95)]:
  assert ordered[max(0,math.ceil(len(values)*fraction)-1)]==w['timing'][percentile]

persistence={}
paths={'atomicWrapper':'atomic-library-write-linux-evidence/atomic-library-write-linux/wrapper-result.json','EFBIG':'atomic-library-write-linux-evidence/atomic-library-write-linux/probe/result.json','commitInterruption':'atomic-library-write-linux-evidence/atomic-library-write-linux/commit-interruption/result.json','recovery':'library-recovery-linux-evidence/library-recovery-linux/result.json'}
for name,path in paths.items():
 j=load(path);assert j['status']=='passed' and j.get('baseRevision',j.get('sourceRevision'))==SOURCE
 assert all(v is True for v in j.get('checks',{}).values())
 scenarios=[]
 for s in j.get('scenarios',[]):
  assert s['status']=='passed' and all(v is True for v in s['checks'].values())
  scenarios.append({'mode':s['mode'],'status':s['status'],'checks':s['checks']})
 persistence[name]={'status':'passed','sourceRevision':SOURCE,'receipt':path,'receiptSHA256':sha(ROOT/path),'checks':j.get('checks',{}),'scenarios':scenarios}
assert [s['mode'] for s in persistence['commitInterruption']['scenarios']]==['before-rename','after-rename','rename-eio']
assert [s['mode'] for s in persistence['recovery']['scenarios']]==['before-rename','rename-eio']

checks={'sourceRevision':SOURCE,'methodCounts':method_counts,'tooling':{'tests':120,'seconds':float(tooling[0][1])},'renders':render,'originalImageHashesVerified':image_checks,'parity':parity,'benchmark':{'frames':8,'cancellations':12,'visibility':4,'samplesPerTimingWorkload':7,'p50AndP95IndependentlyRecomputed':True,'cpuModel':benchmark['cpuModel'],'architecture':benchmark['architecture'],'optimized':True,'originalJSONSHA256':sha(CORE/'study-benchmark.json')},'persistence':persistence}
(ROOT/'independent-checks.json').write_text(json.dumps(checks,indent=2)+'\n')
patterns=['9d18d762f204ed060af5309554d97841ea70ea03','Ran 120 tests','Executed 594 tests','State structure and evidence references valid','All 12 UI test classes assigned','App icon','Source privacy manifest','unsupported pixels','invalid-mask-mismatches','Eight deterministic frames','observed cancellations','Host timings are diagnostics','Artifact ID','SHA256 digest of uploaded artifact','Process completed with exit code']
excerpts=[]
for n,line in enumerate(full.splitlines(),1):
 if any(p in line for p in patterns) and 'KEYFILL_BENCHMARK' not in line and len(line)<1500:excerpts.append(f'L{n}: {line}')
(ROOT/'core-job-excerpts.log').write_text('\n'.join(excerpts)+'\n')
print(json.dumps({'counts':method_counts,'tooling':checks['tooling'],'renders':len(render),'parity':len(parity['sharedKernel']),'precision':len(parity['strictPrecision']),'benchmark':checks['benchmark'],'persistence':{k:v['status'] for k,v in persistence.items()}},indent=2))
