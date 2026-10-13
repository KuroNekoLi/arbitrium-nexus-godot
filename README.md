# Arbitrium Nexus

Godot 4.x single-player 2D horizontal turn-based card JRPG MVP.

## Run

Open this folder in Godot 4.x and run the main scene. The project targets a 1280×720 (16:9) viewport.

## Controls

- Click a hero panel to select that hero's independent deck and hand.
- Drag an ordinary card from the selected hero's hand onto the Nexus during the player phase.
- Click `END TURN` to expose the boss intent.
- During the enemy phase, drag `Interrupt` onto the Nexus if it is in the selected hero's hand and that hero has retained enough Mana; otherwise click `RESOLVE INTENT`.
- Card drag thresholds, tracking, and release state are provided by the open-source Simple Cards `Card` component; card faces and combat rules remain project-specific.
- Hover cards to lift them; invalid drops spring back. On a valid drop, the card flies into the arena while the selected hero dashes or casts. The impact then flashes/shakes the Nexus, shows combat text, and only then resolves the combat state.

## Verification

Run the deterministic domain suites with:

```text
godot --headless --path . --script res://tests/test_battle_state.gd
```

Verify the drag-to-play UI path with:

```text
godot --headless --path . --script res://tests/test_combat_ui.gd
```

Latest in-engine UI capture: [outputs/combat_ui_mvp.png](outputs/combat_ui_mvp.png). Animation captures: [card in flight](outputs/card_attack_midflight.png) and [impact/result](outputs/card_attack_impact.png).

The rules source of truth is [docs/COMBAT_RULES_V1.md](docs/COMBAT_RULES_V1.md).

## MVP scope

M0–M4 are implemented: executable project scaffold, pure combat state, independent decks, opening/refill draw, Mana retention, ordinary play cap, Reaction interrupt, Boss HP/Stability/Weak Node, Analysis, Enemy Intent, and a playable 16:9 UI with original generated party/Boss artwork, animated character sprites, Simple Cards drag input, custom card faces, hover lift, spring-back, card flight, attack/cast motion, and impact feedback. M5 deck builder/export remains future work; this is still a prototype, not a production-ready commercial release.

