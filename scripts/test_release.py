#!/usr/bin/env python3
"""Release safety checks. No compiler, signature, network call or package install runs."""
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().with_name("release.sh")


class ReleaseSafetyTests(unittest.TestCase):
    def run_script(self, *arguments):
        return subprocess.run(
            ["/bin/bash", str(SCRIPT), *arguments], text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10,
        )

    def test_help_has_no_side_effects(self):
        result = self.run_script("--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("preflight, build, sign, package, notarize, verify", result.stdout)

    def test_invalid_arguments_do_not_create_output(self):
        with tempfile.TemporaryDirectory(prefix="photosorter-release-check-") as tmp:
            output = Path(tmp) / "must-not-exist"
            cases = [
                ("build", "--version", "1.2;touch", "--arch", "arm64"),
                ("build", "--version", "1.2.3", "--arch", "invalid"),
                ("build", "--version", "1.2.3", "--arch", "arm64", "--unknown"),
                ("build", "--version"),
            ]
            for arguments in cases:
                with self.subTest(arguments=arguments):
                    result = self.run_script(*arguments, "--output", str(output))
                    self.assertNotEqual(result.returncode, 0)
                    self.assertFalse(output.exists(), result.stderr)

    def test_existing_candidate_is_never_overwritten(self):
        with tempfile.TemporaryDirectory(prefix="photosorter-release-check-") as tmp:
            release = Path(tmp) / "photos-sorter-cli-1.2.3-arm64"
            release.mkdir()
            marker = release / "retained.txt"
            marker.write_text("previous candidate")
            result = self.run_script("build", "--version", "1.2.3", "--arch", "arm64",
                                     "--output", tmp, "--allow-dirty")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("already exists", result.stderr)
            self.assertEqual(marker.read_text(), "previous candidate")
            self.assertEqual(list(release.iterdir()), [marker])

    def test_build_output_cannot_recurse_into_sources(self):
        output = SCRIPT.parent.parent / "Sources"
        release = output / "photos-sorter-cli-1.2.3-arm64"
        self.assertFalse(release.exists())
        result = self.run_script("build", "--version", "1.2.3", "--arch", "arm64",
                                 "--output", str(output), "--allow-dirty")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Output must be outside", result.stderr)
        self.assertFalse(release.exists())

    def test_signing_requires_an_existing_build(self):
        with tempfile.TemporaryDirectory(prefix="photosorter-release-check-") as tmp:
            result = self.run_script("sign", "--version", "1.2.3", "--arch", "arm64",
                                     "--output", tmp)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Build stage is missing", result.stderr)
            self.assertEqual(list(Path(tmp).iterdir()), [])

    def test_default_architecture_is_arm64(self):
        with tempfile.TemporaryDirectory(prefix="photosorter-release-check-") as tmp:
            result = self.run_script("sign", "--version", "1.2.3", "--output", tmp)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Build stage is missing", result.stderr)
            self.assertIn("photos-sorter-cli-1.2.3-arm64", result.stderr)
            self.assertEqual(list(Path(tmp).iterdir()), [])

    def test_verification_rejects_unnotarized_candidate(self):
        with tempfile.TemporaryDirectory(prefix="photosorter-release-check-") as tmp:
            release = Path(tmp) / "photos-sorter-cli-1.2.3-arm64"
            release.mkdir()
            (release / "version.txt").write_text("1.2.3\n")
            (release / "architecture.txt").write_text("arm64\n")
            result = self.run_script("verify", "--version", "1.2.3", "--arch", "arm64",
                                     "--output", tmp, "--team-id", "1234567890")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Run notarize and staple first", result.stderr)
            self.assertFalse((release / "SHA256SUMS").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
