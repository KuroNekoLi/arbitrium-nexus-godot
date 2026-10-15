# 13 — 自動化測試、驗收條件與平衡實驗

> **2026-10-14 LIBRARY Phase 2 最新補充（現行 SoT）**：請優先閱讀 [`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md) 與 [`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)。M-D18～M-D31 已核准；P2-D10～D16 的**設計方向**已整體核准，數值／部分結算邊界仍 TBD。較早段落的「P2-D08 未決」「換牌僅提案」「手牌上限 TBD」「完整詠唱較貴 MP」等屬歷史文字，與 19 衝突時以 19 為準。**僅 Library 更新，未同步 GitHub；尚無 Godot 執行／CI PASS 證據。**


## 1. 驗收層級

- **Unit**：資源守恆、卡牌移區、狀態限制、詠唱進度、ComboOpportunity。
- **Integration**：一整回合完整時序、三角色切換、Boss意圖＋Reaction、Last Spell。
- **Property-based / fuzz**：任何seed／合法命令序列不能負資源、重複卡、同一技能多次結算。
- **Replay regression**：固定seed+command tape輸出相同事件雜湊。
- **Balance simulation**：至少100個seed與不同策略（積極施法、保守、打斷、連攜、Last Spell、共鳴），分別量測勝率/回合/參與/資源，而非只比較單seed。

## 2. MVP 必通條件

| Test ID | Setup / Action | Expected |
|---|---|---|
| DECK-001 | 12卡開戰 | 每角手牌4、牌庫8、棄牌0 |
| DECK-002 | 打出2卡後開始新回合 | 手牌2補到4、卡進棄牌 |
| DECK-003 | draw剩1、discard10、hand1 | 抽完1→洗棄牌→再抽2；不重複 |
| DECK-004 | 牌庫和棄牌都空、hand<4 | 不死循環、不憑空產牌 |
| ECON-001 | 三人共6 AP，出牌費用合計>6 | 超額動作拒絕，沒有部分扣費 |
| ECON-002 | 角色普通攻擊多次 | 回魔次數符合已核准設定（原型每角首次） |
| ECON-003 | MP不足使用Full Chant | 拒絕，卡不移區 |
| CAST-001 | Full Chant開始 | 扣費一次、卡入Casting Zone、Concentration |
| CAST-002 | caster Concentrating 普攻 | 拒絕、state不變 |
| CAST-003 | 下玩家階段詠唱完成 | 不重扣費、正確結算、解除Concentration |
| CAST-004 | FocusWard存在且受干擾 | Ward先吸收、剩餘再削減Stability |
| CAST-005 | Boss法術穩定度歸零 | 當次法術被打斷，不發生原預定攻擊 |
| BREAK-001 | Boss Break=0但Casting>0 | Break和Casting擁有獨立結果，依核准規則 |
| REACT-001 | 無 RP 嘗試 Guard/Protect；有 RP 但無特殊 SP 嘗試特殊 Reaction | 均拒絕且不扣費；但基本 Guard/Protect 有 RP 時不需卡牌即可用 |
| REACT-002 | 過期window ID再次反應 | 拒絕，不二次結算 |
| COMBO-001 | 不同角色順序＋tags＋狀態合法 | 顯示機會，玩家可普通或Combo施放 |
| COMBO-002 | 合法兩卡成本2+1AP | Combo附加效果 **0 額外AP**，只扣3AP |
| COMBO-003 | 第二張卡沒真正使用 | 不會憑Expose免費發動連攜 |
| COMBO-004 | Concentrating角色作finisher | 拒絕；但隊友可強化既存CastingInstance |
| LAST-001 | Last Spell不在12張卡牌 | 永遠不會被抽到 |
| LAST-002 | Last Spell開始後再手動取消 | 拒絕；不可重新啟動 |
| LAST-003 | First destabilization | 延遲一次；不被一般中斷直接取消 |
| LAST-004 | 第二次destabilization | 不會無限延遲、依參數削弱 |
| LAST-005 | 成功結算 | Exhausted；同角色所有新行動被拒絕；全隊AP配額不被直接降低 |
| RNG-001 | 同版本／deck／seed／命令 | 事件序列和最終hash一致 |

