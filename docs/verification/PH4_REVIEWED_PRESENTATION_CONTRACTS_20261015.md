# P4 reviewed localization/readmodel contract promotion

> **Scope: HEADLESS_VERIFIED_ONLY, GUI NOT VERIFIED.** No BattleScreen swap, HUD visual refactor, screenshot assertion relaxation, or playable Lv40 claims.

This change imports Lv40 name/description translations (en/zh_TW), versioned card appearance resources referencing existing asset atlas, and the backward-compatible optional ContentConfig projection + M5 card command factory. It includes 198 named localization and 29 named ReadModel tests from `integration/p4-reviewed-20261015`.

Guardrails:
- `BattleCommandFactory.card(...,config={})` remains backward compatible for fixture callers and only emits `PLAY_LV40_CARD` when `m5_lv40_enabled` is explicit.
- `BattlePresentationAdapter.project(state,config={})` preserves existing fixture projections and does not mutate Domain State.
- Translations are owned, atomically installed, idempotent, and allow two known legacy duplicate keys with explicit last-wins policy.
- All added appearance resources reference existing `assets/card_art_atlas.png`. The source provisional card art and license must not be represented as final approved art.
- Headless assertions do **not** imply GUI screenshot / visual spacing / real-player input / final Lv40 playable acceptance.
- Target master full prior Domain regression 1238+100 seeds must remain passing; original GUI attempt 14/16 is not rerun without explicit owner approval.

Source evidence [integrated branch #38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522). This staged subset must pass new target-branch CI before master promotion.
