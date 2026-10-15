# Arbitrium Nexus Godot — Agent Instructions

> This repository is an executable Godot card-JRPG prototype. These rules apply to this repository, not to the documentation-only source `KuroNekoLi/astraea-combat-rules`.

## Transfer status (2026-10-15)
- Authoritative **source snapshot for this transfer**: `KuroNekoLi/astraea-combat-rules@cac49361e1cbc0e783fbdf75699080724f1c70a9`.
- Source **new content** `docs/combat/25`–`31` and reproducible Python balance tools `tools/balance/` have been copied unchanged (identical blob SHAs).
- **Owner-selected A semantic reconciliation is completed for `docs/combat/00`–`24`.** The retained target canonical rules were checked against upstream, and unique `P2-*` acceptance IDs were merged into file 13. See `docs/combat/UPSTREAM_RECONCILIATION_A_2026-10-15.md`; this does not imply Godot implementation parity.
- The existing `README.md` describes a prototype with 8-card loadouts / two ordinary plays per phase, while the imported approved Combat Rules specify 12 SP instances per actor / shared AP6. **This is an implementation-versus-specification conflict, not yet a completed migration.**
- Document 19's active canonical filename is `docs/combat/19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`; the upstream longer variant is reference-only under `docs/combat/archive/`, not a second authority.
- The source repo's root `AGENTS.md` says “documentation-only”; this does **not** describe this executable Godot repository, so this repository-specific file replaces it, not verbatim copied.
- The imported `31_...` document points to a historically separate implementation repo `Astraea-Academy`. For this migration the active target is `KuroNekoLi/arbitrium-nexus-godot`; references in historical handoff texts are not automatically updated.

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

## Entry points
- [Approved A reconciliation audit](docs/combat/UPSTREAM_RECONCILIATION_A_2026-10-15.md)
- [Original transfer provenance](docs/combat/UPSTREAM_TRANSFER_STATUS.md)
- [Latest imported Lv40 demo handoff](docs/combat/31_LEVEL40_DEMO_GODOT_AGENT_START_HERE.md)
- [Boss encounter fixture](docs/combat/27_LEVEL40_DEMO_BOSS_ENCOUNTER_V0_1.md)
- [Python balance tools](tools/balance/)
