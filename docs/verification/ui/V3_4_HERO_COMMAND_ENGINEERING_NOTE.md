# V3.4 — Hero Roster & Command Visual System

> **IMPLEMENTED / CI PENDING**. Branch `ui/v3-visual-foundation-20261015`; based on V3.3 reviewed source `85d5c64b396145beca43153d66c644ab2497a269`. `master` and Codex-reviewing V2 remain unmodified.

## Objective and changes

- Keep the three real HeroRosterItem buttons, existing Kenney border + portrait sprites, and actor switching via `hero_selected` unchanged. Visual variants for selected/hover/focus are generated from `battle_visual_tokens.gd`; keyboard focus has a real visible cyan outline, not an empty StyleBox.
- The hero HP/MP have independent named **HeroHPBar / HeroMPBar** ProgressBars directly below their matching text labels within `Layout/Stats`, not tiny bars nested *inside* labels. Exact labels and bar values come from the existing actor projection, with safe zero max clamping only for the bar; HP green, MP blue. Legacy `update_status(hp,max_hp,mana,max_mana,hand_count)` signature remains positional-compatible but does **not** display a prohibited hand/deck counter.
- Command Menu retains the same Basic, Analyze, Item, Free Swap, Last Spell and End Player Phase controls and emits their **unchanged command names and field dictionaries**. Adds reusable control styles, hover/focus/pressed variants and a decorative input-transparent semantic accent rail. Utility placeholders are NOT presented as newly implemented gameplay. `hud.end_button`, language strings and disabled-in-enemy-phase behavior remain unchanged.
- No new art pack, font import, Godot plugin or Theme fork. All provisional colors live in `battle_visual_tokens.gd`. No changes to battle damage/AP/RP, cards, Reaction/Enemy actions or any `scripts/domain/` source.

## Verification gates

1. Godot 4.7.2 strict import, original V1/V2/V3.1–3.3 regressions and new `test_p4_v34_roster_command.gd` semantic/geometry suite.
2. Real rendered screen captures at 1280×720, 1920×1080, zh_TW/en, 0/1/4/8 card states and Boss Break projection fixture. Inspect 3× Hero frames and all buttons with original full-res PNG.
3. Dedicated mouse event test for hero A/B/C switching and command UI hit targets; keep existing 31/31 GUI card/context gate unchanged. No rerun/relabel of historical P4.4 14/16.
4. Preserve prior V2/WIP Codex review: after approval, V3 must be reconciled deliberately onto latest master rather than force-merging unreviewed V2 branch content.

## Engineering Learning

Analogous to extracting Jetpack Compose `HeroStatusCard(state, selected, onClick)` and `BattleCommandButton(command, onClick)`: domain/state dictates the numbers and command legality; the style factory owns gradients, semantic tint, and focus. A visual action rail is never an input target or independent gameplay command.

