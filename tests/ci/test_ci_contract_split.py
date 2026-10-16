"""Regression checks for P4 CI split; uses only Python stdlib."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class CIContractSplitTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fast = (ROOT / ".github/workflows/ci-fast.yml").read_text()
        cls.p4 = (ROOT / ".github/workflows/ci-p4-contracts.yml").read_text()

    def test_fast_is_one_job_and_keeps_critical_smoke(self):
        self.assertIn("\n  fast:\n", self.fast)
        self.assertNotIn("\n  p4-contracts:\n", self.fast)
        for marker in (
            "test_m5_fast_seeds:M5_5_FAST_SEEDS_REPORT:5",
            "test_m5_integration:M5_5_INTEGRATION_REPORT:32",
            "test_p4_hud:P4_2_REPORT:36",
            "test_p4_lv40_playable:P4_LV40_PLAYABLE_REPORT:32",
        ):
            self.assertIn(marker, self.fast)

    def test_all_25_p4_contracts_retained_with_same_oracles(self):
        self.assertIn("\n  p4-contracts:\n", self.p4)
        self.assertIn("CI_P4_CONTRACTS_REPORT suites=25 assertions=1149 legacy=4 failed=0", self.p4)
        self.assertIn("test_p4_v35_convergence:V35_CONVERGENCE_REPORT:25", self.p4)
        self.assertIn("test_p4_feedback_edges:P4_4_EDGE_REPORT:80", self.p4)
        self.assertIn("test_p4_localization:P4_LOCALIZATION_REPORT:198", self.p4)
        for legacy in ("test_battle_state", "test_deck_builder", "test_combat_ui", "test_turn_flow"):
            self.assertIn(legacy, self.p4)
        self.assertIn("assert_godot_logs.py", self.p4)
        self.assertIn("GUI_NOT_VERIFIED", self.p4)

    def test_triggers_guard_existing_gui_run_restrictions(self):
        self.assertIn("branches: [master, 'ci/**', 'integration/**', 'handoff/**', 'ui/**']", self.p4)
        self.assertIn("'scripts/battle/**'", self.p4)
        self.assertIn("'scenes/battle/**'", self.p4)
        self.assertIn("'tests/test_p4_*.gd'", self.p4)
        self.assertIn("schedule:", self.p4)
        self.assertIn("workflow_dispatch:", self.p4)
        self.assertIn("github.sha == '81f3d941ae033f9c6523c8fdb2e7049e4cf023d4'", self.p4)
        self.assertIn("GUI_NOT_VERIFIED", self.p4)


if __name__ == "__main__":
    unittest.main()
