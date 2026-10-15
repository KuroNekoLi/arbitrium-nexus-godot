# Phase 4 — portable GPT conversation handoff

## Repository checkpoint

- Repository: https://github.com/KuroNekoLi/arbitrium-nexus-godot
- Verified base: `5103e40a4b95da82f2561b29c2604e9514fd398b` (master / P4.3).
- Checkpoint branch: `handoff/p4-lv40-chat-20261015` — WIP, NOT VERIFIED. Before work fetch this branch and record its actual full SHA; do not use master as if it contains the WIP.
- User explicitly authorized this trial handoff and extension within the existing M5. Balance remains Provisional. No new engine or final art adoption is authorized.
- This file describes a prepared checkpoint; confirm successful push in the sending Codex response. If remote/files are inaccessible, request the supplied source ZIP; never guess missing code.

## Actual state / evidence

- P4.3 pushed and verified: Actions https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38685051780 success.
- P4.4 not verified: feedback45/45, edge80/80; 1238 Domain assertions / 100 fixed seeds / 4 legacy suites passed locally. GUI third attempt14/16: two PNG writes failed. Extra run permission remains pending. New agent/conversation does not reset the three-attempt allowance. See `docs/verification/ui/P4_4_ENGINEERING_NOTE.md` and `P4_FEEDBACK_EDGE_AUDIT.md`.
- Lv40 new modules: content32/32, but M5/M3/M4 entrypoints NOT WIRED. Domain/edge runtime NOT VERIFIED. Domain subagent was interrupted by usage limit; no completed handoff claim.
- Balance policy: parse checks only, no 400 battles / human playtest.
- Account quota last checked 2026-10-15: five-hour remaining97%, weekly99%. This is a user-authorized trial, not threshold-triggered handoff.

## Trial work package — Lv40 Domain wiring ONLY

### Read first

`AGENTS.md`, `.codex/skills/godot-card-rpg-orchestrator/SKILL.md` and its `references/SPEC_GUARDIAN.md`; then combat engineer Skill and its references. Source priority is `docs/combat/COMBAT_SPEC_INDEX.md`; use docs26 starter content, docs27 Boss B01–B11, docs29 candidate A and docs22 implementation contract. Do not substitute prototype eight-card rules or another repository. Read `docs/verification/PH4_LV40_DOMAIN_NOTE.md` for the current public API.

### Existing new files — review and reuse, do not recreate

`scripts/domain/m5/lv40/` contains:

- `lv40_content.gd` — versioned registered content/config.
- `lv40_encounter.gd` — `config()` / `initial(seed)` using existing M1/M2/M3 state.
- `lv40_domain_extension.gd` — proposed dispatch/delegation, not wired.
- `lv40_boss.gd`, `lv40_card_resolver.gd`, `lv40_cast_effect.gd`, `lv40_effects.gd`, `lv40_reaction.gd` — proposed content-specific operations.

Also reuse `resources/combat/lv40/`, `tests/test_lv40_content.gd`, `tests/test_lv40_domain.gd`, `tests/test_lv40_edges.gd`. These are incomplete implementation, not approved oracle by themselves.

`resources/combat/lv40/pending_integration.patch` already contains an **unapplied, unverified apply_patch-format draft** for seven entrypoints: M5 resolver, M3 phase engine, M4 casting timeline, M3 reaction eligibility/queue, M5 status resolver and damage pipeline. Review each hunk against current code and approved rules; do not blindly apply it or rewrite the same proposal from scratch. This is not a standard `git apply` diff.

### Modify existing files, minimal scope

