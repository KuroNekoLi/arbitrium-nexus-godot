# PH3 M3.4 — Reaction UI Mode Contract — Engineering Note

## Authority and scope

Canonical: docs/combat/07 P1-D05 and CORE-04 (2026-10-14 USER_APPROVED), docs/combat/20 CORE-04 and 23 M3.4. Prior passing gates: M1–M2 249/249; M3.1 61/61; M3.2 50/50; M3.3 54/54; last predecessor SHA f7191d2c8b9c66f1afdf963661aba447ead2af23.

This work is DOMAIN ONLY: not a rendered Godot HUD and not a change to scripts/main.gd, whose old 1.5-second reaction timer needs an explicit later Presentation migration.

## New source and tests

- scripts/domain/m3/reaction/reaction_presentation_policy.gd: pure stateless policy, accepts M3 PhaseEngine snapshot and SMART (default), ALWAYS_ASK or QUICK plus optional presentation hint. Returns window/action identity, prompt prominence, persistent affordance, i18n string key identifiers, safe edit and decision commands, explicit pending/blocked flags, and no auto-Pass, no auto-Confirm, no auto-spend, no deadline or timer. Does NOT call PhaseEngine.apply, modify M2 resources or store UI mode in Battle State.
- tests/test_m3_ui_modes.gd: headless positive/negative cases; same snapshot gives same legality/decision requirements across modes and no mutation; real Guard-only window; Smart major vs minor presentation distinction; Always Ask always prominent, Quick compact; no prompt on genuinely empty window; explicit Pass; rejected premature EnemyAction completion; simulated elapsed 120 and 86400 seconds and FPS/device perturbation; same full mixed M3.3 Protect/Guard confirmed command tape across all 3 modes with exact event/state SHA256 and card/resource conservation. UI-only or malicious time fields passed with commands have no effect.
- .github/workflows/godot-m3-4-ui-modes.yml: independent official Godot 4.7.2 ZIP verified via SHA512, editor import, M3.4 acceptance, M3.3 54, M3.2 50, M3.1 61 and M1–M2 249 asserted regressions, four legacy scripts and audit artifacts.

## Smart, Always Ask, Quick exact contract

SMART: for presentation-only significance=MAJOR show a prominent modal; significance=MINOR use a quiet but persistent affordance; absent/unrecognized significance falls back to conservative prominent modal. Major hazard numerical scoring remains TBD, no invented threshold. The screen can be visually nonmodal at minor significance, but the DOMAIN cannot resolve EnemyAction until explicit Confirm or Pass.

ALWAYS_ASK: prominent for every actual DRAFTING window regardless of threat hint. Never display an empty CLOSED window.

QUICK: compact persistent affordance and fewer future UI clicks, but never implicit pass or RP payment. No real-time timer or auto-pass after 120 seconds, even with low FPS, animations or a controller. The tests simulate elapsed_seconds as untrusted input; they do not literally run a screen for two minutes.

ALL modes: legal Reaction/SP/Guard/Protect costs and targeting, queue ordering, explicit decision, JIT effects, RP debits, CardInstance zones, replay RNG/events and state hashes are controlled EXCLUSIVELY by M2/M3.1–M3.3. UI prominence is not authorization. If window is DRAFTING, flags blocks_enemy_resolution and requires_explicit_player_decision remain true regardless of should_block_prompt. CLOSED after explicit Pass/Confirm, or truly empty CLOSED with NO_LEGAL_REACTION, may proceed.

## Not implemented / release boundaries

No real UI mode widgets, touch/keyboard/controller handling, i18n string resources, old UI countdown removal, automatic Smart threat classifier, spell release or HP damage. All of those are deferred to Presentation/M4/M5 as applicable. No Guard numerical percentage promoted to approved. M3.5 combined integration acceptance is still a separate gated milestone; M3 DOMAIN VERIFIED not claimable after M3.4 alone.

Status at authoring: SPECIFIED_NOT_TESTED. Record actual tested SHA, CI URL, suite counts, hashes and repair notes after reading raw Godot stdout.
