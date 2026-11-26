#!/usr/bin/env python3
"""Read retained source/evidence; write only W96's accounting receipt. No tests/renders."""
import hashlib
import json
import os
import platform
from pathlib import Path
import subprocess
import sys
from datetime import datetime, timezone

ROOT = Path('/workspace/scratch/7f4be4bbb2d6/APP1-lane03')
PRIVATE = Path('/tmp/keyfill03-7f4b/workers/W96-resource')
LANE = ROOT / 'docs/parallel/03'
OUT = LANE / 'workers/wave10-evidence/W96-resource.json'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read(rel):
    return json.loads((LANE / rel).read_bytes())

def meta(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': sha(data)}

def run(args, cwd=PRIVATE):
    result = subprocess.run(args, cwd=cwd, text=True, capture_output=True)
    return {'argv': args, 'cwd': str(cwd), 'exit': result.returncode,
            'stdout': result.stdout, 'stderr': result.stderr}

now = datetime.now(timezone.utc).isoformat()
w86 = read('workers/wave09-evidence/W86-resource-bounds.json')
w76 = read('workers/wave08-evidence/W76-resource-checks.json')
source = {}
for rel, expected in w86['input_sha256'].items():
    actual = sha((PRIVATE / rel).read_bytes())
    durable = sha((ROOT / rel).read_bytes())
    source[rel] = {'sha256': actual, 'retained_W86_sha256': expected,
                   'matches_retained': actual == expected,
                   'matches_integration_source': actual == durable}
preview = 'App/ReferenceStudyPreview.swift'
source[preview] = {'sha256': sha((PRIVATE / preview).read_bytes()),
                   'matches_integration_source': (PRIVATE / preview).read_bytes() == (ROOT / preview).read_bytes()}
manifest = read('evidence/final-source-manifest.json')
core = {rel: expected for rel, expected in manifest['sourceSHA256'].items()
        if rel.startswith('Sources/LightingCore/')}
core_mismatches = [rel for rel, expected in core.items()
                   if sha((PRIVATE / rel).read_bytes()) != expected]

ledger_path = LANE / 'WORKER_LEDGER.json'
ledger_bytes = ledger_path.read_bytes()
ledger = json.loads(ledger_bytes)
inventory = []
for worker in ledger['workers']:
    rel = worker.get('primary_report')
    path = ROOT / rel if rel else None
    inventory.append({key: worker.get(key) for key in
                      ['worker', 'execution_status', 'primary_assignment_complete',
                       'primary_report', 'primary_report_exists', 'report_words',
                       'report_bytes', 'primary_report_sha256']})
    inventory[-1]['exists_at_W96_snapshot'] = bool(path and path.is_file())
    inventory[-1]['bytes_at_W96_snapshot'] = path.stat().st_size if path and path.is_file() else None

evidence_paths = [
    'workers/W26-resource.md', 'workers/wave02.json', 'workers/wave02-preservation.json',
    'workers/wave03.json', 'workers/wave04.json', 'workers/wave04-preservation.json',
    'workers/wave06.json', 'workers/wave06-evidence/W51-recovery.json',
    'workers/wave06-evidence/W55-recovery-preservation.json',
    'workers/wave06-evidence/W56-recovery-preservation.json', 'workers/wave07.json',
    'workers/wave08-evidence/W76-resource-checks.json',
    'workers/wave09-evidence/W86-resource-bounds.json',
    'evidence/current-source-manifest.json', 'evidence/final-source-manifest.json',
    'evidence/final-benchmark-inputs.json', 'evidence/runtime-interruption-four.json',
    'evidence/runtime-four-recovery.json', 'evidence/wave09-cleanup.json',
    'evidence/wave05-test-inputs.json', 'evidence/wave05-debug.log',
    'evidence/wave05-debug-retry.log', 'evidence/wave05-debug-serial.log',
    'evidence/wave05-release.log', 'evidence/wave05-debug-corrected.log',
    'evidence/wave05-release-serial.log', 'WORKER_PROTOCOL.md',
]
failed = read('evidence/wave05-test-inputs.json')
four = read('evidence/runtime-interruption-four.json')
recovery = read('evidence/runtime-four-recovery.json')
cleanup = read('evidence/wave09-cleanup.json')
report = LANE / 'workers/W96-resource.md'
storage = []
for path in [ROOT, PRIVATE]:
    stat = os.statvfs(path)
    storage.append({'path': str(path), 'total_bytes': stat.f_blocks * stat.f_frsize,
                    'free_bytes': stat.f_bfree * stat.f_frsize,
                    'available_bytes': stat.f_bavail * stat.f_frsize,
                    'meaning': 'Current filesystem capacity only; not historical pressure, process RSS or attributable cleanup savings.'})

result = {
    'worker': 'W96', 'canonical_task': '/root/wave10/w96_resource',
    'status': 'completed_source_and_retained_evidence_reconciliation',
    'recorded_utc': now, 'input_sha': '342e3280e3eb077d55e122c8bfb88b4062b431ed',
    'private_tree': str(PRIVATE), 'integration_repo': str(ROOT),
    'command': f'python3 {Path(__file__).resolve()}',
    'script': meta(Path(__file__).resolve()),
    'host': {'platform': platform.platform(), 'python': sys.version,
             'uname': run(['uname', '-a'])},
    'revision_and_status': [run(['git', 'rev-parse', 'HEAD']),
                            run(['git', 'rev-parse', 'HEAD^{tree}']),
                            run(['git', 'status', '--short']),
                            run(['git', 'rev-parse', 'HEAD'], ROOT)],
    'inspection_commands': [
        'cat AGENTS.md agents/OPERATING_PROTOCOL.md docs/acceptance/m02-m03-code.md docs/parallel/03/WORKER_PROTOCOL.md',
        'cat agents/HANDOFF.md agents/state.json docs/PRODUCT.md docs/ARCHITECTURE.md docs/ROADMAP.md docs/QUALITY.md docs/DESIGN.md',
        "rg -n -i 'interrupt|signal.?9|empty.?retry|compile.fail|runtime.reset|60%|token|budget|164.?KiB|5248|5,248' docs/parallel/03/HANDOFF.md docs/parallel/03/WORKER_LEDGER.json docs/parallel/03/workers/wave0*.json docs/parallel/03/workers/wave0*.md docs/parallel/03/evidence/*.json docs/parallel/03/workers/W56-resource.md docs/parallel/03/workers/W66-resource.md",
        "sed -n '74,108p' Sources/LightingCore/PortraitHeadMesh.swift",
        "sed -n '230,279p' Sources/LightingCore/PortraitHeadMesh.swift",
        "sed -n '479,503p' Sources/LightingCore/ReferenceStudy.swift",
        "sed -n '120,199p' App/MetalStudyRenderer.swift",
        "sed -n '231,253p' App/MetalStudyRenderer.swift",
        "sed -n '211,233p' App/ReferenceStudyPreview.swift",
        "sed -n '26,48p' Sources/LightingCore/Scene.swift",
    ],
    'source_hashes': source,
    'final_core_source_continuity': {'file_count': len(core), 'mismatches': core_mismatches,
                                    'meaning': 'Hash continuity only; no rerun or global acceptance.'},
    'bounds': {
        'mannequin': {'width_max': 144, 'height_max': 96, 'rgba_bytes': 55296, 'mask_bytes': 13824,
                      'admission': 'Direct API validates 24...144 and multiple of three; engine clamps high bust width to 144 before render.'},
        'rectangle_samples': {'interactive': 64, 'reference': 1024, 'validated_lights_max': 12,
                              'scene_interactive_max': 768, 'scene_reference_max': 12288},
        'fixed_mesh': {'triangles': 5248, 'cached_normal_area_scalar_bytes_each': 32,
                       'logical_added_scalar_bytes': 167936, 'logical_added_scalar_KiB': 164,
                       'scope': 'Cached geometricNormal and twiceArea scalar fields only, not entire mesh or actual Swift stride/allocation.'},
        'cancellation': {'maximum_further_pixel_evaluations_after_false_poll': 8,
                         'preview_debounce_nanoseconds': 80000000,
                         'elapsed_time_guarantee': False,
                         'qualification': 'Debounce is distinct. Validation and setup between polls are outside a wall-clock deadline; cancellation is cooperative.'},
        'engine_cache': {'completed_frames_max': 4, 'rgba_bytes_max': 262144, 'mask_bytes_max': 65536,
                         'cost_source': 'Actual Data.count charged by engine retain; independent nonnegative byte counters and count eviction.',
                         'exclusions': ['caller-retained frames', 'render scratch arrays', 'Data conversions', 'keys/metadata',
                                        'Swift capacity/alignment/allocator overhead', 'static geometry', 'Metal buffers']},
        'name_validation': 'Trim/count validation depends on Unicode and UTF-8 input size. <=80 Swift Characters is not a byte bound. Cache strips display names only after validation; owner01 retains this policy question.'
    },
    'retained_benchmark': {
        'source_commit': w76['benchmarkActualSourceCommit'], 'raw_revision_field': w76['benchmarkRawRevision'],
        'frames': 8, 'cancellation_probes': 12, 'visibility_workloads': 4,
        'measured_samples_per_timed_workload': 7, 'warmup_per_timed_workload': 1,
        'evidence': 'workers/wave08-evidence/W76-resource-checks.json and evidence/final-benchmark-inputs.json',
        'rerun_by_W96': False, 'scope': 'Retained optimized Linux host evidence only; no portable timing threshold or native/device inference.'
    },
    'interruption_accounting': {
        'campaign_reported_total': 4,
        'total_authority': 'workers/wave07.json runtime_interruptions and evidence/runtime-interruption-four.json event label',
        'independently_deduplicated_total': None,
        'caveat': 'Wave02, wave03, wave04, wave06 and fourth-upload narratives lack common event IDs. Preserve all records without equating narrative count to a unique reset census.',
        'narratives': {
            'wave02': read('workers/wave02.json')['interruption'],
            'wave03': read('workers/wave03.json')['recovery'],
            'wave04': read('workers/wave04.json')['storage_events'],
            'wave06': read('workers/wave06.json')['interruptions'],
            'fourth_upload': {'event': four['event'], 'publishedSource': four['publishedSource'],
                              'pending_path_count_at_interruption': len(four['pendingBlobs']),
                              'unique_pending_blob_count': len({item['sha'] for item in four['pendingBlobs']}),
                              'no_cleanup_of_pending_artifacts': four['noCleanupOfPendingArtifacts'],
                              'recovery': recovery}
        },
        'unrun_commands_do_not_pass': True,
        'reconstructed_inline_reports_not_claimed_original_file_recovery': True,
        'historical_private_paths_required_to_exist_now': False,
        'new_W96_executor_interruption_observed': False
    },
    'failed_compile_history': {
        'platform': failed['platform'], 'source_base': failed['base'],
        'attempts': failed['failedAttempts'],
        'empty_retry_bytes': (LANE / 'evidence/wave05-debug-retry.log').stat().st_size,
        'later_corrected_debug': failed['debug'], 'later_per_file_optimized_release': failed['release'],
        'qualification': 'Later outcomes remain separate. Signal 9 cause is not established as OOM; empty retry cause unknown; failed compilation did not run tests. Optimized per-file Release is not standard WMO/native acceptance.'
    },
    'cleanup': {'retained_receipt': cleanup,
                'interpretation': 'Root-only completed-tree cleanup after recorded remote preservation and 35 artifact hashes before each attempt. First attempt stopped at W84 after W81-W83 removal; candidate bytes verified against published aaa3f376 before continuation. W84 was a preserved dirty candidate, not a clean tree. No W96 cleanup or independent remote preservation probe.'},
    'worker_budget_snapshot': {
        'ledger_sha256': sha(ledger_bytes), 'ledger_bytes': len(ledger_bytes),
        'declared_counts': {key: ledger[key] for key in ['status', 'actual_contexts', 'unique_worker_numbers',
                            'unique_actual_runtime_ids', 'completed_primary_assignments', 'primary_reports_existing',
                            'root_counted', 'followups_counted', 'precreated_trees_counted', 'validation_errors']},
        'inventory': inventory,
        'normalization': ledger['normalization'],
        'active_slot_limit': 4, 'slots_include': ['root integrator', 'acceptance leader', 'at most two specialists'],
        'completion_scope': 'Time-scoped ledger inventory only. W91 owns final normalization after all actual reports finish; no 100-worker completion inferred here.',
        'exact_runtime_token_counters_available': False,
        'requested_targets': {'brief_tokens_max': 2000, 'working_tokens_target': 12000,
                              'checkpoint_fraction_target': 0.6, 'final_tokens_max': 800},
        'measured_target_compliance': None,
        'checkpoint': 'Qualitative checkpoint sent to coordinator; no measured 60% claim.',
        'report_sizes_meaning': 'Word/byte proxies only; cannot establish token usage or checkpoint fraction. Inventory uses normalized metadata and file stats, not a reread of all report contents.'
    },
    'current_storage_only': storage,
    'evidence_files': {rel: meta(LANE / rel) for rel in evidence_paths},
    'primary_report': {'path': str(report), **meta(report), 'words': len(report.read_text().split())},
    'execution_limits': ['No production/test/shared/GPU/cache/CI edits', 'No builds, tests, renders or benchmark reruns',
                         'No cleanup, commits, pushes or remote publication actions',
                         'No measured Swift allocation, RSS, FPS, thermal or physical-device claim',
                         'No global M02/M03 promotion, native acceptance or release assertion'],
}
OUT.write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps({'receipt': str(OUT), **meta(OUT), 'report': result['primary_report'],
                  'source_mismatches': [key for key, value in source.items() if value.get('matches_retained') is False or not value['matches_integration_source']],
                  'final_core_source_continuity': result['final_core_source_continuity'],
                  'ledger_snapshot': result['worker_budget_snapshot']['declared_counts'],
                  'current_storage_only': storage}, indent=2))
