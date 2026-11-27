#!/usr/bin/env python3
"""Read retained evidence only; never builds, benchmarks or mutates inputs."""
import collections, hashlib, json, math, pathlib, re, subprocess
repo = pathlib.Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
tree = pathlib.Path('/tmp/keyfill03-7f4b/workers/W79-platform-performance')
out = pathlib.Path('/tmp/keyfill03-7f4b/builds/W79-platform-performance')
out.mkdir(parents=True, exist_ok=True)
e = repo/'docs/parallel/03/evidence'
expected = '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1'
sha = lambda b: hashlib.sha256(b).hexdigest()
def git(*args): return subprocess.check_output(['git', *args], cwd=tree)
def read(p): return json.loads(p.read_text())
def nr(v,p): return sorted(v)[math.ceil(len(v)*p)-1]
def stats(v):
    return dict(n=len(v), minimum=min(v), p50=nr(v,.5), p95=nr(v,.95), maximum=max(v))
b, binding, manifest, ci = [read(e/x) for x in ['final-benchmark.json','final-benchmark-inputs.json','final-source-manifest.json','ci-native-36.json']]
source=(tree/'scripts/benchmark-study.swift').read_text()
checks={}
checks['privateHeadMatchesInput']=git('rev-parse','HEAD').decode().strip()==expected
checks['privateTreeInitiallyClean']=not git('status','--porcelain').decode().strip()
artifact_names=['final-benchmark.json','final-benchmark-inputs.json','final-benchmark-compile.log','final-source-manifest.json','wave05-test-inputs.json','ci-native-36.json','ci-native-36.log']
hashes={x:dict(sha256=sha((e/x).read_bytes()),bytes=(e/x).stat().st_size) for x in artifact_names}
checks['rawBenchmarkMatchesBinding']=hashes['final-benchmark.json']['sha256']==binding['benchmarkSHA256']
checks['nativeLogMatchesPinnedHash']=hashes['ci-native-36.log']['sha256']==ci['logSHA256']=='019f50cd8b9a949c8f5c2e7c93e79a77826cd3cd7b41a6c234c0c3b1f2ef4bf1'
source_hashes=manifest['sourceSHA256']
core_paths=sorted(p for p in source_hashes if p.startswith('Sources/LightingCore/'))
source_rows=[]
for p in core_paths+['scripts/benchmark-study.swift']:
    current=sha((tree/p).read_bytes())
    pinned=sha(git('show',f'{expected}:{p}'))
    actual=sha(git('show',f'{binding["actualSourceCommit"]}:{p}'))
    recorded=source_hashes.get(p,binding['sourceSHA256'].get(p))
    source_rows.append(dict(path=p,sha256=current,privateMatches36=current==pinned,matchesDb7=current==actual,matchesManifest=current==recorded))
checks['exactly31CoreManifestInputs']=len(core_paths)==31
checks['all31AndBenchmarkSourcesUnchanged']=all(all(x[k] for k in ['privateMatches36','matchesDb7','matchesManifest']) for x in source_rows)
checks['fourBenchmarkBindingHashesMatch']=all(sha((tree/p).read_bytes())==h for p,h in binding['sourceSHA256'].items())
rows=[]
for kind in ['frames','visibility']:
    for x in b[kind]:
        t=x['timing']; v=t['samplesMilliseconds']; p50=nr(v,.5); p95=nr(v,.95)
        row=dict(kind=kind,name=x['name'],visibilityEnabled=x.get('visibilityEnabled'),samples=v,p50=p50,p95=p95,rank50=math.ceil(.5*len(v)),rank95=math.ceil(.95*len(v)),reportedMatches=p50==t['p50Milliseconds'] and p95==t['p95Milliseconds'])
        for k in ['width','height','lightSamplesPerSurface','warmupMilliseconds','unsupportedPixels','rgbaFNV1a64','receivers','evaluationsPerSample','signalComponentSum']:
            if k in x: row[k]=x[k]
        rows.append(row)