## 3. 暫時阻塞的測試

**歷史註記（SUPERSEDED）**：舊 `OPEN-P0-HIT` 已由 P2-D01～D09 裁定命中方向，舊 `OPEN-P0-OUTCOME` 已由本輪 CORE-01 核准玩家優先勝利，`OPEN-P0-LIFE` 的一般失能／Exhausted 已由 PRE3-R13/R14 與 CORE-02 的 Last Spell 強制失效確定。**個別數值、特定卡牌／復活邊界仍可能 CONFIGURABLE/CONTENT_DEFERRED**，但不得將上述方向誤標為 BLOCKED_BY_DECISION。

## 4. 平衡報告必含欄位

每策略/seed：是否勝利、完成回合、Boss HP、隊伍HP、Last Spell完成/延遲次數、Combo條件成立/發動次數、Boss施法/被打斷次數、每人AP使用比例、RP剩餘/浪費、MP不足拒絕次數、Full Chant完成率、手牌卡死回合數、每回合有效選項數。輸出置信區間或分位數，避免用單次比賽下結論。

## 5. 檔案與PR驗收

PR必附更改的 rules/ADR IDs、失敗修復前後的seed與事件log、涉及的 module documents、可執行測試指令和實際結果。未執行測試不得寫PASS。新增強制確認流程的UI至少驗證取消按鈕只在提交前有效。


---

## 6. Phase 1 Acceptance Criteria：規則契約、負例、邊界與回歸矩陣

> 狀態：**SPECIFIED / NOT EXECUTED**。這是可供 Godot headless、unit、integration、property-based 實作的預期行為，**不是已完成的測試執行報告**。如使用未核准示例數值，test fixture 名稱與 log 必標 `PROVISIONAL`。

### 6.1 AP／RP／普通攻擊

| Test ID | Setup / Commands | Oracle / Expected (APPROVED) |
|---|---|---|
| P1-ECO-001 | 6 AP，角色A連續普通攻擊兩次，各次成本暫為1AP | 兩次攻擊可成功；只有首個**成功執行**普通攻擊觸發A的MP回復；B的首次獨立計數 |
| P1-ECO-002 | A普通攻擊因不足AP/非法狀態拒絕，稍後合法攻擊 | 首次回魔資格不可被遭拒命令消耗；失敗不扣資源 |
| P1-ECO-003 | A攻擊、B出牌、A再攻擊、C出牌 | 可以交錯使用共享AP，無每角色固定行動次數限制 |
| P1-ECO-004 | 玩家階段末AP=6，無任何花費 | 敵方階段開始 RP=6、AP=0，不截斷到2/3/4 |
| P1-ECO-005 | 玩家階段末AP=3 | RP=3，AP=0；總量守恆 |
| P1-ECO-006 | 玩家階段末AP=0 | RP=0，任何付費Reaction不可執行 |
| P1-ECO-007 | 敵方階段開始RP=4，只花1，然後敵方階段結束 | 無論是否仍有後續攻擊，RP歸零；下輪不能沿用3RP |
| P1-ECO-008 | 敵方階段內兩次不同敵方行動，前者花2RP | 後者看見的是扣費後剩餘RP，不重新轉換AP |
| P1-ECO-009 | 未來額外生成RP的卡未定義 | 應標 `BLOCKED_BY_DECISION`，不可臆測「RP6 cap」或無限產生 |

### 6.2 基本 Guard／Protect 與手牌

