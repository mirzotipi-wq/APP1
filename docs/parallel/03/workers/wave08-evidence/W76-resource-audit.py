from pathlib import Path
import collections, hashlib, json, math, struct, subprocess, sys

source = Path("/tmp/keyfill03-7f4b/workers/W76-resource")
repo = Path("/workspace/scratch/7f4be4bbb2d6/APP1-lane03")
evidence = repo / "docs/parallel/03/evidence"
owned = repo / "docs/parallel/03/workers/wave08-evidence"
report_path = repo / "docs/parallel/03/workers/W76-resource.md"
receipt_path = owned / "W76-resource-checks.json"
failures = []
def check(condition, message):
    if not condition: failures.append(message)
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def git(*args):
    return subprocess.check_output(["git", *args], cwd=source, text=True).strip()
def load(path):
    return json.loads(path.read_text())

head = git("rev-parse", "HEAD")
check(head == "36ed6a1455dee7ca52b55f46d1a47262f5c98cc1", "Wrong pinned source revision")
check(git("status", "--porcelain") == "", "Private source tree is not clean")
manifest_path = evidence / "final/manifest.json"
manifest = load(manifest_path)
original = load(evidence / "original/manifest.json")["fixtures"]
original_by_name = {x["name"]: x for x in original}
check(len(manifest) == len({x["name"] for x in manifest}) == 12, "Final fixture count/uniqueness")
check({x["name"] for x in manifest} == set(original_by_name), "Final/original fixture-name mismatch")
rows = []
totals = collections.Counter()
for item in manifest:
    name = item["name"]
    width, height = item["width"], item["height"]
    pixels = width * height
    expected_dimensions = (120,80) if item["subject"] == "sphere" else (144,96)
    check((width,height) == expected_dimensions, name + ": dimensions")
    check(width == original_by_name[name]["expectedWidth"], name + ": original width")
    check(item["subject"] == original_by_name[name]["subject"], name + ": original subject")
    check(item["rgbaBytes"] == pixels * 4 and item["maskBytes"] == pixels, name + ": manifest payload lengths")
    sizes, hashes = {}, {}
    for ext in ("rgba","mask","ppm","png","json"):
        path = evidence / "final" / (name + "." + ext)
        sizes[ext] = path.stat().st_size
        hashes[ext] = sha(path)
        totals[ext] += sizes[ext]
    check(sizes["rgba"] == item["rgbaBytes"] and sizes["mask"] == item["maskBytes"], name + ": raw storage lengths")
    rgba = (evidence / "final" / (name + ".rgba")).read_bytes()
    mask = (evidence / "final" / (name + ".mask")).read_bytes()
    check(all(a == 255 for a in rgba[3::4]), name + ": nonopaque alpha")
    check(not any(mask) and item["unsupportedPixels"] == 0, name + ": unsupported mask")
    ppm = (evidence / "final" / (name + ".ppm")).read_bytes()
    header = ("P6\n%d %d\n255\n" % (width,height)).encode()
    check(ppm.startswith(header) and len(ppm) == len(header) + pixels * 3, name + ": PPM size/header")
    png = (evidence / "final" / (name + ".png")).read_bytes()
    check(png[:8] == b"\x89PNG\r\n\x1a\n" and png[12:16] == b"IHDR", name + ": PNG signature")
    png_width, png_height, png_depth, png_color = struct.unpack(">IIBB",png[16:26])
    check((png_width,png_height) == (width,height), name + ": PNG dimensions")
    scene = load(evidence / "final" / (name + ".json"))
    check(len(scene["lights"]) <= 12, name + ": light count")
    rows.append(dict(name=name, subject=item["subject"], width=width, height=height, pixels=pixels,
                     fileBytes=sizes, sha256=hashes, pngBitDepth=png_depth, pngColorType=png_color,
                     sceneLightCount=len(scene["lights"])))
check(collections.Counter(x["subject"] for x in rows) == {"sphere":7,"neutral-mannequin":5}, "Subject counts")

bindings_path = evidence / "final-benchmark-inputs.json"
bindings = load(bindings_path)
benchmark_path = evidence / "final-benchmark.json"
benchmark = load(benchmark_path)
check(sha(benchmark_path) == bindings["benchmarkSHA256"], "Benchmark file hash mismatch")
bound_source = {}
for name, expected in bindings["sourceSHA256"].items():
    actual = sha(source / name)
    bound_source[name] = actual
    check(actual == expected, "Benchmark source hash mismatch: " + name)
core_manifest = load(evidence / "final-source-manifest.json")["sourceSHA256"]
core_matches = {}
for name, expected in core_manifest.items():
    if name.startswith("Sources/LightingCore/"):
        actual = sha(source / name)
        core_matches[name] = actual == expected
        check(actual == expected, "Core manifest hash mismatch: " + name)