checks['workloadInventory']=len(b['frames'])==8 and len(b['visibility'])==4 and b['measuredSamplesPerWorkload']==7
checks['all84TimedSamplesAndPercentiles']=sum(len(x['samples']) for x in rows)==84 and all(len(x['samples'])==7 and x['rank50']==4 and x['rank95']==7 and x['reportedMatches'] for x in rows)
checks['eightUniqueFrameWorkloads']=len(set(x['name'] for x in b['frames']))==8
checks['fourUniqueVisibilityWorkloads']=len(set((x['name'],x['visibilityEnabled']) for x in b['visibility']))==4
checks['allFrameUnsupportedZero']=all(x['unsupportedPixels']==0 for x in b['frames'])
checks['sourceChecksWholeImageEquality']= 'guard image == warmup, image.unsupportedPixels == 0 else' in source
checks['sourceWarmsFrameAndVisibilityOnce']= 'let warmup = try render(scene, subject, width)' in source and '_ = try operation()' in source
cancellation=[]
for i,x in enumerate(b['cancellation']):
    y=dict(x,index=i+1)
    y['deadlineToObservedMilliseconds']=x['observedAtMilliseconds']-x['requestedAfterMilliseconds']
    y['observedToReturnMilliseconds']=x['finishedAfterMilliseconds']-x['observedAtMilliseconds']
    y['pollSpanMilliseconds']=x['observedAtMilliseconds']-x['precedingCheckAtMilliseconds']
    y['monotonicValid']=x['precedingCheckAtMilliseconds']<x['requestedAfterMilliseconds']<=x['observedAtMilliseconds']<=x['finishedAfterMilliseconds']
    y['reportedDeadlineDeltaMatches']=math.isclose(x['deadlineToReturnMilliseconds'],x['finishedAfterMilliseconds']-x['requestedAfterMilliseconds'],rel_tol=0,abs_tol=1e-12)
    cancellation.append(y)
groups=collections.defaultdict(list)
for x in cancellation: groups[(x['name'],x['requestedAfterMilliseconds'])].append(x)
cancel_stats={k:stats([x[k] for x in cancellation]) for k in ['deadlineToReturnMilliseconds','deadlineToObservedMilliseconds','observedToReturnMilliseconds','pollSpanMilliseconds','checks']}
cancel_groups=[dict(name=n,deadlineMilliseconds=d,n=len(g),deadlineToReturnMilliseconds=stats([x['deadlineToReturnMilliseconds'] for x in g])) for (n,d),g in groups.items()]
checks['exactly12CancellationProbes']=len(cancellation)==12 and len(groups)==4 and all(len(g)==3 for g in groups.values())
checks['allCancellationsObservedAndConsistent']=all(x['cancelled'] and x['monotonicValid'] and x['reportedDeadlineDeltaMatches'] for x in cancellation)
log=(e/'ci-native-36.log').read_text()
lines=log.splitlines()
strip=lambda l:re.sub(r'\x1b\[[0-9;]*m','',re.sub(r'^\S+Z ','',l)).strip()
clean=[strip(l) for l in lines]
event_re=re.compile(r"Test Case '-\[KeyAndFillTests\.([^ ]+) ([^\]]+)\]' (started|passed|failed|skipped)")
events=collections.defaultdict(collections.Counter)
for line in clean:
    m=event_re.search(line)
    if m: events[m[1]+'.'+m[2]][m[3]]+=1
pipeline={k:v for k,v in events.items() if k.startswith('StudyPreviewPipelineTests.')}
checks['nativeMethods164ExactlyOnce']=len(events)==164 and all(v=={'started':1,'passed':1} for v in events.values())
checks['pipelineMethods10ExactlyOnce']=len(pipeline)==10 and all(v=={'started':1,'passed':1} for v in pipeline.values())
checks['pipelineSummaryNamesMatch']=sorted(k.split('.',1)[1] for k in pipeline)==sorted(ci['previewPipelineMethodsPassed'])
checks['ciSummaryScopeAndSuccess']=ci['sourceCommit']==expected and ci['runID']==45842899560 and ci['jobID']==139992156576 and ci['conclusion']=='success'
checks['checkoutCommitPresentInNativeLog']=expected in log
markers=[dict(line=i+1,text=l) for i,l in enumerate(clean) if ('***' in l or '** ' in l) and ('SUCCEEDED' in l or 'FAILED' in l)]
portable=[dict(line=i+1,text=l) for i,l in enumerate(clean) if re.search(r'Executed 391 tests, with 0 failures',l)]
checks['portable391PassSummary']=len(portable)==2
checks['debugNativeBundleAndReleaseBuildPass']=any('TEST BUILD SUCCEEDED' in x['text'] for x in markers) and any(x['text']=='** BUILD SUCCEEDED **' for x in markers)
fixtures=[dict(line=i+1,text=l) for i,l in enumerate(clean) if ('Metal' in l and any(s in l.lower() for s in ['mean','max','invalid-match','parity'])) and not any(s in l for s in ['swiftc','/Applications/','SwiftCompile','SwiftDriver'])]
toolchain=[dict(line=i+1,text=l) for i,l in enumerate(clean) if re.match(r'(Apple Swift version |Target: |Xcode \d|Build version |ProductVersion:|BuildVersion:|Image: |Version: 2026)',l)]
commands=[dict(line=i+1,text=l) for i,l in enumerate(clean) if re.match(r'(xcodebuild -project|/Applications/[^ ]+/usr/bin/xcodebuild -project)',l)]
compiler_records={}
for filename in ['final-source-manifest.json','wave05-test-inputs.json','baseline.json']:
    obj=read(e/filename)
    compiler_records[filename]={k:v for k,v in obj.items() if any(z in k.lower() for z in ['swift','compiler','toolchain','build','platform','host','command'])}
