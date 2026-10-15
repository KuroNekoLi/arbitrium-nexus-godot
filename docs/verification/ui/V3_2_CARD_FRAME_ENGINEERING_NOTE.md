# V3.2 — Reusable Card Frame & Semantic Card UI

> **Source implementation; CI validation pending**. Branch `ui/v3-visual-foundation-20261015`, based on V2 commit `822b1ce6`. **No changes to master or Codex-reviewed V2.**

## Responsibility split

- `scripts/battle/ui/components/battle_card_frame.gd`: pure presentation style factories and node builder, with separate CostBadge, ArtworkFrame, OrnamentalRule, CardName, CardDescription, and conditional UnavailableReason. Encapsulates display styles and source resource bindings, NOT CardInstanceID or transactions.
- `scripts/battle/ui/battle_card_view.gd`: remains a `SimpleCards.Card` subclass; retains existing `card_clicked`, `drag_started`, `drag_ended`, `selection_requested`, `release_requested`, hover/focus, selected CardInstanceID glow, drag threshold and home-return tweens. Only delegates drawing the card contents.
- Color family: muted arcane-navy frame with restrained gold/accent metal stroke; dark inset artwork; translucent navy cost badge; fine ornamental rule; contrasted title and capped two-line description. Every appearance continues to supply its original artwork, accent, name_key and description_key. CostLabel uses `cost_text` verbatim from UI read-model (AP/MP/Overload); no hardcoded cost or alternate resolver.
- Invalid card remains visible with separate localized UnavailableReason and tooltip, with different frame/badge stroke. No unsupported rarity, class icons, invented game metadata, or baked image text.
- No new third-party assets or fonts, no plugin changes, no art production, and no inferred licenses. High-fidelity art pack adoption is reserved for a separate Major Asset Decision.
- This work does NOT alter 12-card deck, 0–8 hand, AP/RP, MP, target, Reaction, cast/Last Spell or any `scripts/domain/` code. The simplified compositional Card Frame is reversible without losing actual CardInstanceIDs.

## QA scope

- `tests/test_p4_v32_card.gd` checks 4/8 cards, reused panel hierarchy, exact cost, artwork, i18n name/description, SimpleCards type, no input interception, selected/cancel, isolated mutable styles and no Domain mutation. New tests are additive.
- Existing V1, V2.1, V2.2, V2.4, V3.1 headless checks must pass unmodified.
- Run 9 existing real-render screenshots and three Boss Break fixtures for this UI commit at 1280/1920 zh/en; compare card hierarchy, readability, top fan visibility, selection lift, eight-card overlapping silhouettes. Use actual generated PNGs, not AI mockups.
- Re-run the scoped V2.5 eight-card real GUI test under V3.2 to verify that artwork/badge/frames have not stolen pointer events. Do NOT rerun or reinterpret historical P4.4 14/16.
- Final look still requires user review against the approved reference image. A procedural frame does not equal a licensed asset pack or final V3 acceptance.

## Engineering Note

This is similar to extracting a reusable Jetpack Compose `CardSkillSurface(appearance, cost, enabled)`: UI resources determine artwork and colors, the card component exposes click/drag signals, and `BattleScreen`/Domain remain the sole authority over whether a skill is legal or should consume AP/MP.

