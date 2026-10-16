# Arbitrium Nexus Godot — Agent Instructions

## CURRENT COMBAT ENTRY — source of truth
- Read [docs/combat/README.md](docs/combat/README.md), then the system guide, then [engineering contracts](docs/combat/engineering/戰鬥引擎實作契約.md). Historical phase-numbered documents are **not** active authoritative entrypoints.
- New game entry: `res://scenes/battle/lv40_playable_battle.tscn`; never reintroduce the 8-card / two-plays / timed-reaction prototype.
- Current roster is `resources/combat/rosters/lv40_party_v0_3.json`: slot IDs are battle-instance addresses, **not fixed character identities**. Obtain actors, name keys, stats, starting decks, variant IDs, and art paths from content rather than hardcoding `A/B/C` to named heroes.
- Each active actor has exactly **12 SP**, opening hand **4**, refill to **4**, max hand **8**; use M1–M5 Domain as the single authority. Do not reintroduce old `CardCatalog` or `DeckProfileStore`.
- Card eligibility is declared in `resources/combat/cards/lv40_eligibility_v0_3.json` (`UNIVERSAL`, `ROLE_TAG`, `CHARACTER`). `lv40_party_catalog.gd` validates it during encounter setup and card usage; NEVER assume that a card is eligible merely because it is included in a JSON loadout.
- Changing content identity requires updating i18n, matching card and Last Spell definitions, and versioned test fixtures. Never claim a new character is fully supported merely because its name changed in JSON.

> This repository is an executable Godot card-JRPG prototype. These rules apply to this repository, not to the documentation-only source `KuroNekoLi/astraea-combat-rules`.

## Combat Source of Truth（2026-10-16）

**IMPORTANT — mandatory for every combat/UI/gameplay Agent**: First read [docs/combat/README.md](docs/combat/README.md). The descriptive Chinese-language files in that index define current gameplay. Follow with the matching player-facing topic, [engineering contract](docs/combat/engineering/戰鬥引擎實作契約.md), [code traceability](docs/combat/engineering/規則與程式對照表.md), and [open features](docs/combat/engineering/待實作與待驗證功能.md). Check the real `master` HEAD, source code, tests and current CI each time.

**Hard invariants**: each of three active characters has exactly **12 SP instances**, opening 4, refill *only if below 4*, hand cap **8**, and one free one-for-one discard/draw per character per Player Phase. Shared BaseAP **6** (not six per person), MP individual and not naturally restored, RP normally capped at **6** and cleared after the following Enemy Phase. Last Spell occupies a separate slot; casting and Exhausted use approved outcome rules. Reaction with a legal option always waits for explicit Confirm/Pass, never times out. A real successful mutual-KO action is VICTORY. The protagonist starts as swordsman; UNIVERSAL attack/heal/shield magic cards can be equipped by all characters.

**Content status**: named party, **31 ordinary SP CardDefinitions / 3 separate LastSpellDefinitions**, candidate Lv40 Boss, multipliers and starter decks are `CONTENT_PROVISIONAL` unless specifically approved. The Lv40 starter has 24 different SP definitions represented by **36 instances** across three 12-card loadouts, not all 31 available candidate definitions. No new gameplay rule is approved just because it appears in a headless fixture.

**Legacy retired**: the previous 8-card runtime, `CardCatalog`, `DeckProfileStore`, `scripts/main.gd`, old-character hardcoded battle script, old card Resources and four compatibility smoke shims have been deleted. Historical design docs remain under `docs/combat/archive/legacy-2026-10-16/`, not active authority. No automatic import of old `user://deck_profile.json` exists. All three current slots read character, Variant, portrait, stats, passive and Last Spell content from the roster JSON. Do not confuse stable battle slot IDs with fixed identities. Adding more than three active slots is not implemented. New features must be actually tested at the same commit before claiming PASS.

## Work restrictions
1. Verify Git HEAD, Godot project/version, existing tests, and real implementation before attempting changes.
2. Respect explicit USER_APPROVED combat rules; mark candidate values `BALANCE_PROVISIONAL`; do not assume Python smoke tests establish Godot correctness.
3. Preserve active M1–M5 code, scenes, reusable UI, skills and tests. The user has explicitly authorized removing the retired eight-card implementation, its smoke-test shims, and obsolete workflow steps. Do not delete current tests merely because their names mention `legacy`.
4. In conflicts, provide a side-by-side decision proposal; never silently pick a historical or lower-priority rule.
5. Godot Domain owns HP, AP, MP, RP, deck zones, turn order, reaction ordering and RNG; renderer is never authoritative. No unapproved free movement, auto-pass reaction timeout or Counter-Function.
6. For implementation changes, require repeatable headless tests, case IDs, failure logs, CI evidence and code commits. Do not claim pass without evidence.

