#!/usr/bin/env python3
"""Read-only W93 source/artifact audit; no rendering, builds, or Swift tests."""
import hashlib
import json
import math
from pathlib import Path
import re
import struct
import subprocess
import sys

TREE = Path('/tmp/keyfill03-7f4b/workers/W93-api')
ROOT = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
EVIDENCE = ROOT / 'docs/parallel/03/evidence'
OUTPUT = ROOT / 'docs/parallel/03/workers/wave10-evidence/W93-api.json'
PIN = '342e3280e3eb077d55e122c8bfb88b4062b431ed'
CPU_PIN = 'db7a5b5f3dd2d18c2469e78d3cf22ec01d84d6b5'
checks = []
commands = []

def check(label, condition):
    checks.append({'check': label, 'passed': bool(condition)})
    if not condition:
        raise AssertionError(label)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def command(args):
    p = subprocess.run(args, cwd=TREE, capture_output=True, text=True)
    commands.append({'argv': args, 'cwd': str(TREE), 'exitCode': p.returncode,
                     'stdout': p.stdout, 'stderr': p.stderr})
    check('command exit: ' + ' '.join(args), p.returncode == 0)
    return p.stdout

def load(name):
    return json.loads((EVIDENCE / name).read_text())

def file_receipt(path, expected=None):
    data = path.read_bytes()
    result = {'path': str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path),
              'bytes': len(data), 'sha256': sha(data)}
    if expected is not None:
        result['expectedSHA256'] = expected
        result['hashMatches'] = result['sha256'] == expected
        check('hash: ' + result['path'], result['hashMatches'])
    return result

