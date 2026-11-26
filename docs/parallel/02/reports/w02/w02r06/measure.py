#!/usr/bin/env python3
"""Bounded Linux wait4 measurement: helper once, resulting private binary once."""
from pathlib import Path
import json
import os
import platform
import time

work = Path('/tmp/keyfill02-workers/w02r06')
report = Path('/tmp/keyfill02/docs/parallel/02/reports/w02/w02r06')
commands = [
    ('compile_and_run', ['python3', '/tmp/keyfill02-probe.py', str(work), str(work / 'private-output/probe.swift')]),
    ('runtime_only', [str(work / 'private-output/probe')]),
]
measurements = {
    'source_sha': 'f75aa2758b4c14714e7517c4c0df4adb9f1a8b9b',
    'snapshot_configuration': 'debug; Swift6.0.3 per snapshot provenance',
    'host': platform.platform(),
    'method': 'os.wait4 Linux rusage; ru_maxrss in KiB; launch-to-reap wall via perf_counter_ns',
    'time_tool': '/usr/bin/time unavailable; no install attempted',
    'runs': [],
}
for label, command in commands:
    log = report / (label + '.log')
    start = time.perf_counter_ns()
    pid = os.fork()
    if pid == 0:
        fd = os.open(log, os.O_CREAT | os.O_TRUNC | os.O_WRONLY, 0o644)
        os.dup2(fd, 1)
        os.dup2(fd, 2)
        os.close(fd)
        os.execvp(command[0], command)
    _, status, usage = os.wait4(pid, 0)
    elapsed = time.perf_counter_ns() - start
    result = {
        'phase': label,
        'command': command,
        'exit_code': os.waitstatus_to_exitcode(status),
        'wall_ns': elapsed,
        'user_cpu_seconds': usage.ru_utime,
        'system_cpu_seconds': usage.ru_stime,
        'maxrss_kib': usage.ru_maxrss,
        'minor_faults': usage.ru_minflt,
        'major_faults': usage.ru_majflt,
        'voluntary_context_switches': usage.ru_nvcsw,
        'involuntary_context_switches': usage.ru_nivcsw,
        'log': str(log),
    }
    measurements['runs'].append(result)
    (report / 'measurements.json').write_text(json.dumps(measurements, indent=2) + '\n')
    print(json.dumps(result), flush=True)
    if result['exit_code'] != 0:
        raise SystemExit(result['exit_code'])
