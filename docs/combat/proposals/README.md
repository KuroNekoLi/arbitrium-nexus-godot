# Magic System Design Proposals — 導覽與規格狀態

> **CURRENT INTEGRATED PROPOSAL：v0.4**。本目錄是魔法設計提案，不是新 Combat Rules。實際戰鬥以 [目前戰鬥總覽](../README.md)、最新 USER_APPROVED 規範和現行 Domain 為準。**使用者已確認深世界觀／易懂實戰的設計方向，並授權整合文檔；未批准每種學科、新技能與新倍率。**

## 優先閱讀：統一母版與資源／狀態／弱點優化

1. **[控制異常、限時 AP 與敵方行動架構 v0.6（LATEST FOCUSED PROPOSAL）](MAGIC_CONTROL_TEMP_AP_ENEMY_ACTION_ARCHITECTURE_V0_6.md)**：Boss 逐狀態控制免疫／機率、強控防連鎖、下 1～3 玩家階段 AP 加成、A 現行 EnemyIntent vs B 全對稱敵 AP／SP vs C 混合 EnemyActionBudget 的架構比較。**只有設計提案，沒有改 Domain。**
2. **[魔法系統統一設計 v0.4（CURRENT DESIGN PROPOSAL）](MAGIC_SYSTEM_INTEGRATED_DESIGN_V0_4.md)**：集中整理 24 學科、奧術定義、學科／共鳴／職能／效果的邊界、Buff／Debuff、Overload／APDebt、Weakness／Resistance、Break／Exposed、Casting Stability、Combo、完整工程現況、玩家 UI 與准入 Gate。**PROPOSED；不授權改 Domain。**
3. **[資源魔法、異常狀態與弱點優化 v0.5（LATEST SPECIALIZED PROPOSAL）](MAGIC_RESOURCE_STATUS_WEAKNESS_OPTIMIZATION_V0_5.md)**：清楚分開 Overload、即時／下期 AP、AP／MP 減費、敵方行動壓制；提出灼燒／寒霜／感電等六個狀態候選，保留 Weakness／Break／Exposed／Casting Disruption 的既有邊界。**僅設計，未批准新機制。**
2. **[v0.3 — 框架研究（HISTORICAL）](MAGIC_SYSTEM_ARCHITECTURE_V0_3_REVIEW.md)**：當時對 24 學科與卡牌辨識的設計批判與遊戲研究；已納入 v0.4。
5. **[v0.2 — 已確認的易懂實戰方向（HISTORICAL）](MAGIC_DISCIPLINE_AFFINITY_TAXONOMY_V0_2.md)**：世界觀深入、實戰易懂、少量共用機制是確認的方向，其他學科仍是候選。
6. **[24 學科矩陣 v0.1（HISTORICAL）](MAGIC_DISCIPLINE_PLAYSTYLE_MATRIX_V0_1.md)**：學科身份、示例與限制，不等於現存正式卡。
7. **[v0.1 — 原始三軸分類（HISTORICAL）](MAGIC_DISCIPLINE_AFFINITY_TAXONOMY_V0_1.md)**：概念分類初稿。

## 版本採用原則

- **設計研究**：v0.4 為世界觀／魔法整合母版，v0.5 補資源／狀態／弱點，v0.6 補 Boss 控制／限時 AP／敵方行動經濟比較；三者共同作為最新設計輸入；舊版提案保留為歷史，不得以候選替代現行規則。
- **戰鬥實作**：只有當前 `docs/combat/README.md` 及其已核准規則是可執行的權威；v0.4 本身不是新的 Combat Rules Baseline。
- **名詞歧義**：`ARCANUM` 學科 ≠ `ARCANE` 傷害共鳴 ≠ `ROLE_TAG:ARCANE` 資格；Buff／Debuff ≠ Break ≠ Exposed ≠ Casting Disruption。
- **候選數值**：`MaxAPDebt=8`、Lv40 Boss FIRE/ARCANE 倍率、Boss Break Max、SCORCH_TEST 等各有 fixture；本目錄不批准新的全域平衡。
- **分支與驗證**：僅魔法提案分支文件變動，不宣稱 Godot CI 或 Boss 真人試玩因此通過，也不自行合併 master。

## 後續建議

由使用者核准 v0.4 分類方向後，再選 2–4 張具不同可讀戰術抉擇的魔法候選，依 **Card Design Record → Rule/ADR → QA → i18n/UI → Godot/Replay** 逐步導入。**不以一次實作 24 套系統為目標。**
