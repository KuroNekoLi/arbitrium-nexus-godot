# Phase 3 M2.5 — Integration Acceptance and Regression

Current status: **M2_CORE_DOMAIN_VERIFIED / FULL RPG GAMEPLAY NOT VERIFIED**. Historical dependency-blocked baseline and earlier red CI attempts remain documented below as provenance; they are no longer the current assessment.

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

## Executed CI evidence (2026-10-14, Godot 4.7.2)

The test code was committed as `71b753c5b0eba58bb9b21043e8be95e2d49ac44a`.

- **Attempt 1**: [run 38575810018](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38575810018). M1 30/30, M2.1 38/38, M2.2 43/43; new `test_m2_invariants.gd` could not parse due to adjacent string literals (line 140). This was a test syntax error, not a gameplay rule conflict; no card/swap gate was reached.
- **Attempt 2**: [run 38576033292](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38576033292), final `completed/failure` **intentionally** because readiness gate returned exit **2** for missing M2.3/M2.4 code. All **executed test scripts passed** before the gate: M1 30/30, M2.1 38/38, M2.2 43/43, M2.5 partial invariants **14/14**, M2.5 partial replay **6/6**, four legacy prototype scripts exit0. Official `4.7.2.stable.official.ed1daf0bf`; Godot ZIP SHA512 verification OK; editor import OK.
- Independent legacy regression: [run 38576033499](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38576033499) `completed/success` at the same test commit.
- Command (CI): `"$GODOT_BIN" --headless --path . --script res://tests/test_m2_invariants.gd` and analogous `test_m2_replay.gd`. Exit **0** for each partial test, **2** at prerequisite-gate step. Raw logs are in run artifact `godot-phase3-m2-5-blocked-gate-logs`.
- Partial fixed seed: `20261014`; `ruleset=arbitrium-phase3-m2.1-v1`, `content=m2.1-placeholder-content-v1`, `config=m2.2-cost-fixture-v1` (PROVISIONAL).
- Partial replay initial SHA256: `1cbc1e9c568be6458b92f9641e32bb4375273a1e946df0e7a51f5e46aae4bb2e`.
- Partial replay event SHA256: `28de6c96641655057122a210a73f9c3fa77890c0c20eded0417d5e62ebb7ce85`.
- Partial replay final state SHA256: `7389a7975f13b209982a3ba83dd4fd7ceeeb0c4947bda77f3712f4b8da70d9a9`.
- Tape: `PAY_SP_COST_ONLY(AP8/MP2, Overload2)` → `AP_REFUND_EFFECT(+3)` → `REDUCE_AP_DEBT_EFFECT(1)` → `GRANT_AP(+2)` → `CONVERT_AP_TO_RP` → `SPEND_RP(2)` → `EXPIRE_RP` → `START_PLAYER_RESOURCES`. A cost receipt is NOT a played card.
- The only skipped/blocked scenarios are *not included* in the numeric test execution counts: actual card unique-instance/12-card/hand≤8/draw reshuffle and Free Swap/PRE3-R11. These are **BLOCKED_DEPENDENCY**, not counted as passes.

### Verified deliverable scope and exit criteria

**Resource-only test sub-gate: VERIFIED (14+6 PASS); full M2.5/M2 DOMAIN: BLOCKED_DEPENDENCY**. No attempt to implement M2.3, M2.4, M3 or UI in this commit. The deliberately failing readiness gate is not a regression in M1/M2.1/M2.2.

Next owner must implement and separately verify M2.3 → M2.4, replace the `BLOCKED_M2_FULL_INTEGRATION` guard with real cross-module case(s), execute the entire gate, capture full card/swap hashes and only then update the verdict to `M2 DOMAIN VERIFIED`.


## Dependency update after M2.3 implementation — 2026-10-14

