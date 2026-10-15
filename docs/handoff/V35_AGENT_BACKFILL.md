# V3.5 Agent Backfill

STATUS: **NEEDS_REVISION (visual score 16/24 < 20)** — V3.5.1–V3.5.5 code stages implemented and locally tested; not READY_FOR_USER_REVIEW, not user-approved.

## Scope / repository
- Agent / execution environment: Firebender agent, Windows 10, local Godot 4.7.2.stable.official.ed1daf0bf, Compatibility OpenGL 3.3, GTX 1650. No `gh` CLI and no GitHub token on this machine.
- Source branch / full SHA: `ui/v35-hud-convergence-20261015`, started from `f73e07e` (descends from reviewed baseline `50e2eaf`).
- Completed stage(s): V3.5.1 party, V3.5.2 command, V3.5.3 intent, V3.5.4 action context + DomainEvent log, V3.5.5 capture + reference comparison tool.
- Changed/new files and responsibilities:
  - `scripts/ui/hero_roster_item.gd`, `scripts/battle/ui/components/party_status_panel.gd`, `team_phase_header.gd`: selection/hover/focus frame, emblem HP/MP bars, status pill, projection-derived badges (barrier/guard/cast/actor.status); header kept ≤ 64 px.
  - `scripts/battle/ui/components/command_menu.gd`, `battle_command_visual.gd` (new): icons, subtitles, Last Spell/End emphasis, shrink-to-fit titles. Analyze/Item gameplay stays **UNIMPLEMENTED**.
  - `scripts/battle/ui/components/enemy_status_panel.gd`: intent icon, public hit-count chip, target badges. Boss AI unchanged.
  - `scripts/battle/ui/components/action_context_panel.gd`, `battle_log_panel.gd`, `scripts/battle/presentation/battle_log_formatter.gd` (new), `scripts/battle/battle_screen.gd`: log rows built only from real DomainEvents with seq/seq_end; raw events kept for locale re-format.
  - `scripts/battle/ui/components/battle_visual_tokens.gd`: party/status tokens.
  - `assets/ui/v35/*.svg` (12 original SVGs), `assets/asset_manifest.csv`, `CREDITS.md`.
  - `resources/ui/battle_strings.csv`: command subtitle + log keys (zh_TW/en).
  - Tests: `tests/test_p4_v35_party.gd`, `test_p4_v35_command.gd`, `test_p4_v35_intent.gd`, `test_p4_v35_log.gd`, `tests/capture_p4_v35_hud.gd`; tool `tools/qa/compare_v35_references.gd`.
  - CI: `.github/workflows/ci-fast.yml` p4-contracts adds the V3.5 suites (incl. the 32-case resource suite); totals line 1124.
  - Repo hygiene: `.gitignore` (generated `*.translation`, IDE, capture outputs), tracked `.uid` files, regenerated simple_cards layout cache.
- Commit SHA(s): `b0f0459`, `1d02d42`, `68c7924`, `fc7ad97`, `9359c10`, `dbb84b4`, plus this docs/tool commit.
- Master / V2: V2 branch untouched. Owner explicitly instructed (2026-10-16) to merge this work into `master` after completion; that overrides the handoff's "stop on V3 line" rule.

## Code / assets
- Domain / Command / Replay changes: **none**. All UI reads projection/DomainEvents; no rule, RNG or turn-order code touched.
- UI API compatibility / lifecycle: existing node names, facades (`log_label`, `details`, `detail_scroll`, `command_buttons`, `end_button`) and frame positions preserved; locale rebuild replays log history.
- Assets: 12 original SVGs under `assets/ui/v35/`, license "original (project)", registered in manifest/CREDITS; rollback = revert `68c7924`/`fc7ad97`. No reference-image cropping.

