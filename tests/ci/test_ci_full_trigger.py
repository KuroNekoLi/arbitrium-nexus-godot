"""P3 invariants: full seed replay is not scheduled on ordinary pushes."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"


def events_in(workflow_name):
    source = (WORKFLOWS / workflow_name).read_text(encoding="utf-8")
    lines = source.splitlines()
    if "on:" not in lines:
        raise AssertionError("Missing event stanza in " + workflow_name)
    stanza = []
    for line in lines[lines.index("on:") + 1:]:
        if line and not line[0].isspace() and not line.startswith("#"):
            break
        stanza.append(line)
    events = set()
    for line in stanza:
        if line.startswith("  ") and not line.startswith("    ") and line.strip().endswith(":"):
            events.add(line.strip()[:-1])
    return source, events


class FullTriggerPolicyTests(unittest.TestCase):
    def test_full_has_only_daily_manual_and_release_events(self):
        source, events = events_in("ci-full.yml")
        self.assertEqual({"schedule", "workflow_dispatch", "release"}, events)
        self.assertIn("cron: '0 18 * * *'", source)
        self.assertIn("types: [published]", source)
        self.assertIn("cancel-in-progress: false", source)

    def test_full_still_calls_exact_canonical_acceptance(self):
        source, _ = events_in("ci-full.yml")
        self.assertIn("uses: ./.github/workflows/godot-m5-5-acceptance.yml", source)
        acceptance, events = events_in("godot-m5-5-acceptance.yml")
        self.assertEqual({"workflow_call", "workflow_dispatch"}, events)
        self.assertIn("res://tests/test_m5_100_seeds.gd", acceptance)
        self.assertIn("M5_5_100_SEEDS_REPORT executed=110 passed=110 failed=0 runs=100", acceptance)
        self.assertIn("M5_5_100_SEEDED_FULL_BATTLES_VERIFIED", acceptance)
        self.assertIn("res://tests/test_m5_replay.gd", acceptance)
        self.assertIn("assert_godot_logs.py", acceptance)

    def test_push_still_checks_fast_and_domain(self):
        fast, fast_events = events_in("ci-fast.yml")
        integration, integration_events = events_in("ci-integration.yml")
        self.assertIn("push", fast_events)
        self.assertIn("push", integration_events)
        self.assertIn("test_m5_fast_seeds:M5_5_FAST_SEEDS_REPORT:5", fast)
        self.assertIn("test_m5_replay:M5_5_REPLAY_REPORT:15", fast)
        self.assertIn("CI_INTEGRATION_REPORT suites=26 assertions=$actual failed=0", integration)
        self.assertIn("'scripts/domain/**'", integration)


if __name__ == "__main__":
    unittest.main()
