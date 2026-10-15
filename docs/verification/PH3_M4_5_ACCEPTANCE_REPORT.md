# Phase 3 — M4.5 Integrated Casting Acceptance Report

Status: IMPLEMENTED_AWAITING_ACTUAL_CI. Do not certify M4 Domain until both new suites, every predecessor M1–M4.4 suite and 4 legacy scripts pass in official Godot4.7.2.

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

## CI evidence to append
Tested commit, final successful official Godot version+run/job and exit codes; count exact executed M4.5 Integration+Replay named cases, 818 predecessor counts, 4 legacy, seed/tape length/initial/event/final state hashes; failures, corrections and remaining M5/Presentation gates. Only after full success can assert M4 DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE.
