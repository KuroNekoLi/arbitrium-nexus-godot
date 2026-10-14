# Phase 3 / M2.1 — AP, MP and RP Resource Domain Engineering Note

> **Status: IMPLEMENTED_NOT_VERIFIED** until this repo's GitHub Actions finishes green and logs are read. Created 2026-10-14. The authoritative specs are Library-synced `docs/combat/` files, **not** this implementation note. This M2.1 gate does not certify M2.2–M5.

## Source authority, exact requirements

- [03 Party Actions & Resources](../combat/03_PARTY_ACTIONS_RESOURCES.md): P1-D01/D09; shared BaseAP6, first accepted Basic Attack MP restore, AP→RP with expiration.
- [18 Magic AP economy](../combat/18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md): M-D06/07/08/09; AP bonus and APDebt semantics; debt repayment **deferred to M2.2**, never silently waived.
- [19 Phase2 approved M-D18–31](../combat/19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md): M-D18 CurrentAP uncapped; M-D19 no natural MP refill; M-D20 MaxMP clamp; M-D31 per-character MaxMP.
- [20 Preimplementation ADR](../combat/20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md): PRE3-R05 clamp extra RP; provisional numeric fixtures; typed negative/invalid rejection.
- [23 Phase3 plan](../combat/23_PHASE3_EXECUTION_PLAN.md): M2.1 strictly resources; M2.2 owns full cost/Overload; M3 owns turn/status/casting boundary order; M5 owns damage.

## Files and interface

- `scripts/domain/m2/economy/resource_ledger.gd`: **INTERNAL** `Ledger.apply(state, instruction, provisional)` with deterministic state copy, validation, stable event_seq/action_seq, command_id idempotency and replay. Supported internal operations:
  - `SPEND_AP`, `GRANT_AP` (Player Phase); AP above6 is allowed.
  - `PAY_MP`, `RECOVER_MP` (actor-owned; recovery capped at current MaxMP).
  - `BASIC_ATTACK_RESOURCE_ONLY` (resource reservation/first-attack MP policy, **NO ATTACK DAMAGE**).
  - `CONVERT_AP_TO_RP` (one-time Player→Enemy resource seam, 1:1 clamp to effective cap), `SPEND_RP`/`GRANT_RP` (Enemy only), `EXPIRE_RP` (clear remaining RP), `START_PLAYER_RESOURCES` (reset basic-attack eligibility, replenish BaseAP if APDebt=0).
- `scripts/domain/m2/economy/basic_attack_mp_policy.gd`: pure quote of explicit `BALANCE_PROVISIONAL` AP/MP settings, first-success claim and actual MP gain.
- `scripts/domain/m1/combat_model.gd`: append one per-ally MP-restore claim map, resource and MP shell invariants, bump RuleSet/Content version to `arbitrium-phase3-m2.1-v1`/`m2.1-placeholder-content-v1`. **Existing M1 tests and legacy UI remain unchanged**; replay proofs of old commits remain historical.
- `resources/combat/rulesets/m2_1_provisional_resources.json`: test-only sample attack cost AP1, MP+2, per-actor MaxMP6/8/12. These numbers are **BALANCE_PROVISIONAL**, not permanently approved values.
- `tests/test_m2_resources.gd`: positive, negative, boundary, deterministic resource replay and M1 isolation cases.
- `.github/workflows/godot-m2-resources.yml`: official Godot4.7.2 SHA-512 verified headless run, M1 30-case regression + M2.1 suite. Existing `.github/workflows/godot-g0-legacy-baseline.yml` separately runs original 4 legacy prototype tests.

## Scope vs deferred

**M2.1 actual rules:** BaseAP6 is shared, CurrentAP may exceed6, no inherent AP regen between commands; direct AP spend/grant; MP per actor, clamped; only the first *successful* basic-attack resource commit per actor/PlayerPhase grants MP; no natural full-mana refresh; AP→RP 1:1 capped at default6 or explicitly configured effective RP cap; RP clear at Enemy Phase end; no AP carryover.

**Deliberately not implemented:**
- `BASIC_ATTACK` public command in M1's `combat_resolver.gd` still returns `FEATURE_NOT_IMPLEMENTED`. `BASIC_ATTACK_RESOURCE_ONLY` is an internal seam and **does not attack**: it doesn't hit a target, deduct HP, validate target, create attacks or enact player-visible actions. M5 owns actual damage and hit. An adapter must not invoke the internal fixture operation as a completed BASIC_ATTACK.
- `SPEND_AP` and `PAY_MP` are individually atomic, but **not** an approved combined SP transaction. M2.2 must build full all-or-nothing costs, discounts, Overload and APDebt transactions; do not simply chain these two operations and assume rollback.
- Resource boundary functions do not trigger status/chant resolution, draw cards, Boss action or Reaction Queue. M3 must call them in PRE3-R09 legal timing (ticks/outcome before AP refresh and hand refill). `AWAITING_PLAYER_START` is M2.1 internal seam, not a new player-visible phase.
- If APDebt is positive, `START_PLAYER_RESOURCES` returns `DEFERRED_TO_M2_2_AP_DEBT` without clearing debt or inventing repayment.
- Effective RP cap >6 can be injected only into **test fixtures** at M2.1. Legitimate SP grants, duration/expiry and cap modification implemented in M2.2/M3 later. `GRANT_RP` clamps to effective cap. RP always expires at enemy-end.
- No cards/zones/free swaps/LastSpell, no UI integration, no turn timer, no finished Phase 3 milestone.
- M1 `Model.validate_shell` verifies current MP <= MaxMP, nonnegative AP/MP/RP/debt and RP<=cap, but does **not** replace comprehensive M2.5 state/zone invariants.

## Test IDs and expected evidence

Primary tests from Library spec13: `P1-ECO-001..009` (009 obsolete oracle replaced by later M-D08/09, marked `P1-ECO-009-UPDATED`), `M18-AP-001`, `M18-RP-002`, `M19-MP-001`, `M20-MP-002`, `M31-MP-001`; plus unique M2.1 negative/boundary cases.

On success runner prints `M2_1_TEST_REPORT executed=<n> passed=<n> failed=0 skipped=0` and `M2_1_REPLAY_PROOF` with seed, rule/content versions, fixture schema, initial/event/final SHA-256 hashes and complete command tape. Combined CI must still run M1 30/30 and unchanged G0 legacy CI. Runner errors or nonzero exit mean Gate **NOT_VERIFIED**.

## M2.2 handoff

Start with `SPEND_AP`/`PAY_MP` insufficiency and debt/discount rules in `docs/combat/18,19,20`. Build authoritative *combined* `PayCardCost` with atomic validation, SetCost→sum discounts→minimum→Overload shortfall; AP refund enters CurrentAP but never silently clears APDebt. No global CurrentAP cap, no global play-count cap. Do not silently enable Attack or SP functionality until actual effect commit exists.
