# CI/CD 3-tier optimization — 2026-10-15

> Default branch: **master**, not main. CI only; no gameplay balance or GUI approval. Original M1–M5.5 assertions and evidence preserved.

| Tier | Trigger | Coverage |
|---|---|---|
| **Fast** \`.github/workflows/ci-fast.yml\` | Relevant pushes to master/integration/ci/handoff/ui, PR or manual | Verified Godot 4.7.2 import; CI error-gate; M5.5 Golden 32, Replay 15, *new* five-seed authentic battle+full tape replay 5; P4 scene 8, HUD 36, integration 31, Lv40 playable Headless 32, Screenshot Writer 46. No GUI validation claim |
| **Integration** \`.github/workflows/ci-integration.yml\` | Domain/Controller/command/fixture changes or manual/PR | Original 26 Domain suites, **1128/1128** named assertions (M1–M5.5 excluding 100 seed/10 aggregates), four Legacy smoke. Exact named report assertions and strict log checks |
| **Full** \`.github/workflows/ci-full.yml\` | Nightly at 18:00 UTC (02:00 Taipei), manual, published Release, selected high-risk core/fixture push | Calls the original \`godot-m5-5-acceptance.yml\` as a reusable workflow: **1238/1238**, 100 authentic terminal battles and Command Tape Replay with original 110 acceptance IDs, four Legacy smoke plus P4.1–P4.3 |

All former 24 \`godot-*.yml\` flows become **manual dispatch only**. The M5.5 canonical original additionally exposes \`workflow_call\` for \`ci-full\`. This keeps forensic runs and precise per-stage oracles without running dozens of overlapping workflows on one Domain push.

The immutable \`tests/test_m5_100_seeds.gd\` is unchanged. New \`tests/test_m5_fast_seeds.gd\` chooses five fixtures from the original seed range and verifies genuine terminal outcomes, no rejected commands, card zone invariants, and exact Replay event/final hashes. Fast 5 ≠ Full 100; it cannot satisfy or replace the mandatory M5.5 release gate.

Engine installer \`tools/ci/install_godot.sh\` checks official SHA-512 on download; the \`actions/cache\` restore also checks local SHA-512 and \`--version\`. Cached Godot executable is reused; .godot import data are always rebuilt. Fast cancels stale runs of the same ref, Integration never cancels a Master run, and Full never cancels. Strict engine error checks retain the original \`tools/ci/assert_godot_logs.py\`.

No new run of historically exhausted \`test_lv40_domain.gd\`, \`test_lv40_edges.gd\` or denied GUI \`test_p4_input_capture.gd\` is introduced.

### How to verify

1. Verify both new Fast and Integration GitHub Actions succeed on the isolated CI staging branch.
2. Review route changes: 24 old workflows retain their manual triggers; the old canonical M5.5 script still executes 100 seeds only when directly requested or called by Full.
3. Merge to **master** without PR or force push; inspect new actions and report real speed gains from recorded runs, not advertised targets.
4. Run Full before published release if there is no recent green Full for the exact releasable code SHA. If Full fails, treat that as a real regression even when Fast is green.

CD remains **not implemented**: no signed Desktop Godot exports or automated Release artifact deployment have been falsely claimed.
