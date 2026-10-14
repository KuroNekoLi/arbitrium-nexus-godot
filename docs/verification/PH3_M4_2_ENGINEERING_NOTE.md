# Phase 3 M4.2 — Casting Disruption and Focus Ward / Engineering Note

Status: M4_2_DISRUPTION_DOMAIN_VERIFIED — official Godot 4.7.2 independent CI PASS. Overall M4 NOT VERIFIED.

## Authority and prior gate
Library 05, 19 M-D22–24, 20 PRE3-R12–14, 21 and 23. Tested predecessor master 145dc24d2281f43a043f8a0dbb0fe9c8a7992e74; official Godot 4.7.2 M4.1 CI #38654241159 successful 645/645 named Domain cases. Only M4.2 in scope. Initial test plus max 2 corrective re-runs per same failing test group.

## Source implementation
- scripts/domain/m4/casting/casting_disruption_resolver.gd: immutable per-instance FocusWard → CastingStability before/after, event trace and interrupt threshold, Boss Break untouched.
- scripts/domain/m4/casting/focus_ward_resolver.gd: Focus Ward grants/absorbs ONLY casting disruption, not HP or Barrier.
- scripts/domain/m4/casting/casting_refund_policy.gd: M-D22 strictly partial MP quote from actual paid_mp in M2 cost receipt. Ratio and rounding explicitly BALANCE_PROVISIONAL, reject nonapproved settings, clamp at MaxMP, no free refund for cancellation, HP0 or Last Spell.
- scripts/domain/m4/integration/m4_domain_resolver.gd: Internal APPLY_CASTING_DISRUPTION_M4_FIXTURE under explicit gate and versioned effect catalogue; caller may not inject arbitrary power. Requires declared EnemyAction and closed Reaction Window; ON_HIT requires separately trusted M5 hit fixture and uses M3 Protect actual recipient. DIRECT requires matching casting_id and ignores Protect. Once Stability reaches zero: CastingInterrupted → ScheduledEffectCancelled → real M2 MPRestored → Casting CardInstance→Discard → ConcentrationEnded, atomic original-state transaction. Reject duplicate sources, invalid target/effects.
- scripts/domain/m2/integration/m2_domain_resolver.gd and m2/economy/resource_ledger.gd: use original RECOVER_MP authority and dedicated tagged Concentrating-CastCompatible reaction cost, not duplicated RP/MP logic.
- scripts/domain/m3/reaction/reaction_eligibility.gd and reaction_queue_resolver.gd: concentrated actor may react only when actual versioned SP definition explicitly declares cast_compatible, then pays RP+MP and moves held SP only on real Confirm. FOCUS_WARD_FIXTURE applies to matching active CastingInstance and emits FocusWardGranted. No basic Guard/Protect escalation.
- tests/test_m4_disruption.gd: positive, negative, atomicity and seed replay of two independent Full Chant actors, concentrated SP reaction, Protect forwarding, nonhit rejection, Focus Ward shielding, direct disruption, immediate partial MP refund, status/zone conservation.
- .github/workflows/godot-m4-2-disruption.yml: official Godot 4.7.2 SHA512/import; M4.2 new suite, predecessor M4.1 47, M3.5 101, M1–M3.4 497, four smoke scripts and saved failure logs.

## Scope limitations
M4.2 headless fixture-only API is NOT a public direct-stability-decrement command. This requires authoritative encounter effect content and trusted on-hit fixture input; full M5 hit/crit/Barrier/HP remains deferred. Focus Ward does not change HP. No Last Spell instability (M4.3) or caster HP0 invalidation (M4.4) or final M4.5 acceptance or UI countdown replacement. Testing uses provisional refund=1/2 FLOOR_FIXTURE and base stability10 without making either balance value canon.

## Evidence to add after actual CI
Record source HEAD, official CI run/job, M4.2 real executed cases, full 645 prior assertions, seed/event/final state hashes, repairs, remaining scope and final independent verdict.


## Executed evidence / final verdict — 2026-10-15 Taipei

- Initial source SHA 7afbd9001746056766c9dc38f5b1aa60d7138182 failed new M4.2 CI #38655515406 when the test accessed missing paid_mp on a legitimate CastingInstance. This identified a concrete M4.1→M4.2 receipt handoff gap, not a gameplay balance issue; raw failure logs were saved. Source SHA 8b8f9db878f3fd9a15eadd929cf534da4e188e9b fixed it by saving M2-authoritative actual paid MP/AP from SPCostReservedOnly. First correction successful official CI #38655859931 ran M4.2 51/51, all predecessors and 4 legacy scripts PASS.
- Additional eight independent P1-PRT-008 positive/negative oracles tested actual authorized ON_HIT fixture without Protect, no client-supplied power override, rejection without hit verification, duplicate hit rejection and wrong-caster refusal; no prior acceptance criteria were weakened. Final tested source SHA **8a808cb0ef685fa48633740c6ae4a3f60f370c83**.
- **Official completed/success Godot 4.7.2 CI:** https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38656070665, job 116166022604. Release ZIP SHA512 verified; engine 4.7.2.stable.official.ed1daf0bf, editor import PASS. Actual M4.2 test_m4_disruption.gd stdout **59/59 PASS**, 0 failures; M4_2_DISRUPTION_DOMAIN_VERIFIED. In the SAME CI, M4.1 47/47, M3.5 101/101 and M1–M3.4 497/497 PASS. **704/704 cumulative named Domain tests**, 4 legacy smoke scripts exit0.
- Fixed Seed **20261014**, **12** accepted real mixed casting, M3 Reaction, Ward, Protect, direct/on-hit and refund commands. Initial SHA256 **5aa5e836f5ed4812b932a4d33d64697a6163f3ebc9d41722ef158a64fc651426**; event SHA256 **d9f3f8781b59e0e61bd82112f9cad5f86e298400aaa1c8bda4b13aa9d4bc919c**; final state SHA256 **fa38ea93d554ea1dc8b63966a07647c2ecd7eb369b50c39709768bf34119e1d7**. Replay re-executes and compares exact event/state hashes, no mock MP credit.
- Specific events verified in order: FocusWardGranted via legal, manually Confirmed CAST_COMPATIBLE reaction (RP1/MP1 and card discard) → Protect C re-targets A's single-target hit to C → ON_HIT_CASTING suppressed against A → DIRECT_CASTING_INSTANCE bypasses Protect → FocusWard absorbs first 4 of 6 → later absorbs final 2 and reduces Stability → at zero CastingInterrupted → ScheduledEffectCancelled → M2 MPRestored → M2 CardZoneChanged Casting to Discard → ConcentrationEnded. Ordinary Full Chant paid_mp=2 was sourced from M2, provisional refund=1, AP/Overload unchanged, independent B casting remains active. No enemy damage was invented.
- Separate positive without Protect: a trusted and explicitly fixture-authorized ON_HIT source reduces original caster Stability by content-registered power4, not injected player power; no HP changes. Real M5 hit resolution and HP/Barrier/crit/Status are still absent. M4.3 Last Spell, M4.4 caster HP0, M4.5 overall integration, actual controller HUD and legacy timeout migration remain NOT VERIFIED.
- Provisional balance ratio 1/2, FLOOR_FIXTURE and base stability10 were test values only; no automatic approval as combat balance.

**Independent M4.2 Domain PASS. Overall M4 DOMAIN VERIFIED is not authorized before M4.3–M4.5.**