| Test ID | Setup / Commands | Expected |
|---|---|---|
| P1-RXN-001 | actor手牌無任何Reaction SP、RP=1、合法自身受到攻擊 | Basic Guard仍合法，支付1RP；不消耗任何CardInstance |
| P1-RXN-002 | actor手牌無任何Reaction SP、RP=2、可守護單體隊友受擊 | Basic Protect仍合法，支付2RP；不消耗任何CardInstance |
| P1-RXN-003 | RP=0/1時Protect | 不合法且不扣RP；RP=1時Guard仍可合法 |
| P1-RXN-004 | actor沒有該Reaction SP卡、其他隊友有 | actor不能使用別人的SP；基本Guard/Protect不受影響 |
| P1-RXN-005 | 同一window A排Guard後又排Protect | 確認前必須要求擇一；不得成功執行兩個反應 |
| P1-RXN-006 | 同window A與B各排合法不同Reaction，RP足夠 | 兩人都能執行，不能因全局「一張卡」限制造成第二人被拒 |
| P1-RXN-007 | A已在window1反應，另一enemy action開window2 | 在window2若狀態與RP合法可再次反應；計次鍵含window ID |
| P1-RXN-008 | 同window三角都合法、共同資源足夠 | 可三角各反應一次；不可自行設定全局2反應上限 |
| P1-RXN-009 | actor為Exhausted | 新基本／特殊Reaction拒絕，零扣費；不把Exhausted等同死亡判定 |
| P1-RXN-010 | actor Concentrating，沒有CAST_COMPATIBLE標籤 | 一般Reaction不合法；隊友仍能合法守護 |

### 6.3 Guard 固定比例／角色防禦（數值僅測試）

| Test ID | Setup / Commands | Expected |
|---|---|---|
| P1-GRD-001 | DEF計算後HP傷害30，暫時以 Guard率40%測試 | 得到浮點基準18（最後取整 TBD）；不能先對原始攻擊施40%再算DEF |
| P1-GRD-002 | 兩角色同一原始攻擊但DEF不同 | Guard固定比例相同，仍因自身DEF/RES不同而承受不同數值 |
| P1-GRD-003 | Guard後試圖免費反擊／減BossCastingStability | 不允許；基本Guard僅減損，不產生特殊SP效果 |
| P1-GRD-004 | Guard後受到直接 CastingInstance 干擾 | Guard不自動提供FocusWard／阻斷干擾 |
| P1-GRD-005 | Guard最終取整／真傷最小HP傷害 | `BLOCKED_BY_DECISION`；不得把 fixture 的floor/ceil私自升格 |

### 6.4 Protect 轉向／命中型與 直接詠唱型干擾

| Test ID | Setup / Commands | Expected |
|---|---|---|
| P1-PRT-001 | Boss單體物理攻A，B使用Protect | 原攻擊傷害承受者改B，按B的DEF/RES重算；A不受可轉移HP傷害 |
| P1-PRT-002 | Boss單體魔法攻A，B使用Protect | 同上但使用B的相應魔法抗性；非只攔物理 |
| P1-PRT-003 | A原本承傷45、B自身承傷30（樣本） | Protect後應是B受30，不是B受45；Protect不免費加20%減傷 |
| P1-PRT-004 | Boss全體或明示多目標攻擊 | 基本Protect不合法、不可扣2RP；特殊SP按自身定義另論 |
| P1-PRT-005 | Boss單體但帶明示`unprotectable`標記 | 基本Protect不合法，UI消費前須顯示理由 |
| P1-PRT-006 | A正在Full Chant、Boss單體命中附帶CastingDisruption 15，BProtect | A未承受該命中附帶干擾，Stability保持不變；守護者按實際結算 |
| P1-PRT-007 | Boss直接target=A.casting_id施加干擾 | 基本Protect不攔，A的Casting按原干擾規則處理 |
| P1-PRT-008 | 同一招有可守護彈體+獨立 Casting Lock | Protect只轉向彈體及其命中附帶效果；直接Casting Lock繼續指向原casting_id |
| P1-PRT-009 | 守護者同窗口又要求自我Guard | 違反每人每窗口一次，不能雙重付款、重算或偷用兩指令 |
| P1-PRT-010 | 被保護者本有HP Barrier、Protect改變承受者 | 不可繼續把原Barrier當成守護者的免費Barrier；具體Barrier先後待別章確定 |
| P1-PRT-011 | 複數守護者互相轉向、毒/擊退附帶效果 | `BLOCKED_BY_DECISION`，禁止以偶然的事件排序固定規則 |

### 6.5 Reaction planning、D16失效跳過、UI模式