Initial M2.3-missing observations above are historical, scoped to the former baseline (495a2df). M2.3 now exists in new standalone scripts/domain/m2/cards and scripts/domain/m2/persistence, with **46/46 Godot 4.7.2 PASS** at de2178e175846c2eeae5aba7f3f96995bb61323c ([CI run #38580461921](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38580461921)). Spec-13 exact DECK-003 and PRE3-20 oracles were exercised.

**Overall M2.5 verdict remains BLOCKED_DEPENDENCY** because M2.4 Free Swap/trigger dispatcher/test runner do not yet exist and the full Cost→CardZones→EventTrigger→Replay integration is not implemented/tested. The full-domain [run #38580461996](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38580461996) still intentionally fails closed; the independent M2.3 green signal is the correct acceptance evidence for this milestone. Full domain must not emit M2 DOMAIN VERIFIED yet.

## Status addendum after M2.3 and M2.4 (2026-10-14)

Historical 'M2.3/M2.4 missing' statements above are accurate for the recorded **M2.5 initial baseline** SHA, not current master. M2.3 was independently verified 46/46 ([run #38580461921](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38580461921)); M2.4 independently verified 32/32 ([run #38582070292](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38582070292)). The M2.5 workflow [run #38581850850](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38581850850) executed both new suites successfully but deliberately emitted **`BLOCKED_M2_FULL_INTEGRATION` / exit2**, because actual Cost→CardZone→CardDiscarded→trigger→CardDrawn+CostResource unified reducer/replay remains absent. **M2.5 and the full M2 domain are NOT verified.** Do not alter the fail-closed gate until genuine cross-module verification exists.


## Final integrated M2.5 certification — 2026-10-14

- **Final Godot CI:** [run #38586164025](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38586164025), source SHA 418607f954f40a38eff0de0b830eb83bed7080d6. Job 115928633555: completed/success. Official 4.7.2.stable.official.ed1daf0bf binary, SHA512 validated, import and all runner exits 0. Full raw stdout and artifact are available on the workflow.
- Executed assertions in SAME CI: M1 30/30, M2.1 resources 38/38, M2.2 costs 43/43, M2.3 cards 46/46, M2.4 FreeSwap 32/32, earlier M2.5 resource invariants 14/14, resource replay 6/6, NEW integrated M2.5 40/40; **249/249 total Domain test assertions**, plus 4 legacy prototype test scripts (exit0, not included in numeric Domain count).
- Official green markers **M2_5_CROSS_MODULE_DOMAIN_VERIFIED** and **M2_DOMAIN_VERIFIED: core M2 resource, card-instance, FreeSwap and replay mechanics; M3/M4/M5 gameplay deferred** appear in raw Actions logs.
- Previous attempts: c922795 produced invalid YAML before any runner started; 07d85e2 corrected CI syntax but the new GDScript test had a multiline parse error; aec6a54 fixed that parse, [run 38585825453](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38585825453) passed 36/36 integration. Four additional cross-trigger replay tests were then added at 418607f, and final run 38586164025 passed 40/40. No acceptance assertion was disabled or removed.

### Execution architecture and boundaries

New source: scripts/domain/m2/integration/m2_domain_resolver.gd. New cases: tests/test_m2_integration.gd. The reducer holds ACTUAL M1 resource state and ACTUAL M2.3/4 card zone state together, with a global command ID ledger, strictly ordered source-tagged events, deterministic seeded RNG snapshots and canonical event/state SHA256. A failed command returns an unmodified deep copy and zero events. No UI timing enters any transition.

COMMIT_SP_CARD_FIXTURE looks up the cost from an externally fixed definition catalogue (action cannot supply arbitrary cost). It executes real M2.2 CostResolver.apply, then moves that exact owned CardInstance Hand→Discard or Hand→Casting, atomically. Free Swap delegates the real M2.4 resolver, including formal CardDiscarded, legal MOVE_CARD triggers, CardDrawn, PRECHECK failure and PRE3-R11 CardDrawFailed(POOL_CHANGED) without rolling back already executed discard-trigger moves. Extra draw respects cap8 and zones. Resource phase transitions call the real M2.1 Ledger and synchronize quota resetting and eligible actor draw-to-four; M3 remains authoritative over status/casting tick ordering.

The 40 actual integration assertions cover: three allies and 36 unique CardInstanceIDs; AP/MP debit + physical CardInstance movement; actor ownership; double-play/duplicate/stale command; insufficient AP/MP atomicity; provisional Overload/AP debt; zero-AP Free Swap and one-per-phase quota; Casting exclusion; no replacement PRECHECK; post-event POOL_CHANGED preserving prior effects with no phantom CardDrawn; hand cap8; incapacitated actor rejection; across-phase AP→RP/expiry/hand refill/quota refresh; and exact two-run seeded Replay after a mixed Cost→CardZone→Discard→Trigger→Draw command tape, including **both successful CardDrawn and PRE3-R11 failed draw branches**.

Replay seed: 20261014. Canonical initial state SHA256 **e18806c0a2007ea79856b7302a01b35a5ac571e9d9b9d65c700774d452c74b13**; integrated events SHA256 **c26cbea2b560924fb568be1d4dcbadc6c26b26379293f16f6981aa43964fe061**; final state SHA256 **8118b9cc9dc2c30b0d009934e8a3ab5385909d73ca021e958100b41d9509349a**. The seed, initial state, configuration and command tape are deterministic inputs; rejects do not advance RNG or corrupt card zones.

### Important remaining acceptance obligations

This verdict covers **M2 CORE MECHANICS**, not playable SP effects. Spell damage, hit/crit/status, Guard/Protect/Barrier, actual HP/MP/Buff trigger content, Full Chant spell release/interrupt refund, boss AI, real M3 phase tick ordering, Last Spell, and UI integration remain **NOT IMPLEMENTED / NOT CERTIFIED** by this M2.5 suite. M2.4 currently dispatches bounded MOVE_CARD triggers; full spec13 M30 scenario with actual discard-trigger MP restoration and draw-trigger Buff remains **PARTIAL**, not falsely promoted to PASS. Original legacy 8-card UI is still separate. M-D04 long-term APDebt balance and its Max8 test parameter remain **BALANCE_PROVISIONAL**. The earlier missing-dependency bullets in the historical baseline above do not describe the current repository HEAD.

**Conclusion: close the core M2 integration gate as M2_CORE_DOMAIN_VERIFIED, and retain these precise M3–M5 gameplay dependencies.**
