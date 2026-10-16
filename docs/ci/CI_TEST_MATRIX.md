# CI test matrix — P2, P3 and P4 (2026-10-16)

## Goal and verification boundary
Keep **every** existing headless P4 assertion, but avoid running 25 P4 suites on every ordinary code push. As of P4, the separate early-prototype legacy gates run in nightly Full instead of being duplicated in UI and Integration jobs. The 1149-contract P4 gate is moved unchanged from `ci-fast.yml` into `ci-p4-contracts.yml`; existing exception/authorization conditions for historical V3.5 GUI input tests remain intact. Strict import and log-error gates remain mandatory. This is a workflow scheduling refactor, **not** a reduced coverage claim.

| Gate | When it runs | Scope |
|---|---|---|
| `CI Fast` | Relevant push/PR or manual | Godot strict import, core Golden/Replay, 5 fast seeds, P4 scene/HUD/Lv40 smoke and screenshot writer |
| `CI P4 UI Contracts` | Battle/UI/asset/test/config changes, nightly, or manual | Complete 25-suite headless P4 contracts (1149 checks); no legacy prototype suites |
| `CI Integration` | Domain / combat logic changes or manual | 26 named domain suites (1128 assertions); no legacy prototype suites |
| `CI Full` | **Daily 02:00 Asia/Taipei**, manually, or after Release published; **never automatically on push** | 100 seeded battles, complete acceptance regression, and 4 legacy prototype smoke suites |
| `Godot V2.3 Real HUD Render Captures` | Existing UI paths or manual | Actual rendered PNG; distinct from headless P4 tests |

## Execution cost measured before the split
From master runs at `2c31fe9`: Fast total ~170 seconds (two parallel jobs), Integration ~88 seconds, Full ~331 seconds. The P4 contract job took ~170 seconds, while Fast smoke itself took ~96 seconds. The full 100-seed test measured ~226 seconds. These are observed CI run durations, not projections for the refactored flow.

## Expected benefit and next steps
- Ordinary domain changes: Fast + Integration remain; the P4 suite is not scheduled unless affected battle/UI/fixtures/config paths change. A nightly P4 run catches cross-boundary changes.
- UI changes: Fast and P4 contracts run in separate workflows; no assertion is skipped just for being UI work. Visual viewport image capture remains its own renderer-based gate.
- Historical phase-specific workflows remain manual/branch-scoped; do not delete original tests.
- **P3 implemented:** `CI Full` no longer listens to `push` or `pull_request`; Fast/Integration continue on relevant code changes. `godot-m5-5-acceptance.yml` remains reusable and manually dispatchable, without changes to its test oracles.
- Evaluate actual after-run timings before deciding any additional split. Check whether branch protection requires a stable always-running aggregate status.

## Safety
Headless contracts assert structure/state, not actual screenshots; do not represent them as visual-equivalence proof. Real GUI input suites with explicit limited-run authority are still excluded from generic auto re-runs. Keep `assert_godot_logs.py` strict.

## P3 — Full-gate trigger policy

- `CI Full` runs every day at **18:00 UTC = 02:00 Asia/Taipei (next day)**, when a GitHub release is `published`, or when explicitly started with **Actions → CI Full - 100 Battles and 1238 Assertions → Run workflow**.
- Ordinary `push` and `pull_request` events **must never** schedule 100 full seeded battles. The `CI Fast` (5 replayed seeds + Golden/Replay/scene smoke), `CI Integration` (1128 Domain assertions), and UI/scene-specific P4 contracts remain responsible for relevant push events.
- The 100-seed suite, 110 seed-specific checks, 1238 combined acceptance assertions, strict log/error gates, and replay equivalence are untouched.
- **Release governance:** `release: published` starts verification **after** the release is published; it does **not** block publication. For a release candidate, manually run the Full gate on the candidate ref and review the passing result **before** publishing. On failure, investigate rather than changing the expected counts.
- Scheduled workflows only run from the default branch. P4 runs at 19:00 UTC (03:00 Asia/Taipei) and is separately scheduled.
- Check repository branch-protection / required checks administratively before relying on `CI Full` as a required push status. A non-triggered, required workflow may remain Pending. This connector could not read the branch-protection settings.
- Prefer dispatching **CI Full** for one-off manual verification rather than also dispatching the reusable **M5.5** workflow, to avoid duplicate 100-battle work.
- P4 moves the four early-prototype smoke suites out of ordinary P4 and Integration runs; Full still runs all four nightly/release/manually.

## P4 — Legacy prototype execution ownership

**Decision:** the four legacy smoke scripts (test_battle_state, test_deck_builder, test_combat_ui, test_turn_flow) are still in `tests/`, but the **only automatically scheduled** calls to all four now belong to the nightly `CI Full` canonical M5.5 acceptance. The older `godot-g0-legacy-baseline.yml` and milestone Workflows remain manually callable. This does not imply these obsolete prototype tests validate the current 12-card/AP/RP domain.

The tests target the legacy prototype (`scenes/main.tscn`, older `scripts/domain/battle_state.gd`, and an eight-card deck editor), distinct from the modern `battle_screen.tscn` / M1–M5.5 Domain. The daily push gates still provide:
- Fast: representative current battle, replay, 5 seeds, current P4 scene/HUD/Lv40.
- Integration: **26 suites, 1128 assertions** with the same strict log validation.
- P4: **25 suites, 1149 assertions**, no legacy runs (`legacy=0` reports intentional routing, not failure).
- Full: complete M5.5 / 100 seeded battles, plus all four legacy smoke scripts.

**Observed historical overhead (not an end-to-end forecast):** Integration's legacy step took approximately 5.4 seconds in the 2026-10-16 run; P4's four legacy scripts took about 4–5 seconds in its 2026-10-16 successful run. Expect a modest saving, not a multi-minute reduction.

**Tradeoff:** an edit confined to the legacy prototype itself will not receive legacy behavior validation during an ordinary push. Use `CI Full` manually for such changes or wait for the nightly gate. No source test file is deleted; strict error handling on remaining tests is unchanged.

Further candidate optimizations (not implemented here) should benchmark the ~64-second feedback-edge animation waits and representative visual capture, without weakening those assertions.