| Test ID | Setup / Commands | Expected |
|---|---|---|
| P1-QUEUE-001 | 選A Protect、B Ward、拖曳改為B→A，再確認 | 依最終明示順序結算，不按SPD或隱藏固定種類排序 |
| P1-QUEUE-002 | 將SP加入草稿後取消整組 | RP、MP、手牌位置及actor本窗口已反應標記皆維持不變 |
| P1-QUEUE-003 | 同窗口A/B各合法Reaction，確認一次 | 只出現一次總確認，不為B另彈第二個確認；逐步再校驗 |
| P1-QUEUE-004 | A反制成功取消攻擊，B後序Protect依賴該攻擊 | B`SKIPPED_INVALIDATED`：RP/MP零扣、手牌不移、actor不計次 |
| P1-QUEUE-005 | A反制成功取消攻擊，B後序獨立持續護盾SP仍合法 | B照常執行、正常扣費與移區，除非卡面明定必依賴該攻擊 |
| P1-QUEUE-006 | A Protect先執行並扣費，B後來使攻擊最終失效 | A已經執行；不能用D16追溯免除A已付成本 |
| P1-QUEUE-007 | 重複Confirm同window+same command ID | 不得重複扣資源、施法或丟卡 |
| P1-QUEUE-008 | SP排在第二，前序令其觸發失效 | 該SP仍在hand且無棄牌trigger；同名另一CardInstance不受影響 |
| P1-QUEUE-009 | 排隊當時合法，確認時RP不足 | 拒絕提交/要求調整，不能負RP或先扣一半費用 |
| P1-QUEUE-010 | Smart／AlwaysAsk／Quick，輸入同一已確認reaction queue | 引擎狀態／事件/資源計算一致（UI提示數量可不同）；禁止自動花RP |
| P1-QUEUE-011 | 有合法重大Reaction事件且Smart開啟 | 應提供可用的清楚回應方式；重大分類門檻待UI ADR，不能在未核准超時下自動沒收 |
| P1-QUEUE-012 | 敵行動無任何合法反應 | Smart/AlwaysAsk皆不可彈出空白阻塞選單 |

### 6.6 Property-based 與測試證據

- 任意合法 seed/reaction queue：`team_rp >=0`，`actorExecuted(window_id)≤1`，`SkippedIntent.resourceDelta=0`，`SkippedIntent.cardZoneDelta=0`，`SkippedIntent.actorUseDelta=0`；卡牌實例守恆。
- 同一seed/content/rules版本與player command tape，必須得到同序列反應 events、相同最終 hash（包括不同RP池餘額與guard damage），不能依 FPS/UI動畫耗時而變。
- RP 0,1,2,3,4,5,6 每個邊界都測，不要只測2；在多人Reaction中隨機調序做差異性測試，正確區分「確實能影響結果」與「確定性同順序」。
- 每次正式實作PR需附：實際Godot headless執行指令、commit SHA、測試檔名、每類別通過/失敗數、用到的provisional配置值、log／replay seed。**目前此文件沒有任何已執行測試聲稱**。

## 7. Phase 1 文件驗收清單（非程式測試）

- 16份規格及decision log均含同一套 D01–D16結論，沒有活躍 `max_rp=2` 等過期指示。
- README 索引、01 ADR、03 經濟、07 反應、11 計算、12 事件與13驗收相互引用一致。
- 舊 `D01..D23` 重新識別為 `LEGACY-Qxx`，不與 `P1-Dxx`撞號。
- 每一條完成的規則都有至少一個正向、拒絕與跨窗口/跨回合邊界案例。
- 若變更觸及 Repo 或 Library，須檢查每份檔名、路徑、實際變更內容與遠端Commit SHA；操作失敗不能寫同步完成。

## 8. Phase 2 後續驗收矩陣（SPECIFIED，NOT EXECUTED）

