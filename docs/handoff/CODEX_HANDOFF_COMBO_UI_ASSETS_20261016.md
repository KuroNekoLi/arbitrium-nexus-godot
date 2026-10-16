# Codex Handoff — Combo UI Asset Integration (2026-10-16)

## Branch baseline
- Repository: `KuroNekoLi/arbitrium-nexus-godot`
- Start from branch: `asset/combo-ui-candidate-20261016`
- Baseline source branch: `master`
- Master HEAD when candidate assets were added: `50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd`
- Godot version: `4.7.2.stable`

## What is already delivered on this branch
Candidate art assets only, no Combat Domain changes:
- `assets/ui/combo/combo_partner_idle.png`
- `assets/ui/combo/combo_partner_eligible.png`
- `assets/ui/combo/combo_partner_selected.png`
- `assets/ui/combo/combo_partner_unavailable.png`
- `assets/ui/combo/combo_card_eligible.png`
- `assets/ui/combo/combo_card_selected.png`
- `assets/ui/combo/combo_card_unavailable.png`
- `assets/ui/combo/combo_cutin_background.png`
- `assets/ui/combo/combo_cutin_frame.png`
- `assets/ui/combo/combo_cutin_energy.png`
- `assets/ui/combo/combo_offense_impact_sheet.png`
- `assets/ui/combo/combo_defense_barrier_sheet.png`
- `assets/ui/combo/asset_manifest.json`

Preview / planning doc:
- `docs/handoff/CODEX_HANDOFF_COMBO_UI_ASSETS_20261016.md`

## User-approved integration scope
Use the new assets to replace current placeholder combo visuals only. Do **not** modify Combat Domain rules or combo resolution.

### Required targets
1. **Hero roster combo partner indicator**
   - Target: `scripts/ui/hero_roster_item.gd`
   - Replace current `◇ Label` based indicator with texture-based visual states.
   - Use files:
     - idle → `combo_partner_idle.png`
     - eligible → `combo_partner_eligible.png`
     - selected → `combo_partner_selected.png`
     - unavailable → `combo_partner_unavailable.png`
   - Keep readability on dark backgrounds.
   - Preserve non-color state differentiation.

2. **Battle card combo frame**
   - Target: `scripts/battle/ui/battle_card_view.gd`
   - Replace current placeholder combo frame / label presentation.
   - Use texture overlays, not baked text.
   - Respect center transparency and safe border; do not cover card name, cost, or art.
   - States:
     - eligible → `combo_card_eligible.png`
     - selected → `combo_card_selected.png`
     - unavailable → `combo_card_unavailable.png`
   - General pulse candidate:
     - normal mode: alpha 0.35 → 0.55 → 0.35, period 1.5s
     - reduced motion: fixed alpha 0.45, no scale / shake / movement

3. **Combo cut-in presentation**
   - Target: `scripts/battle/presentation/battle_effects.gd::show_combo` (or equivalent current implementation)
   - Replace temporary deep-blue `PanelContainer` look.
   - Compose cut-in from three layers:
     - background → `combo_cutin_background.png`
     - frame → `combo_cutin_frame.png`
     - energy → `combo_cutin_energy.png`
   - Use existing character CG / appearance sources; do not add new characters into the art.
   - Timing:
     - normal: 1.4s + 0.2s fade-out
     - reduced motion: static 0.8s + 0.2s fade-out
   - Allow skip.
   - Event ordering: play only after combo event already resolved; keep A→B order fixed.
   - Animation must not determine damage, costs, zones, or success.

4. **Combo executed VFX**
   - Hook after ComboExecuted presentation/event path.
   - Offense animation sheet:
     - file: `combo_offense_impact_sheet.png`
     - frame size: 256×256
     - 4×4, 16 frames, 12 fps
     - start 0–3 / impact 4–11 / fade 12–15
   - Defense animation sheet:
     - file: `combo_defense_barrier_sheet.png`
     - same grid/fps layout
   - Do not flash full-screen white.
   - Defense barrier must preserve visible character silhouette.

## Accessibility / UX constraints
- Support normal mode and reduced motion mode.
- Support skip.
- Do not let combo visuals override incapacitated / exhausted / focus ring indicators.
- Do not communicate eligibility only by color; preserve shape/icon/state semantics.
- Keep localization independent; images contain no text.

## Verification requirements
1. Godot import succeeds.
2. True-render screenshots required at:
   - 1280×720
   - 1920×1080
   - both `zh_TW` and `en`
3. Verify combo indicator states, card overlay states, cut-in, and offense/defense effect playback.
4. Verify reduced motion mode.
5. Verify no Combat Domain regression.
6. Keep evidence in `docs/verification/ui/` or existing evidence location.

## Important non-goals
- No new gameplay rules.
- No redesign of protagonist / boss final look.
- No replacement of roster identity resolution logic.
- No plugin / shader / external executable dependency requirement in the final asset delivery.

## Suggested commit sequence
1. Import assets + wire manifest paths.
2. Replace roster indicator.
3. Replace card combo frame overlay.
4. Replace cut-in presentation.
5. Add offense / defense sheet playback.
6. Add reduced-motion / skip handling.
7. Add real-render evidence and update docs.

## If blocked
If actual combo hook points differ from assumptions in this note, inspect current `master` code first and adapt the UI glue, but keep the same asset files and user-approved constraints.
