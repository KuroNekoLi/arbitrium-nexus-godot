# Phase 3 M2.5 — Integration Acceptance and Regression

Status: **BLOCKED_DEPENDENCY / M2 DOMAIN NOT VERIFIED**.

## Baseline inspected (2026-10-14)

Repository: `KuroNekoLi/arbitrium-nexus-godot`, branch `master`. Starting HEAD:
`495a2df504135c748cf53e29756fc521b5fad0f7`.

M1, M2.1 (38/38) and M2.2 (43/43) have recorded Godot 4.7.2 CI evidence at
[run 38571553461](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38571553461).
This is NOT evidence that M2.3, M2.4 or full M2 have been verified.

### Blocking dependencies

- **M2.3 NOT IMPLEMENTED** at baseline HEAD: missing `scripts/domain/m2/cards/{card_instance,deck_validator,card_zone_resolver,draw_resolver}.gd`, `scripts/domain/m2/persistence/deck_profile_v2.gd` and `tests/test_m2_cards.gd`.
- **M2.4 NOT IMPLEMENTED**: missing `scripts/domain/m2/cards/{free_swap_resolver,card_trigger_dispatcher}.gd` and `tests/test_m2_free_swap.gd`.
- Legacy eight-unique-card `scripts/domain/deck_profile_store.gd` and legacy UI are NOT substituted for a valid 12-SP new deck.
- Consequently **full card-instance uniqueness, per-actor 12-card conservation, hand cap 8, draw-to-four, no-card-pool behavior, swap precheck/trigger order and PRE3-R11 POOL_CHANGED** cannot currently be tested against an implemented M2.3/M2.4 domain.
- Do NOT record those test IDs as PASS or weaken their oracles.

## Partial test-first deliverables

- `tests/test_m2_invariants.gd` checks **existing resource-only** invariants: AP/MP atomicity, non-negative resources, debt separation, a provisional zero-AP phase, RP cap/expiry, stale/duplicate commands and one-shot refund.
- `tests/test_m2_replay.gd` exercises one fixed-seed command tape across actual M2.1/M2.2 cost, effect and ledger resolvers; compares canonical event/state hashes, strict event sequence and rejection isolation.
- `.github/workflows/godot-m2-domain.yml` downloads/hash-verifies official 4.7.2, runs M1/M2.1/M2.2, both new partial suites, four legacy regressions and then **fails closed with exit 2** if any M2.3/M2.4 input is missing, or if full cross-card/swap replay coverage is still absent.

A red M2.5 gate caused by missing dependencies is **expected BLOCKED_DEPENDENCY**, not a license to downgrade the test assertions or label full M2 verified. Existing green M1/M2.1/M2.2 conclusions stay independent.

## Requirements → Code → Tests

| Decisions | Current implementation | Tests | Current coverage |
|---|---|---|---|
| M-D01/02/03/05/06/07/15, M-D16/17 | M2.2 cost/overload/effect + M2.1 ledger | M2.2 suite, `test_m2_invariants.gd`, `test_m2_replay.gd` | resource-only |
| M-D04 | `overload_debt.gd` | zero-AP phase and next-phase debt repayment | PROVISIONAL only |
| P2-D16 (deterministic facilities) | M1 hashes + seeded state, M2.1/M2.2 resolvers | `test_m2_replay.gd` | no shuffled-card/swap replay yet |
| M-D25, PRE3-R16, DECK-001–004 | M2.3 prerequisite | `test_m2_cards.gd` required | BLOCKED |
| M-D26–30, PRE3-R11 | M2.4 prerequisite | `test_m2_free_swap.gd` required | BLOCKED |
| PRE3-R12 | M4 casting card behavior | M4 once implemented | DEFERRED TO M4 |

## M2 domain completion gate

1. First implement and separately verify M2.3 and M2.4; preserve their individual CI logs.
2. Add true M2.5 **cross-module** case(s), not just separate unit suites. Begin with 3 independently owned 12-card decks, initial hand 4, character-specific draw/hand/discard/casting, seeded draw and discard reshuffle. Verify global instance conservation after each accepted/declined transition, cap 8 and hand preservation.
3. Replay `Cost -> card-zone transition -> CardDiscarded -> trigger -> CardDrawn`, including negative PRECHECK without an alternative and PRE3-R11 `CardDrawFailed(POOL_CHANGED)` after a valid precheck, with no duplicated instances and stable event/state hashes.
4. Run same full command tape twice, compare seed, RNG draw index, exact ordered event hashes and final state hash; assert rejected commands leave state/seed unchanged.
5. Run official Godot 4.7.2 with M1, M2.1, M2.2, M2.3, M2.4, M2.5 and legacy smoke. Capture exit codes and raw logs. Update RTM only after real results.
6. Stop after third failed attempt per test group (initial + 2 repairs). M2 overall becomes VERIFIED only after the entire above gate passes.

**The legacy UI, real SP effect execution, M3 enemy action and M4 casting are not certified by M2.5.**

## CI evidence

Not yet run for the new M2.5 tests when this report is initially written. Record the actual CI run URL, tested commit SHA, Godot binary version, test counts and replay seed / hashes from stdout below after fetching the completed run. Do not use fabricated outputs.
