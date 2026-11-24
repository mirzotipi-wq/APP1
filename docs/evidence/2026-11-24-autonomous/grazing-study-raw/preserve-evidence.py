from pathlib import Path
import difflib, hashlib, json, shutil, subprocess
root=Path.cwd();repo=Path('/workspace/scratch/73dcd6a65726/APP1');base='3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18'
evidence=repo/'docs/evidence/2026-11-24-autonomous';raw=evidence/'grazing-study-raw';raw.mkdir(parents=True,exist_ok=True)
paths=['Sources/LightingCore/ReferenceStudy.swift','Sources/LightingCore/StudyAreaClipping.swift','App/StudyKernel.h','Tests/LightingCoreTests/StudyComputeInputTests.swift','Tests/LightingCoreTests/StudyGrazingTests.swift','scripts/verify-kernel-host.cpp','scripts/grazing-study-probe.swift','scripts/verify-study-grazing.cpp']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
patch=[];source_manifest=[]
for rel in paths:
    result=subprocess.run(['git','show',base+':'+rel],cwd=repo,stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
    old=result.stdout.decode() if result.returncode==0 else ''
    new=(root/rel).read_text()
    if result.returncode==0:
        assert (repo/rel).read_bytes()==result.stdout, 'Live production target changed: '+rel
    else: assert not (repo/rel).exists(), 'Unexpected live new file: '+rel
    patch.extend(difflib.unified_diff(old.splitlines(keepends=True),new.splitlines(keepends=True),fromfile='a/'+rel if old else '/dev/null',tofile='b/'+rel))
    source_manifest.append({'path':rel,'sha256':sha(root/rel),'bytes':(root/rel).stat().st_size,'baseExists':result.returncode==0})
patch_path=evidence/'grazing-study-candidate.patch';patch_path.write_text(''.join(patch))
selected=[]
for source in (root/'verification').rglob('*'):
    if not source.is_file():continue
    rel=source.relative_to(root/'verification')
    take=source.suffix in ['.log','.py'] or (source.suffix=='.json' and ('paired' in str(rel) or source.name=='manifest.json'))
    take=take or source.name in ['grazing-study-continuity.swift','grazing-study-continuity.cpp','main.swift','SCOPE.md']
    if not take:continue
    target=raw/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    selected.append({'path':str(target.relative_to(repo)),'sha256':sha(target),'bytes':target.stat().st_size})
fixtures=[{'path':str(p.relative_to(root)),'sha256':sha(p),'bytes':p.stat().st_size} for p in sorted((root/'verification/candidate').rglob('*.bin'))]
first=json.loads((root/'verification/paired-before-fast-path/summary.json').read_text())
final=json.loads((root/'verification/paired/summary.json').read_text())
rows=[]
for row in final['frames']:
    previous=next(x for x in first['frames'] if x['name']==row['name'])
    rows.append('| '+row['name']+' | '+f"{previous['baseline']['median']:.3f} → {previous['candidate']['median']:.3f} ({(previous['candidateToBaselineMedian']-1)*100:+.1f}%) | {row['baseline']['median']:.3f} → {row['candidate']['median']:.3f} ({(row['candidateToBaselineMedian']-1)*100:+.1f}%) |")
report='''# Grazing study renderer candidate — HOLD

**Do not integrate this candidate.** It corrects the reproduced false-zero cases but introduces a measured internal-cell continuity defect. Its added rendering cost is also not accepted: paired host measurements vary substantially, including point-light controls, and do not establish an ordinary-path performance pass. Production renderer/core source is unchanged by this experiment. KF-025 remains unresolved; no product, native, physical-device or performance gate is promoted.

## Provenance and reconstruction

The isolated candidate was copied with `git archive` from exact source **`3b2a4cee68a06a9ff2a1cb3de88814fefc0f0d18`**, tree **`0ff9fa32a412534af0e11629e442f0a46a1176a0`**, into `verification/grazing-study-candidate`. There was no new Git branch, live-source application, staging or commit by this specialist. The root integration lead authorized this evidence-only preservation after deciding HOLD.

[The complete patch](grazing-study-candidate.patch) contains all eight changed/new source, test and probe files. Apply it only to an isolated archive of that base to reconstruct the held candidate. [The manifest](grazing-study-manifest.json) identifies every proposed file, the patch, retained raw files and generated fixture inputs by SHA-256. Raw fixture binaries are reproducible from the recorded generators and their exact hashes; they are not represented as native artifacts. The candidate and baseline were compiled with Swift 6.4.3 on Debian 13 x86_64; shared-kernel checks used the bundled Clang C++ host compiler. This is not Apple SDK, Metal GPU or device execution.

The raw [build driver](grazing-study-raw/build-release.py), [baseline build driver](grazing-study-raw/build-baseline-bench.py), [client build driver](grazing-study-raw/build-clients.py), [paired benchmark driver](grazing-study-raw/paired-benchmarks.py) and generated [259-method XCTest entry point](grazing-study-raw/candidate/release/main.swift) preserve the actual standalone build/test procedure. No SwiftPM build cache was created for this experiment.

## Candidate algorithm and scope

The prepared rectangle grid remains 8×8 or 32×32. A cell wholly inside the receiver hemisphere retains its original ordered midpoint and weight. A crossed cell is clipped to positive incidence in normalized cell coordinates. The polygon is triangulated and each triangle uses three interior degree-two quadrature points. Each weight is the triangle cross-product magnitude divided by 24: one half for triangle area, one quarter for cell area, and one third for its three points. Shader and Swift half-cell extents are the rectangle half-width/half-height divided by the grid count.

For the mannequin, Swift also clips against the actual geometric hemisphere and retains the per-point geometric-normal check. Every generated position passes through the original irradiance, material and finite shadow-segment evaluation. Two CPU clipping planes need at most six polygon vertices; the implementation provides two eight-element temporary buffers. One shader plane needs at most five vertices. This is bounded quadrature over representable regions narrower than a grid cell; it does not guarantee recovery of arbitrarily small regions under floating-point rounding.

Sample `color.w` now carries zero for non-area samples or a one-based area index. `parameters[5].w` carries the grid count. All packed consumers were inspected: the native adapter uploads the rows unchanged, the Metal entry point delegates to the shared header, fixture writers serialize the same row counts, and packing tests/host validation cover the new fields. The row layout, near-field thresholds, Float32 eligibility/guard/routing, material model, visibility segment endpoints and pixel cancellation check schedule were not relaxed.

The proposed `sampleCount` and the unchanged benchmark field `lightSamplesPerSurface` describe prepared base samples/cells. They do **not** count the additional receiver-dependent points. A crossed cell can emit at most nine points for one plane or twelve for shading plus geometric planes. Actual extra visibility/material work therefore exists even where ordinary-cell metadata overhead is reduced. The one final fast-path attempt bypasses per-cell metadata branches only when every rectangle is wholly front-facing to both required hemispheres.

## Baseline reproduction and numerical results

The actual [baseline probe](grazing-study-raw/baseline/grazing-regressions.log) failed all 16 exploratory comparisons to an independent vertical-slice Simpson integral at 0.2%; **12 returned exactly zero**. Both baseline qualities returned zero for the 1 mm strip with reference illuminance **0.0004866464210327955 lx**.

The final [Swift candidate probe](grazing-study-raw/candidate/grazing-regressions.log) makes all 12 false-zero cases positive. **13/16** meet the exploratory 0.2% bound, and all 16 lie below the unchanged study-area 5% criterion. The exploratory criterion was not rewritten to conceal the remaining failures.

| Retained broader case | Candidate relative error against independent integral |
| --- | ---: |
| Interactive corner, cut 0.6 | 4.721595766% |
| Reference strip, cut 0.45 | 1.079596363% |
| Reference corner, cut 0.6 | 0.566641887% |

For the 1 mm strip, candidate values are 0.0004866459822363482 lx interactively and 0.0004866464129290847 lx at reference quality: relative errors about 9.02×10⁻⁷ and 1.67×10⁻⁸. These are numerical fixture results, not calibrated portrait evidence or general meter equivalence.

The [shared Float32 probe](grazing-study-raw/candidate/grazing-float32.log) passes its 16 explicitly declared checks, plus full-cell, dark/tangent and intensity-scaling controls. Its 1 mm/narrow-region checks retain 0.2%; 10 µm cases use a separately disclosed 2% finite-precision bound. The largest observed microscopic relative error is about 0.543%. That probe directly exercises `kfClipStudyCell` and `kfStudyIncident` at grids 8 and 32. It does **not**, by itself, exercise `kfStudyPixel`'s cached whole-area path, material/occlusion logic or invalid masks; the separate full-frame tests cover some of those paths.

At the broad cut=0.6 corner, Double yields **1.9710131637547668 lx** and Float32 **1.8831355571746826 lx**. Their linear-light difference is about **4.46% relative to Double**. Both passing a 5% reference check, or the existing tone-mapped image threshold, does not establish general CPU/GPU numerical equivalence.

## Confirmed continuity defect

The independent reviewer challenged the switch from a full-cell midpoint to multiple clipped-region points. Exactly one bounded experiment evaluated cut **0.6−10⁻⁸, 0.6, 0.6+10⁻⁸**, with the same interactive receiver and slope 1. The [raw log](grazing-study-raw/grazing-study-continuity.log), [Swift source](grazing-study-raw/grazing-study-continuity.swift), and [shared-Float32 source](grazing-study-raw/grazing-study-continuity.cpp) are retained.

| Cut | Baseline Double (lx) | Candidate Double (lx) | Independent Simpson (lx) |
| --- | ---: | ---: | ---: |
| 0.5999999899999999 | 1.7651909651029574 | 1.9710135102369204 | 1.8821461933566823 |
| 0.6 | 1.7651906408809135 | 1.9710131637547668 | 1.8821458452128712 |
| 0.60000001 | 1.7651903166588767 | 1.8836090427411123 | 1.8821454970691125 |

Across the two adjacent cuts, baseline changes by **6.484440806531211×10⁻⁷ lx** and Simpson by **6.962875698235393×10⁻⁷ lx**, while candidate Double jumps **0.0874044674958081 lx**, or **4.4344943556%** of its central value. The three Float32 inputs produce the same quantized result, 1.8831355571746826 lx. This is a measured linear-light numerical defect. No visible flicker or native GPU failure was observed, and neither is claimed.

The passing whole-emitter full/partial transition test covers a different boundary. It does not establish continuity at internal grid-cell boundaries. This new counterexample is a blocker despite the otherwise green existing suites. A future design must retain this as a failing continuity regression before integration; expanding already-positive cells merely to hide the exploratory accuracy numbers is not an accepted fix.

## Regression evidence and its limits

- Final [optimized Swift run](grazing-study-raw/candidate/release/tests.log): **259/259 passed**, comprising all 251 existing methods and eight new methods. Coverage includes narrow strips/corners, dark/tangent/backface/near-field behavior, full-cell midpoint and whole-face transition controls, intensity/material scaling, real per-point visibility, geometric hemispheres and bounded weights. This passing suite does not override the later continuity counterexample.
- The [initial new-test failure](grazing-study-raw/candidate/release/tests-initial.log) is retained. It assumed exact mirror symmetry from finite triangle quadrature. The new test was corrected to compare the half-domain against the independent integral with the same 0.2% narrow-region bound and to assert the actual geometric hemisphere for every ray. No preexisting test tolerance was changed.
- [Original six full-frame host fixtures](grazing-study-raw/candidate/kernel-parity.log): **6/6 passed**, maximum channel difference at most one; invalid masks match, including **84/84** near-field pixels.
- [Eight strict controls](grazing-study-raw/candidate/precision-parity.log): **8/8 passed** at the repository's existing `--maximum-channel-error 1` setting, with matching invalid masks. Seven are byte-exact; one has a single channel differing by one level. The extra [zero-error exploration](grazing-study-raw/candidate/precision-byte-exact-exploratory.log), which failed that one control, remains separate. The actual preexisting gate was not loosened.
- There was no actual Apple compilation or new Metal/device run of this candidate. Earlier native successes at other source revisions do not certify it.

## Performance: retained measurements, no pass claim

Both paired sequences ran after the integration lead reported its compiler/tests complete. Baseline/candidate full-frame order was B/C/C/B, three measured frames per workload per process after warmup. Surface order was B/C/B/C, six measured batches after warmup. The host remains shared; point-light controls expose substantial variability. These finite observations cannot establish a clean speedup or a reliable decomposition of code overhead and scheduling noise.

| Workload | Before fast path, baseline → candidate ms | Final fast path, baseline → candidate ms |
| --- | ---: | ---: |
'''+ '\n'.join(rows)+'''

The [first CPU-clear raw sequence](grazing-study-raw/paired-before-fast-path/summary.json) and [final raw sequence](grazing-study-raw/paired/summary.json) retain every measured value and per-run report. Initial unpaired [baseline](grazing-study-raw/baseline/grazing-benchmark.log)/[candidate](grazing-study-raw/candidate/grazing-benchmark.log) timings are retained. The [overlapping run](grazing-study-raw/paired-load-overlap/SCOPE.md) is explicitly excluded from the decision because root compilation/tests were active.

For fully lit surface batches, the first CPU-clear sequence measured +16.8% at 8×8 and +0.7% at 32×32. After the final fast path, those medians changed to −15.6% and +10.9%; that inconsistency is not evidence of an optimization win. Point-frame ratios in the final sequence range from +13.8% to about +194%. Area workloads perform genuinely more visibility/material evaluations, but the exact wall-clock cost cannot be attributed solely to that work from these runs.

Pixel cancellation still checks at most every eight pixel evaluations; each evaluation can now contain more quadrature work. No CPU wall-clock cancellation bound, device frame-time guarantee, thermal result or Metal performance claim follows from that schedule. The full raw benchmark reports include the actual cancellation probes and visibility batches.

## Disposition

**HOLD / not integrated.** Preserve the useful false-zero reproduction and the candidate's positive-region results, but do not promote KF-025 or a performance/native gate. The internal-cell continuity jump is a concrete numerical blocker. The broad linear-light backend difference and uncertain additional CPU cost also remain explicit. The source patch, authored tests/probes, all raw result logs/reports and exploratory prototype records are retained for a later redesign and independent review. The isolated source and this evidence do not modify live production renderer/core source.
'''
report_path=evidence/'grazing-study-report.md';report_path.write_text(report)
manifest={'schema':1,'decision':'HOLD; not integrated','sourceBase':base,'sourceBaseTree':'0ff9fa32a412534af0e11629e442f0a46a1176a0','productionSourceChanged':False,'sourceFiles':source_manifest,'patch':{'path':str(patch_path.relative_to(repo)),'sha256':sha(patch_path),'bytes':patch_path.stat().st_size},'report':{'path':str(report_path.relative_to(repo)),'sha256':sha(report_path),'bytes':report_path.stat().st_size},'rawFiles':sorted(selected,key=lambda x:x['path']),'reproducibleGeneratedFixtureInputs':fixtures,'scope':'Linux numerical/host checks only; no native/GPU/device acceptance. Raw fixture binaries are regenerable from the retained base/patch/scripts and are identified here by hash.'}
manifest_path=evidence/'grazing-study-manifest.json';manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
print('PRODUCTION_TARGETS_UNCHANGED',len(paths));print('PATCH',sha(patch_path));print('REPORT',sha(report_path));print('MANIFEST',sha(manifest_path));print('RAW_FILES',len(selected),'RAW_BYTES',sum(x['bytes'] for x in selected));print('FIXTURE_INPUT_HASHES',len(fixtures))
