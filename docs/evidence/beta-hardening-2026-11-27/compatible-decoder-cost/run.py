#!/usr/bin/env python3
"""A085 bounded matched full-decode comparison; no repository mutations."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import statistics
import subprocess
import time

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent / 'APP1'
REVISION = '135d3b4755d97bbb8fcff993d8dfd532a8d48b93'
NEW_HASH = 'f82fa22d3f3018919ddaea22c22de148268b1a3f1bff43d7232c2a58e90481ce'
SWIFTC = ROOT.parent / 'toolchains/swift-6.0.3/usr/bin/swiftc'
MAX_BYTES = 8 * 1024 * 1024

def sha(data):
    return hashlib.sha256(data).hexdigest()

def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')

for directory in ['sources', 'inputs', 'logs']:
    (ROOT / directory).mkdir(exist_ok=False)
hashes = {}
for source in sorted((REPO / 'Sources/LightingCore').glob('*.swift')):
    data = source.read_bytes()
    relative = source.relative_to(REPO).as_posix()
    if source.name == 'LightingProjectDocument.swift':
        assert sha(data) == NEW_HASH
    else:
        assert data == subprocess.check_output(['git', 'show', REVISION + ':' + relative], cwd=REPO)
    (ROOT / 'sources' / source.name).write_bytes(data)
    hashes[relative] = sha(data)
old = subprocess.check_output(['git', 'show', REVISION + ':Sources/LightingCore/LightingProjectDocument.swift'], cwd=REPO)
(ROOT / 'old-original.swift').write_bytes(old)
renamed = old.replace(b'LightingProjectDocument', b'OldProjectDocument')
(ROOT / 'sources/OldProjectDocument.swift').write_bytes(renamed)
write_json(ROOT / 'source-hashes.json', {'baseRevision': REVISION, 'currentProductionSources': hashes,
    'oldOriginalSHA256': sha(old), 'oldRenamedSHA256': sha(renamed),
    'adaptation': 'Only the old document type name is changed to permit both production implementations in one binary.'})

prefix = (b'{"schemaVersion":1,"name":"Benchmark","scene":'
          b'{"schemaVersion":4,"subject":{"x":0,"y":1.5,"z":0},'
          b'"camera":{"x":0,"y":1.5,"z":3},"lights":[],"metadata":')
suffix = b'}}'
ordinary = prefix + json.dumps('Éclairage 💡 測光 العربية', ensure_ascii=False).encode('utf-8') + suffix
budget = MAX_BYTES - len(prefix) - len(suffix)
unit = 'é'.encode('utf-8')
body = b'"' + unit * ((budget - 2) // len(unit)) + b'"'
large_unicode = prefix + body + b' ' * (budget - len(body)) + suffix
assert len(large_unicode) == MAX_BYTES
fixtures = []
for name, data in [('ordinary_unicode', ordinary), ('unicode_value_8mib', large_unicode)]:
    assert json.loads(data)['scene']['lights'] == []
    path = ROOT / 'inputs' / (name + '.json')
    path.write_bytes(data)
    fixtures.append({'id': name, 'path': str(path.relative_to(ROOT)), 'bytes': len(data), 'sha256': sha(data)})

generator = REPO / 'docs/evidence/beta-hardening-2026-11-27/reproduce-parser-benchmark/reconstruct_inputs.py'
spec = importlib.util.spec_from_file_location('frozen_input_generator', generator)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
before, after = module.load_manifests()
expected = next(f for f in before['fixtures'] if f['id'] == 'long_string_8mib')
for fixture_id, shape, data, *_ in module.generated_fixtures():
    if fixture_id == expected['id']:
        assert len(data) == expected['bytes'] and sha(data) == expected['sha256']
        path = ROOT / 'inputs' / 'ascii_value_8mib.json'
        path.write_bytes(data)
        fixtures.append({'id': 'ascii_value_8mib', 'path': str(path.relative_to(ROOT)), 'bytes': len(data),
                         'sha256': sha(data), 'originalFrozenFixture': fixture_id})
        break
assert len(fixtures) == 3
write_json(ROOT / 'fixtures.json', fixtures)

env = dict(os.environ)
env['PATH'] = str(SWIFTC.parent) + os.pathsep + env['PATH']
env['CLANG_MODULE_CACHE_PATH'] = str(ROOT.parent / 'cache/clang')
binary = ROOT / 'decode-probe'
command = [str(SWIFTC), '-O', '-whole-module-optimization', '-num-threads', '1',
           '-module-name', 'A085DecodeProbe', '-module-cache-path', env['CLANG_MODULE_CACHE_PATH'],
           *map(str, sorted((ROOT / 'sources').glob('*.swift'))), str(ROOT / 'main.swift'), '-o', str(binary)]
started = time.monotonic()
with (ROOT / 'logs/build.stdout').open('w') as stdout, (ROOT / 'logs/build.stderr').open('w') as stderr:
    result = subprocess.run(command, env=env, cwd=ROOT, stdout=stdout, stderr=stderr, timeout=240)
build = {'command': command, 'exitCode': result.returncode, 'wallSeconds': time.monotonic() - started,
         'swift': subprocess.check_output([str(SWIFTC), '--version'], text=True),
         'platform': platform.platform(), 'binarySHA256': sha(binary.read_bytes()) if result.returncode == 0 else None,
         'harnessSHA256': sha((ROOT / 'main.swift').read_bytes()), 'runnerSHA256': sha(Path(__file__).read_bytes()),
         'sourceHashManifestSHA256': sha((ROOT / 'source-hashes.json').read_bytes())}
write_json(ROOT / 'build.json', build)
print(json.dumps({'stage': 'build', **build}), flush=True)
if result.returncode:
    raise SystemExit(result.returncode)

records = []
with (ROOT / 'raw.jsonl').open('x') as raw:
    for sample in range(1, 4):
        variants = ['old', 'compatible'] if sample % 2 else ['compatible', 'old']
        for fixture in fixtures:
            path = ROOT / fixture['path']
            assert sha(path.read_bytes()) == fixture['sha256']
            small = fixture['id'] == 'ordinary_unicode'
            warmups, iterations = (10, 1000) if small else (1, 1)
            for variant in variants:
                cmd = [str(binary), variant, str(path), str(warmups), str(iterations)]
                start = time.monotonic_ns()
                result = subprocess.run(cmd, env=env, cwd=ROOT, text=True, capture_output=True, timeout=30)
                record = {'fixture': fixture['id'], 'sample': sample, 'command': cmd,
                          'exitCode': result.returncode, 'stderr': result.stderr,
                          'processWallNanoseconds': time.monotonic_ns() - start, 'loadAverage': os.getloadavg()}
                if result.returncode == 0:
                    record.update(json.loads(result.stdout))
                    assert record['checksum'] == (warmups + iterations) * 14
                    assert record['input_bytes'] == fixture['bytes']
                else:
                    record['stdout'] = result.stdout
                raw.write(json.dumps(record, sort_keys=True) + '\n'); raw.flush()
                records.append(record)
                print(json.dumps(record, sort_keys=True), flush=True)
                if result.returncode:
                    raise SystemExit(result.returncode)

summaries = []
for fixture in fixtures:
    row = dict(fixture)
    for variant in ['old', 'compatible']:
        samples = [r['nanoseconds_per_decode'] / 1e6 for r in records if r['fixture'] == fixture['id'] and r['variant'] == variant]
        assert len(samples) == 3
        row[variant] = {'rawMilliseconds': samples, 'medianMilliseconds': statistics.median(samples)}
    row['compatibleOverOld'] = row['compatible']['medianMilliseconds'] / row['old']['medianMilliseconds']
    row['deltaMilliseconds'] = row['compatible']['medianMilliseconds'] - row['old']['medianMilliseconds']
    summaries.append(row)
write_json(ROOT / 'summary.json', {'source': 'Current parser plus exact renamed135d parser, same optimized binary and host',
    'method': 'Full production decode. Three independent process samples per variant/fixture; alternate variant order. Input reads outside timer. One warmup plus one timed decode for8MiB; ten warmups and1000 timed decodes for ordinary Unicode. Every decode checks actual name, scene version, subject, camera and empty lights.',
    'results': summaries, 'rawSHA256': sha((ROOT / 'raw.jsonl').read_bytes()),
    'limits': 'Three samples do not establish statistical equivalence or tail latency. Linux Foundation timings are not Apple/device timings. Previous14.7x comparison is not rerun here.'})
print(json.dumps({'stage': 'complete', 'results': summaries}), flush=True)
print(json.dumps({'totalAdditionalBytes': sum(p.stat().st_size for p in ROOT.rglob('*') if p.is_file())}), flush=True)
