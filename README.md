# Arbitrium Nexus

Godot 4.x single-player 2D horizontal turn-based card JRPG MVP.

## Run

Open this folder in Godot 4.x and run the main scene. The project targets a 1280×720 (16:9) viewport.

## Controls

- Click a hero panel to select that hero's independent deck and hand.
- Click an ordinary card to play it during the player phase.
- Click `END TURN` to expose the boss intent.
- During the enemy phase, click `Interrupt` if it is in the selected hero's hand and that hero has retained enough Mana; otherwise click `RESOLVE`.

## Verification

Run the deterministic domain suites with:

```text
godot --headless --path . --script res://tests/test_battle_state.gd
```

The rules source of truth is [docs/COMBAT_RULES_V1.md](docs/COMBAT_RULES_V1.md).

## MVP scope

M0–M3 are implemented: executable project scaffold, pure combat state, independent decks, opening/refill draw, Mana retention, ordinary play cap, Reaction interrupt, Boss HP/Stability/Weak Node, Analysis, Enemy Intent, and a playable 16:9 UI. M4 authored animations and M5 deck builder/export remain the next expansion layer.

