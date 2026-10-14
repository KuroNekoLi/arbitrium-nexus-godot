# PH3 — M3.3 Guard & Protect Engineering Note

## Authority and dependencies

Requires M1–M2 core Domain 249/249; M3.1 61/61 and M3.2 50/50 independent passing gates. Source of Truth: docs/combat/07 (P1-D03/04/11–16, PRE3-R01–04/R17), docs/combat/20 and 13. Guard numerical 40% is BALANCE_PROVISIONAL; never promoted to approved.

## Implementation

- basic_guard_resolver.gd: Guard exactly 1RP, no SP card/MP, legal for active recipient of HP attack, all eligible HP hits within SAME EnemyAction. Outputs coverage descriptor, NO damage computation.
- basic_protect_resolver.gd: Protect exactly 2RP, no SP/MP, single-target HP attack ONLY. No AOE/MULTI/direct casting disruption/unprotectable. Distinct living active guardian can protect a living teammate, including an exhausted target. Redirect actual recipient BEFORE M5 hit/defense. Only first Protect changes recipient; any later competing Protect skips without charge.
- reaction_eligibility.gd: one eligibility checker shared by SP and basic Defense; action active/target/card/MP/RP/actor status checked JIT; M4 Concentrating exception remains fail-closed.
- reaction_window_resolver.gd: detects Guard from explicit HP attack even if card catalogue empty. Under-specified damage_type still fails closed to avoid silently skipping a potential basic reaction; explicit direct casting disruption with no legal SP is legitimately empty.
- reaction_queue_resolver.gd: drafts/preview/reorder/remove are free. CONFIRM delegates fixed basic RP cost to existing M2 integrator and ResourceLedger; then registers Guard coverage or Protect reroute; emits records in order. Every subsequent reaction rechecks effective target and source. No duplicate payment, rollback of earlier legal action, card use or auto-pass.
- m2_domain_resolver.gd: COMMIT_BASIC_REACTION internally maps GUARD=1RP and PROTECT=2RP; uses authoritative M2 ResourceLedger PAY_REACTION_COST_FIXTURE with MP cost zero. Never accepts client-supplied RP price. No copy of resource state machine.
- phase_engine.gd: same M3.2 Window and queue; at EnemyAction completion logs defense_snapshot (EnemyActionId, effective damage recipient, Guard actor coverage, hit count, explicit-only follows_damage_recipient). Resets window after action so protections never leak to next EnemyAction.
- tests/test_m3_guard_protect.gd: positive, negative, multihit, first-Protect-only, AOE/MULTI reject, status, no-Card cost, cancel-before-Protect skip, multiple windows, replay and zero RP fee invariants.
- .github/workflows/godot-m3-3-guard-protect.yml: official Godot4.7.2 SHA512 and import, new M3.3 test, prior M3.2 50 + M3.1 61 + M1–M2 249 assertions and four legacy scripts.

## Event and gameplay boundary

EnemyActionDeclared -> ReactionWindowOpened -> draft/preview/reorder -> explicit Confirm -> charge RP through actual M2 -> GuardCoverageRegistered / AttackTargetRedirected -> ReactionExecuted -> EnemyActionFixtureResolved with defense_snapshot for M5. Later Protect on same attack cannot redirect chain and is ReactionSkipped without cost. Guard paid before a subsequent Protect does not receive a retroactive refund. If an earlier Reaction SP fixture cancels EnemyAction, pending Guard/Protect is skipped with reason TRIGGER_GONE, no cards and no fees. Player can Pass. No deadline or real-time auto-Pass.

M5 remains owner of actual hit/crit/defense/resist, Guard coefficient and rounding, Barrier absorption, HP damage, status effects and explicit follows_damage_recipient tags. M4 owns real magic counter/casting. This stage does NOT calculate damage or claim the deprecated 1.5sec UI timer was removed.

Status at authoring: SPECIFIED_NOT_TESTED. Must append final SHA, official CI run, exact cases and event/state hashes based on raw logs. M3 overall still blocked until M3.4–M3.5 accepted.
