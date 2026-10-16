"""P4: legacy prototype smoke has a single automatic owner (nightly CI Full)."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
LEGACY_SUITES = ("test_battle_state", "test_deck_builder", "test_combat_ui", "test_turn_flow")


class LegacyCIProbeOwnershipTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fast = (WORKFLOWS / "ci-fast.yml").read_text(encoding="utf-8")
        cls.integration = (WORKFLOWS / "ci-integration.yml").read_text(encoding="utf-8")
        cls.p4 = (WORKFLOWS / "ci-p4-contracts.yml").read_text(encoding="utf-8")
        cls.full = (WORKFLOWS / "ci-full.yml").read_text(encoding="utf-8")
        cls.acceptance = (WORKFLOWS / "godot-m5-5-acceptance.yml").read_text(encoding="utf-8")

    def test_no_legacy_runner_in_fast_integration_or_p4(self):
        for name, source in (("Fast", self.fast), ("Integration", self.integration), ("P4", self.p4)):
            for suite in LEGACY_SUITES:
                self.assertNotIn("res://tests/" + suite + ".gd", source, name)
                self.assertNotIn("for suite in " + suite, source, name)
            self.assertNotIn("for suite in test_battle_state", source, name)
        self.assertIn("CI_INTEGRATION_REPORT suites=26 assertions=$actual failed=0", self.integration)

    def test_p4_still_runs_all_25_headless_contracts(self):
        specs = re.findall(r"'test_[^']+:[A-Z0-9_]+:[0-9]+'", self.p4)
        self.assertEqual(25, len(specs))
        self.assertIn("CI_P4_CONTRACTS_REPORT suites=25 assertions=1149 legacy=0 failed=0", self.p4)
        self.assertIn("test_p4_feedback_edges:P4_4_EDGE_REPORT:80", self.p4)
        self.assertIn("test_p4_v35_convergence:V35_CONVERGENCE_REPORT:25", self.p4)
        self.assertIn("assert_godot_logs.py", self.p4)

    def test_nightly_full_keeps_legacy_tests_and_100_seed_acceptance(self):
        self.assertIn("cron: '0 18 * * *'", self.full)
        self.assertIn("uses: ./.github/workflows/godot-m5-5-acceptance.yml", self.full)
        self.assertIn(
            "for script in test_battle_state test_deck_builder test_combat_ui test_turn_flow; do",
            self.acceptance,
        )
        for suite in LEGACY_SUITES:
            self.assertTrue((ROOT / "tests" / (suite + ".gd")).is_file(), suite)
        self.assertIn("M5_5_100_SEEDED_FULL_BATTLES_VERIFIED", self.acceptance)
        self.assertIn("assert_godot_logs.py", self.acceptance)


if __name__ == "__main__":
    unittest.main()