check(len(core_matches) == 31, "Core manifest file count")
additional_source_hashes = {name:sha(source/name) for name in (
    "Sources/LightingCore/Scene.swift", "Sources/LightingCore/StudyFrameCache.swift",
    "App/MetalStudyRenderer.swift", "scripts/render-study-fixtures.swift")}
workloads = []
for kind in ("frames", "visibility"):
    expected_count = 8 if kind == "frames" else 4
    check(len(benchmark[kind]) == expected_count, kind + ": workload count")
    for item in benchmark[kind]:
        times = item["timing"]["samplesMilliseconds"]
        check(len(times) == 7 and all(math.isfinite(t) and t >= 0 for t in times), item["name"] + ": measured samples")
        ordered = sorted(times)
        for quantile in (50,95):
            computed = ordered[math.ceil(len(times)*quantile/100)-1]
            check(computed == item["timing"]["p%dMilliseconds"%quantile], item["name"] + ": quantile")
        if kind == "frames":
            check(item["unsupportedPixels"] == 0, item["name"] + ": unsupported frame")
            check(math.isfinite(item["warmupMilliseconds"]) and item["warmupMilliseconds"] >= 0, item["name"] + ": warmup")
        else:
            check(item["evaluationsPerSample"] == 1000 and item["receivers"] == 34, item["name"] + ": visibility setup")
        check(item["lightSamplesPerSurface"] == (3 if "point3" in item["name"] else 192), item["name"] + ": light samples")
        workloads.append(dict(kind=kind, name=item["name"], measuredSamples=len(times),
                              lightSamplesPerSurface=item["lightSamplesPerSurface"],
                              visibilityEnabled=item.get("visibilityEnabled")))
cancel = benchmark["cancellation"]
cancel_groups = collections.Counter((x["name"],x["requestedAfterMilliseconds"]) for x in cancel)
check(len(cancel) == 12 and all(x["cancelled"] and x["observedAtMilliseconds"] is not None for x in cancel),
      "Cancellation probe outcomes/count")
check(len(cancel_groups) == 4 and set(cancel_groups.values()) == {3}, "Cancellation groups")
check(benchmark["measuredSamplesPerWorkload"] == 7 and benchmark["optimizedBuild"], "Benchmark declared settings")
check(benchmark["sourceRevision"] == "74f7584b4e474c752ec0939add6b7522ba98094f", "Raw revision changed")

budget = dict(maximumFrames=4, maximumRGBABytes=262144, maximumMaskBytes=65536,
              fourMaximumBustRGBABytes=4*55296, fourMaximumBustMaskBytes=4*13824,
              fourArchivedSphereRGBABytes=4*38400, fourArchivedSphereMaskBytes=4*9600,
              maximumInteractiveSpherePixels=192*128, maximumInteractiveSphereRGBABytes=192*128*4,
              maximumInteractiveSphereMaskBytes=192*128, maximumFullSizeSphereFrames=2)
receipt = dict(worker="W76-resource", canonicalTask="/root/wave08/w76_resource",
               inputCommit=head, sourceTree=git("rev-parse","HEAD^{tree}"), privateTree=str(source),
               privateSourceClean=git("status","--porcelain") == "",
               command="python3 " + str(owned/"W76-resource-audit.py"),
               inspection="Read-only archive parsing, file stat/SHA-256, source review and arithmetic. No Swift build/test/render/benchmark.",
               status="PASS" if not failures else "FAIL", failures=failures,
               manifestSHA256=sha(manifest_path), benchmarkInputsSHA256=sha(bindings_path),
               benchmarkSHA256=sha(benchmark_path), benchmarkActualSourceCommit=bindings["actualSourceCommit"],
               benchmarkRawRevision=benchmark["sourceRevision"], boundSourceSHA256=bound_source,
               unchangedCoreFileCount=len(core_matches), all31CoreHashesMatch=all(core_matches.values()),
               otherReviewedSourceSHA256=additional_source_hashes, fixtures=rows,
               totals=dict(totals), totalPixels=sum(x["pixels"] for x in rows),
               rgbaPlusMaskBytes=totals["rgba"]+totals["mask"], archiveFixtureFilesBytes=sum(totals.values()),
               manifestBytes=manifest_path.stat().st_size,
               archiveDirectoryFiles=len([p for p in manifest_path.parent.iterdir() if p.is_file()]),
               archiveDirectoryBytes=sum(p.stat().st_size for p in manifest_path.parent.iterdir() if p.is_file()),
               sourceNumericalBounds=dict(mannequinWidth=144, sceneLights=12,
                   rectangleInteractiveSamples=64, rectangleReferenceSamples=1024,
                   sceneInteractiveSamplesPerSurface=768, sceneReferenceSamplesPerSurface=12288,
                   maximumPixelsBetweenCancellationPolls=8),
               cachePayloadBudget=budget, benchmarkWorkloads=workloads,
               frameMeasuredSamples=sum(w["measuredSamples"] for w in workloads if w["kind"]=="frames"),
               visibilityMeasuredSamples=sum(w["measuredSamples"] for w in workloads if w["kind"]=="visibility"),
               measuredVisibilityEvaluations=28000, cancellationProbes=len(cancel),
               frameWarmupTimings=len(benchmark["frames"]), visibilityWarmupCallsFromSource=4,
               caveats=[
                   "Cache limits describe retained RGBA/mask payload maxima, not resident-process-memory measurements.",
                   "Numerical loops and sample arrays are bounded after validation; existing caller arrays and arbitrary Unicode name validation cost are outside those bounds.",
                   "StudioLight validates trimmed nonempty names and <=80 Swift Characters, with no UTF-8 byte cap. Cache keys strip names only after validation. Lane02 owns name policy.",
                   "Cancellation limit is pixel work, not a wall-clock deadline including validation.",
                   "Benchmark is archived optimized Linux x86_64 CPU evidence; native/device timing unrun. No benchmark or tests rerun by W76.",
                   "Prior runtime resets and optional W72 receipt ENOSPC were not modified or cleaned."])
