"""Bounded source-level startup-budget probe; never invokes Apple tools."""
import contextlib
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import time
from unittest import mock

ROOT = Path('/workspace/scratch/b25ffdc7aed8/APP1')
OUT = Path(__file__).parent
spec = importlib.util.spec_from_file_location('test_boot', ROOT / 'scripts/tests/test_boot_simulator.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
results = []
for index in range(1, 3):
    test = module.BootSimulatorTests()
    original = test.run_case
    captured = {}
    def wrapped(*args, **kwargs):
        def preserve(root, report):
            destination = OUT / f'baseline-{index}'
            shutil.copytree(root / 'evidence', destination)
            shutil.copy2(root / 'calls.jsonl', destination / 'calls.jsonl')
        kwargs['before_cleanup'] = preserve
        value = original(*args, **kwargs)
        captured.update(report=value[1], outerElapsedSeconds=value[4])
        return value
    test.run_case = wrapped
    try:
        test.test_two_postflight_timeouts_exhaust_same_budget_after_one_recovery()
        status = 'passed'
        failure = None
    except AssertionError as error:
        status = 'failed'
        failure = str(error)
    report = captured['report']
    results.append({'kind': 'unchanged exact test method', 'index': index, 'status': status,
                    'failure': failure, 'reportElapsedSeconds': report['elapsedSeconds'],
                    'outerElapsedSeconds': captured['outerElapsedSeconds'],
                    'lastCommandFinishedSeconds': report['commands'][-1]['finishedElapsedSeconds'],
                    'commandDeadlines': [c['deadlineElapsedSeconds'] for c in report['commands']],
                    'directChildrenReaped': all(c.get('cleanup', {}).get('directChildReaped') is True
                                               for c in report['commands'])})

boot = module.BOOT
with tempfile.TemporaryDirectory(prefix='a078-report-delay-') as temporary:
    root = Path(temporary)
    tool = root / 'xcrun'
    tool.write_text(module.SYNTHETIC_XCRUN)
    tool.chmod(0o755)
    scenario = {'udid': module.UDID, 'runtime': module.RUNTIME, 'device_type': module.DEVICE_TYPE,
                'list': [{}, {'sleep': 60}, {}, {}, {'sleep': 60}]}
    (root / 'scenario.json').write_text(json.dumps(scenario))
    environment = {'KEYFILL_STARTUP_TEST_DIRECTORY': str(root),
                   'PATH': str(root) + os.pathsep + os.environ['PATH'],
                   'GITHUB_ACTIONS': 'true', 'RUNNER_ENVIRONMENT': 'github-hosted'}
    real_write_json = boot.write_json
    injections = []
    def delayed_write_json(path, value):
        if path.name.endswith('attempt-2-postflight.result.json'):
            assert value['status'] == 'timed_out'
            assert value['cleanup']['directChildReaped'] is True
            injections.append({'delaySeconds': 0.65, 'where': str(path.name),
                               'childReapedBeforeInjection': True,
                               'recordedCommandFinishedSeconds': value['finishedElapsedSeconds']})
            time.sleep(0.65)
        real_write_json(path, value)
    stdout, stderr = io.StringIO(), io.StringIO()
    with mock.patch.dict(os.environ, environment), mock.patch.object(boot, 'write_json', delayed_write_json), \
            contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
        started = time.monotonic()
        exit_code = boot.main(['--udid', module.UDID, '--runtime', module.RUNTIME,
                              '--device-type', module.DEVICE_TYPE, '--output', str(root / 'evidence'),
                              '--timeout-seconds=3'])
        outer_elapsed = time.monotonic() - started
    report = json.loads((root / 'evidence/report.json').read_text())
    shutil.copytree(root / 'evidence', OUT / 'injected-report-delay')
    (OUT / 'injected-report-delay/stdout.log').write_text(stdout.getvalue())
    (OUT / 'injected-report-delay/stderr.log').write_text(stderr.getvalue())
    shutil.copy2(root / 'calls.jsonl', OUT / 'injected-report-delay/calls.jsonl')
    assert len(injections) == 1
    assert exit_code == 1
    assert all(c['deadlineElapsedSeconds'] <= 2.700001 for c in report['commands'])
    assert report['commands'][-1]['cleanup']['directChildReaped'] is True
    assert report['elapsedSeconds'] > 3.15
    results.append({'kind': 'explicitly injected post-child-cleanup report delay',
                    'notObservedCICause': True, 'injections': injections, 'exitCode': exit_code,
                    'reportElapsedSeconds': report['elapsedSeconds'], 'outerElapsedSeconds': outer_elapsed,
                    'lastCommandFinishedSeconds': report['commands'][-1]['finishedElapsedSeconds'],
                    'commandDeadlines': [c['deadlineElapsedSeconds'] for c in report['commands']],
                    'directChildrenReaped': all(c.get('cleanup', {}).get('directChildReaped') is True
                                               for c in report['commands'])})

receipt = {'sourceRevision': '135d3b4755d97bbb8fcff993d8dfd532a8d48b93',
           'sourceHashes': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                            for p in [ROOT/'scripts/boot_simulator.py', ROOT/'scripts/tests/test_boot_simulator.py']},
           'CIObservation': {'run': 46030746634, 'job': 140613601950,
                             'reportedElapsedSeconds': 3.4117361060000064,
                             'failedAssertion': 'report.elapsedSeconds < 3.15',
                             'precedingOuterElapsedAssertionPassed': '< 3.5 seconds',
                             'rawCommandReceiptsUnavailable': True},
           'budgetSemantics': {'fixtureTotalSeconds': 3, 'fixtureCleanupReserveSeconds': 0.3,
                               'fixtureWorkDeadlineSeconds': 2.7, 'fixtureFirstAttemptDeadlineSeconds': 1.35,
                               'productionTotalSeconds': 580, 'maximumAcceptedSeconds': 600,
                               'productionCleanupReserveSeconds': 5},
           'runs': results,
           'limitations': ['No Apple simulator started; synthetic xcrun only.',
                           'Injected delay demonstrates a possible reporting-time mechanism, not the actual GitHub runner cause.',
                           'CI raw child/command timing receipts were not retained by the failing unit-test temporary directory.',
                           'No repository changes, threshold changes, CI reruns or gate acceptance.']}
(OUT/'receipt.json').write_text(json.dumps(receipt, indent=2)+'\n')
print(json.dumps(results, indent=2))
