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


## Actual verification evidence — 2026-10-15

**V3.2 scope: HEADLESS_VERIFIED + REAL_RENDER_VERIFIED + SCOPED_GUI_VERIFIED.** This is not final V3 art approval.

- Implementation commit: [`cc97b18e`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/cc97b18e9a83aa92033620a3be4f2076753a4fc6), changes only card UI script, reusable style factory, tests, CI and the engineering note. No `scripts/domain/`, asset imports, licensed packs, `project.godot` or V2 branch writes.
- First dedicated regression [Run #38744219640](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38744219640) reported `V32_CARD_REPORT executed=73 passed=71 failed=2`. The *new test only* erroneously expected language switch to reset an active eight-card hand to four. Existing behavior correctly preserves the active eight-card hand, so this was a test expectation mistake; every existing P4, V1, V2 and V3.1 regression gate was green in this run.
- Corrective **test-only** commit [`5711c686`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/5711c686cc10dc09f04e17c0b8fb405f3b71a1e0) now requires **all eight cards to remain** on zh_TW ⇄ English locale rebuild. Nothing in production sources changed. [Successful V3.2 Headless Run #38744554159](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38744554159): `V32_CARD_REPORT executed=73 passed=73 failed=0`; all previous gates passed, including Scene 8/8, P4 HUD 36/36, V1 Component 24/24, V2.1 18/18, V2.2 23/23, V2.4 39/39, P4 Integration 31/31, Localization 198/198, Lv40 32/32, V3.1 Visual 31/31. No Godot import/script errors. [Raw headless logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38744554159/artifacts/11978071034).
- [Real GUI regression #38744445451](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38744445451) against the same production code, at `c4b30d3f1e7af7327e04f2089115824b7c1cbbc3`: `V25_GUI_REPORT executed=31 passed=31 failed=0`; actual X11/Xvfb Godot 4.7.2 mouse and keyboard events still choose all eight cards at 1280 and the last card at 1920, and the Context confirmation area remains operable. [Raw GUI logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38744445451/artifacts/11977087446). Old P4.4 14/16 remains unresolved and is NOT rerun or relabeled.
- [Real-render screenshot Run #38744219567](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38744219567), implementation SHA `cc97b18e`: nine ordinary screenshots `V23_CAPTURE_REPORT executed=30 passed=30 failed=0` and three Boss Break fixtures `V31_BOSS_RENDER_REPORT executed=20 passed=20 failed=0`; strict PNG/dimension checks and error gate passed. [12 original screenshots, render manifests and logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38744219567/artifacts/11976992143) (14-day retention).
- **Visual review, 1280 zh_TW idle thumbnail**: artwork now sits within a bounded dark inset with fine metallic stroke; top cost badge, thin dividing rule, title and description are separate data-driven Controls. Four-card fan remains close to bottom and card silhouettes distinct. This is a qualitative inspection of real Godot output, not a numerical pixel diff against the still-unpinned approved concept. At 640×360 preview size, micro-typography cannot be declared optimally readable without inspecting original 1280 PNG.
- **Known remaining issues:** a full hand still overlaps by design (scoped real GUI verification covers selection), selected/hover details need full-size readability review, absent/long name or cost text clipping, testing of genuinely illegal card frames with a representative runtime fixture and all V3 visual artwork/style approval. Do not present provisional hand-made StyleBox borders as approved final art assets.

### Integration boundary

Continue V3.3 separately for Boss HUD ornaments/Intent. Do **not** merge V3 over V2 when Codex's review is ongoing; reconcile against reviewed master and carry over the minimal validated V3 commits. The new workflows are branch-scoped and must not overwrite the canonical optimized master CI.
