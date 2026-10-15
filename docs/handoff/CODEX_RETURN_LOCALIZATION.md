# Codex Return — Localization

- Repository: https://github.com/KuroNekoLi/arbitrium-nexus-godot
- Branch: `handoff/p4-card-localization-chat-20261015`
- Input common base: `977a289654e1470bcda83c6c25c14d4cda4c86ab`
- Pre-return implementation HEAD: `097aa2b2c48a50436fa1e86cdd83a9218052c204`（本回填自身再提交一筆，實際最終SHA請讀該branch HEAD。）
- Status: **IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED**
- Write scope: 本包對應任務白名單檔案；無跨包Domain/CI/project/master更動。
- Context: 使用 GitHub connector 直接提交本工作包、保留原歷史 commit，未開PR/未合併主分支。
- Tools: GitHub read/write; **NO GODOT binary / OS runner**。Godot import、GUI及下述測試沒有執行，無runtime hash、exit code、log或CI run URL。

## Exact changed files

| Path | Mode | Content / full text and diff |
|---|---|---|
| [`CHAT_TASK.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-card-localization-chat-20261015/CHAT_TASK.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-card-localization-chat-20261015.diff) |
| [`docs/handoff/P4_CARD_LOCALIZATION_HANDOFF.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-card-localization-chat-20261015/docs/handoff/P4_CARD_LOCALIZATION_HANDOFF.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-card-localization-chat-20261015.diff) |
| [`docs/verification/ui/P4_LOCALIZATION_ENGINEERING_NOTE.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-card-localization-chat-20261015/docs/verification/ui/P4_LOCALIZATION_ENGINEERING_NOTE.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-card-localization-chat-20261015.diff) |
| [`resources/ui/lv40_strings.csv`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-card-localization-chat-20261015/resources/ui/lv40_strings.csv) | MODIFY | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-card-localization-chat-20261015.diff) |
| [`scripts/battle/presentation/battle_translations.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-card-localization-chat-20261015/scripts/battle/presentation/battle_translations.gd) | MODIFY | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-card-localization-chat-20261015.diff) |
| [`tests/test_p4_localization.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-card-localization-chat-20261015/tests/test_p4_localization.gd) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-card-localization-chat-20261015.diff) |

**完整 unified diff**：[compare from original common base](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-card-localization-chat-20261015.diff)；新檔完整內容可由上表連結讀取。應先review、核對共同基底，**不要將diff再套用到已包含改動的本分支**。

## Public contracts / blocker

Translations.install() 保留；新增 validate_catalogues(paths), install_checked(paths), uninstall_owned(), owned_count()。26卡＋角色／Boss Intent雙語key；原battle CSV兩個歷史重複key明確last-wins，其餘fail-closed。

整合前先核對 26 卡雙語候選文案及新增Intent/Last Spell名稱；不跨scope改 battle_strings.csv。

## Verification (actual evidence)

- 實際Godot version: NOT_AVAILABLE。
- Current package suite: **NOT_EXECUTED**（未進行 attempt；已寫測試程式但不宣稱PASS）。
- Proposed local command after using real Godot 4.7.2: `godot --headless --path . --script res://tests/test_p4_localization.gd`。
- Domain M1–M5.5 regression /100 seeded Replay：本工作包 **NOT_EXECUTED**。
- P4.4 GUI第三輪14/16 (two PNG writes failed)屬獨立歷史Gate；未授權第四次，不重設attempt、不以新runner冒充通過。
- No runtime screenshot, performance claim, 400-game research or human playtest acceptance.

## Risks / rollback

尚未驗證Godot實際CSV解析、翻譯資源註冊、字型及UI overflow；新增Boss名稱僅候選顯示字串。

- Undo scope: only this package's new/modified white-list source files. Do not reset workspace, discard user changes, force push, overwrite other branches or alter master.

## Codex next actions (maximum five)

1. Re-fetch this branch full SHA and compare against common base; review exact changed paths and official combat/UI skills.
2. On checked out Godot 4.7.2, import project and run specified suite; preserve real attempt number, raw logs, exit status and failures.
3. Verify old P4.3 fixtures, previously confirmed M5.5 Domain/replay, and P4.4 unresolved GUI evidence remain unchanged.
4. Resolve listed dependencies with respective owners; cherry-pick approved narrow commits into **reviewed integration** branch, not wholesale merge WIP branches.
5. Run true integrated UI/Domain/CI gates and update RTM only with actual evidence; no P4.5 VERIFIED until all acceptance requirements are met.

## Architecture / learning handoff

See package Engineering Note for Godot/Kotlin concept mapping, alternative designs, regression strategy and interview questions. Domain owns transactions, reducer state and deterministic tape; UI/metrics do not invent cost/damage or secretly auto-confirm Reaction.
