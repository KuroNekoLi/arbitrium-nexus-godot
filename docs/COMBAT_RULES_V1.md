# Combat Rules v1.0 — Arbitrium Nexus

## Scope

Single-player 2D horizontal turn-based card JRPG prototype for Godot 4.x. The combat simulation is deterministic under a fixed RNG seed and has no UI dependencies.

## Roster and decks

- Player roster: Kleya, Nova, Yora.
- Each character owns an independent 8-card deck, draw pile, discard pile, hand, Mana pool, and reaction-ready state.
- Opening hand: 4 cards per character.
- At the start of each player phase, draw until 4 cards; hand hard cap is 6.
- Cards are data-driven `CardData` Resources. The first slice uses eight cards per character, with shared rules and character identity.

## Turn and resource rules

- Combat opens in `PLAYER` phase, round 1.
- Each player phase allows at most two ordinary card plays across the party.
- Mana refills to the character's maximum at the start of every player phase.
- Unspent Mana remains available during the enemy phase for immediate Reaction cards.
- `END TURN` moves to enemy phase. The boss executes its visible intent, then returns to player phase.
- A card can be played only by its owner, only if its cost is affordable, and only while that owner is alive.

## Boss: Arbitrium Nexus

- HP: 300.
- Stability: 50. Damage to Stability exposes a Weak Node at 0; Stability recovers by 4 after the boss acts, capped at 50.
- Weak Node: exposed while Stability is 0; the next ordinary damage action deals +50% damage and restores Stability to 20.
- Enemy Intent: telegraphed before the enemy phase; the first slice cycles `NEXUS_LANCE` (24 damage to the lowest HP hero) and `STABILITY_SURGE` (stability +10, then 12 damage to all heroes).
- Analysis: each ordinary card play increments Analysis. At 3, the boss intent is revealed with a higher-confidence label and Analysis resets to 0.
- Interrupt: Reaction cards can spend retained Mana during enemy phase to cancel the current intent once per enemy phase.

## Determinism and validation

- `BattleState` owns a `RandomNumberGenerator` seeded with `v1_seed=104729`.
- Domain tests cover opening draw, refill-to-four, hand cap, two-play limit, Mana retention, damage, Stability/Weak Node, and deterministic intent order.
- UI and animation are consumers of domain signals; they do not own combat rules.

## M0–M5 delivery plan

- M0: project scaffold, toolchain detection, source of truth, CI-like headless test entrypoint.
- M1: pure combat engine and deterministic tests.
- M2: playable 16:9 battle UI with clickable hand, phase flow, intent, logs.
- M3: Boss Analysis, Interrupt, Reaction, and Weak Node feedback.
- M4: authored visual pass, motion and impact feedback.
- M5: deck builder, save/load, export profiles.

## Resolved prototype ambiguities

- “每玩家階段最多兩次普通出牌” is interpreted as a party-wide limit of two ordinary plays per player phase, while Reaction plays are outside that limit.
- Each character begins with 3 Mana and cards cost 0–3. Mana refill occurs before the draw refill.
- The prototype uses a compact shared card vocabulary so the engine is testable before M5 content expansion.

