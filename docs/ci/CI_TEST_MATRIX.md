# P2 — CI contract split (2026-10-16)

## Goal and verification boundary
Keep **every** existing headless P4 assertion and legacy gate, but avoid running 25 P4 suites on every ordinary code push. The 1149-contract P4 gate is moved unchanged from `ci-fast.yml` into `ci-p4-contracts.yml`; existing exception/authorization conditions for historical V3.5 GUI input tests remain intact. Strict import and log-error gates remain mandatory. This is a workflow scheduling refactor, **not** a reduced coverage claim.

| Gate | When it runs | Scope |
|---|---|---|
| `CI Fast` | Relevant push/PR or manual | Godot strict import, core Golden/Replay, 5 fast seeds, P4 scene/HUD/Lv40 smoke and screenshot writer |
| `CI P4 UI Contracts` | Battle/UI/asset/test/config changes, nightly, or manual | Complete 25-suite headless P4 contracts (1149 checks) + 4 legacy smoke suites |
| `CI Integration` | Domain / combat logic changes or manual | 26 named domain suites (1128 assertions) and 4 legacy smoke suites |
| `CI Full` | Existing scheduled/release/core-change trigger or manual | 100 seeded battles plus complete acceptance regression |
| `Godot V2.3 Real HUD Render Captures` | Existing UI paths or manual | Actual rendered PNG; distinct from headless P4 tests |

## Execution cost measured before the split
From master runs at `2c31fe9`: Fast total ~170 seconds (two parallel jobs), Integration ~88 seconds, Full ~331 seconds. The P4 contract job took ~170 seconds, while Fast smoke itself took ~96 seconds. The full 100-seed test measured ~226 seconds. These are observed CI run durations, not projections for the refactored flow.

## Expected benefit and next steps
- Ordinary domain changes: Fast + Integration remain; the P4 suite is not scheduled unless affected battle/UI/fixtures/config paths change. A nightly P4 run catches cross-boundary changes.
- UI changes: Fast and P4 contracts run in separate workflows; no assertion is skipped just for being UI work. Visual viewport image capture remains its own renderer-based gate.
- Historical phase-specific workflows remain manual/branch-scoped; do not delete original tests.
- P3 will consider moving `CI Full`'s 100-seed gate away from ordinary pushes. **Not changed in P2**.
- Evaluate actual after-run timings before deciding any additional split. Check whether branch protection requires a stable always-running aggregate status.

## Safety
Headless contracts assert structure/state, not actual screenshots; do not represent them as visual-equivalence proof. Real GUI input suites with explicit limited-run authority are still excluded from generic auto re-runs. Keep `assert_godot_logs.py` strict.
