# Phase 3 M4.4 — Last Spell Forced Invalidation Engineering Note

Status at implementation: IMPLEMENTED AWAITING ACTUAL GODOT CI; do not certify until actual run completes.

## Authority and prerequisite
User-approved CORE-02 and PRE3-R13/14/15 in docs/combat/08_LAST_SPELL_EXHAUSTED.md, 20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md, 21_PHASE2_SPEC_ACCEPTANCE_REPORT.md, 23_PHASE3_EXECUTION_PLAN.md. Previous master 9a071e0b6fffd75da3a8c208f52f65e80ac67613, official M4.3 [CI #38658513064](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38658513064) 759/759 prior named Domain assertions and 4 legacy smoke runners passed.

## Implementation
- NEW scripts/domain/m4/casting/casting_invalidation_resolver.gd: pure post-verified HP0 forced invalidation; actor status becomes INCAPACITATED, hand/draw/discard frozen, pending Last Spell immediately invalidated, schedule canceled, one-use remains permanently committed and AP/MP/Overload refund zero. Ordinary Full Chant moves its physical Casting CardInstance to Discard using existing M2 transaction, no M-D22 refund. Tagged Revive returns HP without reinstating spent Last Spell.
- UPDATED scripts/domain/m4/integration/m4_domain_resolver.gd: internal APPLY_INCAPACITATION_M4_FIXTURE / APPLY_REVIVE_M4_FIXTURE commands gated by trusted config and M4_4_TRUSTED_FIXTURE_ONLY effect catalogue. HP0 requires already declared M3 EnemyAction, completed Reaction Window, matching source id, authorized verified hit fixture and actual target recipient after Protect redirect. No arbitrary caller hp/damage/refund overrides. Atomic same-boundary events ActorIncapacitated then LastSpellInvalidated then ScheduledEffectCancelled then BattleOutcomeEvaluated, with existing M3 victory priority. Revive must be explicitly tagged and only from Incapacitated HP0.
- UPDATED scripts/domain/m4/last_spell/last_spell_resolver.gd: successful release records lifetime resolved marker; subsequent HP0 and Revive preserve EXHAUSTED and cannot retroactively invalidate an effect already emitted.
- NEW tests/test_m4_incapacitation.gd: T1 commit & T3 scheduled, T2 EnemyAction HP0, immediate cancellation and T3 no release, Revive cannot restart, prior cost retained, ordinary Full Chant HP0 card Casting to Discard without interrupt refund, success-first vs late HP0, negative untrusted/mismatched/duplicate/stale, replay.
- NEW .github/workflows/godot-m4-4-invalidation.yml: official Godot4.7.2 SHA512 verified ZIP, editor import, new suite and prior M4.3 55, M4.2 59, M4.1 47, M1–M3.5 598, and 4 old prototype scripts.

## Explicit M4.4 boundary
These HP0 and Revive commands are internal, versioned trusted encounter FIXTURES, NOT a live player-accessible kill or healing engine. Genuine M5 damage, hit confirmation, HP/Barrier statuses and Revive card implementation remain deferred. No fake Last Spell HP damage: success emits LastSpellEffectDeferredToM5 only. Ordinary healing does not automatically revive; post-release Exhausted survives a tagged Revive.

## Release gate
M4.4 VERIFIED only after official Godot4.7.2 CI recorded actual case counts, replay Seed, initial/event/final SHA256, 759 prior named tests, 4 legacy runners. Repair limit: first run plus at most two corrected reruns per failing group; third failure stop with retained logs, never weaken accepted gameplay assertions. Overall M4 still requires M4.5 integration acceptance.