1. `scripts/domain/m5/integration/m5_domain_resolver.gd`: dispatch enabled/versioned Lv40 config through the same M5 public entry and shared untrusted-input guards. Preserve fixture/default behavior.
2. Trace actual M3 enemy / reaction and M4 cast execution call sites. Propose the exact additional paths/functions before patching them; add narrow Lv40 hooks, not whole-engine replacement. Boss AoE, charge/release and R05/T05 must use existing payment/window/damage authorities. No raw client damage payloads.
3. `scripts/domain/m5/status/status_resolver.gd`: check whether the extension's proposed `tick(...,"ENEMY_PHASE_END")` signature exists; if not, supply a backwards-compatible, source-justified boundary selector with tests. Do not add a second status implementation.
4. Extend the existing three Lv40 runners with positive/negative/atomic/order/replay cases, not weaker assertions. Do not re-run blocked P4.4 GUI tests.
5. Update `docs/verification/PH4_LV40_DOMAIN_NOTE.md` with real signatures, required caller changes, failures, retry counts and evidence.

### New deliverables

- `docs/handoff/CODEX_RETURN.md`, filled from the template.
- A unified diff covering the exact changes; include complete contents of any genuinely necessary new source/test file.
- Optional `docs/verification/PH4_LV40_WIRING_REVIEW.md` for issues found and spec-to-test mapping; do not substitute this report for code.

### Contract / acceptance

`M5.apply(state, command, config)` remains the sole formal transaction entry. `PLAY_LV40_CARD` only carries actor/card instance/target/mode/command ID/expected event sequence, never costs or effects. Preserve M2 payments, card conservation, M3 manual Reaction, M4 Full/Last lifecycle, M5 damage/status/outcome and versioned RNG. Rejection preserves complete state/RNG/events. Same seed/config/tape must replay identically.

Test real hand-owned card payment and discard, wrong owner/stale/duplicate/wrong target/insufficient resources, Boss charge/release/interrupt, AoE protection restrictions, already published Intent retention, R05/T05, passives, Last Spell HP0 invalidation, terminal outcome and replay. Docs29 candidate A remains provisional; do not multiply attack factor twice.

With tools: use the repo's Godot4.7.2 runners, preserve raw logs and test-group retry counts, check full Domain regression. Without Godot: deliver PROPOSED_PATCH / NOT_EXECUTED, not PASS. No CI claim without actual run URL/head SHA.

### Out of scope / merge policy

Do not change UI, `project.godot`, CI, translations, RTM, art, balance or P4.4 gates. Do not push master or mark P4.5 VERIFIED. Codex will review the returned patch and integrate only after P4.4 gate is resolved. Work can remain proposed/reversible on checkpoint without bypassing milestone acceptance.

## Subsequent work map — NOT part of trial

After Domain contract: modify `scripts/battle/battle_command_factory.gd` for config-aware Lv40 routing; `battle_screen.gd` for encounter selection / support Last target; `presentation/battle_presentation_adapter.gd` for actor metadata and Boss casting/AoE; `presentation/battle_translations.gd` for both CSV catalogues; `ui/battle_hud.gd` for localized modes/intent/reactions.

Create `scenes/battle/lv40_battle.tscn` reusing existing battle scene, then update `project.godot` only after tests. Reuse the already added 26 `resources/ui/appearances/*.tres` U/R/A/T entries and `resources/ui/lv40_strings.csv`; do not generate duplicate cards. New candidates: `tests/test_p4_lv40_integration.gd`, `tests/capture_p4_lv40.gd`.

After playable integration: run existing `tools/balance/lv40_godot_policy.gd` / `tests/test_lv40_balance.gd` for four strategies x100seeds with replay. Add a real hardware profiler only if needed. Human playtest / balance approval cannot be generated by agents.

## Portable use / safety

Receiving GPT conversation may have no repository tools. Supply the source bundle rather than pasting entire chat history. If a patch is returned instead of a commit, Codex validates its base, reviews it and applies it with file tools, then runs actual gates. ChatGPT does not become able to operate the user's PC just by receiving this prompt.

Preserved but excluded from checkpoint: user `.codex/COMBAT_SPEC_MEMORY.md`, unrelated generated import files, overwritten old `outputs/p4_3_*` screenshots. New P4.4 evidence and failure logs are separate. Do not reset, delete or publish unrelated data.
