# Phase 3 — M4 Domain Handoff to M5 and Presentation

Status: VERIFIED_DOMAIN — M4 HEADLESS FIXTURE SCOPE. Official final M4.5 CI passed 897/897 named assertions; real M5 still NOT IMPLEMENTED.

## Engineering authority
Source of truth: docs/combat/05_DUAL_CASTING_AND_INTERRUPTION.md, 07_REACTIONS_PROTECTION.md, 08_LAST_SPELL_EXHAUSTED.md, 20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md, 21_PHASE2_SPEC_ACCEPTANCE_REPORT.md, 23_PHASE3_EXECUTION_PLAN.md. M1 Model, M2 real CostResolver/AP/MP ledger/card zones, M3 authoritative phase+Reaction queue, M4 integration apply remain single source. Do not start another BattleState or second timeline.

## Contracts to M5 and Presentation
1. Chantless cost once / immediate SpellEffectDeferredToM5 contract; Full Chant cost once / Hand→Casting physical CardInstance → due Casting→Discard before AP/hand refresh; Concentration locks ordinary actions and permits specifically CAST_COMPATIBLE SP reactions.
2. Focus Ward absorbs casting disruption before per-instance Casting Stability and is NOT HP Barrier; Protect changes the actual recipient of verified ON_HIT effects. DIRECT_CASTING_INSTANCE targets casting_id even when Guard/Protect protects HP. Ordinary Full Stability0 => CastingInterrupted, cancellation, M2-only MP partial refund and card Discard, never refund AP/debt. Ratio provisional.
3. Last Spell independent one-use Full-only slot, M2 actual AP/MP cost, no hand/deck card; first destabilization delays once, later thresholds weaken with provisional amounts. Upon success LastSpellReleased→deferred M5 effect→Exhausted, team base AP stays6. Exhausted actor may be hit/healed/protected but cannot initiate actions.
4. CORE-02 HP0 before release immediately ActorIncapacitated→LastSpellInvalidated(CASTER_INCAPACITATED)→ScheduledEffectCancelled, never restore paid costs/once-used after Revive; after lawful release, later HP0 cannot roll back effects; tag Revive must preserve exhausted lifetime.
5. M4.2/M4.4 internal fixture command families can only be replaced by trusted M5 actual hit/damage outputs, not publicly accepted client instructions. Same Seed+Ruleset+ContentConfig+CommandTape => same canonical state/event hashes and stable event_seq.
6. M3.4 Smart/Always Ask/Quick presentation policy is only a UI projection; NEVER silently auto-Pass an actionable Reaction. The legacy prototype 1.5s countdown still requires Presentation migration; no UI mode shall alter Domain costs or legality.

## Still outside M4
M5: real hit/crit/damage/DEF/RES, barrier, break/combos/status, Boss AI, precise target death semantics, actual Last Spell effects and Victory outcomes. Presentation: landscape battle UI, confirmation and reaction controls, i18n, animations, gamepad/touch, timer removal and player playtest. Balance: Stability formula, MP partial refund rate, Last Spell weakening/cast resonance effects are not canon.

## Completed gate and next owner

Completed official Godot4.7.2 [M4.5 CI #38665591370](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38665591370), job116196697087, tested SHA 7dc487f3f6ad1021f73293d7de222f1700fb819f. M4.5 new 41 Integration + 38 Replay, all 818 predecessors and four legacy runners passed; **897/897** named Godot Domain assertions. Seed20261014, 34 commands. Event SHA256 82dfac4a2ea16cf30382a095d0881d74c5d90995eb01fad6f45fc61297d71a25, final SHA256 c99b758c59c044c6c9fea8dae5306eac877c1a6b9381e8529578468d3f9ce7f6. Full reports and the single corrected replay-type failure are documented in PH3_M4_5_ACCEPTANCE_REPORT.md.

Only headless fixture Domain M4 is VERIFIED. **M5 remains the next separately commissioned milestone** to replace trusted internal hit/HP0 bridges with actual authoritative damage/hit pipeline. Preserve M2 cost/card conservation, M3 Reaction window semantics, and deterministic replay; no playable HUD or actual Boss damage is claimed.