source_excerpts={}
for relative in git('ls-tree','-r','--name-only','HEAD').decode().splitlines():
    if 'Study' in relative and relative.endswith('.swift') and ('Tests' in relative or 'Validation' in relative or 'Parity' in relative):
        p=tree/relative
        if not p.exists():continue
        content=p.read_text(); ls=content.splitlines()
        hits=[i for i,l in enumerate(ls) if ('metrics.passes' in l or 'invalidMasksMatch' in l or 'invalidMaskMatches' in l or 'Metal parity' in l or 'func test' in l and 'Metal' in l or 'invalidMaskMismatch' in l)]
        if hits: source_excerpts[relative]=[dict(line=j+1,text=ls[j]) for i in hits for j in range(max(0,i-2),min(len(ls),i+4))]
receipt=dict(worker='W79',canonicalID='/root/wave08/w79_platform_performance',inputCommit=expected,privateTree=str(tree),outputDirectory=str(out),
 status='complete' if all(checks.values()) else 'inspect-failed-checks',checks=checks,artifactHashes=hashes,
 benchmark=dict(metadata={k:v for k,v in b.items() if k not in ['frames','visibility','cancellation']},binding=binding,
 sourceProvenance=source_rows,compilerRecords=compiler_records,workloads=rows,cancellation=cancellation,cancellationStatistics=cancel_stats,cancellationGroups=cancel_groups,
 sampleAccounting=dict(frameMeasured=56,visibilityMeasured=28,workloadWarmups=12,cancellationProbes=12),
 imageEvidence='Original JSON preserves one FNV-1a64 hash per workload; source guards full StudyImage equality for each of seven measured renders against its warmup. It does not archive individual measured-frame bytes or per-sample hashes.',
 compilerLog='Empty stdout/stderr is retained unchanged; command/methodology is supplied by final-benchmark-inputs.json, not inferred from an empty log.'),
 native=dict(source=ci['sourceCommit'],run=ci['runID'],job=ci['jobID'],toolchain=toolchain,commands=commands,markers=markers,portable=portable,
 methodCount=len(events),methodsManifestSHA256=sha(json.dumps(dict(events),sort_keys=True).encode()),pipeline=pipeline,metalMethodEvents={k:v for k,v in events.items() if 'Metal' in k},fixtureLogLines=fixtures,fixtureSummary=ci['actualSimulatorMetalFixtures'],sourceExcerpts=source_excerpts),
 limits=['Historical Linux shared-host timing only; no portable threshold, sustained FPS, device, RSS or thermal inference.',
 'Host Float32 parity six and precision eight are separate from six actual Apple simulator Metal fixtures.',
 'Apple evidence covers builds and native unit methods; no separate UI interaction/AX-shard, physical-device or manual VoiceOver pass.',
 'No new benchmark, render, build or XCTest execution; only independent JSON/log/source arithmetic and hash inspection.',
 'Four historical runtime resets and W72 optional ENOSPC evidence remain unchanged; no new reset observed.',
 'The first attempted finalized-CI read from the private input returned missing-file; finalized evidence was then read from the integration checkout.',
 'Exact token counters unavailable; no measured 60% checkpoint claim.'])
(out/'W79-calculation.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(dict(status=receipt['status'],checks=checks,compilerRecords=compiler_records,
 hashSummary={k:v for k,v in hashes.items() if k in ['final-benchmark.json','ci-native-36.log']},
 timings=[{k:x[k] for k in ['kind','name','visibilityEnabled','p50','p95']} for x in rows],
 cancellationStats=cancel_stats,toolchain=toolchain,markers=markers,metalMethodEvents=receipt['native']['metalMethodEvents'],
 fixtureLogLines=fixtures,sourceExcerpts=source_excerpts,receiptBytes=(out/'W79-calculation.json').stat().st_size),indent=2))

