# PH3 — M3.5 Integration Acceptance and Regression

Status: VERIFIED — actual official Godot 4.7.2 GitHub Actions CI PASS. Never label M3 DOMAIN VERIFIED without real successful official Godot 4.7.2 CI and complete M1–M3.4 regression.

## Scope, authority, and gate

Sources: docs/combat/07_REACTIONS_PROTECTION.md, docs/combat/20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md, docs/combat/23_PHASE3_EXECUTION_PLAN.md and verified M1–M3.4. Predecessor test counts: M1–M2 249, M3.1 61, M3.2 50, M3.3 54, M3.4 83 — 497 authoritative named assertions. Reuse all previous resolvers without duplicating ResourceLedger, card zones, PhaseEngine, Reaction Window/Queue or UI Mode domain policy.

## Deliverables

- scripts/domain/m3/integration/m3_domain_resolver.gd: thin reducer boundary delegates to ACTUAL M3 PhaseEngine and authoritative M2 atomic resource/card transactions. It adds invariant checks, immutable rejection enforcement, canonical state/event hashes, deterministic replay receipts, and M3.4 read-only mode projection. Does not reimplement any mechanics.
- tests/fixtures/m3_5_fixture.gd: fixture-only 3 allies x12 SP instances + 1 Boss with 4 publicly ordered EnemyActions; explicit BALANCE_PROVISIONAL basic attack profile and synthetic reaction Counter and independent support. These are not actual M4/M5 magic or approved content cards.
- tests/fixtures/m3_5_scenario.gd: composes a real 2-full-round command tape from actual integrated transaction outcomes, with generated authoritative WindowIds, EnemyActionIds, event sequence and hand CardInstance IDs.
- tests/test_m3_integration.gd: 2-round workflow, first Action counter -> subsequent Protect skipped at zero cost while independent support executes, single-target 3-hit Guard then Protect redirect, AOE multi-hit Guard and invalid Protect, RP reaching zero then truly empty Window, enemy end, phase renewal and hands replenish to 4, second PlayerPhase A-A-B-A immediate action order, second Enemy Phase 4 explicit Passes, third player round opens. Resource/card guardrails and negative stale, duplicate, premature and no MOVEMENT.
- tests/test_m3_replay.gd: full tape with fixed seed, canonical event and final state SHA256, receipts, repeated same-seed/state and mode-independence across Smart, Always Ask, Quick; invalid stale, duplicate and premature commands; mutated configuration, changed seed and hand conservation.
- .github/workflows/godot-m3-5-integration.yml: official Godot 4.7.2 release with SHA512, real import and both new M3.5 suites; all 497 preceding Domain assertions, 4 legacy smoke scripts and full logs upload. Any failure must leave the Gate red.

## Scope boundaries

M3.5 verifies the **headless M3 fixture domain only**: Guard basic 1RP for all eligible multi-hits in one EnemyAction, Protect basic 2RP redirects a single-target attack before future hit; same-window execution quota and skipped invalidated Protect no debit/card, shared 6 RP cap from existing M2; empty Window only when truly no Reaction; never time-driven Pass even with Quick. Commands and their receipt hashes determine results, not UI prompts/FPS.

No actual enemy attack HP calculation, crit/hit/DEF/RES/Barrier, numerical Guard 40% coefficient, or Status effects: those belong to M5. Counter and Support are explicitly synthetic M3.2 reaction fixtures, not real M4 casting interruptions; true CastingInstance/LastSpell are M4 scope. Legacy scripts/main.gd 1.5s countdown, real HUD, input modes and translations remain a separate Presentation migration even after this Domain gate. Do not say PLAYABLE VERIFIED. Real queued incapacitation from M5 damage cannot be certified until actual HP/status pipeline exists; the PRE3-R04 cancellation fixture tests existing free-skip behavior only.

## Evidence to append after CI

Record exact source and document HEAD SHA, official Actions run and Godot version/SHA512, integration and replay case counts, all predecessor regression counts, seed, command count, event and final state hashes, repairs/retries and cross-milestone limits. Only with fully successful CI can the final verdict be M3 DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE.


