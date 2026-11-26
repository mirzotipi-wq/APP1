#!/usr/bin/env python3
"""Real Linux subprocess cancellation with harmless temporary sleep fixtures.

No compiler, interposer, or project-library write is executed. The test runner
temporarily acts as a child subreaper so even a regression cannot strand its
fixture processes or zombies after assertion failure.
"""

import ctypes
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import textwrap
import time
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "run_atomic_library_write_probe.py"

HARNESS = textwrap.dedent("""\
    import importlib.util
    import inspect
    import json
    import os
    from pathlib import Path
    import signal
    import sys

    script, directory, mode, timeout, grace = sys.argv[1:]
    root = Path(directory)
    spec = importlib.util.spec_from_file_location("cancellation_wrapper", script)
    wrapper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(wrapper)
    signal.signal(signal.SIGINT, signal.default_int_handler)
    signal.signal(signal.SIGTERM, signal.SIG_DFL)

    if mode == "spawn-race":
        original_popen = wrapper.subprocess.Popen
        def cancel_before_registration(*args, **kwargs):
            child = original_popen(*args, **kwargs)
            temporary = root / "spawned.tmp"
            temporary.write_text(json.dumps({"pid": child.pid}))
            temporary.replace(root / "spawned.json")
            os.kill(os.getpid(), signal.SIGTERM)
            return child
        wrapper.subprocess.Popen = cancel_before_registration

    if mode == "timeout-race":
        lines, first_line = inspect.getsourcelines(wrapper.run_logged)
        cancellation_line = next(
            first_line + offset for offset, line in enumerate(lines)
            if line.strip() == 'observation["timedOut"] = True'
        )
        def cancel_before_timeout_cleanup(frame, event, _argument):
            if (event == "line" and frame.f_code is wrapper.run_logged.__code__
                    and frame.f_lineno == cancellation_line):
                sys.settrace(None)
                child = frame.f_locals["process"]
                os.kill(child.pid, 0)
                (root / "timeout-signal-injected.json").write_text(json.dumps({
                    "pid": child.pid,
                    "blockedSignals": sorted(signal.pthread_sigmask(signal.SIG_BLOCK, set())),
                }))
                os.kill(os.getpid(), signal.SIGTERM)
            return cancel_before_timeout_cleanup
        sys.settrace(cancel_before_timeout_cleanup)

    def run_fixture():
        receipt = wrapper.run_logged(
            [sys.executable, str(root / "fixture.py"), str(root), mode],
            root, root, "fixture", float(timeout),
            graceful_timeout_seconds=float(grace),
        )
        (root / "result.json").write_text(json.dumps(receipt))
        return 1 if receipt.get("timedOut") else receipt["returnCode"]

    wrapper.main = run_fixture
    sys.exit(wrapper.run_with_cancellation())
""")

FIXTURE = textwrap.dedent("""\
    import json
    import os
    from pathlib import Path
    import signal
    import subprocess
    import sys
    import time

    root, mode = Path(sys.argv[1]), sys.argv[2]
    leaf = None

    def publish(name, value):
        temporary = root / (name + ".tmp")
        temporary.write_text(json.dumps(value))
        temporary.replace(root / (name + ".json"))

    def terminate(number, _frame):
        publish("term-received", {"signal": number})
        if leaf is not None:
            leaf.kill()
            code = leaf.wait(timeout=2)
            publish("leaf-reaped", {"returnCode": code})
            # Leave a bounded window for a repeated cancellation of the wrapper.
            time.sleep(0.15)
            sys.exit(0)
        # The noncooperative fixture returns to its sleep until SIGKILL.

    if mode in ("graceful", "unresponsive"):
        signal.signal(signal.SIGTERM, terminate)
    if mode == "graceful":
        leaf = subprocess.Popen(
            [sys.executable, __file__, str(root), "leaf"], start_new_session=True,
        )
        deadline = time.monotonic() + 3
        while not (root / "leaf-ready.json").exists():
            if time.monotonic() >= deadline:
                leaf.kill()
                leaf.wait(timeout=2)
                raise RuntimeError("Fixture leaf did not become ready")
            time.sleep(0.005)
    publish("leaf-ready" if mode == "leaf" else "child-ready", {
        "pid": os.getpid(), "processGroup": os.getpgrp(),
        "blockedSignals": sorted(signal.pthread_sigmask(signal.SIG_BLOCK, set())),
    })
    time.sleep(30)
""")


