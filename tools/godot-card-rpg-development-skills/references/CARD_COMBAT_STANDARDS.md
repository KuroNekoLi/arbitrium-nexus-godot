# 卡牌戰鬥規範與測試 oracle

先讀 Spec Guardian，再讀當前 repo 的00/01、相關模組、18～21、22；本文件不是新 baseline。下面是 2026-10-15 master 快照的查核索引，使用時需核對來源批准及取代關係。任何與新版衝突的舊規則廢棄。

## 規則對照

| 主題 | 查核位置 | 快照應防止的誤植 |
|---|---|---|
| 個人牌組 | 04、19、22§2 | 每角12 SP；起手4，每玩家階段補至4，保留牌，手牌上限8；不是每輪抽4／補至8 |
| 牌識別 | 04、10、12 | definition ID 與 CardInstanceID 分開，ownership／eligibility／deck construction／卡區守恆；rarity 僅依已定內容 |
| 免費換牌 | 04、19、20 | 每角每玩家階段一次；無替代不扣次數；隔離被棄實例，真實棄牌觸發後再抽，不即刻抽回同一實例 |
| AP/MP/RP | 03、18/19、22 | 三人共享 BaseAP6，個人MP；CurrentAP合法可大於6，不能以6作消耗硬上限；剩AP轉RP，預設RP cap6，敵方階段末歸零 |
| 普攻回魔 | 03、18～20 | 每角該玩家回合僅首次符合條件普攻；無固定自然回滿；數值不猜 |
| 逐次行動 | 02、22 | 合法 action 即結算／啟動排程，同人或他人可續行；不是三人預排全回合 |
| Reaction | 07、20§7、21 | 合法窗口由玩家 Confirm/Pass，無強制倒數／auto-pass；多人queue，確認後逐筆JIT校驗；每角每敵方行動窗口最多實際執行一次 |
| Guard/Protect | 07、20 | 基本防禦不需抽卡；Guard1RP、Protect2RP；Protect重導向先於命中，用守護者防禦抗性；AoE／不可守護標籤依規格 |
| 失效 Reaction | 07、22 | 前序使後續不合法則跳過，不扣RP/MP、不棄卡、不計反應；已實際執行的效果遭抵銷不追溯退款 |
| 雙模式與中斷 | 05、19 M-D21～24 | 同SP預設同MP，Full提交扣費延後結算；普通成功中斷立即部分退MP，AP／債務不退；比例／取整不偷定Canon |
| Last Spell | 08、20§7、21 CORE-02 | 每角每戰一次獨立槽、不占12卡，Full only、不能主動Cancel；釋放前HP0強制失效、不死後續唱／復活恢復／退款；一般干擾走專用延遲削弱 |
| 勝敗 | 02、21 CORE-01 | 合法action與必要效果完結後敵全滅優先VICTORY，即使全隊HP0；不使用舊DRAW提案 |
| 2.5D | 21 CORE-03 | 純視覺，不增自由走位或AP移動 |

AP debt／Overload、最大MP、Guard比例、逐卡數值、AI權重、暴擊／取整與內容邊界逐項查核 APPROVED／DELEGATED_DEFAULT／BALANCE_PROVISIONAL／TBD，不能由此摘要推定全部已凍結。Mana 是需求中的泛稱，對接實作 MP 欄位，不另建重複資源。

## 行動與狀態契約

對每種 command 建立 `source state | command | guard | costs | next state | events | rejection code` 表。Idle/AwaitingAction/ResolvingAction/AwaitingReaction/ResolvingEffects/TurnEnding/BattleFinished 僅候選命名；保留現有 phase engine 契約。

驗證 AP不足、MP不足、RP不足、非法／已死目標、角色不能行動／HP0、錯誤owner／eligibility、已使用卡實例、過期窗口、重複command、過期state revision、已結束戰鬥、取消／中斷與Last Spell特殊限制。拒絕需對照全狀態、RNG及events hash，不只UI按鈕disabled。禁止同時接受衝突行動。

效果順序從11/20及逐卡規格抽取；Protect→命中→暴擊／攻防／元素→Guard→Barrier→取整／HP等必須按有效契約確認。Barrier與Focus Ward不可互換。Status的duration、stack、refresh、tick、dispellable、死亡後存續與觸發作用域全部需要來源；沒有明文不新增規則。

## Enemy AI

從已核准的可見Intent、行動集合、目標資格、Break狀態、成本與權重選擇。tie-break與隨機抽選使用版本化Domain RNG，記錄候選、分數／權重、選擇與draw index。簡單decision table足夠就不導入behavior tree。fixture-only敵方hit／disruption接口不能被UI或外部呼叫變成任意扣傷害指令。

## 可重現測試

同初始snapshot＋commands＋seed＋ruleset/content/RNG版本 → 相同事件序列、資源差值與final hash。包含跨角色／跨phase／Reaction JIT／洗牌／延後施法的順序測試；非法行動前後狀態與RNG不變；相同卡僅存在一牌區；不能扣費兩次。失敗保存最小fixture，不靠多跑幾個seed碰巧通過。

依13與22為每個有效 requirement 對應正／負／邊界／event-order／replay test ID。現有 `tests/test_m2_*`、`test_m3_*`、`test_m4_*` 是擴充起點；先查該測試scope與fixture限制，不能把M4.2的測試推論為M4.3、Last Spell、M5傷害已完成。
