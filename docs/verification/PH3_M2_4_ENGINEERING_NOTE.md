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

## Executed CI attestation — 2026-10-14

- Source commit: [ff561ae3b86d49e5249c1ac755ebb876051d53b6](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/ff561ae3b86d49e5249c1ac755ebb876051d53b6), followed by CI-only correction [7b115720716c5fd155088313d14c9df81344bd74](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/7b115720716c5fd155088313d14c9df81344bd74).
- **Final independent M2.4 CI** [run #38582070292](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38582070292) `completed/success`; GitHub raw job log confirms official Godot `4.7.2.stable.official.ed1daf0bf`, release ZIP SHA512 OK, editor import exit0, `test_m2_free_swap.gd` **32/32 PASS, failed=0**, and final marker `M2_4_FREE_SWAP_DOMAIN_VERIFIED`.
- Regression same run: `test_m2_cards` **46/46 PASS**, M1 **30/30**, M2.1 **38/38**, M2.2 **43/43**, and four legacy scripts exit0 (workflow completed/success; logs archived).
- First run [#38581850818](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38581850818): Free Swap runner **32/32 PASS**, predecessor scripts exit0; CI step failed because it still grepped the superseded M2.3 43-count while upstream tests now total 46. Adjusted CI oracle only, **did not weaken the M2.4 assertions**. Second run is all green.
- Seed `20261014`. Successful CardDrawn-trigger replay event SHA256 `f8003dc11c5831b29a7e07c9fcae1b085c45fdb6d85a95e58933ebd077c5add4`; final card-zone/swap-state SHA256 `dd5c7d9896614711c522cc17ab3091f05635fb3b7708acacb55a599457cdd3f2`. Both hashes are from identical source state, seed, trigger rules, and FREE_SWAP command, repeated twice. **This is card-domain replay, not full M2.5 resource+card replay.**
- The combined M2.5 gate [run #38581850850](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38581850850) also executed M2.3 **46/46** and M2.4 **32/32** successfully, then **intentionally stopped with exit 2 `BLOCKED_M2_FULL_INTEGRATION`** because integrated Cost→Card→Event→Replay oracles are not yet authored. Do not report full M2 DOMAIN VERIFIED.

### Precise scope of source test IDs

| Source test ID | Evidence and limitation |
|---|---|
| `M26-SWAP-001` | Per actor per phase quota, zero AP/MP cost **in FreeSwap event metadata**, other actors independent. Cross-resource ledger cost not yet integrated. |
| `M27-SWAP-002` | Original instance isolated, cannot be redrawn even through seeded discard reshuffle; other same-definition instance can be drawn. |
| `M29-SWAP-003` / `PRE3-11` (spec13) | No eligible replacement -> no events, no quota spent, no card mutation, can retry. |
| `M30-SWAP-004` | Discard-event-before-draw-event and deterministic **MOVE_CARD** triggers verified. Source spec's MP recovery/Buff effects are **not** implemented; full oracle remains partially unexecuted. |
| `PRE3-12` (spec13) / `PRE3-R11` (Library 20) | Valid precheck then last alternative moved by trigger -> `CardDrawFailed(POOL_CHANGED)`, no `CardDrawn`, quota consumed, original discarded, prior effects kept. |
| `PRE3-R12` (Library 20) | Separate Casting lifecycle decision; M2.4 proves Casting is excluded from replacement pool, not that M4 Casting effects have been implemented. |

**Final result: `M2_4_FREE_SWAP_DOMAIN_VERIFIED` (32/32); M2.5 full-domain integration remains `BLOCKED_FULL_INTEGRATION`.**