def inspect_bin(relative, expected_sha=None, expected_width=None):
    path = EVIDENCE / relative
    data = path.read_bytes()
    receipt = file_receipt(path, expected_sha)
    w, h, parameter_rows, sample_rows, area_rows, invalid = struct.unpack_from('<6I', data)
    check('binary dimensions/packing: ' + relative,
          w == expected_width and h == w * 2 // 3 and parameter_rows == 6
          and sample_rows % 3 == 0 and area_rows % 3 == 0)
    total_rows = parameter_rows + sample_rows + area_rows
    check('binary size: ' + relative, len(data) == 24 + total_rows * 16 + w * h * 4)
    floats = struct.unpack_from('<' + 'f' * (4 * total_rows), data, 24)
    check('finite packed values: ' + relative, all(math.isfinite(v) for v in floats))
    check('packed sample/area counts: ' + relative,
          floats[20] == sample_rows // 3 and floats[21] == area_rows // 3)
    rgba = data[24 + total_rows * 16:]
    alpha = rgba[3::4]
    check('reference flag values/count: ' + relative,
          set(alpha) <= {0, 255} and alpha.count(0) == invalid)
    check('reference invalid RGB: ' + relative,
          all(rgba[i:i+3] == bytes((255, 0, 255)) for i in range(0, len(rgba), 4) if rgba[i+3] == 0))
    receipt.update({'width': w, 'height': h, 'parameterRows': parameter_rows,
                    'sampleRows': sample_rows, 'areaRows': area_rows,
                    'referenceUnsupportedPixels': invalid,
                    'referencePayloadAlphaCounts': {'0': alpha.count(0), '255': alpha.count(255)}})
    return receipt

def parse_log(name):
    rows = []
    for line in (EVIDENCE / name).read_text().splitlines():
        m = re.search(r'/([^/]+)\.bin: mean=([^,]+), max=(\d+), >4 fraction=([^,]+), invalid=(\d+)/(\d+), invalid-mask-mismatches=(\d+)(?:, max-limit=(\d+))?, (PASS|FAIL)$', line)
        check('parse log line: ' + name, m is not None)
        n, mean, maximum, fraction, actual, expected, mismatch, limit, status = m.groups()
        rows.append({'name': n, 'meanChannelError': float(mean), 'maximumChannelError': int(maximum),
                     'fractionAboveFour': float(fraction), 'actualUnsupported': int(actual),
                     'expectedUnsupported': int(expected), 'invalidMaskMismatches': int(mismatch),
                     'maximumLimit': int(limit) if limit else None, 'status': status,
                     'execution': 'retained root-owned host harness; not rerun by W93'})
    return rows

check('pinned HEAD', command(['git', 'rev-parse', 'HEAD']).strip() == PIN)
check('private source tree clean', command(['git', 'status', '--short']).strip() == '')
scope = ['Sources/LightingCore', 'scripts/render-study-fixtures.swift',
         'scripts/prepare-kernel-fixtures.swift', 'scripts/precision-boundary.swift',
         'scripts/verify-kernel-host.cpp', 'App/StudyKernel.h']
check('CPU/generators/shared harness unchanged since db7',
      command(['git', 'diff', '--name-only', CPU_PIN, 'HEAD', '--'] + scope).strip() == '')
preview_diff = command(['git', 'diff', '--name-only', '36ed6a1455dee7ca52b55f46d1a47262f5c98cc1',
                        'HEAD', '--', 'App/ReferenceStudyPreview.swift', 'NativeTests']).splitlines()

source_manifest = load('final-source-manifest.json')
parity_manifest = load('final-parity-inputs.json')
comparison = load('final-comparison.json')
original = load('original/manifest.json')
final = load('final/manifest.json')
precision_manifest = load('final-parity/precision/manifest.json')
sources = []
for relative, expected in {**source_manifest['sourceSHA256'], **parity_manifest['sourceSHA256']}.items():
    path = TREE / relative
    if not path.exists():
        path = ROOT / relative
    actual = sha(path.read_bytes())
    sources.append({'path': relative, 'manifestSHA256': expected, 'currentSHA256': actual,
                    'matches': actual == expected})
core_sources = [x for x in sources if x['path'].startswith('Sources/LightingCore/')]
check('31 CPU manifest hashes', len(core_sources) == 31 and all(x['matches'] for x in core_sources))
changed_sources = [x['path'] for x in sources if not x['matches']]
check('only expected preview/pipeline manifest differences',
      set(changed_sources) == {'App/ReferenceStudyPreview.swift', 'NativeTests/StudyPreviewPipelineTests.swift'})
generator_sha = sha((TREE / 'scripts/render-study-fixtures.swift').read_bytes())
archive_sources = [x for x in sources if Path(x['path']).name in
                   ['Scene.swift', 'SceneCodec.swift', 'SceneFileStore.swift', 'LightingProjectDocument.swift', 'ProjectLibrary.swift']]

preview_source = (TREE / 'App/ReferenceStudyPreview.swift').read_text()
entry = {'type': '@MainActor struct ReferenceStudyPreview: View',
         'visibility': 'internal Swift type, app-facing memberwise scene/subject entry',
         'scene': 'LightingScene', 'subject': 'StudySubject', 'defaultSubject': 'sphere',
         'sourceSHA256': sha(preview_source.encode()),
         'ordinaryCallSites': [],
         'internalTestingSeam': 'renderStudy: @MainActor (LightingScene, StudySubject) async throws -> StudyPreviewOutput'}
check('scene/subject/default-sphere entry retained',
      '@MainActor struct ReferenceStudyPreview: View' in preview_source
      and 'let scene: LightingScene' in preview_source and 'var subject: StudySubject = .sphere' in preview_source)
for relative in ['App/StudioView.swift', 'App/ReferenceComparisonView.swift']:
    for number, line in enumerate((TREE / relative).read_text().splitlines(), 1):
        if 'ReferenceStudyPreview(' in line:
            entry['ordinaryCallSites'].append({'path': relative, 'line': number, 'text': line.strip()})
check('both ordinary caller shapes retained', len(entry['ordinaryCallSites']) == 2
      and any('subject: studySubject' in x['text'] for x in entry['ordinaryCallSites'])
      and any('scene: selectedRig?.scene ?? scene)' in x['text'] for x in entry['ordinaryCallSites']))
entry['nativeTypecheckByW93'] = False

image_names = re.findall(r'\.init\(name: "([^"]+)"', (TREE / 'scripts/render-study-fixtures.swift').read_text())
check('exact twelve ordinary definitions/manifests', len(image_names) == len(set(image_names)) == 12
      and image_names == [x['name'] for x in original['fixtures']]
      and image_names == [x['name'] for x in final]
      and image_names == [x['name'] for x in comparison['fixtures']])
images = []
for c, o, f in zip(comparison['fixtures'], original['fixtures'], final):
    name = c['name']; w, h = c['width'], c['height']
    artifacts = {filename: file_receipt(EVIDENCE / 'final' / filename, expected)
                 for filename, expected in c['hashes'].items()}
    originals = {suffix: file_receipt(EVIDENCE / 'original' / (name + '.' + suffix), c['original_' + suffix + '_sha256'])
                 for suffix in ['ppm', 'png', 'json']}
    check('original/final JSON PNG PPM byte correspondence: ' + name,
          all((EVIDENCE / 'original' / (name + '.' + suffix)).read_bytes() ==
              (EVIDENCE / 'final' / (name + '.' + suffix)).read_bytes() for suffix in originals))
    rgba = (EVIDENCE / 'final' / (name + '.rgba')).read_bytes()
    mask = (EVIDENCE / 'final' / (name + '.mask')).read_bytes()
    ppm = (EVIDENCE / 'final' / (name + '.ppm')).read_bytes()
    expected_header = f'P6\n{w} {h}\n255\n'.encode()
    rgb = bytes(v for i, v in enumerate(rgba) if i % 4 != 3)
    check('opaque RGBA, all-zero raw mask, RGB projection: ' + name,
          len(rgba) == w * h * 4 == f['rgbaBytes'] and set(rgba[3::4]) == {255}
          and len(mask) == w * h == f['maskBytes'] and set(mask) == {0}
          and ppm == expected_header + rgb)
    check('zero-unsupported manifests: ' + name,
          c['unsupportedPixels'] == o['unsupportedPixels'] == f['unsupportedPixels'] == 0
          and c['opaque'] and c['validMask'] and c['maskAllZero'] and f['opaque'] and f['validMask']
          and o['passed'] and not o['validationErrors'])
    absent = {suffix: not (EVIDENCE / 'original' / (name + '.' + suffix)).exists() for suffix in ['rgba', 'mask']}
    check('original raw payloads absent: ' + name, all(absent.values()))
    images.append({'name': name, 'subject': o['subject'], 'width': w, 'height': h,
                   'coverage': o['coverage'], 'savedSceneConfiguration': load('final/' + name + '.json'),
                   'artifacts': artifacts, 'originalArtifacts': originals,
                   'originalRawAbsent': absent, 'finalRGBAAlphaValues': [255], 'finalRawMaskValues': [0],
                   'unsupportedPixels': 0, 'originalRawRGBAOrMaskByteEqualityEstablished': False})

required_parity_names = ['hard', 'soft', 'warm-rotated', 'dark', 'near-field', 'translated']
fixture_source = (TREE / 'Sources/LightingCore/StudyValidationFixtures.swift').read_text()
check('six parity definitions', re.findall(r'\("([^"]+)",', fixture_source) == required_parity_names)
required_precision_names = sorted([f'area-camera-{d}-lens-{f}' for d in ['19.0', '19.999999', '20.0']
                                   for f in [85, 200]] + ['world-translation--77', 'world-translation-77'])
required_parity = []
required_precision = []
for relative, expected in parity_manifest['fixtures'].items():
    is_parity = '/kernel/' in relative
    item = inspect_bin(relative, expected, 96 if is_parity else 192)
    item['name'] = Path(relative).stem
    (required_parity if is_parity else required_precision).append(item)
check('exact six parity hashes', sorted(x['name'] for x in required_parity) == sorted(required_parity_names)
      and parity_manifest['requiredParityCount'] == 6)
check('exact eight required precision hashes', sorted(x['name'] for x in required_precision) == required_precision_names
      and parity_manifest['requiredPrecisionCount'] == 8)
check('near-field 84 reference flags; five ordinary parity cases zero',
      all(x['referenceUnsupportedPixels'] == (84 if x['name'] == 'near-field' else 0) for x in required_parity))
parity_log = parse_log('final-kernel.log'); precision_log = parse_log('final-precision.log')
for inventory, log in [(required_parity, parity_log), (required_precision, precision_log)]:
    by_name = {x['name']: x for x in log}
    check('retained gate log exact inventory', sorted(by_name) == sorted(x['name'] for x in inventory))
    for item in inventory:
        result = by_name[item['name']]
        check('retained numerical gate: ' + item['name'], result['status'] == 'PASS'
              and result['invalidMaskMismatches'] == 0 and result['actualUnsupported'] == result['expectedUnsupported'] == item['referenceUnsupportedPixels']
              and result['meanChannelError'] <= 1 and result['fractionAboveFour'] <= .005)
        if inventory is required_precision:
            check('strict precision limit: ' + item['name'], result['maximumLimit'] == 1 and result['maximumChannelError'] <= 1)
        item['retainedHostResult'] = result

supplemental = []
precision_by_name = {x['name']: x for x in precision_manifest}
check('33 generated precision records, including required eight', len(precision_by_name) == len(precision_manifest) == 33
      and set(required_precision_names) <= set(precision_by_name))
for name, manifest_row in precision_by_name.items():
    scene = file_receipt(EVIDENCE / 'final-parity/precision' / (name + '.scene.json'))
    if name in required_precision_names:
        item = next(x for x in required_precision if x['name'] == name)
        item['savedScene'] = scene
        item['generatorManifestRecord'] = manifest_row
    else:
        item = inspect_bin('final-parity/precision/' + name + '.bin', expected_width=192)
        item.update({'name': name, 'savedScene': scene, 'generatorManifestRecord': manifest_row,
                     'requiredGateCase': False, 'executionResultClaimed': False})
        supplemental.append(item)
    check('precision manifest reference count: ' + name, item['referenceUnsupportedPixels'] == manifest_row['doubleUnsupportedPixels'])
check('25 separate supplemental probes', len(supplemental) == 25
      and sum(x['name'].startswith('tangent-') for x in supplemental) == 9
      and sum(x['name'].startswith('near-mask-') for x in supplemental) == 14
      and sum(x['name'].startswith('light-distance-') for x in supplemental) == 2)

ci = load('ci-core-342.json')
ci_log = (EVIDENCE / 'ci-core-342.log').read_text()
check('current core receipt source/result', ci['source'] == PIN and ci['result'] == 'success')
ci_log_receipt = file_receipt(EVIDENCE / 'ci-core-342.log', ci['raw_log_sha256'])
check('391 Debug and Release receipt/raw summaries', ci['debug']['tests'] == ci['standard_release']['tests'] == 391
      and ci['debug']['failures'] == ci['standard_release']['failures'] == 0
      and 'Executed 391 tests, with 0 failures (0 unexpected) in 13.234' in ci_log
      and 'Executed 391 tests, with 0 failures (0 unexpected) in 5.368' in ci_log)
check('current 6+8 raw gate result correspondence', len(ci['gate_results']) == 14
      and all(line in ci_log for line in ci['gate_results'])
      and sum('max-limit=1' in line for line in ci['gate_results']) == 8)
prior_native = load('ci-native-36.json')
prior_native_log = file_receipt(EVIDENCE / 'ci-native-36.log', prior_native['logSHA256'])
adoption_source = TREE / 'NativeTests/StudyPreviewAdoptionTests.swift'
new_test_name = 'testReactivatedCompletedFrameConsultsEngineAfterCancelledDowngrade'
check('new hosted test differs from prior native source', new_test_name in adoption_source.read_text()
      and 'NativeTests/StudyPreviewAdoptionTests.swift' in preview_diff)

tracked_evidence = ['final-source-manifest.json', 'final-comparison.json', 'final-parity-inputs.json',
                    'original/manifest.json', 'final/manifest.json', 'final-parity/precision/manifest.json',
                    'final-matrix-render.log', 'final-kernel.log', 'final-precision.log',
                    'final-precision-boundary.swift-generate.log', 'ci-core-342.json', 'ci-native-36.json']
result = {
    'worker': 'W93-api', 'canonicalTask': '/root/wave10/w93_api', 'parent': '/root/wave10',
    'inputCommit': PIN, 'privateWorktree': str(TREE), 'cpuEvidenceSourceCommit': CPU_PIN,
    'scope': 'Source and retained-byte audit only. No fresh render, build, Swift test, native execution, or physical claim.',
    'commands': commands,
    'auditInvocation': ['python3', str(Path(__file__).resolve())],
    'auditScriptSHA256': sha(Path(__file__).read_bytes()),
    'inspectionReadCommands': ['sed -n <scoped ranges> <AGENTS/protocol/acceptance/source files>',
                               'rg -n <API and packing patterns> <scoped source files>',
                               'python3 - <<PY: inspect selected manifest and log fields; sha256 retained inputs'],
    'toolReadNotes': ['Two initial combined reads exceeded returned output budgets; targeted bounded reads recovered the needed fields. No subprocess error or missing evidence file occurred.'],
    'api': entry,
    'packing': {'parameterRows': 6, 'rowsPerSample': 3, 'rowsPerArea': 3, 'bytesPerRow': 16,
                'source': 'Sources/LightingCore/ReferenceStudy.swift', 'unchangedSince': CPU_PIN,
                'fixtureAlphaScope': 'Packed binary references use alpha 0 for unsupported magenta, 255 for supported pixels. This is separate from opaque StudyImage.rgba and the twelve final raw RGBA files.'},
    'sourceManifestComparison': sources, 'savedSceneAndArchiveSourceHashes': archive_sources,
    'fixtureGeneratorSHA256': generator_sha,
    'unchangedSourceRationale': 'All 31 portable-core hashes match the retained source manifest and git diff from db7 to the pinned HEAD is empty for the core, fixture generators and shared host harness. Preview/native changes are excluded from carrying CPU evidence forward.',
    'ordinarySyntheticImages': images, 'requiredHostParity': required_parity,
    'requiredPrecision': required_precision, 'supplementalPrecisionDiagnostics': supplemental,
    'supplementalScope': '25 additional generated records (9 tangent, 14 near-mask, 2 light-distance) are inventoried only; they are not the eight required precision gates and are not claimed to pass.',
    'evidenceReceipts': [file_receipt(EVIDENCE / p) for p in tracked_evidence],
    'latestRootOwnedCoreExecution': {'receipt': ci, 'rawLog': ci_log_receipt, 'executedByW93': False},
    'nativeBoundary': {'priorSource': prior_native['sourceCommit'], 'priorNativeTests': prior_native['nativeTests'],
                       'priorNativeFailures': prior_native['nativeFailures'], 'priorRawLog': prior_native_log,
                       'currentExpectedTests': 165, 'status': 'pending at assignment; latest core receipt records native queued',
                       'newHostedTest': new_test_name, 'newHostedTestSHA256': sha(adoption_source.read_bytes()),
                       'prior164DoesNotExecuteNewHostedTest': True, 'liveStatusCheckedByW93': False},
    'validation': {'assertionsPassed': len(checks), 'failedAssertions': 0, 'checks': checks,
                   'result': 'retained source/artifact correspondence verified', 'executionErrors': [],
                   'freshRuntimeTests': 0, 'tokenCountersAvailable': False},
    'limitations': ['Original raw RGBA and masks are absent. Do not infer original/final raw-mask byte equality from zero counts or identical PPM/PNG.',
                    'The final probe copied original scene bytes; equality verifies preservation, not an independent re-encoding.',
                    'Host shared-Float32 parity is not actual Metal execution; prior native evidence remains source-specific.',
                    'No visual rereview or new image generation was performed by W93; retained render evidence is carried forward only for unchanged CPU source.']
}
OUTPUT.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'output': str(OUTPUT), 'sha256': sha(OUTPUT.read_bytes()),
                  'assertionsPassed': len(checks), 'ordinaryImages': len(images),
                  'requiredParity': len(required_parity), 'requiredPrecision': len(required_precision),
                  'supplementalDiagnostics': len(supplemental), 'coreSourceHashesMatched': len(core_sources),
                  'expectedChangedManifestSources': changed_sources, 'errors': []}, indent=2))
