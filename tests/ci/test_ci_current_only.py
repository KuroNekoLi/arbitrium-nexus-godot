"""Current combat CI safety net: legacy eight-card runtime must never return.

The historical M1–M5 Domain engine and the present UI roster widget are
*current code* despite historical phase or component names.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
RETIRED_TESTS = ("test_battle_state", "test_deck_builder", "test_combat_ui", "test_turn_flow")


class CurrentCombatOnlyTests(unittest.TestCase):
    def test_superseded_phase_and_duplicate_headless_workflows_stay_removed(self):
        removed = (
            "godot-m1-domain", "godot-m2-cards", "godot-m2-domain",
            "godot-m2-free-swap", "godot-m2-resources", "godot-m3-1-phase",
            "godot-m3-2-reactions", "godot-m3-3-guard-protect",
            "godot-m3-4-ui-modes", "godot-m3-5-integration",
            "godot-m4-1-dual-cast", "godot-m4-2-disruption",
            "godot-m4-3-last-spell", "godot-m4-4-invalidation",
            "godot-m4-5-acceptance", "godot-m5-1-damage",
            "godot-m5-2-status", "godot-m5-3-boss-combo",
            "godot-m5-4-outcome", "godot-p4-reviewed-headless",
            "godot-p4-reviewed-presentation", "godot-v2-4-hand-headless",
            "godot-v3-1-visual", "godot-v3-2-card",
            "godot-v3-3-boss-intent", "godot-v3-4-roster-command",
        )
        for name in removed:
            self.assertFalse((WORKFLOWS / (name + ".yml")).exists(), name)

    def test_eight_card_compatibility_shims_are_deleted(self):
        for name in RETIRED_TESTS:
            self.assertFalse((ROOT / "tests" / (name + ".gd")).exists(), name)
            self.assertFalse((ROOT / "tests" / (name + ".gd.uid")).exists(), name)
        self.assertFalse((WORKFLOWS / "godot-g0-legacy-baseline.yml").exists())

    def test_no_workflow_invokes_deleted_tests(self):
        for workflow in WORKFLOWS.glob("*.yml"):
            body = workflow.read_text(encoding="utf-8")
            for name in RETIRED_TESTS:
                self.assertNotIn(name, body, workflow.name)
        self.assertTrue((WORKFLOWS / "ci-integration.yml").is_file())
        self.assertTrue((WORKFLOWS / "godot-m5-5-acceptance.yml").is_file())

    def test_full_keeps_current_engine_stress_and_replay(self):
        full = (WORKFLOWS / "ci-full.yml").read_text(encoding="utf-8")
        acceptance = (WORKFLOWS / "godot-m5-5-acceptance.yml").read_text(encoding="utf-8")
        self.assertIn("uses: ./.github/workflows/godot-m5-5-acceptance.yml", full)
        self.assertIn("res://tests/test_m5_100_seeds.gd", acceptance)
        self.assertIn("res://tests/test_m5_replay.gd", acceptance)

    def test_p4_current_component_contracts_are_preserved(self):
        p4 = (WORKFLOWS / "ci-p4-contracts.yml").read_text(encoding="utf-8")
        contracts = re.findall(r"'test_[^']+:[A-Z0-9_]+:[0-9]+'", p4)
        self.assertEqual(25, len(contracts))
        self.assertIn("test_p4_v34_legacy_roster:V34_LEGACY_ROSTER_REPORT:18", p4)


if __name__ == "__main__":
    unittest.main()
