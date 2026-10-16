# ADR-001：未提交連攜預備與隔離複合命令

狀態：USER_APPROVED（2026-10-16 本次任務）。Base：50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd。

| 要求 | 既有行為 | 本次決策 |
|---|---|---|
| CP2-PREP | A 已結算才建立 Opportunity | Controller 保存未提交選擇，絕不寫入 Domain |
| CP2-ATOMIC | 每張 SP 獨立命令 | 單一 COMMIT_PREPARED_COMBO_V2 在深複製 snapshot 逐次呼叫既有 Lv40.apply；全成功才回傳候選狀態 |
| CP2-ORDER | A→Opportunity→B→Bonus | 保留每張 SP 的費用、RNG、中間事件、勝敗 boundary；A 結束戰鬥時 B 無法執行，整組拒絕 |
| CP2-TARGET | 每張 SP 一個 target anchor | 命令分開保存 setup_target_ids 與 finisher_target_ids；目前每張一個 anchor，不將不存在的全體連攜配方當已實作 |
| CP2-REPLAY | 舊單卡 tape | 新增版本化命令；舊解碼不變；內部命令 ID 由外部 ID 確定性衍生，保留 seen IDs |
| CP2-COST | M2 Cost Engine | A 前查詢、A 結算後查詢 B；UI 只顯示 Domain quote，不自行計算 |
| CP2-EXCEPT | Full Chant／Last Spell／Reaction | Preparation 僅支援既有瞬發攻擊與防護配方；不縮短詠唱、不引入終式共鳴 |

既有配方仍為 CONTENT_PROVISIONAL／BALANCE_PROVISIONAL。配方以卡牌定義匹配，不以 A/B/C 推論角色身分。防護配方允許不同合法友方目標；攻擊配方要求共同敵方目標。預覽在 detached snapshot 執行相同 Resolver，不回寫 RNG、卡區、事件或資源；同 seed/snapshot/命令重播相同結果。

採用 Clone-and-Commit，而非先提交 A 再補償退款；後者無法回滾 RNG、觸發事件及傷害。未引入第二套交易引擎。UI 不把潛在配方視為真正 Opportunity；成功候選中必須看到來自該 Setup 的新 Opportunity 及 ComboExecuted。

現況限制：Lv40 目前只有單 Boss，兩種可執行配方；多敵人／敵全體／友全體連攜需要正式配方及 Resolver 支援，不為截圖創造玩法。新視覺先使用既有素材及 placeholder，另附 AI 素材規格。
