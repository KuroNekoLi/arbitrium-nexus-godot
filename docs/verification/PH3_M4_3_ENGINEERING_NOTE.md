# Phase 3 M4.3 — Last Spell Engine Engineering Note

Status: IMPLEMENTED_AWAITING_ACTUAL_CI. Do not certify success before actual completed official Godot 4.7.2 test logs.

## Binding specifications and prerequisite
Authority: docs/combat/08_LAST_SPELL_EXHAUSTED.md, 20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md, 21_PHASE2_SPEC_ACCEPTANCE_REPORT.md and 23_PHASE3_EXECUTION_PLAN.md. The latest previously verified source master b8fae6ae3af3310b2be0b386910dab5b8dc870ae and official successful M4.2 CI #38656317851: **704/704 prior Domain named assertions**, four prototype headless runners. User explicitly asks ONLY M4.3, not M4.4 or M4.5.

## Minimal files and authority delegation
- NEW scripts/domain/m4/last_spell/last_spell_resolver.gd: independent Last Spell skill slot and unlock, per-actor per-battle once, public pre-confirm read-only cost and irreversible-risk quote, only Full Chant; actual AP/MP charge once via existing authoritative M2 cost system. No CardInstance or Hand/Draw/Casting/Discard zone move. Track one casting instance per actor on existing BattleState. At valid due release => legal M5-deferred effect event and actor EXHAUSTED; preserve BaseAP6.
- NEW scripts/domain/m4/last_spell/last_spell_instability_resolver.gd: instability threshold first delays release exactly once, later threshold applies a versioned provisional weakening modifier with no further delay or infinite stacking. Ordinary M-D22 CastingInterrupted MP refund is not applicable to Last Spell disruption.
- UPDATED scripts/domain/m4/integration/m4_domain_resolver.gd: ACTIVATE_LAST_SPELL_M4 requires explicit confirmed flag, legal player phase, exact event seq and unique command ID; M4.2 direct/authorized hit disruption branch routes Last Spell to dedicated destabilization, not ordinary cancellation/refund.
- UPDATED scripts/domain/m2/integration/m2_domain_resolver.gd: internal COMMIT_LAST_SPELL_COST_M4 directly reuses M2 Cost.apply and cost receipts; no cloned money model and no phantom SP CardInstance.
- UPDATED scripts/domain/m4/casting/casting_instance_resolver.gd: one-cast-per-actor invariants, special last spell with no associated CardInstance and persistent used-once marker, while normal Full still holds exact card in Casting.
- UPDATED scripts/domain/m4/casting/casting_timeline_resolver.gd: at next specified Phase Boundary resolve pending Last Spell before M3 outcome, M2 AP renewal and hand refill; no release during wrong round.
- NEW tests/test_m4_last_spell.gd: verified quote/confirmation/full-only/locked/once/cost/exhaustion, first destabilization delay, second weakening, no further delay, separate cost and card zones, exact event order, fixed-seed command tape and fail-closed.
- NEW .github/workflows/godot-m4-3-last-spell.yml: verified Godot 4.7.2 SHA512 download and import; run M4.3 and all previously verified M4.2 59, M4.1 47, M1–M3.5 598 (704 total predecessor named assertions), four prototype scripts and upload failure logs.

## Bounded rules and unresolved future gates
Only explicitly versioned BALANCE_PROVISIONAL base/reset Stability10 and weakening modifier3/4 used for this fixture. User-approved functionality: initial Last Spell planned round1→round3, first threshold delays once to round4, subsequent thresholds weaken not cancel; successful cast yields EXHAUSTED (NOT INCAPACITATED), ally can still be targeted or protected, BaseAP6 remains. No ordinary MP refund. The second-click Presentation modal is NOT implemented, although Domain requires explicit confirmation and offers cost/risk info.

M4.4 still MUST handle caster HP0 before release by immediate forced invalidation and ScheduledEffectCancelled, no repayment or revive continuation. M4.3 deliberately fails closed on this with LAST_SPELL_HP0_NEEDS_M4_4_INVALIDATION. No false real M5 HP damage or Last Spell animation. Do not label overall M4 DOMAIN VERIFIED until M4.4 and M4.5 actually pass.

## Actual CI proof to append
Source SHA, official Godot version/run/job, seed and event/final state hashes, executed case count, 704/704 predecessor assertions, all script exit codes, corrections and limitations. Repair budget initial test + at most two corrective reruns for the same failing group; never remove approved tests.
