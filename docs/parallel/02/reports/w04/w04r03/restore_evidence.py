from pathlib import Path
import hashlib, json, subprocess
root = Path('/tmp/keyfill02-r2-workers/w04r03')
out = root / 'private-output'
lines = (out / 'probe.log').read_text().splitlines()
(out / 'scalars.tsv').write_text('\n'.join(x for x in lines if x and not x.startswith('SUMMARY')) + '\n')
production = '1b286885cb803ba17e159713651515ab119e17f1'
rebuild = '047803c0bff16137467e751263f1c11d8aa165aa'
source_path = 'Sources/LightingCore/SurfacePhotometry.swift'
source = subprocess.check_output(['git', 'show', f'{production}:{source_path}'], cwd=root)
rebuilt_source = subprocess.check_output(['git', 'show', f'{rebuild}:{source_path}'], cwd=root)
assert source == rebuilt_source == (root / source_path).read_bytes()
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
probe_sha = sha(out / 'probe.swift')
scalar_sha = sha(out / 'scalars.tsv')
assert probe_sha == 'd954d0cdfdb8ff80a7671bae9a2e9d5048b4f4f462fd99acf1717bebbe55d77b'
assert scalar_sha == 'e579166b635382e4d864757c77f00238e9fa0b3d6afb2b22b9cd744e9356e4b2'
provenance = {
  'executor': 'second',
  'purpose': 'Evidence-recovery followup for the same W04 R03 context; no extra role count',
  'initial_evidence_status': 'Initial execution passed, but /tmp artifacts were lost in executor reset; initial raw logs are unavailable',
  'raw_logs_origin': 'New actual Swift execution on second executor; not reconstructed logs',
  'production_input_sha': production,
  'snapshot': 'v1',
  'snapshot_rebuild_source_sha': rebuild,
  'root_verified_entire_sources_diff_empty': True,
  'surface_source_matches_production_rebuild_and_worker': True,
  'worker_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
  'surface_source_sha256': hashlib.sha256(source).hexdigest(),
  'probe_sha256': probe_sha,
  'scalar_sha256': scalar_sha,
  'probe_and_scalars_match_hashes_recorded_before_reset': True,
  'cases': 24, 'failures': 0,
}
(out / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
(out / 'commands.txt').write_text('python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r03 /tmp/keyfill02-r2-workers/w04r03/private-output/probe.swift v1\n/tmp/keyfill02-r2-toolchain/usr/bin/swiftc --version > private-output/environment.txt\npython3 private-output/restore_evidence.py\n')
report = '''# W04 R03 — exact rectangle separation boundary

**Second-executor evidence recovery, same context.** Initial execution passed; an executor reset erased its /tmp artifacts. These raw logs come from a genuine new execution of the recreated original probe, not reconstructed output. Probe and scalar SHA-256 values match those recorded before the reset.

**Provenance:** production `1b286885cb803ba17e159713651515ab119e17f1`; immutable `v1` rebuilt by root from `047803c0bff16137467e751263f1c11d8aa165aa`, Swift 6.0.3, x86_64 Linux. Root verified the complete Sources diff empty; this recovery independently confirms identical SurfacePhotometry source. Worker HEAD: `47de6afe6afe24a7822f4276950f70bd3db9f57d`.

**Exact commands:**
```sh
python3 /tmp/keyfill02-r2-probe.py /tmp/keyfill02-r2-workers/w04r03 /tmp/keyfill02-r2-workers/w04r03/private-output/probe.swift v1
/tmp/keyfill02-r2-toolchain/usr/bin/swiftc --version > private-output/environment.txt
python3 private-output/restore_evidence.py
```

**Result: PASS, 24/24; exit 0.** Centered 0.1 m and 1 m squares were tested at 0.05 m and 0.25 m separation boundaries and immediate floating-point neighbors, on both emitter-plane sides with both receiver-facing directions. Eight below-limit cases returned nil; twelve supported back-facing cases returned exact zero; four illuminated cases returned finite positive lux. Maximum analytic-reference error: **0.025708464%**, within the unchanged 5% area gate. The unchanged 1% point gate was not exercised. No defect found.

**Evidence:** probe.swift, compile.log, probe.log, scalars.tsv, environment.txt, provenance.json, commands.txt, restore_evidence.py.

**Limits:** unchanged fixed samples; no additional role, expanded checks, package build, production change, device measurement or calibration claim.
'''
(out / 'report.md').write_text(report)
print(json.dumps(provenance, indent=2))
print('report_words=' + str(len(report.split())))
print((out / 'environment.txt').read_text())