| Test ID | 輸入／事件 | 期望 |
|---|---|---|
| M18-AP-001 | BaseAP6；SP 花2得8 | CurrentAP=12，不以6截斷 |
| M18-RP-002 | Player Phase 末剩9 AP；RP cap6 | RP=6，多餘3不可延續 |
| M19-MP-001 | 無自然回魔來源的角色跨 Player Phase | MP不因過回合而增加 |
| M20-MP-002 | CurrentMP9 MaxMP10；合法恢復4 | MP=10，超額3消失 |
| M21-CAST-001 | 同一正常雙模式 SP | Chantless／Full Chant 預設 MP 成本相同、Full 提交支付後延遲生效 |
| M22-CAST-002 | Full Chant Casting Interrupt 成立 | 立即按配置比例部分退 MP，不退 AP，不消除 Overload Debt；退 MP capped MaxMP |
| M25-HAND-001 | 手上3/4/7 張且開始新 Player Phase | 分別抽1/0/0；任時手牌不得 >8 |
| M25-HAND-002 | 手牌7，合法額外抽3且無打牌先移區 | 只抽1，餘下需求不將牌從 draw pile 移除 |
| M26-SWAP-001 | 每角色第一次合法免費換牌 | 0 AP/MP、換1卡、扣該角色一次；其他角色不受影響 |
| M27-SWAP-002 | 抽牌堆空，棄牌堆有其他合法實例 | 重洗也絕不立刻抽回剛換掉的原 CardInstance |
| M29-SWAP-003 | 除原卡外沒有合法替代實例 | 操作拒絕、手牌/區域/次數不變、不發抽棄牌事件 |
| M30-SWAP-004 | 有棄牌回 MP + 抽牌 Buff | `CardDiscarded` 及回 MP 先於 `CardDrawn` 及其效果；事件可重播 |
| M31-MP-001 | 角色各自 BaseMaxMP 不同，特性提高其中一名 | 各自 MaxMP 與回復 cap 獨立；不能改隊友 MP |
| P2-D10-001 | 同命令、同 seed、同戰鬥資料 | 完整傷害事件與 HP 結果一致，可追溯防禦／暴擊／抗性／盾 |
| P2-D11-001 | 多階段小數傷害配置 | 僅最終取整；不可在未配置時暗定最低1傷 |
| P2-D12-001 | 同時有 Barrier 與 Focus Ward | 前者只處理HP傷害、後者只處理詠唱干擾 |
| P2-D13-001 | 兩種不同 Buff/DoT 配置 | 各自遵守層數／時限／tick／dispellable 規則 |
| P2-D14-001 | HP0 | 角色進 Incapacitated，不可一般主動行動 |
| P2-D15-001 | 多段同張 SP 中途令目標HP0 | 不無條件丟棄仍合法結算的其餘效果；在完成合法行動結算後進勝敗檢查 |
| P2-D16-001 | 相同 seed + command tape + rules version | 狀態與事件雜湊完全一致 |

**注意**：全部是**規格案例**，尚未附實際 Godot 4 headless test log，不能標 PASS。

## 9. Phase 1–2 實作前授權預設驗收矩陣（SPECIFIED / NOT EXECUTED）

