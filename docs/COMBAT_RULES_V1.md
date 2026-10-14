# 仲裁核心戰鬥規格 — Library 最新整合入口

> **Source of Truth：** `docs/combat/` 內 25 份由 ChatGPT Library `/docs/combat/` 匯入的完整 Markdown。  
> **此文件已取代舊 v1.0 戰鬥玩法規格。** 原有 Godot 程式、Scene、測試、存檔可能仍遵循舊原型；此次文件更新**不代表程式已完成遷移、CI 已通過**。

## 正式閱讀順序

1. [00 戰鬥系統規格入口](combat/00_README_COMBAT_RULES_BASELINE_V0_8.md)
2. [01 核准決策與衝突優先順序](combat/01_DECISIONS_AND_CONFLICTS.md)
3. [20 Phase 1–2 實作前 ADR 與未決事項](combat/20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md)
4. [21 Phase 2 文件驗收](combat/21_PHASE2_SPEC_ACCEPTANCE_REPORT.md)
5. [22 Agent 實作契約](combat/22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md)
6. [23 Phase 3 G0/M1–M5 計畫](combat/23_PHASE3_EXECUTION_PLAN.md)
7. [24 歷史 G0/M1 工程紀錄](combat/24_PHASE3_G0_M1_EXECUTION_REPORT.md)

其餘卡牌、AP/RP/MP、詠唱、Reaction、Boss、Damage、Combo、Last Spell、測試矩陣等完整規則均在 `docs/combat/` 對應獨立文件，**不得僅看本入口就實作**。

## 版本優先級

**使用者最新明確核准 USER_APPROVED** > 其他已核准 Phase 1/2/M 決議 > 經明確委派的實作預設 > **PROVISIONAL** 平衡係數 > **HISTORICAL/SUPERSEDED** 舊規格。文件歷史快照可能保留 OPEN 提案，依最新核准 ADR 解決；數值未正式核准不得自作主張。

## 舊版 v1.0 必須遷移的矛盾

| 原 Godot v1.0 實作／文件 | Library 新權威規格 |
|---|---|
| 每角色 8 張牌、手牌最多6 | 每角 **12 張**獨立 SP；起手及每玩家階段補至4，**手牌上限8** |
| 全隊每階段最多普通出牌2次 | 三人共享基礎 **6 AP**，允許多次合法出牌，不另設兩次硬上限 |
| 個人能量每玩家階段回滿 | 每人獨立 MP 跨回合，普通攻擊首次符合回魔條件 |
| 未用個人能量當作反應資源 | 隊伍 AP 與 RP 轉換規則；基本 Guard=1 RP、Protect=2 RP |
| 每敵方階段最多打斷一次 | 敵方行動 Reaction Window 多角色排隊，一人同窗口實際 React 最多一次 |
| Boss 穩定度兼任弱點指標 | Casting Stability 與本體 Break Gauge 分離 |
| 普通出牌三次觸發分析 | Analyze 為獨立共通命令（以完整文件最新核准為準） |
| 老版 M0–M5 以 UI／牌組編輯器為主 | 新 Phase 3：G0 環境與需求追溯、M1 Domain、M2 資源牌區、M3 回合反應、M4 詠唱 Last Spell、M5 傷害狀態 Combo Outcome |

原舊檔中的 Boss HP 300、固定傷害、種子104729等**只屬歷史 prototype**，不因此升格為新平衡 Canon。

## 重要工程與驗收邊界

- Library `24_PHASE3_G0_M1_EXECUTION_REPORT.md` 的 M1 已驗證紀錄指向 **另一個** Godot 專案 `KuroNekoLi/Astraea-Academy`，**不可直接宣稱此 `arbitrium-nexus-godot` 已通過 M1**。
- 下一步應對**本 repository 的真實程式與 CI**執行 G0 稽核：`project.godot`、Godot 版本、runner、行為差異、requirements traceability；分類為 ALREADY_IMPLEMENTED / CONFLICTING_LEGACY / MISSING / UNVERIFIED。
- 區分 `SPEC_ACCEPTANCE` 與 `ENGINE_TEST_PASS`；在此專案執行實測前，不得宣稱 M1–M5 VERIFIED。
- 後續規則變更需同步 Library 與本 repo 對應模組、ADR、測試矩陣，勿只改本入口。