## Test ledger (local, Godot 4.7.2 headless unless noted)
| Suite | Attempts | Final SHA | Result | Raw log | CI |
|---|---|---|---|---|---|
| test_p4_v35_party | 4 (1st: 4 fail TopBar 65px, fixed) | dbb84b4 | 57/57 PASS | `../v35-work/` (outside repo) | CI_PENDING |
| test_p4_v35_command | 3 (red/green check incl.) | dbb84b4 | 30/30 PASS | `../v35-work/` | CI_PENDING |
| test_p4_v35_intent | 3 | dbb84b4 | 35/35 PASS | `../v35-work/` | CI_PENDING |
| test_p4_v35_log | 5 | dbb84b4 | 33/33 PASS | `../v35-work/` | CI_PENDING |
| Full ci-fast p4-contracts (27 suites + 4 legacy) | 3 | dbb84b4 | 1124/1124 + legacy exit 0 | `../v35-work/` | CI_PENDING |
| Other ci-fast suites (Golden/Replay/Fast Seeds/Playable/writer) | 1 | dbb84b4 | PASS | `../v35-work/` | CI_PENDING |
| capture_p4_v35_hud (windowed render) | 3 | dbb84b4 | 45/45 PASS | `../v35-work/cap3.log` | not in CI |
| AP static capture | 0 this session (budget exhausted at 3) | — | NOT_RUN | — | — |
| Original GUI, Full 1238, 100 Seeds | 0 | — | NOT_RUN | — | — |

Earlier CI runs `38754989017` (Fast) / `38754989102` (Render) and the two cancelled duplicates: **still unverified** — no API token available to read results. Not re-dispatched.

## Visual evidence
- Renderer: Compatibility OpenGL 3.3 / GTX 1650, windowed.
- Reference hashes: verified equal to `docs/verification/ui/V35_BASELINE.md`.
- PNGs (`outputs/p4_input_capture/v35_hud_r3_20261016/`, git-ignored, SHA256 prefix):
  vis01_idle_1280_zh `620CD62E9A512864`, vis02_idle_1920_zh `EE5F710D9DB2E7DB`, vis03_idle_1280_en `80BFDEE7273C8072`, vis04_idle_1920_en `683ADCFF39E84AD4`, vis05_selected_1280_zh `3500DCB4C31EFFBC`, vis06_hand0 `C02A040313F9C25F`, vis06_hand1 `D392F11EBF4C7CE0`, vis06_hand8 `0A7A4B5E98FEB61B`, vis07_mock_status (**MOCK_ONLY**) `2D48C2F3231B2477`, vis08_focus `E3E0CCF939E6B934`, vis09_real_events_1280_zh `BB050AEF80CB1C79`, vis10_real_events_1920_en `40CF5B0E560A820C`.
- Side-by-side / overlay: `outputs/p4_input_capture/v35_compare_r3_vis01/` (side_by_side, overlay_50, corner_*). Corner mean abs diff: TL 0.261, TR 0.179, BL 0.189, BR 0.162 (lower is closer).
- Top 5 mismatches:
  1. `HandView` cards: flat, uniform card art and no arc/fan or large selected lift vs reference's tall illustrated cards with cost gems.
  2. `PartyStatusPanel` items: no ornate portrait frame or per-hero action label; bars thinner than reference.
  3. `EnemyStatusPanel`: no boss portrait in the intent card, no break/stability gauge strip.
  4. `BattleLogPanel`: empty on idle; reference shows icon-led colored rows with a hero portrait.
  5. Panel chrome overall: thin flat borders vs reference's gold filigree corners and glow.
- Six-dimension scores (scorer: agent, scale 0–4 per BATTLE_UI_VISUAL_ACCEPTANCE §4):
  Spatial layout 3, Hand presentation 2, HUD visual language 2, Typography + localization 3, Information hierarchy 3, Interaction feedback 3 → **16/24**.
- Four corners: TL 3, TR 3, BL 3, BR 2.

## Handoff
- VERIFIED (local evidence only): V3.5 contract suites and full ci-fast p4-contracts pass locally at `dbb84b4`; capture 45/45.
- NEEDS_REVISION: visual exit (16/24, Hand 2, HUD language 2, BR 2). CI_PENDING: GitHub Actions results for the pushed commits.
- Retry budgets: AP static capture 0 left; V3.5 capture used 3.
- Next tasks: (1) hand arc/lift + cost gem card faces in `hand_view.gd`/`battle_card_frame.gd`; (2) ornate frame tokens for all panels; (3) boss portrait + stability strip in `enemy_status_panel.gd`; (4) read CI results with a token and backfill URLs.
