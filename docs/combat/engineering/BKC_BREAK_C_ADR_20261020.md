# BKC-01 — Break C／Exposed／Boss Action Contract（2026-10-20）

> AUTHORITATIVE DESIGN DECISION: USER_APPROVED Break C；implementation values BALANCE_PROVISIONAL. 此 ADR 授權實作行為，但 CI 未綠前不宣稱功能已驗證。
> 關聯總體設計：[v0.8](../proposals/BREAK_EXPOSED_CASTING_UNIFIED_RULES_V0_8.md)

## 採用與界線

1. BreakGauge 是本體失衡量表，CastingStability 是單次詠唱；互不混用。每張合法 SP 完整結算之後才判斷 Break，整張 SP 只觸發一次。
2. Break 歸零時鎖定一次「下一個合格且尚未開始」的 Boss 行動、**並立即創建 Exposed ×1**；原本已經有 Exposed 時不可疊加或刷新。
3. 公開 Intent 設定 `break_response` = `CANCEL`／`DOWNGRADE`／`NOT_ELIGIBLE`；`DOWNGRADE` 的 fallback 與目標/範圍必須是玩家出牌前公開的分支。已開始／結算行動絕不回溯。
4. `CANCEL` 的 EnemyAction 仍依既有 Scheduler 結算為一次取消動作，不產生攻擊傷害、免費 Counter 或偽 Reaction。 `DOWNGRADE` 選定公開預備弱化效果再依既有 Reaction 系統處理。
5. Boss 的 Exposed 來源為 `on_break`（預設 true）、`on_special_posture`、`on_boss_action`。後兩者是內容選配，不是必要條件；姿態授權 SP 與 Break 都用同一槽位。
6. Exposed 只能由來源行動**結束後的不同合法 SP**利用一次；成功命中才消耗，全 Miss 保留；持續至**下一玩家階段結束**，避免當期 AP 耗盡時白費。本版暫沿用內容既有合法 Finisher 增益：不以 ADR 隨意新增通用 +20% 倍率。
7. Break 壓制一個合格行動後 BreakGauge 重新填滿，下一完整玩家階段 Break 冷卻保護：該階段 BreakDamage 不扣 Gauge，HP 傷害照常。BKC 將以配置欄位啟用；不能無限疊層。每個 Boss 特定保護期日後可設定。
8. `CORE_OPEN` 主動弱點是**內容配置可選**，不需讓 Boss AI 主動選擇暴露。示範 Lv40 保留蓮 R01/R07 `CORE_OPEN` 觸發 Exposed；不要求 `CORE_OPEN` 才能建立蓮的攻擊 ComboOpportunity。
9. 硬控與 Break 不得重複取消同一 EnemyAction。這次不引入機率麻痺／冰凍新引擎；保留後續專屬 ADR。
10. 施法者 Full Chant、Focus Ward、Last Spell、支付 AP／MP／RP、Reaction Window 原規則不改。敵法術合法 Interrupt 優先於相同釋放動作的 Break 降級；不可以再免費壓制下一招。

## Lv40 示範 Profile（內容候選，非世界共通）

- B01/B02/B03/B04：普通攻擊 → `CANCEL`。
- B05/B08：蓄力大招準備 → `DOWNGRADE` 為 B12「失衡蓄力失敗」（不發動高階詠唱、不免費普攻）。
- B06：單體光束 → `DOWNGRADE` 為 B13「弱化光束」；保持已鎖定的同目標。
- B09：全體掃射 → `DOWNGRADE` 為 B14「弱化掃射」；仍使用既有公開全體目標規則。
- B07：防護技能 → `CANCEL`；B10：合法中斷後冷卻 → `NOT_ELIGIBLE`；B11：舊版降級 fixture → `NOT_ELIGIBLE`。
- B12/B13/B14 是版本化示範內容、中文英文各有翻譯；不能從客戶端輸入任意 SkillId；攻擊倍率在內容表標記為 provisional。
- Lv40 現有初始 `Boss.publish()` 和每次 `START_PLAYER_PHASE` 已公告下一招；通用 M5 假資料在 `END_PLAYER_PHASE` 才 publish，需要保持相容，不可宣稱所有模式原本都先公告。

## 測試與驗收

- BKC-01 文件與原本權威路徑一致；BKC-02 至 04 改動請見對應 handoff。
- 驗收涵蓋合法卡真付費、Break 多 hit、Barrier、取消與降級不偷換、Intent 分支公開、保護期防鎖、Exposed 來源可選與期限、合法 CastingInterrupt 與 Break 同時命中、Last Spell、Combo、固定 Seed 重播、1280×720/1920×1080 UI、zh_TW/en。
- 只有 Actions 同一 SHA 完成相關 headless 測試才能宣稱已驗證；不能跳過失敗的舊測試。
