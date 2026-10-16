# CI/CD 與測試矩陣（2026-10-17）

> 本倉庫目前的 GitHub Actions 是驗證與證據保存流程，沒有部署或發布遊戲的 CD 工作。完成與否以該分支／commit 的 Actions 結果為準；本機成功和舊 run 都不能代替當次 CI 證據。

## 核心自動化驗證

| Workflow | 觸發 | 覆蓋 |
|---|---|---|
| `ci-fast.yml` | 相關程式 push、PR、手動 | Godot import/log gate、Python CI guard、M5 Golden/Replay、5 seeds、代表性 P4/HUD/Lv40 smoke。Headless；特定 Last Spell GUI gate 有受限分支條件。 |
| `ci-integration.yml` | Domain 相關 push、PR、手動 | `tools/ci/integration_suites.txt` 的 26 套、1128 個明確斷言，涵蓋 M1–M5 / Replay。 |
| `ci-p4-contracts.yml` | UI/場景/資產相關 push、PR、每日、手動 | 25 套、1149 個 UI/內容/整合斷言；另有特定 SHA 授權的 GUI gate。 |
| `ci-reviewed-presentation.yml` | presentation 相關 push、手動 | 4 套、126 個額外呈現／角色狀態／瞄準箭頭斷言。 |
| `godot-v2-3-visual-capture.yml` | UI/場景/資產相關 push、PR、手動 | Xvfb 真正渲染與 PNG/manifest 檢查；含 HUD、Boss 與拖曳互動證據。 |
| `ci-full.yml` → `godot-m5-5-acceptance.yml` | 每日台北 02:00、手動、Release published | 完整 M1–M5 長回歸、100 場固定種子戰鬥與 replay。一般 push 不執行 100 seeds。 |

`ci-fast` 與 `ci-integration` 在 M5 Golden/Replay 有刻意的小範圍交集，讓快速回饋也保有核心戰鬥 smoke；`ci-full` 是每日／發佈前的長驗收，不應改成每次 push 都跑。

## 專項與互動驗收

保留的 17 個 workflow 依用途分組：

- Combo V2 與定向 GUI：`ci-combo-preparation-v2.yml`、`godot-card-targeting-arrow-poc.yml`。
- 角色與戰鬥呈現：`godot-character-editor-preview.yml`、`godot-character-state-cg.yml`、`godot-spell-projectile-visuals.yml`、`godot-three-ally-retirement.yml`。
- 專項 headless 輔助：`godot-p4-hud-headless.yml`。
- 真實 GUI/畫面 capture：`godot-v2-5-gui-input.yml`、`godot-v3-1-render.yml`、`godot-v3-2-card-gui.yml`。
- 共用入口：上表列出的六個核心 workflow（`ci-full` 呼叫的 M5.5 workflow 是可重用子流程）。

專項流程提供核心矩陣以外的 GUI、渲染或特定新功能覆蓋。手動入口保留給針對性驗收，不等於每個 commit 都會執行。

## 本次精簡

- 移除 19 個 M1–M5 單里程碑 workflow。它們重複執行 `integration_suites.txt` 中的現役 Domain 測試；`ci-integration` 已用共同的 Godot 安裝/import、嚴格 log gate 與 suite runner 執行這些測試。
- 移除 7 個重複的 P4/headless workflow。其測試都已在 `ci-p4-contracts.yml` 或 Fast/Integration/Full 中；原 workflow 另重複跑共享 HUD/整合回歸。
- 保留現役測試程式、M1–M5 斷言、P4 契約、GUI 測試、真實渲染與 100-seed/replay；此輪沒有刪除任何仍有獨立驗收內容的測試腳本。
- 工作流程從 43 個減為 17 個。四個退役八卡相容測試先前已刪，且 CI guard 持續禁止回流；`test_p4_v34_legacy_roster.gd` 仍驗證現役 `HeroRosterItem`，不可按名稱刪除。

## 仍需注意

- Full 由 `ci-full.yml` 呼叫可重用的 `godot-m5-5-acceptance.yml`；兩者不是兩次獨立執行。
- `ci-fast.yml` 和 `ci-p4-contracts.yml` 含特定分支/SHA 的執行限制，修改前須先看限制用途及目前 branch/commit，不可自行放寬。
- GitHub Actions 遠端結果仍須在合併後或 push 後查看；本地測試只驗證目前 checkout。
- 目前無遊戲打包、部署或上架 workflow；若日後加入，須明確定義 artifact、簽署、發布觸發與回滾流程。

## 本機驗證順序

1. `python -m unittest discover -s tests/ci -p 'test_*.py' -v`
2. Godot 4.7.2 strict editor import，並以 `tools/ci/assert_godot_logs.py` 檢查原始 log。
3. 執行受影響的 Fast、Integration、P4 或專項 suite；Full 僅用於每日或高風險／發佈驗收。

所有報告需保留實際 commit、suite、斷言數、log gate 結果與未覆蓋項目；不可把未執行的 GUI/遠端 Actions 說成 PASS。
