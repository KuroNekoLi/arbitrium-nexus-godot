# Codex Return — ReadModel

- Repository: https://github.com/KuroNekoLi/arbitrium-nexus-godot
- Branch: `handoff/p4-readmodel-chat-20261015`
- Input common base: `977a289654e1470bcda83c6c25c14d4cda4c86ab`
- Pre-return implementation HEAD: `4cd72219010e7b118abf6a3ee75f5b13536ef977`（本回填自身再提交一筆，實際最終SHA請讀該branch HEAD。）
- Status: **IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED**
- Write scope: 本包對應任務白名單檔案；無跨包Domain/CI/project/master更動。
- Context: 使用 GitHub connector 直接提交本工作包、保留原歷史 commit，未開PR/未合併主分支。
- Tools: GitHub read/write; **NO GODOT binary / OS runner**。Godot import、GUI及下述測試沒有執行，無runtime hash、exit code、log或CI run URL。

## Exact changed files

| Path | Mode | Content / full text and diff |
|---|---|---|
| [`docs/handoff/TASK_READMODEL.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-readmodel-chat-20261015/docs/handoff/TASK_READMODEL.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-readmodel-chat-20261015.diff) |
| [`docs/verification/ui/P4_READMODEL_ENGINEERING_NOTE.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-readmodel-chat-20261015/docs/verification/ui/P4_READMODEL_ENGINEERING_NOTE.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-readmodel-chat-20261015.diff) |
| [`scripts/battle/battle_command_factory.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-readmodel-chat-20261015/scripts/battle/battle_command_factory.gd) | MODIFY | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-readmodel-chat-20261015.diff) |
| [`scripts/battle/presentation/battle_presentation_adapter.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-readmodel-chat-20261015/scripts/battle/presentation/battle_presentation_adapter.gd) | MODIFY | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-readmodel-chat-20261015.diff) |
| [`tests/test_p4_lv40_readmodel.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-readmodel-chat-20261015/tests/test_p4_lv40_readmodel.gd) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-readmodel-chat-20261015.diff) |

**完整 unified diff**：[compare from original common base](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-readmodel-chat-20261015.diff)；新檔完整內容可由上表連結讀取。應先review、核對共同基底，**不要將diff再套用到已包含改動的本分支**。

## Public contracts / blocker

Factory.card(state,actor,instance,target,mode='CHANTLESS',combo=false,config={}); Adapter.project(state,config={}); preview仍呼叫同一M5深複本。新增 hand_cards、actor_name_keys、public_intent_labels、boss_cast_public；舊project(state)不變。

需由Codex審核整合Domain與Localization後才做正式UI caller；不可由Factory決定HP/資源費用。

## Verification (actual evidence)

- 實際Godot version: NOT_AVAILABLE。
- Current package suite: **NOT_EXECUTED**（未進行 attempt；已寫測試程式但不宣稱PASS）。
- Proposed local command after using real Godot 4.7.2: `godot --headless --path . --script res://tests/test_p4_lv40_readmodel.gd`。
- Domain M1–M5.5 regression /100 seeded Replay：本工作包 **NOT_EXECUTED**。
- P4.4 GUI第三輪14/16 (two PNG writes failed)屬獨立歷史Gate；未授權第四次，不重設attempt、不以新runner冒充通過。
- No runtime screenshot, performance claim, 400-game research or human playtest acceptance.

## Risks / rollback

本分支仍繼承未接線Domain基底；真Lv40 M5 accepted receipt、完整Replay及與Screen的端到端連線不在本包驗證。

- Undo scope: only this package's new/modified white-list source files. Do not reset workspace, discard user changes, force push, overwrite other branches or alter master.

## Codex next actions (maximum five)

1. Re-fetch this branch full SHA and compare against common base; review exact changed paths and official combat/UI skills.
2. On checked out Godot 4.7.2, import project and run specified suite; preserve real attempt number, raw logs, exit status and failures.
3. Verify old P4.3 fixtures, previously confirmed M5.5 Domain/replay, and P4.4 unresolved GUI evidence remain unchanged.
4. Resolve listed dependencies with respective owners; cherry-pick approved narrow commits into **reviewed integration** branch, not wholesale merge WIP branches.
5. Run true integrated UI/Domain/CI gates and update RTM only with actual evidence; no P4.5 VERIFIED until all acceptance requirements are met.

## Architecture / learning handoff

See package Engineering Note for Godot/Kotlin concept mapping, alternative designs, regression strategy and interview questions. Domain owns transactions, reducer state and deterministic tape; UI/metrics do not invent cost/damage or secretly auto-confirm Reaction.