| Test ID | 情境 | 預期狀態與 log |
|---|---|---|
| PRE3-01 | 單體技能 A 命中原目標低閃避，B 高閃避先合法 Protect | 先重導向 B，再用 B 閃避擲命中並依 B 防禦；不使用 A 已擲結果 |
| PRE3-02 | 同一 Action 被 B、C 依序排 Protect | B 首次成功、C 的改向失效跳過，不扣後序RP、不可連鎖到 C |
| PRE3-03 | Boss 同一 EnemyAction 連續 3 hit；A Guard | A 的該次 1 RP Guard 作用於本 Action 所有合格 HP hits，下一獨立 Action 不帶過去 |
| PRE3-04 | Boss 單體三段物理傷害對 A；B Protect | 全部 hit 以 B 為承受者；AoE／多目標必拒基本 Protect |
| PRE3-05 | Protect 遇上中毒/擊退、命中型詠唱干擾與直接指定施法實例干擾 | 只有標記 follows_damage_recipient 的合法命中依附項轉向；直接 CastingInstance 不轉向 |
| PRE3-06 | Reaction Queue 2 筆；首筆使次筆 actor HP0 或共享 RP 不足 | 次筆在執行前跳過、無費、無棄牌、不占已執行次數，其他獨立合法後序繼續 |
| PRE3-07 | 一筆單體 HP hit：防禦後100，Guard40%，Barrier20 | provisional Guard 後60，Barrier吸20，最後HP傷40；Focus Ward不扣 |
| PRE3-08 | 攻擊經修正得0.8 HP，無保底效果 | final floor0；不得在中間小數階段取整或強制1 HP |
| PRE3-09 | 同一個 phase boundary 多個不同 DoT/HoT/到期 | 逐狀態依明文 tick trigger/priority/instance_id，結果與 seed/指令帶一致 |
| PRE3-10 | 同時有 SetCost、累加折扣、有限次折扣與 Overload | SetCost→數值減費→有效最低→不足差額借 AP；扣次序穩定、trace可重播 |
| PRE3-11 | 免費換牌預檢無替代牌 | 不棄牌、不抽牌、不耗次數、不發事件（維持 M-D29） |
| PRE3-12 | 換牌預檢有候選，但 CardDiscarded 觸發拿走最後替代卡 | 原卡末端進 discard，發 CardDrawFailed，不發 CardDrawn，換牌額度消耗且不回滾觸發 |
| PRE3-13 | 一般 Full Chant 施法者 HP0，並未被合法 CastingInterrupt | 取消並移入discard；不返 AP、不自動套中斷部分退款 |
| PRE3-14 | Exhausted 角色成 Boss 單體攻擊目標，隊友 Protect 後又受治療 | 允許受擊/保護/治療但不可發新行動，治療不移除 Exhausted |
| PRE3-15 | Incapacitated 的手牌4，普通治療命中 | 不自動復活／重抽/棄牌；明文 Revive 才能恢復 HP>0與行動資格 |
| PRE3-16 | Last Spell 已提交但尚未釋放，施法者 HP0 | 立即 `LastSpellInvalidated(CASTER_INCAPACITATED)` 並取消到期效果，**永不死後續放**（USER_APPROVED） |
| PRE3-17 | Boss 與最後一位我方角色在同一合法行動事件結算後都 HP0 | 行動及必要觸發結算完成後 `VICTORY`（USER_APPROVED，劇情通關） |
| PRE3-18 | Quick UI/動畫加速、seed/state/tape相同 | domain events/outcome 完全一致；不能用真實按鍵延遲決定自動扣費或 Pass |
| PRE3-19 | 各角色不同MaxMP，普通攻擊回魔2與Casting Interrupt退50% floor | fixture值可調，不超過當前MaxMP；測試 log 必顯示 BALANCE_PROVISIONAL |
| PRE3-20 | 有9張抽入請求而hand已7張，牌庫中有其他實例 | 最多抽1張至8；不把超出容量的牌從牌庫移除，且不得造出同一CardInstance兩份 |

以上均為**預期案例**。沒有 Godot 版本、實際執行命令、seed、event log、最終狀態 hash 和 CI evidence，任何案例都不得宣稱 PASS。

## 10. Phase 2 USER_APPROVED 四項核心決策 — Spec Acceptance Cases（全部 SPECIFIED / NOT EXECUTED）

