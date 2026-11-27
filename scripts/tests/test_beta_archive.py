"""Owner input, output preservation, and no-execution contract for archive plans."""

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import shlex
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "prepare_beta_archive.py"
SPEC = importlib.util.spec_from_file_location("prepare_beta_archive", SCRIPT)
beta_archive = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(beta_archive)


class BetaArchiveTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.root = self.directory / "source"
        self.root.mkdir()
        (self.root / "project.yml").write_text("name: KeyAndFill\n", encoding="utf-8")
        (self.root / "Package.swift").write_text("// local package fixture\n", encoding="utf-8")
        self.library = self.root / "protected-library.json"
        self.library.write_bytes(b"retained original library bytes\n")
        self.output = self.directory / "beta artifacts"
        self.values = {
            "bundle_id": "org.photographer.keyandfill", "team_id": "AB12CD34EF",
            "version": "0.1.0", "build_number": "3", "output": str(self.output),
        }
        replacement = patch.object(beta_archive, "ROOT", self.root)
        replacement.start()
        self.addCleanup(replacement.stop)

    def arguments(self, **changes):
        values = {**self.values, **changes}
        return [argument for key, value in values.items()
                for argument in ("--" + key.replace("_", "-"), value)]

    def test_plan_preserves_local_package_root_and_isolates_archive_outputs(self):
        plan = beta_archive.create_plan(**self.values)
        self.assertEqual(plan["mode"], "dry-run")
        self.assertFalse(plan["execution_supported"])
        self.assertEqual(plan["commands_require_host"], "Darwin")
        self.assertEqual(plan["archive_kind"], "unsigned-iphoneos")
        self.assertEqual(plan["owner_inputs"]["team_id"], self.values["team_id"])
        commands = [item["argv"] for item in plan["commands"]]
        self.assertEqual([argv[0] for argv in commands], ["mkdir", "xcodegen", "xcodebuild"])
        generation, archive = commands[1:]
        self.assertEqual(generation[generation.index("--project") + 1], str(self.root))
        self.assertEqual(generation[generation.index("--project-root") + 1], str(self.root))
        self.assertEqual(plan["generated_project_path"], str(self.root / "KeyAndFill.xcodeproj"))
        self.assertEqual(archive[archive.index("-project") + 1], plan["generated_project_path"])
        for argument in ("PRODUCT_BUNDLE_IDENTIFIER=org.photographer.keyandfill", "DEVELOPMENT_TEAM=AB12CD34EF",
                         "MARKETING_VERSION=0.1.0", "CURRENT_PROJECT_VERSION=3", "CODE_SIGNING_ALLOWED=NO",
                         "CODE_SIGNING_REQUIRED=NO", "CODE_SIGN_IDENTITY=", "-disableAutomaticPackageResolution",
                         "-skipPackageUpdates", "generic/platform=iOS", "iphoneos", "archive"):
            self.assertIn(argument, archive)
        for flag in ("-archivePath", "-derivedDataPath", "-resultBundlePath"):
            self.assertIn(self.output, Path(archive[archive.index(flag) + 1]).parents)
        self.assertFalse(any("Provisioning" in arg or "exportArchive" in arg or "upload" in arg
                             or "KEYFILL_PRO_PRODUCT_ID" in arg for argv in commands for arg in argv))

    def test_all_owner_values_are_required_without_environment_fallback(self):
        for missing in self.values:
            with self.subTest(missing=missing):
                arguments = self.arguments()
                index = arguments.index("--" + missing.replace("_", "-"))
                del arguments[index:index + 2]
                with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as raised:
                    beta_archive.main(arguments)
                self.assertEqual(raised.exception.code, 2)

    def test_placeholder_or_invalid_bundle_ids_are_rejected(self):
        for value in ("com.example", "com.example.keyandfill", "COM.Example.keyandfill", "org.example.app",
                      "app", "com..app", ".org.photo.app", "org.photo.app.", "org.photo.*", "org.photo_app",
                      "org.-photo.app", "org.photo-.app", "org." + "a" * 64, "a." * 128 + "b"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                beta_archive.create_plan(**{**self.values, "bundle_id": value})

    def test_invalid_team_version_and_build_are_rejected(self):
        invalid = {
            "team_id": ("", "AB12CD34E", "AB12CD34EFG", "ab12cd34ef", "AB12_CD34E", "ＡB12CD34EF"),
            "version": ("", "1", "1.2", "1.2.3.4", "01.2.3", "1.02.3", "1.2.03", "1.2.3-beta", "10000.0.1"),
            "build_number": ("", "0", "-1", "01", "1.2", "10000", "1e2", "１"),
        }
        for field, values in invalid.items():
            for value in values:
                with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                    beta_archive.create_plan(**{**self.values, field: value})

    def test_scalar_injection_is_rejected_before_printing_a_plan(self):
        for field in self.values:
            for suffix in ("\nCODE_SIGNING_ALLOWED=YES", "\r", "\t", "\x00", "\u2028", ";touch /tmp/marker",
                           "$(inherited)", "`id`", " CODE_SIGN_STYLE=Automatic"):
                with self.subTest(field=field, suffix=repr(suffix)):
                    stdout = io.StringIO()
                    with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(io.StringIO()):
                        with self.assertRaises(SystemExit) as raised:
                            beta_archive.main(self.arguments(**{field: self.values[field] + suffix}))
                    self.assertEqual(raised.exception.code, 2)
                    self.assertEqual(stdout.getvalue(), "")
        self.assertFalse(self.output.exists())

    def test_existing_file_directory_and_dangling_symlink_are_preserved(self):
        for kind in ("file", "directory", "symlink"):
            with self.subTest(kind=kind):
                path = self.directory / kind
                if kind == "file":
                    path.write_bytes(b"keep archive")
                elif kind == "directory":
                    path.mkdir()
                    (path / "original").write_bytes(b"keep archive")
                else:
                    path.symlink_to(self.directory / "absent")
                with self.assertRaisesRegex(ValueError, "already exists"):
                    beta_archive.create_plan(**{**self.values, "output": str(path)})
                if kind == "symlink":
                    self.assertTrue(path.is_symlink())
                else:
                    self.assertEqual((path if kind == "file" else path / "original").read_bytes(), b"keep archive")

    def test_invalid_output_parent_and_paths_are_rejected(self):
        for value in ("relative/output", str(self.directory / "missing" / "output"),
                      str(self.directory) + "/../output", str(self.root / "artifacts"),
                      str(self.directory / ("a" * 256)), "/" + "a" * 1024):
            with self.subTest(value=value), self.assertRaises((ValueError, OSError)):
                beta_archive.create_plan(**{**self.values, "output": value})
        with patch.object(beta_archive, "MAX_INPUT_PATH", len(str(self.output / "KeyAndFill.xcarchive")) - 1):
            with self.assertRaisesRegex(ValueError, "paths must"):
                beta_archive.create_plan(**self.values)

    def test_existing_generated_project_is_never_overwritten(self):
        project = self.root / "KeyAndFill.xcodeproj"
        project.mkdir()
        original = project / "project.pbxproj"
        original.write_bytes(b"preserved generated project")
        with self.assertRaisesRegex(ValueError, "generated project already exists"):
            beta_archive.create_plan(**self.values)
        self.assertEqual(original.read_bytes(), b"preserved generated project")
        original.unlink()
        project.rmdir()
        project.symlink_to(self.directory / "absent-project")
        with self.assertRaisesRegex(ValueError, "generated project already exists"):
            beta_archive.create_plan(**self.values)
        self.assertTrue(project.is_symlink())

    def test_symlink_parent_cannot_redirect_output_into_source(self):
        link = self.directory / "link"
        link.symlink_to(self.root, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "outside the source"):
            beta_archive.create_plan(**{**self.values, "output": str(link / "artifact")})

    def test_missing_symlinked_and_oversized_specs_fail_closed(self):
        spec = self.root / "project.yml"
        spec.unlink()
        with self.assertRaisesRegex(ValueError, "regular file"):
            beta_archive.create_plan(**self.values)
        spec.symlink_to(self.library)
        with self.assertRaisesRegex(ValueError, "regular file"):
            beta_archive.create_plan(**self.values)
        spec.unlink()
        spec.write_bytes(b"a" * (beta_archive.MAX_SPEC_BYTES + 1))
        with self.assertRaisesRegex(ValueError, "exceeds"):
            beta_archive.create_plan(**self.values)

    def test_dry_run_on_linux_and_macos_never_executes_or_writes(self):
        before = {str(path.relative_to(self.directory)): path.read_bytes()
                  for path in self.directory.rglob("*") if path.is_file()}
        for host in ("Linux", "Darwin"):
            for mode in ([], ["--dry-run"]):
                with self.subTest(host=host, mode=mode), patch.object(beta_archive.platform, "system", return_value=host):
                    stdout = io.StringIO()
                    with patch("subprocess.run") as run, patch("subprocess.Popen") as popen, patch("os.system") as system:
                        with contextlib.redirect_stdout(stdout):
                            self.assertEqual(beta_archive.main(self.arguments() + mode + ["--json"]), 0)
                        run.assert_not_called()
                        popen.assert_not_called()
                        system.assert_not_called()
                    plan = json.loads(stdout.getvalue())
                    self.assertEqual(plan["host"], host)
                    self.assertEqual(plan["mode"], "dry-run")
        after = {str(path.relative_to(self.directory)): path.read_bytes()
                 for path in self.directory.rglob("*") if path.is_file()}
        self.assertEqual(before, after)
        self.assertFalse(self.output.exists())

    def test_execute_and_unrecognized_options_are_rejected_on_linux(self):
        for option in ("--execute", "--upload", "--allowProvisioningUpdates", "--team"):
            with self.subTest(option=option), patch.object(beta_archive.platform, "system", return_value="Linux"):
                with patch("subprocess.run") as run, patch("subprocess.Popen") as popen:
                    with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as raised:
                        beta_archive.main(self.arguments() + [option])
                    self.assertEqual(raised.exception.code, 2)
                    run.assert_not_called()
                    popen.assert_not_called()
        self.assertFalse(self.output.exists())

    def test_human_command_rendering_round_trips_spaces_and_apostrophes(self):
        self.values["output"] = str(self.directory / "photographer's beta")
        plan = beta_archive.create_plan(**self.values)
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            self.assertEqual(beta_archive.main(self.arguments()), 0)
        for command in plan["commands"]:
            rendered = shlex.join(command["argv"])
            self.assertIn(rendered, stdout.getvalue())
            self.assertEqual(shlex.split(rendered), command["argv"])


if __name__ == "__main__":
    unittest.main()
