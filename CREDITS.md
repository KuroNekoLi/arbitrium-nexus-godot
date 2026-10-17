# Third-party asset credits

## Last Spell targeting preview (2026-10-16)

Reuses the existing party portrait atlas for cut-ins/target cards and existing v35 SVG/NinePatch assets for scope markers and framing. No pixels were extracted from the three supplied concept images. Existing portrait provenance remains pending; no new final character design or commercial license is asserted.

## V3.5 incremental HUD assets

`assets/ui/v35/ap_core.svg`, `ap_crystal.svg` and the V3.5.1–V3.5.3 icon set (`cmd_*.svg`, `status_*.svg`, `intent_skill.svg`) are original editable repository-native vector code authored for this task, not extracted from the user's reference images or an external pack. They contain no baked UI text. The resource frame reuses the existing Kenney Fantasy UI Borders CC0 asset and bundled notice below. No new external downloads, fonts or plugins were adopted. Reference A/B JPEGs under docs/ui/references/v35 are user-supplied comparison material only; commercial redistribution rights are not inferred.

## Phase 4 reused prototype artwork

The existing `assets/*.png` and `assets/portraits/party_portraits.png` are reused as reversible prototype placeholders, not adopted as new final character/Boss designs. Original provider/model/license evidence is not bundled in this checkout; commercial provenance remains pending. See `assets/asset_manifest.csv`. No new external artwork was downloaded for P4.1.

## Kenney Fantasy UI Borders

- Author: Kenney (Kenney.nl).
- Used in: character roster and boss information frame.
- License: CC0 1.0 Universal.
- Source: [Kenney Fantasy UI Borders](https://kenney.nl/assets/fantasy-ui-borders).
- License text: `addons/kenney_fantasy_ui_borders/LICENSE.txt`.

## Kenney Particle Pack

- Author: Kenney Vleugels (Kenney.nl); Godot packaging by Calinou.
- Used in: combat slash, magic, and spark impact effects.
- License: CC0 1.0 Universal.
- Sources: [Godot Asset Library entry](https://godotengine.org/asset-library/asset/784), [Godot-ready package](https://github.com/Calinou/kenney-particle-pack).
- License text: `addons/kenney_particle_pack/LICENSE.txt`.

## Kenney UI Audio

- Author: Kenney Vleugels (Kenney.nl); Godot packaging by Calinou.
- Used in: card hover, card pickup, hero selection, and interface button feedback.
- License: CC0 1.0 Universal.
- Sources: [Godot Asset Library entry](https://godotengine.org/asset-library/asset/796), [Godot-ready package](https://github.com/Calinou/kenney-ui-audio).
- License text: `addons/kenney_ui_audio/LICENSE.txt`.

## Kenney RPG Audio

- Author: Kenney Vleugels (Kenney.nl).
- Used in: weapon swing and impact cues during attacks.
- License: CC0 1.0 Universal.
- Sources: [Godot Asset Library entry](https://godotengine.org/asset-library/asset/1840), [original asset pack](https://kenney.nl/assets/rpg-audio).
- License text: `addons/kenney_rpg_audio/LICENSE.txt`.

Attribution is not required by CC0, but is included here as a courtesy. Check each asset's included license before redistributing extracted files separately from this project.
# Phase 4 font / framework research

V3.5 convergence: `assets/ui/v35/arcane_panel.svg` is original project-authored vector ornamentation (PROJECT_ORIGINAL), not extracted from the reference artwork. Existing party portraits and v35 icons are reused unchanged. No new external package or executable plugin was acquired.

Noto Sans TC: Copyright 2014-2021 Adobe. SIL Open Font License 1.1; see assets/fonts/OFL.txt. Official source: https://github.com/google/fonts/tree/main/ofl/notosanstc .

CGF https://github.com/db0/godot-card-game-framework (AGPL-3.0 with upstream addendum) was researched as an interaction reference only. No CGF source or assets are bundled. Existing SimpleCards remains the interaction dependency.

SimpleCards 2.13 by twdoor, MIT: https://github.com/twdoor/simple-cards-v-2 . Full upstream notice restored at addons/simple_cards/LICENSE; inherited local fixes are retained.

## Character appearance candidates — 2026-10-16

Six transparent PNGs (Ren / Akane / Tsumugi, one 3×3 action atlas and one independent portrait CG per character) were generated with a project-authorized image-generation tool on 2026-10-16. Original file SHA-256 values and dimensions are recorded in `assets/asset_manifest.csv` and `docs/handoff/CHARACTER_ATLAS_EDITOR_PREVIEW_CHECKPOINT_20261016.md`. The tool did not disclose its generation model. These are **replaceable AI-generated character design candidates**, not bundled Kenney assets or public-domain CC0 artwork. User approval of final canonical character appearance and actual visual QA is still pending. Original legacy art assets remain available for compatibility until every original caller is safely migrated.

## Character state CG replacement candidates — 2026-10-17

Ren, Akane, and Tsumugi state sheets were supplied by the user from a ChatGPT image-generation conversation. The source model, exact prompt, and redistribution/license details were not supplied. They are integrated as task-approved, replaceable 1024×1280 RGBA PNGs at `assets/characters/<character_id>/cg_states.png`, replacing the previous 256×320 state sheets. SHA-256, dimensions, and current QA status are recorded in `assets/asset_manifest.csv`. Do not claim final Canon approval or external redistribution rights from the image files alone.

## Boss Astriom layered asset candidates — 2026-10-17

Three separate transparent PNGs (`boss_body.png`, `boss_aura.png`, `boss_magic_circle.png`) were supplied by the user and integrated under `assets/monsters/boss/` as replaceable, user-provided ChatGPT-generated candidates. Source model, exact prompt, and external licensing/redistribution terms were not supplied. Their SHA-256 values and dimensions are recorded in `assets/asset_manifest.csv`; no public-domain or external redistribution license is asserted.
