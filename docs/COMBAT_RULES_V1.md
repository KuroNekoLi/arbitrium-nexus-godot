# 戰鬥規則入口（向後相容）

> 此檔名是歷史相容入口，**不再是一套獨立的 Combat Rules v1**。原文件曾引用已搬移的 `docs/combat/00～31` 路徑，以及已不存在的八卡戰鬥程式，該內容已過時。

**現行唯一權威**：[戰鬥系統總覽](combat/README.md)。

請依序閱讀：[戰鬥基本規則](combat/戰鬥基本規則.md) → 目前工作所涉規則 → [戰鬥引擎實作契約](combat/engineering/戰鬥引擎實作契約.md) → [規則與程式對照表](combat/engineering/規則與程式對照表.md) → 真實程式與測試。沒有新核准時，不以舊 Phase 文字覆寫主題規則。

### 現行關鍵條件

- 目前戰鬥隊伍三個位置；每位角色固定配置 12 張 SP；起手 4、每玩家階段不足 4 補 4、手牌上限 8。
- 隊伍 Base AP 為 6；各人 MP 獨立且不自然每階段補滿；React 無合法操作倒數和自動 Pass。
- Guard、Protect、完整詠唱、Break、Last Spell、HP 歸零失能、成功施放後耗竭按現行主題規則運作。
- 暫定角色、技能倍率、Boss 和數值屬 `CONTENT_PROVISIONAL`／`BALANCE_PROVISIONAL`，不能因測試存在就宣告正式核准。
- 舊八張牌／每階段兩次出牌／限時反應原型已退役；M1～M5 是現行 Domain，不是待移除的舊系統。

歷史正式決策與工程證據保存於 [封存索引](combat/archive/README.md)，退役修改見 [工程紀錄](combat/engineering/舊系統退役與驗收紀錄.md)。
