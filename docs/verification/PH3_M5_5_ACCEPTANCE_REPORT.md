# Phase 3 — M5.5 Full Battle / Seeded Replay Acceptance Report

> **CI gate:** This document records the actual M5.5 source, test matrix, and reproducibility policy. The final verification verdict must match the latest **post-merge master** GitHub Actions run. In-progress CI and prior green subgates do not establish completion.

## Authority

- Executable repository: `KuroNekoLi/arbitrium-nexus-godot`.
- Source baseline at branch creation: `master@9b45bbf004221ff5dab9b87736a684c09e2747e8` (includes M5.4 master `679252d61d56ecea71053692c62532a82846a94d`; newer source-only resource skills commit does not modify this domain).
- `AGENTS.md`; approved `docs/combat/00`–`23` and upstream semantic reconciliation Plan A; exact `docs/verification/PH3_M5_EXECUTION_PLAN.md` §M5.5.
- Verified **predecessor** before M5.5: M1–M5.4 **1,081/1,081** named Domain tests plus four legacy smoke runners, Godot 4.7.2 master [#38676746490](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676746490). Never count these 1,081 as new M5.5 checks.
- **Content**: `m5.5-three-party-boss-fixture-v1`, fully `FIXTURE_ONLY / BALANCE_PROVISIONAL`. No user-approved retail pricing/ability balance is inferred.

## Genuine 3×12 card encounter

`tests/fixtures/m5_full_battle_fixture.gd` constructs one fresh Godot M1 battle `Model.make_state(["A","B","C"],["Boss"],seed)`; M2 `Draw.start_battle()` creates 12 actual unique CardInstance IDs per actor, seeded shuffle, hand 4, remaining draw 8. Every ally starts `ACTIVE`, HP100, MP10; shared CurrentAP6, legitimate start PlayerPhase, one Boss with HP290. Each actor uses a different registered role loadout:

| Actor | Physical deck composition (12 SP instances) | Role |
|---|---|---|
| A | 9 `setup` + 3 `burn` | Break / Exposed / Combo setup, DoT, separate legal Last Spell slot `nova` |
| B | 9 `finish` + 3 `ward` | second-party Combo finisher, Barrier |
| C | 9 `regular` + 3 `regen` | magical Chantless/Full Chant, heal-over-time |

Boss has actual `boss_strike` and `boss_fallback` M5 enemy profiles, deterministic public intent selection and HP/Defense. All numbers versioned. M5.4's special self-recoil test effect is **removed from this fixture**: it is not a permanent card mechanic.

`tests/fixtures/m5_full_battle_driver.gd` is **test policy only**. It does not set HP, outcome, card zones or action costs. It sends real `M5.apply(state,command,config)` commands: setup→different actor paid Combo, Full Chant→real release, A's separate Last Spell after its actual AP/MP cost, status/Barrier support, EnemyAction public intent, explicit Reaction Guard/Confirm or explicit Pass if there is a drafting legal window, real M5.1 HP updates, phase progression until VICTORY or DEFEAT.

The driver has 32-round, 480-command, and 4,500-event hard guards; a missing legal successor does **not** trigger a hidden auto-pass. Missing/invalid commands cause a nonzero test failure. Every accepted command is added to `tape`; no prewritten successful post-battle snapshot is used. Post-command invariants include Godot integrated Domain state, M4 state, unique cards, HP/MP/AP/RP bounds, no negative resources, and honest command/replay receipts.

## Named executable scripts and mandatory gates

- `tests/test_m5_integration.gd`: **32 named checks**, `M55-INT-01`–`M55-INT-32`, one **golden** full party versus Boss encounter, major mechanic event coverage, actual terminal outcome and full replay.
- `tests/test_m5_replay.gd`: **15 named checks**, `M55-REP-01`–`M55-REP-13-PRESENTATION_... `, including three explicit presentation-equivalence modes (`ALWAYS_ASK`, `SMART`, `QUICK`), canonical final/event digest, tampered tape, and post-terminal command rejection.
- `tests/test_m5_100_seeds.gd`: **100 individually named seeds** `M55-SEED-20261014`–`M55-SEED-20261113`, each run from actual initial state to terminal, then the *whole tape* is replayed. Includes 10 aggregate checks `M55-100-01`–`M55-100-10` for seed count, outcome, card/resource invariants, no rejected policy actions, distinct tapes, full replay, actual HP0, fallback, command/round/event limits. Each seed emits one `M5_5_SEED_REPORT` with seed, ruleset/content/PRNG, accepted/rejected command counts, rounds, event count, first HP0, fallback, outcome, initial/tape/event/final SHA256, and elapsed time (outside Domain only).
- `.github/workflows/godot-m5-5-acceptance.yml`: independently downloads SHA512-verified official Godot **4.7.2**, imports project headlessly, runs M5.5 three suites and **every** prior 1,081 Domain case and four legacy smoke runners. Raw CI logs uploaded. Every fail exits nonzero. Gate rejects any missing named report even if Godot exits zero.

**Expected total if all M5.5 new assertions execute and PASS**: `32 + 15 + 110 = 157 new`; `1,081 + 157 = 1,238` cumulative. **Expected does not mean VERIFIED**: quote the final Godot logs, zero failures, successful same-master CI and actual hashes.

## Reproducibility and failure handling

- Golden seed = `20261014`; bulk seeds = `20261014..20261113` (inclusive, exactly 100).
- Same initial config/seed/Command Tape yields exact same per-command event sequence, Event SHA256 and final State SHA256. Application time/frames, viewport mode and test timing never affect Domain rules.
- Invalid/stale/terminal commands must be rejected with no event, resource, zone, or RNG mutation.
- Same failing **test group** is limited to first execution + two repair reruns. Record actual CI history, do not hide red test or weaken approved oracle for convenience.

## Engineering principles and interview teaching

1. **Application vs policy**. A script may choose explicit legal actions but must not become a parallel simulator; only the existing Domain reducer can update gameplay state. Compare to Android Clean Architecture where a ViewModel dispatches intents and a single use-case/reducer owns committed business-state transitions.
2. **Deterministic tape as a contract**. A record of public Command+CardInstanceID+expected event sequence is stronger than a snapshot-only golden check: it can reveal a wrong reaction cost, wrong discard move, or illegal extra RNG draw even if final Boss HP matches.
3. **Property tests vs balancing**. 100 terminal seeded battles are a software stability floor, not a statistically significant fairness or RPG balance approval. A future `Ashfang Balance Test Sheet` must separately measure action diversity, attrition, expected turns and boss difficulty.
4. **Bounded event loop**. Each battle has explicit command/event/round caps; a stall or self-triggering status loop is a failed Gate rather than waiting forever or modifying states by fiat.
5. **Human Reaction control**. Driver only chooses Guard/Confirm or Pass after the M3 legal Drafting window opens, never via timeout or FPS. Quick/Smart/AlwaysAsk remain presentation-only.
6. **No retroactive Last Spell**. A pre-release caster HP0 cancels the scheduled spell immediately (M4.4); a legal completed release may already have dealt real damage. Exposed and Break obey the separate actual lifetimes tested in M5.3.

## Explicit exclusion and honest status

- Spell Counter post-release pre-effect Reaction window/eligibility: **BLOCKED_CONTENT / NOT VERIFIED**; don't pretend Casting Interrupt is a full Spell Counter.
- Analyze / Enemy Intel: **DEFERRED_CONTENT / NOT VERIFIED**.
- All-positive-HP yet all-EXHAUSTED party terminal outcome: **CORE_RULE_EDGE_PENDING**, not automatically DEFEAT.
- Commercial, content-balanced Boss or all archetypes, mixed AoE targeting, complete animation/HUD, 2.5D implementation, bilingual player-facing strings, and human usability: **NOT VERIFIED**. After Domain M5.5, move to Presentation Spike and Real Player Playtest, not claim PLAYABLE VERIFIED.

## CI evidence

- First complete 32-case golden and 15-case Replay steps were observed as successful in [initial active workflow #38677695295](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38677695295). The 100-seed result and cumulative gate are pending in this draft.
- This section **must be completed with the actual latest post-merge Master CI SHA and numeric logs** before declaring `M5 DOMAIN VERIFIED — HEADLESS BATTLE SCOPE`.