owned.mkdir(parents=True, exist_ok=True)
if receipt_path.exists() or report_path.exists():
    raise RuntimeError("Refusing to overwrite existing W76 report/receipt")
receipt_path.write_text(json.dumps(receipt,indent=2,sort_keys=True)+"\n")
receipt_sha = sha(receipt_path)
report = f"""# W76 resource review

- Canonical ID: `/root/wave08/w76_resource`; input `{head}`.
- Private tree: `{source}` (detached, clean); output: `/tmp/keyfill03-7f4b/builds/W76-resource`.
- Status: **{receipt["status"]}: archive checks and scoped source inspection**. No Swift test, build, render or benchmark executed.
- Evidence: `wave08-evidence/W76-resource-audit.py`, `W76-resource-checks.json`; receipt SHA-256 `{receipt_sha}`.

## Verified resources

All twelve final manifest records match actual RGBA/mask lengths, PNG dimensions and PPM dimensions/lengths: seven spheres at 120×80; five mannequins at 144×96. A sphere contains 38,400 RGBA + 9,600 mask bytes; a mannequin 55,296 + 13,824. Aggregate: **545,280 RGBA + 136,320 mask = 681,600 bytes**, covering 136,320 pixels. Archived PPMs total {totals["ppm"]:,} bytes; PNGs {totals["png"]:,}; scene JSON {totals["json"]:,}. These sixty fixture files total {sum(totals.values()):,} bytes; the manifest adds {manifest_path.stat().st_size:,}. Raw alpha is uniformly 255 and masks zero.

Pinned source enforces mannequin width ≤144, twelve scene lights, 64/1,024 samples per rectangular emitter (≤768/12,288 scene samples per surface), and cancellation polling every eight pixels. The cache admits ≤4 frames, ≤262,144 RGBA bytes and ≤65,536 mask bytes. Four maximum mannequins need 221,184 RGBA +55,296 mask bytes; a 192×128 sphere needs 98,304 +24,576, so only two such frames fit. These are retained-payload maxima, **not measured process memory**.

Names are trimmed and counted (≤80 Swift Characters), with no UTF-8 byte cap. Cache keys remove names after validation. Numerical/sample-array bounds do not bound caller input storage or arbitrary-name validation cost; cancellation's pixel bound is not a validation-time guarantee. Lane02 owns name policy.

## Archived benchmark

Actual arrays contain **56 frame measurements (8×7), 28 visibility measurements (4×7), and 12 successful cancellation probes**. All twelve p50/p95 pairs recompute correctly; frames report zero unsupported pixels. Visibility uses 1,000 evaluations/sample over 34 receivers (28,000 measured evaluations). Eight frame warm-up timings are stored; four visibility warm-ups are source-confirmed.

Benchmark hash matches its binding; all four bound source hashes and all 31 core hashes match this input. Raw revision remains 74f7584; binding identifies compiled source db7a5b5. No concrete resource mismatch found. Native/device timing is unrun; prior failures remain untouched.
"""
report_path.write_text(report)
print(json.dumps({k:receipt[k] for k in ("status","failures","totals","totalPixels","rgbaPlusMaskBytes",
     "archiveFixtureFilesBytes","archiveDirectoryFiles","archiveDirectoryBytes","all31CoreHashesMatch",
     "frameMeasuredSamples","visibilityMeasuredSamples","cancellationProbes")},indent=2))
print("receiptSHA256",receipt_sha)
print("reportWords",len(report.split()))
print("reportBytes",report_path.stat().st_size)
print("benchmarkSHA256",receipt["benchmarkSHA256"])
print("privateSourceStatus",git("status","--porcelain") or "clean")
sys.exit(1 if failures else 0)

