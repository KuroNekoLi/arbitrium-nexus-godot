# Arbitrium Nexus Godot — Agent Instructions

> This repository is an executable Godot card-JRPG prototype. These rules apply to this repository, not to the documentation-only source `KuroNekoLi/astraea-combat-rules`.

## Transfer status (2026-10-15)
- Authoritative **source snapshot for this transfer**: `KuroNekoLi/astraea-combat-rules@cac49361e1cbc0e783fbdf75699080724f1c70a9`.
- Source **new content** `docs/combat/25`–`31` and reproducible Python balance tools `tools/balance/` have been copied unchanged (identical blob SHAs).
- Existing `docs/combat/00`–`24` have differences from the source versions. **Do not automatically overwrite or reinterpret these as resolved.** Consult `docs/combat/UPSTREAM_TRANSFER_STATUS.md` before combat changes.
- The existing `README.md` describes a prototype with 8-card loadouts / two ordinary plays per phase, while the imported approved Combat Rules specify 12 SP instances per actor / shared AP6. **This is an implementation-versus-specification conflict, not yet a completed migration.**
- Both sources share the same conceptual Phase 2 decision family for document 19 under different filenames. Do not introduce two competing canonical copies.
- The source repo's root `AGENTS.md` says “documentation-only”; this does **not** describe this executable Godot repository, so this repository-specific file replaces it, not verbatim copied.
- The imported `31_...` document points to a historically separate implementation repo `Astraea-Academy`. For this migration the active target is `KuroNekoLi/arbitrium-nexus-godot`; references in historical handoff texts are not automatically updated.

## Work restrictions
1. Verify Git HEAD, Godot project/version, existing tests, and real implementation before attempting changes.
2. Respect explicit USER_APPROVED combat rules; mark candidate values `BALANCE_PROVISIONAL`; do not assume Python smoke tests establish Godot correctness.
3. Preserve existing Godot scenes, assets, skills and tests until a separately authorized implementation task.
4. In conflicts, provide a side-by-side decision proposal; never silently pick a historical or lower-priority rule.
5. Godot Domain owns HP, AP, MP, RP, deck zones, turn order, reaction ordering and RNG; renderer is never authoritative. No unapproved free movement, auto-pass reaction timeout or Counter-Function.
6. For implementation changes, require repeatable headless tests, case IDs, failure logs, CI evidence and code commits. Do not claim pass without evidence.

## Entry points
- [Transfer conflict and provenance audit](docs/combat/UPSTREAM_TRANSFER_STATUS.md)
- [Latest imported Lv40 demo handoff](docs/combat/31_LEVEL40_DEMO_GODOT_AGENT_START_HERE.md)
- [Boss encounter fixture](docs/combat/27_LEVEL40_DEMO_BOSS_ENCOUNTER_V0_1.md)
- [Python balance tools](tools/balance/)