| Case | 類型 | 給定／輸入 | 預期結果 |
|---|---|---|---|
| `P2-OUT-01` | 正例 | 同一完整合法多段技能令最後 Boss 與最後可戰鬥隊員 HP0 | 所有應合法結算事件完成後，`VICTORY`（不會 DRAW） |
| `P2-OUT-02` | 對照 | 所有我方 HP0，但仍至少一敵人 HP>0 | `DEFEAT` |
| `P2-OUT-03` | 邊界 | Boss HP0 而仍有我方存活 | `VICTORY`；勝敗檢查不截斷單張技能合法事件 |
| `P2-LAST-01` | 正例 | 甲 PlayerPhase1 啟動 2 回合後生效的 Last Spell；下回合甲 HP0 | 立即 `INCAPACITATED → LastSpellInvalidated`，第3回合到期無傷害 |
| `P2-LAST-02` | 費用 | 上述被強制失效且本回合合法支付 AP/MP/Overload | 不返 AP、MP 或減掉債務，once-per-battle 已使用 |
| `P2-LAST-03` | 復活 | 失效後甲被 Revive，仍在原到期時間之前 | 原 Last Spell 不恢復、不再發動，不能同戰再使用 |
| `P2-LAST-04` | 對照 | 玩家試圖主動 Cancel 尚未生效的 Last Spell | 拒絕；不是合法取消 |
| `P2-LAST-05` | 對照 | 仍有 HP 的施法者 Last Spell 被一般 Casting Disruption | 延遲/削弱而非第一下直接取消（保留特別規則） |
| `P2-LAST-06` | 邊界 | Last Spell 已合法釋放完成，同 Action 後續事件施法者 HP0 | 已釋放效果不回溯取消；結束判定按 `P2-OUT` |
| `P2-VIS-01` | 視覺 | 同一命令/seed 切換 2D 與 2.5D 演出 | Domain event log、HP、資源與勝敗完全一致 |
| `P2-VIS-02` | 負例 | UI 嘗試 Phase 3 自由走位或移動成本操作 | 不存在自由移動指令，不能以 2.5D 換得新增走位 |
| `P2-RXN-01` | 正例 | Quick 開啟、合法 Reaction、玩家停留 120 秒才 Confirm | 不自動 Pass，仍依確認的合法 queue 結算 |
| `P2-RXN-02` | 對照 | Quick 開啟、玩家明確 Pass | 不消耗 RP／手牌；敵方行動續行 |
| `P2-RXN-03` | 負例 | 任意 mode 有合法 Reaction，但未回應／動畫已播完 | 不得 timeout、自動Pass、或自動花費資源 |
| `P2-RXN-04` | 邊界 | 本敵方行動沒有任何合法 Reaction | 可略過空窗口，不強迫使用者開空選單 |
| `P2-REPLAY-01` | 決定性 | 固定 `seed + initial_state + ruleset_version + command_tape`，分別用 2D/2.5D、不同 FPS、同樣人工決策 | domain event trace、state hash、BattleOutcome 完全一致 |

此表是**規格 oracle**，不聲稱 Godot unit/integration/replay 任何一項已執行或 PASS。詳細稽核與待測清單見 `21_PHASE2_SPEC_ACCEPTANCE_REPORT.md`。

## 11. A 方案：來源 13 中獨有的 P2-D16 驗收 ID（SPECIFIED，不宣稱本組已執行）

以下 10 個來源版本中特有的測試 ID 在目標原矩陣中未列出，本次增量併入，不覆寫或降低原有驗收案例。若既有 Godot CI 覆蓋了相同語義，Agent 應逐項建立 **ID → 真實測試 → 執行記錄 → Commit** 的映射，不能將規格測試直接報成新通過。

| ID | 條件 | 預期 |
|---|---|---|
| `P2-AP-01` | AP 增益使 `CurrentAP>6` | 合法共享池可超過 6；沒有全域硬上限 |
| `P2-MP-01` | 角色回復量超過當前 MaxMP | 截斷到各角色各自 MaxMP |
| `P2-CAST-01` | 同一雙模式 SP | Chantless／Full Chant 預設相同 MP |
| `P2-CAST-02` | Full Chant 因有效干擾中斷 | 立即部分退 MP，不退 AP 或 Overload 債務 |
| `P2-DECK-01` | Player Phase 開始／手牌容量 | 每人最多 8，只有低於 4 時才補至 4 |
| `P2-MULL-01` | 免費換牌有合法替代 SP | 棄牌觸發先結算，抽牌觸發後結算；原 instance 本次不可抽回 |
| `P2-MULL-02` | 免費換牌無合法替代 SP | 拒絕，手牌／事件／換牌額度均不變 |
| `P2-DMG-01` | 同 seed/state/command tape | 事件與狀態 hash 一致，傷害步驟具完整 trace |
| `P2-STATUS-01` | Buff/Debuff/DoT 疊層／刷新／到期／驅散 | 依逐狀態明文設定，不使用隱含通則 |
| `P2-END-01` | HP0 與同時終局 | HP0 進 Incapacitated；結算後判勝負；同時最後敵人／我方倒地依 CORE-01 判玩家 VICTORY |

**來源**：`KuroNekoLi/astraea-combat-rules@cac49361` 的 `13_TEST_MATRIX_ACCEPTANCE.md` §「P2-D16 seeded replay 與最新接受矩陣」。本段是測試契約增量，不代表 Godot 新增 10 個 PASS。
