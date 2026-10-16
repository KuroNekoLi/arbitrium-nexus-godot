# Arbitrium Nexus Godot — Agent Instructions

> This repository is an executable Godot card-JRPG prototype. These rules apply to this repository, not to the documentation-only source `KuroNekoLi/astraea-combat-rules`.

## Combat Source of Truth（2026-10-16）

**IMPORTANT — mandatory for every combat/UI/gameplay Agent**: First read [docs/combat/README.md](docs/combat/README.md). The descriptive Chinese-language files in that index define current gameplay. Follow with the matching player-facing topic, [engineering contract](docs/combat/engineering/戰鬥引擎實作契約.md), [code traceability](docs/combat/engineering/規則與程式對照表.md), and [open features](docs/combat/engineering/待實作與待驗證功能.md). Check the real `master` HEAD, source code, tests and current CI each time.

**Hard invariants**: each of three active characters has exactly **12 SP instances**, opening 4, refill *only if below 4*, hand cap **8**, and one free one-for-one discard/draw per character per Player Phase. Shared BaseAP **6** (not six per person), MP individual and not naturally restored, RP normally capped at **6** and cleared after the following Enemy Phase. Last Spell occupies a separate slot; casting and Exhausted use approved outcome rules. Reaction with a legal option always waits for explicit Confirm/Pass, never times out. A real successful mutual-KO action is VICTORY. The protagonist starts as swordsman; UNIVERSAL attack/heal/shield magic cards can be equipped by all characters.

**Content status**: named party, **31 ordinary SP CardDefinitions / 3 separate LastSpellDefinitions**, candidate Lv40 Boss, multipliers and starter decks are `CONTENT_PROVISIONAL` unless specifically approved. The Lv40 starter has 24 different SP definitions represented by **36 instances** across three 12-card loadouts, not all 31 available candidate definitions. No new gameplay rule is approved just because it appears in a headless fixture.

**Legacy**: the 2026-10-14/15 numbered combat docs have been retained as historical evidence under `docs/combat/archive/legacy-2026-10-16/`; they are **NOT** parallel combat authority. Old 8-card `scripts/domain/deck_profile_store.gd` and `kleya/nova/yora` are prototype code, not grounds to downgrade the 12-card specification. This documentation reorganization does not itself change Godot gameplay or establish CI/visual acceptance.

## Work restrictions
1. Verify Git HEAD, Godot project/version, existing tests, and real implementation before attempting changes.
2. Respect explicit USER_APPROVED combat rules; mark candidate values `BALANCE_PROVISIONAL`; do not assume Python smoke tests establish Godot correctness.
3. Preserve existing Godot scenes, assets, skills and tests until a separately authorized implementation task.
4. In conflicts, provide a side-by-side decision proposal; never silently pick a historical or lower-priority rule.
5. Godot Domain owns HP, AP, MP, RP, deck zones, turn order, reaction ordering and RNG; renderer is never authoritative. No unapproved free movement, auto-pass reaction timeout or Counter-Function.
6. For implementation changes, require repeatable headless tests, case IDs, failure logs, CI evidence and code commits. Do not claim pass without evidence.


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