## Token-efficient development and handoff

For feature work, use a two-stage AI workflow when the user can assign models:

1. A stronger AI implements the change and completes an independent code review before handoff. Keep implementation and review focused on the relevant source, contracts, and diff.
2. After review, that AI writes one concise, task-specific handoff under `docs/handoff/`. Include the goal and scope, changed files/commit, exact test and acceptance commands, expected results, known risks, and any tests that must not be rerun. Do not duplicate specifications or paste large logs; link to durable evidence.
3. The user gives the handoff to a lower-cost AI for test execution and acceptance. That AI verifies the stated commit, runs only authorized/current test groups, records actual results, and does not silently change implementation or weaken assertions. On failure, it returns a concise failure handoff to the stronger AI for fixes and review.
4. Once required tests and acceptance pass for the reviewed commit, delete the task-specific handoff and remove its README entry. If blocked or failed, keep/update the handoff until resumed or explicitly closed.

Keep durable records that remain useful after handoff: source-of-truth specifications, test code, concise verification status, raw test logs/artifacts required by CI or audit, asset manifests/licensing/provenance, and unresolved requirements. Only the temporary coordination handoff is deleted on completion; do not delete evidence or authoritative documentation to save tokens. Never mark acceptance complete from a prior commit's results.

When the app does not expose model selection, state the intended role split in the handoff so the user can route it to the appropriate model; do not claim that a model was switched automatically.


## Asset-first one-command requests（2026-10-15）

When asked to **"製作 XX 場景" / "生產 XX 圖片" / "新增角色或卡牌插畫" / "製作 Boss 攻擊動畫"**, do not ask the user to manually choose every asset website. Treat the instruction as a deliverable request and route through:

`godot-card-rpg-orchestrator` → `.codex/skills/godot-resource-library-manager/SKILL.md` (search existing assets/Vault, check license, safely obtain/index permitted free packs, compare candidates) → `.codex/skills/godot-game-asset-pipeline/SKILL.md` (separate/generate/convert/import assets) → UI/rendering/architecture implementation → true Godot screenshot + QA.

**Low-risk reversible assets:** choose automatically and record license/manifest. **Major choices:** protagonist/Boss final look, main scene art direction, UI style system replacement, new executable plugins, ambiguous licensing, paid or large acquisition require a `Major Asset Decision Report` (recommended selection plus real alternatives, previews, rights, fit, costs, rollback) and user approval before final adoption. A planning-only request authorizes documentation, **not** downloading or implementing. These skills do not confer network, persistence or image-generation permissions; disclose missing tools and never fabricate downloaded artifacts or runtime evidence.

Read [UI Resource Scout / Asset Vault SOP](docs/ui/03_FREE_OPEN_SOURCE_RESOURCE_SCOUT.md) and [UI entrypoint](docs/ui/README.md). Preserve existing approved Combat Domain and every existing asset unless explicitly authorized to replace it.

## Context-efficient exploration

- Use `rg --hidden --ignore-file .codexignore --files` for broad discovery and `rg --hidden --ignore-file .codexignore -n PATTERN scripts scenes tests docs .codex` for scoped search. `--hidden` keeps `.codex/skills` visible; `.git/` remains excluded. This is an explicit ripgrep policy, not a verified native Codex setting or access-control boundary.
- Read the new authoritative Combat README and current handoff first; then relevant modules and required Skill references. Read selected instructions completely. Do not dump all docs, logs, JSON tapes, images or addon sources into context.
- Exclusions only affect broad discovery. For audits, failures, asset work or historical conflicts, explicitly inspect required excluded paths (`Get-Content PATH` or `rg --no-ignore -n PATTERN EXACT_PATH`). Never omit required evidence or tests because of this policy.
- Keep raw logs on disk; report counts, failures and relevant excerpts. Do not print image base64, entire Command Tapes or unbounded output. This reduces irrelevant context, but does not guarantee cache hits, quota savings or billing reductions.
- Keep current scripts, scenes, tests, combat authority, UI specs, Skills, manifests and handoffs discoverable. Preserve all Git tracking and test evidence.

## Entry points
- [Current Combat Rule Index](docs/combat/README.md)
- [Character and full card catalog](docs/combat/角色圖鑑.md) / [Card catalog](docs/combat/卡牌圖鑑.md)
- [Agent implementation and mapping](docs/combat/engineering/戰鬥引擎實作契約.md)
- [Current UI source and resource workflow](docs/ui/README.md)
- [Historical transfer and provenance archive](docs/combat/archive/README.md)
- [Python balance tools](tools/balance/)
