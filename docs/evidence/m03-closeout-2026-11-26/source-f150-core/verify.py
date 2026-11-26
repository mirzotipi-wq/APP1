import collections
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess

BASE = Path('/tmp/app1-818a-coref150-review')
REPO = Path('/workspace/scratch/818a608c3c08/APP1')
SHA = 'f150f98e35dd735927075aac4d2f8b02295c6a67'
def read(path):
    return json.loads(path.read_text())
def digest(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
def exact_source(path):
    return subprocess.check_output(['git', 'show', SHA + ':' + path], cwd=REPO)

metadata = read(BASE/'github-metadata.json')
assert metadata['job']['id'] == 139858259874
assert metadata['job']['status'] == 'completed' and metadata['job']['conclusion'] == 'success'
artifacts = []
for name, prefix in [('core-test-log', 'core'), ('atomic-library-write-linux-evidence', 'atomic')]:
    record = next(x for x in metadata['artifacts'] if x['name'] == name)
    ident = record['id']
    actual = digest(BASE/(prefix + '-f150.zip'))
    assert record['name'] == name
    assert record['workflow_run']['head_sha'] == SHA
    assert record['workflow_run']['id'] == 45805136256
    assert actual['bytes'] == record['size_in_bytes']
    assert 'sha256:' + actual['sha256'] == record['digest']
    artifacts.append({'id':ident, 'name':name, **actual, 'githubDigestMatches':True})

log = (BASE/'job.log').read_text()
assert SHA in log
environment = (BASE/'core/core-environment.log').read_text()
swift_version = re.search(r'^Swift version ([^ ]+)', environment, re.MULTILINE).group(1)
python_version = re.search(r'^Python ([^\n]+)', environment, re.MULTILINE).group(1)
assert environment.splitlines()[-1] == SHA
tests = {}
for name, path in [('Debug','core-tests.log'), ('Release','core-release-tests.log')]:
    text = (BASE/'core'/path).read_text()
    started = re.findall(r"Test Case '([^']+)' started", text)
    passed = re.findall(r"Test Case '([^']+)' passed", text)
    failed = re.findall(r"Test Case '([^']+)' failed", text)
    skipped = re.findall(r"Test Case '([^']+)' skipped", text)
    assert len(started) == len(passed) == len(set(started)) == 366
    assert collections.Counter(started) == collections.Counter(passed)
    assert not failed and not skipped
    assert 'Executed 366 tests, with 0 failures' in text
    tests[name] = {'started':len(started),'passed':len(passed),'failed':0,'skipped':0,'uniqueMethods':366, **digest(BASE/'core'/path)}
tooling = re.search(r'Ran 100 tests in ([0-9.]+)s\n.*\n[^\n]+ OK\n', log)
assert tooling
tests['tooling'] = {'passed':100,'seconds':float(tooling.group(1)),'terminalResult':'OK','source':'job.log'}

render_dir = BASE/'core/study-artifacts'
manifest = read(render_dir/'manifest.json')
assert manifest['expectedFixtureCount'] == len(manifest['fixtures']) == 12
assert manifest['softwareValidationPassed'] and manifest['syntheticOnly']
baseline = REPO/'docs/evidence/m02-m03-code-2026-11-25/renders'
images = []
for f in manifest['fixtures']:
    assert f['passed'] and not f['validationErrors'] and f['unsupportedPixels'] == 0
    ppm = render_dir/f['ppmFile']
    prior = baseline/f['ppmFile']
    assert ppm.read_bytes() == prior.read_bytes()
    assert json.loads((render_dir/f['sceneFile']).read_text()) == json.loads((baseline/f['sceneFile']).read_text())
    images.append({'name':f['name'], 'width':f['width'], 'height':f['height'], **digest(ppm), 'retainedPPMByteIdentical':True, 'retainedSceneStructurallyIdentical':True, 'unsupportedPixels':0})

pattern = re.compile(r'([^/]+)\.bin: mean=([0-9.e+-]+), max=(\d+), >4 fraction=([0-9.e+-]+), invalid=(\d+)/(\d+), invalid-mask-mismatches=(\d+)(?:, max-limit=(\d+))?, (PASS|FAIL)')
parity = {}
for name,path,count in [('kernel','study-kernel.log',6),('precision','study-precision.log',8)]:
    rows=[]
    for ln in (BASE/'core'/path).read_text().splitlines():
        m=pattern.search(ln);assert m, ln
        fixture,mean,maximum,fraction,invalid1,invalid2,mismatch,limit,status=m.groups()
        assert status=='PASS' and invalid1==invalid2 and int(mismatch)==0
        assert float(mean)<=1 and float(fraction)<=0.005
        if name=='precision':assert int(maximum)<=1 and limit=='1'
        rows.append({'fixture':fixture, 'meanChannelError':float(mean),'maximumChannelError':int(maximum),'fractionAbove4':float(fraction),'unsupportedPixels':int(invalid1),'maskMismatches':0})
    assert len(rows)==count
    parity[name]={'passed':count,'fixtures':rows,**digest(BASE/'core'/path)}

bench=read(BASE/'core/study-benchmark.json')
assert bench['sourceRevision']==SHA and bench['optimizedBuild'] and bench['measuredSamplesPerWorkload']==7
assert len(bench['frames'])==8 and len(bench['visibility'])==4 and len(bench['cancellation'])==12
assert 'swiftc -O Sources/LightingCore/*.swift scripts/benchmark-study.swift' in log
bench_source=exact_source('scripts/benchmark-study.swift').decode()
assert 'guard image == warmup, image.unsupportedPixels == 0' in bench_source
timings=[]
for kind in ['frames','visibility']:
    for f in bench[kind]:
        s=f['timing']['samplesMilliseconds'];assert len(s)==7 and all(math.isfinite(x) and x>=0 for x in s)
        sorted_s=sorted(s)
        p50=sorted_s[math.ceil(.50*len(s))-1]
        p95=sorted_s[math.ceil(.95*len(s))-1]
        assert p50==f['timing']['p50Milliseconds'] and p95==f['timing']['p95Milliseconds']
        if kind=='frames':assert f['unsupportedPixels']==0 and f['warmupMilliseconds']>=0 and f['rgbaFNV1a64']
        timings.append({'kind':kind,'name':f['name'],'visibilityEnabled':f.get('visibilityEnabled'),'samples':7,'p50Milliseconds':p50,'p95Milliseconds':p95})
for c in bench['cancellation']:
    assert c['cancelled'] and c['observedAtMilliseconds']>=c['requestedAfterMilliseconds']
    assert c['precedingCheckAtMilliseconds']<c['requestedAfterMilliseconds']
    assert c['finishedAfterMilliseconds']>=c['observedAtMilliseconds']
    assert math.isclose(c['finishedAfterMilliseconds']-c['requestedAfterMilliseconds'],c['deadlineToReturnMilliseconds'],abs_tol=1e-12)

atomic=BASE/'atomic/atomic-library-write-linux'
wrapper=read(atomic/'wrapper-result.json')
probe=read(atomic/'probe/result.json')
interrupt=read(atomic/'commit-interruption/result.json')
compile_manifest=read(atomic/'compile-manifest.json')
assert wrapper['status']==probe['status']==interrupt['status']=='passed'
assert wrapper['baseRevision']==probe['sourceRevision']==interrupt['sourceRevision']==SHA
assert all(probe['checks'].values()) and probe['parentLimitAndSignalUnchanged']
assert wrapper['sourcesUnchangedDuringProbe'] and compile_manifest['sourcesUnchangedDuringCompilation']
assert wrapper['compileManifestSHA256']==digest(atomic/'compile-manifest.json')['sha256']
sources=compile_manifest['sourceSHA256']
for path,expected in sources.items():
    assert hashlib.sha256(exact_source(path)).hexdigest()==expected, path
assert compile_manifest['binarySHA256']['atomic-library-write-probe']==probe['helperBinarySHA256']
fs=wrapper['filesystemProvenance']['observations']
assert all(x['status']=='observed' and x['selectedFilesystem']['type']=='ext4' and x['targetIdentityUnchangedDuringObservation'] for x in fs)
file_checks=[]
for directory,result in [(atomic/'probe',probe)]+[(atomic/'commit-interruption'/s['mode'],s) for s in interrupt['scenarios']]:
    for filename, expected in result['files'].items():
        assert digest(directory/filename)==expected
    prior=read(directory/'prior.json');candidate=read(directory/'candidate.json');after=read(directory/'after.json')
    assert prior['activeID']==candidate['activeID']==after['activeID']
    before_map={p['id']:p for p in prior['projects']};after_map={p['id']:p for p in after['projects']}
    for ident, record in before_map.items():
        if ident!=prior['activeID']:assert after_map[ident]==record
    mode=result.get('mode','efbig')
    expected_file='candidate.json' if mode=='after-rename' else 'prior.json'
    assert (directory/'after.json').read_bytes()==(directory/expected_file).read_bytes()
    assert (directory/'control/projects.json').read_bytes()==(directory/'candidate.json').read_bytes()
    file_checks.append({'mode':mode,'allRecordedByteDigestsMatch':True,'activeIDPreserved':True,'unrelatedRecordsPreserved':True,'afterMatches':expected_file,'checksAllTrue':all(result['checks'].values()),'returnCode':result.get('injection',{}).get('returnCode')})
assert len(interrupt['scenarios'])==3 and all(s['status']=='passed' and all(s['checks'].values()) for s in interrupt['scenarios'])
assert interrupt['ownedChildrenReaped'] and interrupt['binariesUnchanged'] and interrupt['diagnosticsUnchanged'] and interrupt['sourcesUnchanged']

report={
 'reviewer':'a001_m02_audit, existing context reused; independent source/artifact review',
 'sourceRevision':SHA,'workflowRun':45805136256,'coreJob':139858259874,'jobConclusion':'success',
 'jobLog':{'path':'job.log',**digest(BASE/'job.log'),'provenance':'Complete connector decoded log, preserved as UTF-8 with original BOM and trailing newline.'},
 'artifacts':artifacts,'tests':tests,
 'host':{'environmentLog':'core/core-environment.log','operatingSystem':bench['operatingSystem'],'architecture':bench['architecture'],'cpuModel':bench['cpuModel'],'processors':bench['reportedActiveProcessors'],'swift':swift_version,'python':python_version},
 'images':{'count':12,'baseline':'docs/evidence/m02-m03-code-2026-11-25/renders','allPPMBytesAndSceneStructuresMatch':True,'fixtures':images,'scope':'Byte equivalence to retained previously reviewed images, not a new visual review.'},
 'parity':parity,
 'benchmark':{'artifact':'core/study-benchmark.json',**digest(BASE/'core/study-benchmark.json'),'optimizedBuild':True,'oneWarmupPerWorkload':True,'frameWorkloads':8,'visibilityWorkloads':4,'cancellationProbes':12,'cancellationObserved':12,'samplesPerTimedWorkload':7,'allNearestRankPercentilesRecomputedExactly':True,'repeatedFrameEquality':'Enforced by exact-source executable guard; successful execution with zero unsupported pixels. Individual repeated images are not separately archived.','timings':timings},
 'linuxAtomic':{'status':'passed','filesystem':'ext4','observedFilesystemMounts':list({json.dumps(x['selectedFilesystem'],sort_keys=True) for x in fs}),'filesystemObservations':len(fs),'compiledSourcesRehashedAtExactRevision':len(sources),'compileManifest':digest(atomic/'compile-manifest.json'),'efbigMechanism':probe['injection'],'efbigEvidence':probe['expectedFailureEvidence'],'byteAndIdentityChecks':file_checks,'sourceBinaryDiagnosticsUnchanged':True,'ownedChildrenReaped':True},
 'scope':'Exact-source portable CI and actual Linux host filesystem evidence only. No actual Metal, Apple native/UI, device performance, power-loss, physical calibration or milestone promotion claim.',
 'verificationStatus':'passed','repositoryModified':False
}
(BASE/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'status':'passed','report':str(BASE/'report.json'),'Debug':366,'Release':366,'tooling':100,'imageByteMatches':12,'kernel':6,'precision':8,'percentilesRecomputed':len(timings),'atomicScenarios':4,'exactRevisionSourceDigests':len(sources)}))
