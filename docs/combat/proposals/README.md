# Arbitrium Nexus — 魔法系統設計索引

> **CURRENT GENERAL MAGIC DESIGN：v0.7；CURRENT BREAK-C DETAILED DESIGN：v0.8。** 方案 C「普通招式取消、特殊大招降級，Break 自動建立 Exposed」的**高階方向已確認**；v0.8 詳細時序與數值仍需 ADR，不得直接改 Domain。 本目錄是世界觀與下一階段玩法設計，不取代 [現行戰鬥規格](../README.md)。既有 AP／MP／RP、12 SP、雙詠唱、Break／Exposed、Combo、Last Spell 真正耗竭退場，仍以目前正式規則為準。

## 最新設計入口：總體魔法 v0.7 ＋ Break 專題 v0.8

**[魔法系統統一設計 v0.7（全系統總覽）](MAGIC_SYSTEM_UNIFIED_V0_7.md)**

**[Break／Exposed／詠唱干擾 v0.8（方案 C：最新細部規則提案）](BREAK_EXPOSED_CASTING_UNIFIED_RULES_V0_8.md)**

v0.8 **在 Break 方面取代 v0.7 的舊方向**：失衡時普通行動取消、重大招式降級、同時建立一次 Exposed，保留 Casting Disruption 的獨立性。v0.7 其餘魔法研究領域、APDebt、Buff／Debuff、限時 AP、弱點等仍是總體入口。

完整涵蓋 24 個魔法研究領域、ARCANUM 定義、Buff／Debuff／DoT／HoT、Overload／APDebt、AP／MP 減費、限時 1～3 玩家階段 AP 增益、機率性 Frozen／Paralyzed 與 Boss 個別免疫／抵抗／保護窗、逐敵人 Weakness、Break／Exposed／Casting Disruption、公開 Boss Intent／未來 EnemyActionBudget、UX、ADR 與測試。

**重大區別：使用者已同意的是設計架構，不是具體 30% 麻痺、5AP+5MP、+2AP/3期、抵抗倍率、新 SP 或程式已實裝。**

## 歷史研究（非最新設計入口）

1. [v0.6 — 控制、限時 AP 與敵方行動經濟比較](MAGIC_CONTROL_TEMP_AP_ENEMY_ACTION_ARCHITECTURE_V0_6.md)
2. [v0.5 — 資源／異常／弱點](MAGIC_RESOURCE_STATUS_WEAKNESS_OPTIMIZATION_V0_5.md)
3. [v0.4 — 原始統一魔法設計](MAGIC_SYSTEM_INTEGRATED_DESIGN_V0_4.md)
4. [v0.3 — 架構重審](MAGIC_SYSTEM_ARCHITECTURE_V0_3_REVIEW.md)
5. [24 學科玩法矩陣 v0.1](MAGIC_DISCIPLINE_PLAYSTYLE_MATRIX_V0_1.md)
6. [學科分類 v0.2](MAGIC_DISCIPLINE_AFFINITY_TAXONOMY_V0_2.md)
7. [學科分類 v0.1](MAGIC_DISCIPLINE_AFFINITY_TAXONOMY_V0_1.md)

## Agent 讀取／工作順序

根目錄 `AGENTS.md` → [現行戰鬥總覽](../README.md) → **v0.7 總體魔法設計 + v0.8 Break-C 專題** → 新玩法的單獨 ADR／Card Design Record（需明確核准）→ 程式、測試、Replay、UI 驗證。禁止將 `ARCANUM` 學科、`ARCANE` 傷害共鳴和 `ROLE_TAG:ARCANE` 資格混成一個 enum，亦禁止不經核准直接把候選新狀態寫入 Domain。
