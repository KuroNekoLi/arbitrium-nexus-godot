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

Historical authoring status was SPECIFIED_NOT_TESTED; the actual Godot verification and limitations are recorded below.

## Actual Godot 4.7.2 verification — 2026-10-14

**M2.3 CARD DOMAIN VERIFIED (46/46 PASS)** on commit de2178e175846c2eeae5aba7f3f96995bb61323c, [CI run #38580461921](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38580461921). Actual runtime: 4.7.2.stable.official.ed1daf0bf; official ZIP SHA512 OK; editor import exit0; runner M2_3_TEST_REPORT executed=46 passed=46 failed=0 seed=20261014 and M2_3_CARD_DOMAIN_VERIFIED exit0. Regressions: M1 30/30; M2.1 38/38; M2.2 43/43; four original smoke scripts all exit0. CI artifacts: godot-m2-3-card-domain-logs.

Exact spec-13 test coverage: DECK-001 (start hand4 draw8), DECK-002 (two card moves then explicit refill), DECK-003 (draw1 discard10 hand1, three cards via seed-deterministic reshuffle), DECK-004 (draw0 discard0 bounded), M25-HAND-001 (hand 3/4/7 refill only to4), M25-HAND-002 and PRE3-20 (7 hand/request3 → only 1 card), PRE3-R16 (valid exactly12 with no auto-fill), plus persistence, owner, inventory, Variant, duplicate/missing instances and 8-card hand cap negative oracles.

**Trace ID correction:** PRE3-R16 is the 12-SP loadout rule in Library 20; the existing spec-13 testcase PRE3-16 concerns Last Spell caster incapacitation and remains M4 NOT_EXECUTED. PRE3-20 in spec-13 is a hand-cap testcase, not the v2-save testcase. Persistence cases use distinct M2_3-PERSIST-* names.

Test repair record, no suppressed failures: initial [run #38579069372](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38579069372) 41/43, failed strict JSON numeric version comparison and raw dictionary-order persistence oracle; [run #38579370915](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38579370915) 42/43 after integral numeric JSON version repair; [run #38579650132](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38579650132) 43/43 after semantic round-trip comparisons. Expanded spec-13 oracle [run #38580219264](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38580219264) had a GDScript multiline syntax parse failure; repaired at de2178e1 and final verified 46/46. Every test run used actual Godot headless; numbers exclude cases not executed.

**M2.3 scope only:** Phase-change legality/status and actual round transitions remain M3, spell/casting effects M4, complete M2.2 SP payment-to-card integration and replay M2.5; isolated zone does not constitute Free Swap. M2.4 and full M2.5 gate remain BLOCKED, and their intentionally red CI is expected. No full game/M2 DOMAIN VERIFIED claim.
