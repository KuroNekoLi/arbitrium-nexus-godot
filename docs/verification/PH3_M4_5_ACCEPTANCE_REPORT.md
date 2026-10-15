# Phase 3 — M4.5 Integrated Casting Acceptance Report

Status: M4 DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE. Actual official Godot4.7.2 CI passed.

## Authority, prerequisites and scope
Sources: docs/combat/05_DUAL_CASTING_AND_INTERRUPTION.md, 08_LAST_SPELL_EXHAUSTED.md, 20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md, 21_PHASE2_SPEC_ACCEPTANCE_REPORT.md and 23_PHASE3_EXECUTION_PLAN.md.
M4.4 verified master 8aacc62e99a166faaab4c124a42619a978ac9901, official successful https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38661029564. Predecessor named assertions: M4.4 59, M4.3 55, M4.2 59, M4.1 47, M1–M3.5 598 = **818/818**, plus four legacy runners.

## New M4.5 integrated deliverables
- tests/fixtures/m4_5_scenario.gd: deterministic accepted real M4 reducer command tape of A Last Spell, B Full, C Chantless and Full, M3 queued CAST_COMPATIBLE Ward and Protect A, ON_HIT suppression from Protect, DIRECT casting_id destabilizing A, ordinary Full B due at round2 before AP/draw, fresh Protect B redirecting HP0 from A, C Full due at round3, A HP0 later invalidating Last Spell, round4 no deferred effect and explicit Revive without refunded once-use. Config is versioned test-only (not approved final magic damage or HP balancing).
- tests/test_m4_integration.gd: positive and negative cross-slice code path checks not satisfied by re-running predecessor suites; M2 payment, card/zone uniqueness, ward/protect transaction at Confirm, direct-vs-on-hit after redirect, due order and zero refunds, CORE-02 same-boundary event ordering, reviving used-once validity.
- tests/test_m4_replay.gd: full authoritative seeded replay, repeated M1 canonical state/event SHA256, event sequence/receipts, actual three M3.4 UI-policy projections, stale/duplicate/unauthorized hit rejection, changed content changes replay identity, changed Seed differs.
- .github/workflows/godot-m4-5-acceptance.yml: official Godot 4.7.2 ZIP SHA512 + import, new integration+replay, ALL M4.1–M4.4 and M1–M3.5 predecessor suites (818 named), four legacy smoke scripts; always-upload logs.
- docs/verification/PH3_M4_5_ACCEPTANCE_REPORT.md and PH3_M4_HANDOFF.md: formal engineering and M5 handoff, finalized only after actual CI.

## Headless fixture boundary, not false claims
All hit/disruption/HP0/Revive events use M4.2 and M4.4 **trusted internal fixtures**, NOT the unimplemented real M5 hit/damage calculation or actual gameplay Revive/HP/Barrier/crit/status. Do not expose these as end-user commands. Combat damage, Boss AI, Last Spell actual effect, game HUD and UI two-step confirmation, animation/i18n/old Reaction countdown are not M4.5 deliverables. Casting Stability 10, refund ratio 1/2 and Last Spell weaken 3/4 are BALANCE_PROVISIONAL only.
User-approved CORE-02 and CORE-01 event precedence remain binding. Same failing group: initial test + max 2 corrective reruns, never remove required assertions for green.

## Final official M4.5 acceptance — 2026-10-15 (Taipei)

Official completed SUCCESS: [GitHub Actions #38665591370](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38665591370), job 116196697087, tested source SHA **7dc487f3f6ad1021f73293d7de222f1700fb819f**. Verified SHA512 download of official Godot 4.7.2.stable.official.ed1daf0bf and Godot editor import PASS.

The same CI successfully ran:
- M4.5 test_m4_integration.gd **41/41 PASS**, marker M4_5_INTEGRATION_DOMAIN_ACCEPTED
- M4.5 test_m4_replay.gd **38/38 PASS**, marker M4_5_REPLAY_DOMAIN_ACCEPTED
- All prior M4.4 59 + M4.3 55 + M4.2 59 + M4.1 47 + M3.5 101 + M1–M3.4 497 = **818/818 predecessor Domain assertions PASS**
- All four legacy headless prototype regression scripts exit0
- Overall **897/897 named Domain assertions PASS**; zero failing assertions; complete job success

### Fixed-seed reproducibility

**Seed 20261014, 34 accepted mixed M2/M3/M4 commands.** Both independently executed M4.5 Integration and Replay printed the SAME canonical values:
- Initial state SHA256 **38f22585ad007413001f460772cbe2400c0b10e6601d6e03a4f3820490e49bdd**
- Event SHA256 **82dfac4a2ea16cf30382a095d0881d74c5d90995eb01fad6f45fc61297d71a25**
- Final state SHA256 **c99b758c59c044c6c9fea8dae5306eac877c1a6b9381e8529578468d3f9ce7f6**

This scenario exercises A Last Spell, B ordinary Full, C Chantless and Full, Focus Ward via B CAST_COMPATIBLE while Concentrating, C Protect A and on-hit suppression, direct CastingInstance disruption and Last Spell delay, actual B/C Casting-zone releases before M2 AP/draw, a fresh Protect B intercepting A hit and becoming incapacitated, later HP0 invalidating A Last Spell before release, no Last Spell output at the next due phase, and tagged Revive without restoring once-use. Cards retain their actual M2 zones and real M3 Phase/Reaction queue. Replay verifies monotonic events, command receipts, unchanged inputs, duplicate/stale rejection, different content/seed and three M3.4 UI modes cannot change Domain results.

### Actual failure and repair record

First submission source SHA **7951a4014d3e83c214d9a23942074ab2fe5102fb**, [CI #38662179634](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38662179634): Integration 41/41 passed, Replay parse failed because typed Array[Dictionary] was passed into Model.state_hash(Dictionary). No actual gameplay rule failed; CI correctly skipped following regressions and uploaded raw logs.
First and only correction SHA **7dc487f3f6ad1021f73293d7de222f1700fb819f** wrapped the command tape in a Dictionary for the original canonical hash. No gameplay logic, test count or accepted test oracle was changed or removed. Corrected CI #38665591370 passed all 897/897 + four prototype scripts. This stayed within the initial + two repairs cap.

### Certified meaning and exclusions

**M4 DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE.** M4 engine transaction, scheduled events, CORE-02 forced Last Spell invalidation, Replay and existing M2/M3 invariants are certified. It does NOT demonstrate M5 real HP/damage/crit/Barrier/Boss Break/status/Combo/Boss AI, actual Last Spell damage, actual Revive card implementation, UI second confirmation, playable HUD, touch/gamepad, localization or animation. M4 trusted internal hit/HP0/Revive fixtures are NOT end-user-accessible commands. MP 1/2 refund, Stability10 and 3/4 weakening remain BALANCE_PROVISIONAL rather than canonical tuning; CORE-01 simultaneous-win actual damage outcome is M5 scope. Next milestone M5, independent authorization required.
