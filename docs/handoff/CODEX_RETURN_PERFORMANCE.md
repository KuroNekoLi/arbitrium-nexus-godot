# Codex Return — Performance QA

- Repository: https://github.com/KuroNekoLi/arbitrium-nexus-godot
- Branch: `handoff/p4-performance-qa-chat-20261015`
- Input common base: `977a289654e1470bcda83c6c25c14d4cda4c86ab`
- Pre-return implementation HEAD: `f9ffe527e51a6b0f6fffdcffcc038747f6132905`（本回填自身再提交一筆，實際最終SHA請讀該branch HEAD。）
- Status: **IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED**
- Write scope: 本包對應任務白名單檔案；無跨包Domain/CI/project/master更動。
- Context: 使用 GitHub connector 直接提交本工作包、保留原歷史 commit，未開PR/未合併主分支。
- Tools: GitHub read/write; **NO GODOT binary / OS runner**。Godot import、GUI及下述測試沒有執行，無runtime hash、exit code、log或CI run URL。

## Exact changed files

| Path | Mode | Content / full text and diff |
|---|---|---|
| [`docs/handoff/TASK_PERFORMANCE.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-performance-qa-chat-20261015/docs/handoff/TASK_PERFORMANCE.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-performance-qa-chat-20261015.diff) |
| [`docs/verification/ui/P4_PERFORMANCE_ENGINEERING_NOTE.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-performance-qa-chat-20261015/docs/verification/ui/P4_PERFORMANCE_ENGINEERING_NOTE.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-performance-qa-chat-20261015.diff) |
| [`docs/verification/ui/P4_VISUAL_ACCEPTANCE_CHECKLIST.md`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-performance-qa-chat-20261015/docs/verification/ui/P4_VISUAL_ACCEPTANCE_CHECKLIST.md) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-performance-qa-chat-20261015.diff) |
| [`tests/profile_p4.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-performance-qa-chat-20261015/tests/profile_p4.gd) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-performance-qa-chat-20261015.diff) |
| [`tests/test_p4_profile_metrics.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-performance-qa-chat-20261015/tests/test_p4_profile_metrics.gd) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-performance-qa-chat-20261015.diff) |
| [`tools/qa/p4_profile_metrics.gd`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/handoff/p4-performance-qa-chat-20261015/tools/qa/p4_profile_metrics.gd) | NEW | GitHub source / [exact unified diff](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-performance-qa-chat-20261015.diff) |

**完整 unified diff**：[compare from original common base](https://github.com/KuroNekoLi/arbitrium-nexus-godot/compare/977a289654e1470bcda83c6c25c14d4cda4c86ab...handoff/p4-performance-qa-chat-20261015.diff)；新檔完整內容可由上表連結讀取。應先review、核對共同基底，**不要將diff再套用到已包含改動的本分支**。

## Public contracts / blocker

Metrics.summarize/aggregate/percentile/scoped_run_id/write_new；profile_p4.gd -- --run-id=... 支援固定1280/1920 GUI量測與截圖，0/無GPU值為null。

實機GUI跑 godot --path . --script res://tests/profile_p4.gd -- --run-id=p4_gui_001；Lv40需要已合併scene。新runner不視為P4.4第四次。

## Verification (actual evidence)

- 實際Godot version: NOT_AVAILABLE。
- Current package suite: **NOT_EXECUTED**（未進行 attempt；已寫測試程式但不宣稱PASS）。
- Proposed local command after using real Godot 4.7.2: `godot --headless --path . --script res://tests/test_p4_profile_metrics.gd`。
- Domain M1–M5.5 regression /100 seeded Replay：本工作包 **NOT_EXECUTED**。
- P4.4 GUI第三輪14/16 (two PNG writes failed)屬獨立歷史Gate；未授權第四次，不重設attempt、不以新runner冒充通過。
- No runtime screenshot, performance claim, 400-game research or human playtest acceptance.

## Risks / rollback

目前只有程式，無真FPS、CPU/GPU、PNG、商售性能或人工評審證據；此runner預設測既有Scene idle，不是完整戰鬥。

- Undo scope: only this package's new/modified white-list source files. Do not reset workspace, discard user changes, force push, overwrite other branches or alter master.

## Codex next actions (maximum five)

1. Re-fetch this branch full SHA and compare against common base; review exact changed paths and official combat/UI skills.
2. On checked out Godot 4.7.2, import project and run specified suite; preserve real attempt number, raw logs, exit status and failures.
3. Verify old P4.3 fixtures, previously confirmed M5.5 Domain/replay, and P4.4 unresolved GUI evidence remain unchanged.
4. Resolve listed dependencies with respective owners; cherry-pick approved narrow commits into **reviewed integration** branch, not wholesale merge WIP branches.
5. Run true integrated UI/Domain/CI gates and update RTM only with actual evidence; no P4.5 VERIFIED until all acceptance requirements are met.

## Architecture / learning handoff

See package Engineering Note for Godot/Kotlin concept mapping, alternative designs, regression strategy and interview questions. Domain owns transactions, reducer state and deterministic tape; UI/metrics do not invent cost/damage or secretly auto-confirm Reaction.
