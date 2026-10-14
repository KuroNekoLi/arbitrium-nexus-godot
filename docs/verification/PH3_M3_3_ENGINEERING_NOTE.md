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

Current status: M3_3_BASIC_DEFENSE_DOMAIN_VERIFIED, independently certified below. Full M3 remains blocked until M3.4 and M3.5.


## Actual CI certification — 2026-10-14

- First source commit: 4b5b3bc921c878fc2541fd758976849cb0f174f4. Its initial CI run https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38596366026 passed the leading Guard, Protect, targeting and skip oracles but failed later at the second-window fixture. Cause: the test helper reused command_id "setup-open" across different EnemyActions; the existing PhaseEngine correctly rejected this duplicate. Corrected ONLY the test helper to use action-scoped unique IDs in tested source SHA **42d0ac055b457f96123b4a669e558b0bcc3bcb65**; no test expectation was weakened or gameplay rule changed.
- **Final successful official Godot 4.7.2 CI:** https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38596728929, job 115965263542, completed/success. Godot version 4.7.2.stable.official.ed1daf0bf and release SHA512 verified, import exit0. M3.3 test suite 54 executed / 54 passed / 0 failed, final stdout marker M3_3_BASIC_DEFENSE_DOMAIN_VERIFIED.
- Same-run mandatory regressions: M3.2 **50/50**, M3.1 **61/61**, M1–M2 **249/249**, all passed; **414/414** total named Domain assertions plus four legacy smoke scripts exit0.
- Fixed replay seed: 20261014. Initial state SHA256 **41079c151d2ef278314cc99cfe71a419d1fdd309054508f2f612e75be91cc124**. Event SHA256 **33da67eb4cd91d0e1b3ce0a5ca3d59d76ac6f5ff993f85fd57f5e6593853d077**. Final state SHA256 **153aa594a108b70cecd4bb5e12188429cf636ad555e2727963c508455d6da9fa**. Two same-seed executions have exact hashes.
- Tested positive/negative: SP-free Guard for one EnemyAction with three hit_count, 1 RP, no MP or CardInstance; exact event timing and zero damage formula hardcoding. Single-target Protect 2 RP, original target A -> guardian B before M5 hit; three-hit scope. Second Protect C becomes ReactionSkipped(PROTECT_ALREADY_REDIRECTED) without charge or actor quota. Guard before Protect retains previously paid RP; Guard queued after redirect fails JIT eligibility and skips free. AoE/MULTI and direct casting disruption reject Protect. Invalid target, self-protect, unprotectable, incapacitated/exhausted/concentrating guardian reject. Living EXHAUSTED ally may be protected (PRE3-R14); dead target may not. First Counter SP fixture cancels source, pending Protect skips with reason TRIGGER_GONE and no RP/card/MP. Basic commands cannot inject a custom RP fee. All protections are action-scoped and never automatically continue into a second EnemyAction.
- Actual defense_snapshot handoff includes source_enemy_action_id, guard_actor_ids, protected_by_actor_id, original_target_actor_id, damage_recipient_actor_id and hit_count, with only explicit follows_damage_recipient status transfer. Numerical Guard percent, actual hit/crit/defence/resistance, Barrier, HP/status calculations and CastingInstance disruption remain NOT IMPLEMENTED until M5/M4. Old UI automatic countdown remains a future presentation migration; no timer exists in this Domain. M3.4 modes and M3.5 end-to-end remain NOT_EXECUTED.

**Verdict: M3.3 independent Domain PASS, not the full M3 DOMAIN VERIFIED gate.**
