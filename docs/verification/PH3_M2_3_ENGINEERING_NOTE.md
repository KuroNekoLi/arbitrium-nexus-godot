# Phase 3 / M2.3 — Twelve SP Card Instances, Zones and V2 Persistence

Authority: Library 04, 19 M-D25–30 and 20 PRE3-R12/R16. This is the headless card domain, not UI / Free Swap.

## Approved contracts

Each of three actors equips exactly 12 eligible, owned SP card instances. Different CardInstanceIDs can reference the same CardDefinition; only explicitly configured per-definition limits or inventory quantities restrict copies. Guard / Protect definitions and Last Spell do not enter the 12-card deck. Each ID occupies exactly one of Draw, Hand, Discard, Casting, Isolated. Conservation must hold globally (36 unique IDs) before and after each operation.

At battle start the domain seeded-shuffles 12 per actor and draws four. Basic phase refill only tops up to four, preserving existing cards. Extra draws cap at eight and never remove unavailable ninth cards. Empty Draw recycles seeded Discard, never Casting or Isolated; an empty supply exits without looping. Accepted card moves are cloned / validated and event_seq is deterministic. M3 will own actor status and phase legality.

## Storage contract

Legacy scripts/domain/deck_profile_store.gd stays untouched. V1 8-card JSON is returned unchanged with LEGACY_RECONFIGURATION_REQUIRED and cannot enter V2 battle or be auto-padded. Separate user://deck_profile_v2.json uses version 2, loadouts per actor containing variant_id and exactly 12 CardDefinition IDs. Inspect returns V2_CANDIDATE only; battle admission and writing require full 12-card / variant / actor / tag / inventory / optional ContentDeckRules verification. Variant changes require revalidation. Reconfiguration UI is deferred.

## Milestone boundaries

The zone snapshot is standalone and not yet part of M1/M2.2's battle reducer. M2.4 owns official Free Swap triggers and PRE3-R11 POOL_CHANGED; M3 phase/status; M4 Casting effects. M2.5 must supply actual cross-system replay before overall M2 gate turns green. Isolated zone is reserved for M2.4, not a claim of implemented Free Swap.

## Tests and execution

Runner: tests/test_m2_cards.gd. Acceptance cases: DECK-001/002/003/004, M25-HAND-001/002, PRE3-16, PRE3-20, plus wrong actor, Variant/tag, insufficient ownership, explicit copy caps, same-name instances, seeded replay, depleted pool, cap overflow, corrupted ID, casting exclusion, legacy bytes, V2 save/load and refusal.

Status at initial authoring: SPECIFIED_NOT_TESTED. Record actual run/commit/exit/logs after CI. Successful M2.3 is separate from the intentionally red M2.5 full integration gate.