@unittest.skipUnless(sys.platform.startswith("linux"), "Real process ownership checks require Linux subreaping")
class AtomicLibraryProbeCancellationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.libc = ctypes.CDLL(None, use_errno=True)
        cls.previous_subreaper = ctypes.c_int()
        if cls.libc.prctl(37, ctypes.byref(cls.previous_subreaper), 0, 0, 0) != 0:
            raise OSError(ctypes.get_errno(), "Cannot observe test subreaper state")
        if cls.libc.prctl(36, 1, 0, 0, 0) != 0:
            raise OSError(ctypes.get_errno(), "Cannot enable test fixture cleanup")

    @classmethod
    def tearDownClass(cls):
        if cls.libc.prctl(36, cls.previous_subreaper.value, 0, 0, 0) != 0:
            raise OSError(ctypes.get_errno(), "Cannot restore test subreaper state")

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="atomic cancellation regression ")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "harness.py").write_text(HARNESS)
        (self.root / "fixture.py").write_text(FIXTURE)
        self.process = None
        self.addCleanup(self.clean_fixture_processes)

    def start(self, mode="simple", timeout=10, grace=0):
        self.process = subprocess.Popen(
            [sys.executable, str(self.root / "harness.py"), str(SCRIPT), str(self.root),
             mode, str(timeout), str(grace)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, start_new_session=True,
            env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"),
        )

    def receipt(self, name, timeout=5):
        deadline = time.monotonic() + timeout
        path = self.root / (name + ".json")
        while time.monotonic() < deadline:
            if path.exists():
                return json.loads(path.read_text())
            if self.process.poll() is not None:
                stdout, stderr = self.process.communicate(timeout=1)
                self.fail(f"Wrapper exited before {name}: {self.process.returncode}\n{stdout!r}\n{stderr!r}")
            time.sleep(0.005)
        self.fail("Timed out waiting for fixture receipt: " + name)

    def assert_gone(self, pid):
        with self.assertRaises(ProcessLookupError, msg=f"Fixture process {pid} still exists after wrapper exit"):
            os.kill(pid, 0)

    def finish(self, expected_code):
        stdout, stderr = self.process.communicate(timeout=5)
        self.assertEqual(self.process.returncode, expected_code, (stdout, stderr))

    def clean_fixture_processes(self):
        if self.process is None:
            return
        pids = {self.process.pid}
        for name in ("spawned", "child-ready", "leaf-ready"):
            path = self.root / (name + ".json")
            if path.exists():
                pids.add(json.loads(path.read_text())["pid"])
        for pid in pids:
            try:
                os.killpg(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        self.process.communicate(timeout=3)
        # These are only known temporary fixtures adopted if their owner failed
        # to reap them. Never consume an unrelated child's wait status.
        deadline = time.monotonic() + 3
        for pid in pids - {self.process.pid}:
            while True:
                try:
                    waited, _ = os.waitpid(pid, os.WNOHANG)
                except ChildProcessError:
                    break
                if waited:
                    break
                if time.monotonic() >= deadline:
                    self.fail(f"Test cleanup could not reap owned fixture {pid}")
                time.sleep(0.005)

    def assert_child_signals_unblocked(self, child):
        self.assertFalse({signal.SIGTERM, signal.SIGINT} & set(child["blockedSignals"]))
        self.assertEqual(child["pid"], child["processGroup"])

    def test_sigterm_reaps_owned_child_and_preserves_signal_exit(self):
        self.start()
        child = self.receipt("child-ready")
        self.assert_child_signals_unblocked(child)
        self.process.send_signal(signal.SIGTERM)
        self.finish(-signal.SIGTERM)
        self.assert_gone(child["pid"])

    def test_sigint_reaps_owned_child_and_preserves_signal_exit(self):
        self.start()
        child = self.receipt("child-ready")
        self.process.send_signal(signal.SIGINT)
        self.finish(-signal.SIGINT)
        self.assert_gone(child["pid"])

    def test_sigterm_allows_driver_to_reap_separate_child_session(self):
        self.start(mode="graceful", grace=2)
        child = self.receipt("child-ready")
        leaf = self.receipt("leaf-ready")
        self.assert_child_signals_unblocked(child)
        self.assert_child_signals_unblocked(leaf)
        self.process.send_signal(signal.SIGTERM)
        self.assertEqual(self.receipt("term-received")["signal"], signal.SIGTERM)
        self.process.send_signal(signal.SIGINT)
        self.finish(-signal.SIGTERM)
        self.assertEqual(json.loads((self.root / "leaf-reaped.json").read_text())["returnCode"], -signal.SIGKILL)
        self.assert_gone(child["pid"])
        self.assert_gone(leaf["pid"])

    def test_signal_between_spawn_and_registration_does_not_orphan_child(self):
        self.start(mode="spawn-race")
        child = self.receipt("spawned")
        self.finish(-signal.SIGTERM)
        self.assert_gone(child["pid"])

    def test_sigterm_during_timeout_cleanup_cannot_interrupt_kill_and_reap(self):
        self.start(mode="unresponsive", timeout=0.5, grace=0.35)
        child = self.receipt("child-ready")
        self.receipt("term-received")
        self.process.send_signal(signal.SIGTERM)
        self.finish(-signal.SIGTERM)
        self.assert_gone(child["pid"])

    def test_sigterm_before_timeout_cleanup_reaps_owned_child(self):
        self.start(mode="timeout-race", timeout=0.5)
        child = self.receipt("child-ready")
        self.finish(-signal.SIGTERM)
        injected = json.loads((self.root / "timeout-signal-injected.json").read_text())
        self.assertEqual(injected["pid"], child["pid"])
        self.assertNotIn(signal.SIGTERM, injected["blockedSignals"])
        self.assert_gone(child["pid"])

    def test_timeout_retains_failure_receipt_and_reaps_unresponsive_child(self):
        self.start(mode="unresponsive", timeout=0.5, grace=0.1)
        child = self.receipt("child-ready")
        self.finish(1)
        result = json.loads((self.root / "result.json").read_text())
        self.assertTrue(result["timedOut"])
        self.assertTrue(result["gracefulTerminationExpired"])
        self.assertNotIn("returnCode", result)
        self.assertIn("SIGKILL", result["timeoutCleanup"])
        self.assert_gone(child["pid"])


if __name__ == "__main__":
    unittest.main()
