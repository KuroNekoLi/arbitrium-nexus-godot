# Phase 3 M2.4 — Free Swap and Card Events

## Normative contracts

- Library 19 M-D26–M-D30: **USER_APPROVED**, one actor-specific free hand-SP swap per Player Phase, zero AP/MP, independent allowance per actor, no quota carry-over; M-D27 selected CardInstance temporarily isolated to prevent same-instance redraw; M-D28 formal CardDiscarded and successful CardDrawn trigger events; M-D29 no candidate at PRECHECK => entire action rejected, no events/no quota/no RNG mutation; M-D30 explicit discard triggers BEFORE drawing, then draw triggers, then selected instance enters discard.
- Library 20 PRE3-R11: **DELEGATED_DEFAULT**, valid PRECHECK followed by a discard trigger exhausting legal replacements => CardDrawFailed(POOL_CHANGED), no rollback of legal effects, swap quota consumed and original finally discarded. No phantom CardDrawn, no infinite retries.
- Library 20 PRE3-R12: regular Full Chant transfers Hand→Casting and later Casting→Discard. This step tests casting-zone exclusion; the actual M4 casting resolver is future work.

## Design / boundary

Code: scripts/domain/m2/cards/free_swap_resolver.gd, card_trigger_dispatcher.gd and amended card_zone_resolver.gd. Works on the independent M2.3 12-SP / 36-instance zone snapshot, **not** legacy DeckProfileStore or M1's battle reducer. Snapshot owns PLAYER_PHASE, increasing player_phase_index, actor-specific boolean swap quota and seen_swap_command_ids. M3 MUST authoritatively call open_next_player_phase only on legitimate new phases and supply actor eligibility (Concentrating unresolved); the free-swap module must not infer real game turn order from a UI timer.

Input command: type=FREE_SWAP, actor_id, card_instance_id, command_id, expected_event_seq, expected_phase_index. Stale or repeated IDs, wrong actor/card/zone, exhausted phase quota, non-player phase or ineligible actor all reject atomically. Event hashes/states include quota and seen command IDs. Direct phase-index forgery isn't a public gameplay command; M3 controls that lower-level boundary.

Ordered happy path: CardZoneChanged(Hand→Isolated) → CardDiscarded (formal while isolated) → each lawful discard effect / corresponding CardZoneChanged + CardTriggerResolved or CardTriggerSkipped → normal seeded Draw, optional reshuffle, CardDrawn → lawful draw effects → CardZoneChanged(Isolated→Discard) → FreeSwapCompleted. Selected instance never enters drawable pool during the attempt; the final event records draw_succeeded, drawn_instance_id, ap_cost=0/mp_cost=0.

PRE3-R11: identical beginning and card conservation; when legal discard effects relocate the final alternative, emit CardDrawFailed(reason=POOL_CHANGED), **do not** emit CardDrawn, move original Isolated→Discard, mark quota/command consumed and emit FreeSwapCompleted(draw_succeeded=false). Rejected PRECHECK has no trace, no consumption. A failed legitimate effect execution after matching is recorded as CardTriggerSkipped and cannot roll back earlier lawful effects.

Dispatcher intentionally supports an explicitly declared, bounded/non-recursive **MOVE_CARD** rule set for this M2.4 headless contract: rules include unique effect_id, on CardDiscarded/CardDrawn, source_definition_id and optional source_actor_id, target actor/instance/from/to. No content card is silently granted such a trigger. Isolation cannot be a trigger source/destination; all effect moves use ZoneResolver validation. Actual specialized HP/MP/status effects and their reactive chain policy are M4/M5 or M2.5 integration, **not** claimed implemented here. Effects run once in supplied stable order, max 32 rules, with no recursive event processing; no zero-cost trigger loop.

## Acceptance and status

Runner tests/test_m2_free_swap.gd; required M26-SWAP-001, M27-SWAP-002, M29-SWAP-003, M30-SWAP-004, PRE3-11 and PRE3-12 category plus no-pool rejection, inter-actor isolation, 0 AP/MP event evidence, stale/duplicate command, phase reset, event order, CardDrawn trigger, terminal pool change, normal reshuffle, seeded replay/hash and zone conservation. Test fixture definitions and trigger effects are explicitly fixture-only, not approved actual SP card content.

**Before CI execution: SPECIFIED_NOT_TESTED**. Must record actual official Godot 4.7.2 SHA / log / run / test counts afterward. M2.4 domain pass does NOT close M2.5 full integration gate; that workflow deliberately fails closed until the full cross-module replay oracles are authored.
