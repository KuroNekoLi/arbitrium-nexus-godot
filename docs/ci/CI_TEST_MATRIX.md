# CI 測試矩陣｜現行戰鬥引擎（2026-10-16 清理版）

> 這是可供開發與 Agent 理解的**目標驗證架構**。通過與否只根據當次分支 HEAD 的 GitHub Actions 日誌，不能引用歷史成功結果替代。

| Workflow | 觸發時機 | 驗證內容 | 不等於 |
|---|---|---|---|
| `ci-fast.yml` — CI Fast | master、refactor/** 等允許分支有相關程式碼 push，PR，手動 | Godot 4.7.2 strict import／log gate、M5 Golden／Replay、5 seed、P4 scene／HUD／Lv40 互動 smoke | GUI 真實滑鼠、100 場 |
| `ci-integration.yml` — CI Integration | Domain 變更 push、PR、手動 | `tools/ci/integration_suites.txt` 中 **26 套／1128 斷言**；M1～M5／Replay，維持逐套實測 | 像素畫面或真人全場 |
| `ci-p4-contracts.yml` — P4 Contracts | UI／場景／內容／資產變更 push、PR、每日、手動 | **25 套／1149 斷言**，包含正式 HUD 元件；歷史取名 `test_p4_v34_legacy_roster.gd` 是**目前仍在使用的** HeroRosterItem 驗證 | 已授權限制外的 GUI 操作測試 |
| `godot-v2-3-visual-capture.yml` — CI Visual | 畫面／美術／場景變更 push、PR、手動 | Godot + Xvfb 真實渲染：9 張 HUD 與 3 張 Boss 快照、PNG 及 Manifest 驗證 | Golden pixel diff 或人工 UX 驗收 |
| `ci-full.yml` — CI Full | 每日台北02:00、手動、Release published；**非一般 push** | 透過 `godot-m5-5-acceptance.yml` 執行 100 固定種子戰鬥、Replay、M1～M5 長回歸與嚴格 log gate | 人工完成整場戰鬥、舊八卡程式相容性 |

## 為什麼刪除舊 smoke 但保留很多 M1～M5 測試？

- `test_battle_state.gd`、`test_deck_builder.gd`、`test_combat_ui.gd`、`test_turn_flow.gd` 在刪除前早已不是舊行為的測試，只是導向 `test_lv40_roster.gd` 的重複相容殼。現在已從 `tests/` 和 M2～M5 workflows 移除。
- 已退役 `godot-g0-legacy-baseline.yml`；其當時的八卡／兩次出牌／反應倒數不能重新成為驗收基準。
- `scripts/domain/m1～m5/` 和 `tests/test_m2_*.gd`、`test_m3_*.gd`、`test_m4_*.gd`、`test_m5_*.gd` 是**新引擎**，不是舊版；所有原有當前 Domain／Replay 斷言及實機必要場景都應保留。
- `tests/test_p4_v34_legacy_roster.gd` 驗證新 `PartyStatusPanel` 所使用的現役共用 UI 元件，其名稱僅是歷史標籤。P4 仍是 **25 套／1149 斷言**，未削減。
- `tests/ci_failure_probe.gd` 用來檢測非零退出是否會讓 CI 失敗；屬正式安全網，仍必須保留。
- `tests/ci/test_ci_current_only.py` 阻止被刪除的四個舊測試／workflow 回流，同時檢查 Full 的 100 場與 Replay 仍存在。

## Agent 執行順序

1. 先跑 `python3 -m unittest discover -s tests/ci -p 'test_*.py' -v` 和 Godot strict editor import。
2. 再跑最小受影響的 `tests/test_m*.gd`、`test_lv40_roster.gd`、`test_lv40_content.gd` 或 `test_p4_*.gd`。
3. 以分支的 Fast／Integration／P4／Visual Actions 檢查真正的 success／failure 和失敗日誌。
4. 大改動、候選 Release 才執行 Full；不能為了快速開發去刪除或放寬 100 場與 Replay 的驗收契約。
5. 記錄 commit SHA、測試名稱、執行時機、通過數與實際限制。舊 run 的證據只能標記 `HISTORICAL`。

可參考：[戰鬥規則總覽](../combat/README.md)、[規則與程式對照](../combat/engineering/規則與程式對照表.md)、[舊系統退役紀錄](../combat/engineering/舊系統退役與驗收紀錄.md)。
