"""Infrastructure oracles, not gameplay or GUI acceptance tests."""
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from tools.ci.assert_godot_logs import inspect_text, read_log


class LogGateTests(unittest.TestCase):
    def test_positive_summary(self):
        result = inspect_text("PASS case\nM1_TEST_REPORT executed=30 passed=30 failed=0 skipped=0\n")
        self.assertEqual(result["errors"], [])
        self.assertEqual(result["summaries"], 1)

    def test_script_error_even_with_pass(self):
        result = inspect_text("SCRIPT ERROR: crash\nX_REPORT executed=1 passed=1 failed=0\n")
        self.assertTrue(result["errors"])

    def test_engine_error(self):
        self.assertTrue(inspect_text("ERROR: missing texture\n")["errors"])

    def test_failed_assertion(self):
        self.assertTrue(inspect_text("FAIL CASE-01\n")["errors"])

    def test_parse_error(self):
        self.assertTrue(inspect_text("Parse Error: invalid declaration\n")["errors"])

    def test_ansi_wrapped_error(self):
        self.assertTrue(inspect_text("\x1b[31mSCRIPT ERROR: crash\x1b[0m\n")["errors"])

    def test_failed_count(self):
        self.assertTrue(inspect_text("X_REPORT executed=2 passed=1 failed=1\n")["errors"])

    def test_inconsistent_count(self):
        self.assertTrue(inspect_text("X_REPORT executed=4 passed=3 failed=0\n")["errors"])

    def test_zero_tests_not_success(self):
        self.assertTrue(inspect_text("X_REPORT executed=0 passed=0 failed=0\n")["errors"])

    def test_duplicate_summary(self):
        line = "X_REPORT executed=1 passed=1 failed=0\n"
        self.assertTrue(inspect_text(line + line)["errors"])

    def test_seed_records_not_assertion_summary(self):
        self.assertEqual(inspect_text("M5_5_SEED_REPORT seed=42 accepted=49\n")["summaries"], 0)

    def test_warnings_visible_not_silently_dropped(self):
        result = inspect_text("WARNING: ObjectDB instances leaked at exit\n")
        self.assertEqual(result["errors"], [])
        self.assertEqual(len(result["warnings"]), 1)

    def test_probe_not_normal_pass_log(self):
        self.assertTrue(inspect_text("G0_PROBE_EXPECTED_FAILURE: deliberate exit17\n")["errors"])

    def test_version_log_has_no_required_summary(self):
        self.assertEqual(inspect_text("4.7.2.stable.official.ed1daf0bf\n")["errors"], [])

    def test_utf8_and_utf16_bom(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "sample.log"
            for encoding in ("utf-8-sig", "utf-16"):
                path.write_text("PASS 繁體中文\n", encoding=encoding)
                self.assertIn("繁體中文", read_log(path))

    def test_invalid_encoding_fails(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "sample.log"
            path.write_bytes(b"\xff\x80bad")
            with self.assertRaises(UnicodeDecodeError):
                read_log(path)

    def test_cli_missing_file_nonzero(self):
        with tempfile.TemporaryDirectory() as folder:
            result = self.run_cli(Path(folder) / "missing.log")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("CI_LOG_GATE", result.stdout)

    def test_cli_error_nonzero_despite_pass_marker(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "bad.log"
            path.write_text("X_REPORT executed=1 passed=1 failed=0\nERROR: failure\n", encoding="utf-8")
            self.assertNotEqual(self.run_cli(path).returncode, 0)

    def test_cli_clean_success(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "good.log"
            path.write_text("X_REPORT executed=1 passed=1 failed=0\n", encoding="utf-8")
            self.assertEqual(self.run_cli(path).returncode, 0)

    @staticmethod
    def run_cli(path):
        return subprocess.run(
            [sys.executable, "tools/ci/assert_godot_logs.py", str(path)],
            capture_output=True, text=True, timeout=10,
        )


if __name__ == "__main__":
    unittest.main()