## Final executed CI evidence (2026-10-14; UTC logs)

- Tested source commit **e638626a3c9fe44c2c4d172d04e1b409a9af08e0**. Official successful CI: https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38601022642 ; job 115979993873, completed/success. Godot **4.7.2.stable.official.ed1daf0bf**; official binary download checksum SHA512 PASS; editor import PASS; test stdout and all exit codes were checked, with logs uploaded as the workflow artifact.
- M3.5 integration actual stdout: **61 executed / 61 PASS / 0 failed**; exact marker M3_5_INTEGRATION_ACCEPTED. M3.5 full deterministic replay stdout: **40 executed / 40 PASS / 0 failed**; exact marker M3_5_REPLAY_ACCEPTED.
- Full predecessor suites executed in the SAME official CI: M3.4 **83/83**, M3.3 **54/54**, M3.2 **50/50**, M3.1 **61/61**, M1–M2 **249/249** (M1 30, M2.1 38, M2.2 43, M2.3 46, M2.4 32, M2.5 resource invariants 14 / replay 6 / integration 40). **Total 598/598 actual named Domain assertions passed**. All 4 legacy prototype test scripts exited 0.
- Test seed **20261014**, **47** real accepted phase/Reaction commands across two Enemy Phases and 3 Player Phase boundaries; source ruleset Model.RULESET_VERSION and content Model.CONTENT_VERSION, existing M2-approved 36 independent CardInstances conserved, no M4/M5 invented effects. Initial state SHA256 **435fe62907f8f5006bfb5fb201db0a54207bc06694173dc172c2757b94dc5430**; full event SHA256 **05599b881ad2ba6ee37e9cd1b2cc89ce9b6d97ce1e7b53e1ec58ea439ae17717**; final state SHA256 **25ca6dfaee05dc68d175adcea0392a679248b477d8d3bbdc9611a96714611b66**. Repeated same-seed Replay has identical event & final state hashes; 47 receipts match the 47 accepted commands.
- Validated cross-module assertions: cross-Window and cross-action shared RP, real M2 cost and CardZone transactions, cancellation fixture causing free downstream Protect skip, independent Support after cancellation still executed, multihit Guard and Protect before damage, AOE Protect denied, RP-zero empty Window, PlayerPhase opening renew resources + draw-to-four, player immediate A→A→B→A, next Enemy Phase explicit Pass across all 4 actions, clean third Player Phase, duplicate/stale/premature command rejection and invariant fail-closed, Smart / Always Ask / Quick canonical identical results despite untrusted elapsed-time/FPS hints.
- **Audit repair evidence:** first commit ed85ba1aeb0b3b9e1169c1ed4e5d88fe2b832c7f had malformed workflow YAML (the workflow could not start its job). Fixed YAML at commit 8d1f146766e8ccb045c668560a463ab8eb864c8b. Actual CI run #38600824010 then ran Godot M3.5 integrated suite **61/61 PASS**, but its separate replay suite failed GDScript parsing at line70 due a multi-line lambda assertion, not due gameplay. Corrected that test-only assertion using an explicit loop in the tested commit e638626a3c9fe44c2c4d172d04e1b409a9af08e0, without modifying approved mechanics or weakening any named test. Final run #38601022642 completed all gates successfully.
- **Precise gate declaration:** M3 DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE. M3.1 through M3.5 are independently passing. M4 true spell/casting interruption and Last Spell; M5 hit/crit/Guard coefficient/Barrier/HP/status/AI; Presentation HUD, i18n and legacy reaction timer replacement remain NOT_VERIFIED. This is not a playable battle, no actual 120-second UI interaction was executed, and the simulated counter does not constitute M4 implementation.

## Final M3.5 exact test case evidence

Both source runner files are in tests/ and verified by Godot CI. The 61 integration IDs and 40 replay IDs have been added verbatim to the adjacent PH3_PHASE12_TEST_INVENTORY.md. Factual evidence is the completed workflow logs rather than this document alone.
