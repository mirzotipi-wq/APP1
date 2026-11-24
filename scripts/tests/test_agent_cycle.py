"""Regression tests for gate provenance and fail-closed ledger validation."""
import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "agent_cycle.py"
SPEC = importlib.util.spec_from_file_location("agent_cycle", SCRIPT)
agent_cycle = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(agent_cycle)

OLD_REVISION = "a" * 40
NEW_REVISION = "b" * 40


def observation(gate, result="pass", revision=OLD_REVISION, **extra):
    return {
        "gate": gate, "result": result, "revision": revision,
        "date": "2026-11-24", "method": "Fixture test run",
        "environment": "Synthetic validator fixture, not product evidence",
        "artifact": "fixture.log", "reviewer": "Unit test fixture",
        "notes": "Validation test only; does not claim a product gate.", **extra,
    }


class AgentCycleTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for name in agent_cycle.REQUIRED:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("Synthetic contract fixture\n", encoding="utf-8")
        self.root_patch = patch.object(agent_cycle, "ROOT", self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)
        self.state = {
            "schema": 1,
            "milestones": [
                {"id": "M01", "name": "Foundation", "depends": [],
                 "gates": ["core_tests", "native_build", "persistence_smoke"], "status": "active"},
                {"id": "M02", "name": "Photometry", "depends": ["M01"],
                 "gates": ["photometry"], "status": "pending"},
            ],
        }
        self.evidence = {"schema": 1, "entries": [
            observation(gate) for gate in ["core_tests", "native_build", "persistence_smoke"]
        ]}

    def write(self, state=None, evidence=None):
        (self.root / "agents/state.json").write_text(
            json.dumps(self.state if state is None else state), encoding="utf-8")
        (self.root / "agents/evidence.json").write_text(
            json.dumps(self.evidence if evidence is None else evidence), encoding="utf-8")

    def validate(self):
        self.write()
        return agent_cycle.validate()

    def command(self, command):
        self.write()
        output, error = io.StringIO(), io.StringIO()
        with patch("sys.argv", [str(SCRIPT), command]), contextlib.redirect_stdout(output), contextlib.redirect_stderr(error):
            result = agent_cycle.main()
        return result, output.getvalue(), error.getvalue()

    def test_existing_entries_default_to_current_and_expose_selected_revision(self):
        _, _, latest = self.validate()
        self.assertEqual(latest["native_build"]["revision"], OLD_REVISION)
        self.assertEqual(agent_cycle.result_for(latest, "native_build"), "pass")
        self.assertEqual(agent_cycle.result_for(latest, "photometry"), "unverified")
        result, output, error = self.command("status")
        self.assertEqual(result, 0, error)
        self.assertIn(f"native_build: pass at {OLD_REVISION}", output)
        self.assertIn("photometry: unverified (no current observation)", output)
        self.assertIn("not proof of freshness or release readiness", output)

    def test_delayed_historical_pass_does_not_revoke_current_invalidation(self):
        self.evidence["entries"] += [
            observation("native_build", "unverified", NEW_REVISION),
            observation("native_build", "pass", OLD_REVISION, scope="historical"),
        ]
        _, _, latest = self.validate()
        self.assertEqual(latest["native_build"]["revision"], NEW_REVISION)
        self.assertEqual(agent_cycle.result_for(latest, "native_build"), "unverified")
        result, output, _ = self.command("next")
        self.assertEqual(result, 0)
        self.assertIn("Outstanding gates: native_build", output)
        self.state["milestones"][0]["status"] = "complete"
        with self.assertRaisesRegex(ValueError, "Completion lacks passing evidence"):
            self.validate()

    def test_historical_observation_alone_cannot_close_a_gate(self):
        self.evidence["entries"] = [
            dict(entry, scope="historical") for entry in self.evidence["entries"]
        ]
        _, _, latest = self.validate()
        self.assertEqual(latest, {})
        self.state["milestones"][0]["status"] = "complete"
        with self.assertRaisesRegex(ValueError, "Completion lacks passing evidence"):
            self.validate()

    def test_current_failure_and_unverified_each_revoke_a_pass(self):
        original = copy.deepcopy(self.evidence)
        for result in ("fail", "unverified"):
            with self.subTest(result=result):
                self.evidence = copy.deepcopy(original)
                self.evidence["entries"].append(observation("native_build", result, NEW_REVISION, scope="current"))
                _, _, latest = self.validate()
                self.assertEqual(agent_cycle.result_for(latest, "native_build"), result)
                self.state["milestones"][0]["status"] = "complete"
                with self.assertRaises(ValueError):
                    self.validate()
                self.state["milestones"][0]["status"] = "active"

    def test_historical_failure_does_not_override_current_pass(self):
        self.evidence["entries"].append(observation("native_build", "fail", scope="historical"))
        _, _, latest = self.validate()
        self.assertEqual(agent_cycle.result_for(latest, "native_build"), "pass")

    def test_complete_dependencies_require_gates_and_allow_different_tested_revisions(self):
        self.state["milestones"][0]["status"] = "complete"
        self.state["milestones"][1]["status"] = "complete"
        self.evidence["entries"].append(observation("photometry", revision=NEW_REVISION))
        _, _, latest = self.validate()
        self.assertNotEqual(latest["core_tests"]["revision"], latest["photometry"]["revision"])
        self.state["milestones"][0]["status"] = "active"
        with self.assertRaisesRegex(ValueError, "Unmet dependencies"):
            self.validate()

    def test_schema_requires_integer_one_and_object_documents(self):
        for document_name in ("state", "evidence"):
            baseline = copy.deepcopy(getattr(self, document_name))
            for invalid in (True, False, "1", 1.0, 2, None):
                with self.subTest(document=document_name, schema=invalid):
                    replacement = dict(baseline, schema=invalid)
                    self.write(**{document_name: replacement})
                    with self.assertRaises(ValueError):
                        agent_cycle.validate()
            for invalid in ([], "state", 1):
                with self.subTest(document=document_name, value=invalid):
                    self.write(**{document_name: invalid})
                    with self.assertRaises(ValueError):
                        agent_cycle.validate()

    def test_dates_require_real_calendar_day_and_full_iso_format(self):
        for invalid in ("not-a-date", "2026-02-29", "2026-02-30", "2026-13-01", "2026-1-01", "20261124", "2026-11-24T00:00:00Z", "0000-01-01"):
            with self.subTest(date=invalid):
                self.evidence["entries"][0]["date"] = invalid
                with self.assertRaises(ValueError):
                    self.validate()
        self.evidence["entries"][0]["date"] = "2024-02-29"
        self.validate()

    def test_missing_or_blank_milestone_name_fails_check_cleanly(self):
        for invalid in (None, "", "  ", [], 123):
            with self.subTest(name=invalid):
                self.state["milestones"][0]["name"] = invalid
                result, _, error = self.command("check")
                self.assertEqual(result, 1)
                self.assertIn("invalid name", error)
                self.assertNotIn("Traceback", error)
        del self.state["milestones"][0]["name"]
        with self.assertRaises(ValueError):
            self.validate()

    def test_collection_types_and_items_fail_closed(self):
        baseline = copy.deepcopy(self.state)
        for key in ("milestones",):
            for invalid in (None, {}, "M01", [], [None]):
                with self.subTest(key=key, value=invalid):
                    self.state = copy.deepcopy(baseline)
                    self.state[key] = invalid
                    with self.assertRaises(ValueError):
                        self.validate()
        for key in ("gates", "depends"):
            for invalid in (None, {}, "core_tests", [None], [" "], ["core_tests", "core_tests"]):
                with self.subTest(key=key, value=invalid):
                    self.state = copy.deepcopy(baseline)
                    self.state["milestones"][0][key] = invalid
                    with self.assertRaises(ValueError):
                        self.validate()
        self.state = baseline
        for invalid in (None, {}, "pass", [None], [[]]):
            with self.subTest(entries=invalid):
                self.evidence["entries"] = invalid
                with self.assertRaises(ValueError):
                    self.validate()

    def test_unknown_scopes_and_malformed_evidence_fields_are_rejected(self):
        baseline = copy.deepcopy(self.evidence["entries"][0])
        for invalid in ("archive", "", None, True, [], {}):
            with self.subTest(scope=invalid):
                self.evidence["entries"][0] = dict(baseline, scope=invalid)
                with self.assertRaises(ValueError):
                    self.validate()
        for key in ("gate", "revision", "date", "method", "environment", "artifact", "reviewer", "notes"):
            with self.subTest(field=key):
                self.evidence["entries"][0] = dict(baseline, **{key: []})
                with self.assertRaises(ValueError):
                    self.validate()
        self.evidence["entries"][0] = dict(baseline, result="queued")
        with self.assertRaises(ValueError):
            self.validate()

    def test_duplicate_and_forward_dependency_validation_remains_enforced(self):
        baseline = copy.deepcopy(self.state)
        mutations = [
            lambda state: state["milestones"][1].update(id="M01"),
            lambda state: state["milestones"][1].update(gates=["native_build"]),
            lambda state: state["milestones"][0].update(depends=["M02"]),
            lambda state: state["milestones"][1].update(depends=["missing"]),
        ]
        for mutation in mutations:
            self.state = copy.deepcopy(baseline)
            mutation(self.state)
            with self.assertRaises(ValueError):
                self.validate()

    def test_pass_requires_exact_commit_but_existing_failure_provenance_is_retained(self):
        self.evidence["entries"][0]["revision"] = "abcdef12"
        with self.assertRaisesRegex(ValueError, "exact tested commit"):
            self.validate()
        self.evidence["entries"][0]["result"] = "fail"
        _, _, latest = self.validate()
        self.assertEqual(latest["core_tests"]["revision"], "abcdef12")

    def test_required_contract_and_disclaimer_are_preserved(self):
        result, output, error = self.command("check")
        self.assertEqual(result, 0, error)
        self.assertIn("does NOT verify test truth or release readiness", output)
        (self.root / "docs/QUALITY.md").unlink()
        with self.assertRaisesRegex(ValueError, "Missing contract"):
            agent_cycle.validate()


if __name__ == "__main__":
    unittest.main()
