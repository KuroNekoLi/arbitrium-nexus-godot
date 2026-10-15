# Phase 1–2 / Phase 3 — 全量 Test ID 追溯清單（G0.2 + M1 + M2.1）

> Repo: `KuroNekoLi/arbitrium-nexus-godot`；建立日期：2026-10-14。來源：[`docs/combat/13_TEST_MATRIX_ACCEPTANCE.md`](../combat/13_TEST_MATRIX_ACCEPTANCE.md)。**此表完整列出該規格中的 128 個具名測試案例**，外加新 M1 30 個具名測試與 M2.1 38 個具名資源測試。狀態以實際 CI 執行證據為準；`SPECIFIED` 不代表測試已執行。

## 1. 核查結論與判定

- 來源規格13的 Test ID：**128/128 已建立追溯記錄，無重複 ID**。每項保留來源行號、輸入／期望摘要、負責里程碑與目前執行狀態。
- 當前可執行 M1 Domain runner：**30/30 PASS**，M2.1 Resource runner：**38/38 PASS**。來源 128 個完整 gameplay oracle 仍不可因這些子合約測試升格為完整驗收。
- 目前的 `PARTIAL_M1_ONLY` 只有 deterministic replay／RNG 抽象骨架相關需求，因為尚未有正式卡牌牌序、Boss、多段效果、2.5D FPS 交叉驗證，仍待 M5 完整測試。
- `REVIEW_SUPERSEDED_EXPECTATION` 代表舊範例的 `BLOCKED_BY_DECISION` 等文字或未定範圍已被後續核准／委派預設影響，測試實作前必須重新閱讀 19/20/21 的最新版裁決。**不代表規則被本工具重新定義**。
- 第13號文件已提及其他 ADR / Test ID 的概念，但只有表格中實際出現的具名案例計入此 128；若後續另檔新增 ID 須額外追溯。

### 狀態圖例

| 狀態 | 意義 |
|---|---|
| SPECIFIED / NOT_EXECUTED | 已有完整規格 oracle，尚未在正確 Godot Repo 以新版規則執行 |
| PARTIAL_M1_ONLY | M1 符合該測試的「確定性設施」子條件，完整玩法測試仍未執行 |
| REVIEW_SUPERSEDED_EXPECTATION | 舊期望存在新版規格修正，先核對裁決再寫測試 |
| RESOURCE_LEDGER_ONLY_VERIFIED | M2.1 已在新資源模組驗證該項的資源子條件；整體攻擊／SP／Reaction／Boss 尚未整合通過 |\n| VERIFIED (M1-only) | 實際 Godot CI 中有對應具名 Case 的 PASS stdout、退出碼與 commit |

## 2. Phase 1–2 規格案例 128 項

| Case ID | 13文件行 | 輸入情境（依來源摘要） | 預期／Oracle（依來源摘要） | 負責階段 | 執行狀態 |
|---|---:|---|---|---|---|
| `DECK-001` | 18 | 12卡開戰 | 每角手牌4、牌庫8、棄牌0 | M2 | M2.3 CARD_DOMAIN_VERIFIED; FULL_M2_PENDING |
| `DECK-002` | 19 | 打出2卡後開始新回合 | 手牌2補到4、卡進棄牌 | M2 | M2.3 CARD_LOGIC_VERIFIED; M3 PHASE_WIRING_PENDING |
| `DECK-003` | 20 | draw剩1、discard10、hand1 | 抽完1→洗棄牌→再抽2；不重複 | M2 | M2.3 CARD_DOMAIN_VERIFIED; FULL_M2_PENDING |
| `DECK-004` | 21 | 牌庫和棄牌都空、hand<4 | 不死循環、不憑空產牌 | M2 | M2.3 CARD_DOMAIN_VERIFIED; FULL_M2_PENDING |
| `ECON-001` | 22 | 三人共6 AP，出牌費用合計>6 | 超額動作拒絕，沒有部分扣費 | M2 | SPECIFIED / NOT_EXECUTED |
| `ECON-002` | 23 | 角色普通攻擊多次 | 回魔次數符合已核准設定（原型每角首次） | M2 | SPECIFIED / NOT_EXECUTED |
| `ECON-003` | 24 | MP不足使用Full Chant | 拒絕，卡不移區 | M2 | SPECIFIED / NOT_EXECUTED |
| `CAST-001` | 25 | Full Chant開始 | 扣費一次、卡入Casting Zone、Concentration | M4 | SPECIFIED / NOT_EXECUTED |
| `CAST-002` | 26 | caster Concentrating 普攻 | 拒絕、state不變 | M4 | SPECIFIED / NOT_EXECUTED |
| `CAST-003` | 27 | 下玩家階段詠唱完成 | 不重扣費、正確結算、解除Concentration | M4 | SPECIFIED / NOT_EXECUTED |
| `CAST-004` | 28 | FocusWard存在且受干擾 | Ward先吸收、剩餘再削減Stability | M4 | SPECIFIED / NOT_EXECUTED |
| `CAST-005` | 29 | Boss法術穩定度歸零 | 當次法術被打斷，不發生原預定攻擊 | M4 | SPECIFIED / NOT_EXECUTED |
| `BREAK-001` | 30 | Boss Break=0但Casting>0 | Break和Casting擁有獨立結果，依核准規則 | M5 | SPECIFIED / NOT_EXECUTED |
| `REACT-001` | 31 | 無 RP 嘗試 Guard/Protect；有 RP 但無特殊 SP 嘗試特殊 Reaction | 均拒絕且不扣費；但基本 Guard/Protect 有 RP 時不需卡牌即可用 | M3 | SPECIFIED / NOT_EXECUTED |
| `REACT-002` | 32 | 過期window ID再次反應 | 拒絕，不二次結算 | M3 | SPECIFIED / NOT_EXECUTED |
| `COMBO-001` | 33 | 不同角色順序＋tags＋狀態合法 | 顯示機會，玩家可普通或Combo施放 | M5 | SPECIFIED / NOT_EXECUTED |
| `COMBO-002` | 34 | 合法兩卡成本2+1AP | Combo附加效果 **0 額外AP**，只扣3AP | M5 | SPECIFIED / NOT_EXECUTED |
| `COMBO-003` | 35 | 第二張卡沒真正使用 | 不會憑Expose免費發動連攜 | M5 | SPECIFIED / NOT_EXECUTED |
| `COMBO-004` | 36 | Concentrating角色作finisher | 拒絕；但隊友可強化既存CastingInstance | M5 | SPECIFIED / NOT_EXECUTED |
| `LAST-001` | 37 | Last Spell不在12張卡牌 | 永遠不會被抽到 | M4 | SPECIFIED / NOT_EXECUTED |
| `LAST-002` | 38 | Last Spell開始後再手動取消 | 拒絕；不可重新啟動 | M4 | SPECIFIED / NOT_EXECUTED |
| `LAST-003` | 39 | First destabilization | 延遲一次；不被一般中斷直接取消 | M4 | SPECIFIED / NOT_EXECUTED |
| `LAST-004` | 40 | 第二次destabilization | 不會無限延遲、依參數削弱 | M4 | SPECIFIED / NOT_EXECUTED |
| `LAST-005` | 41 | 成功結算 | Exhausted；同角色所有新行動被拒絕；全隊AP配額不被直接降低 | M4 | SPECIFIED / NOT_EXECUTED |
| `RNG-001` | 42 | 同版本／deck／seed／命令 | 事件序列和最終hash一致 | M1/M5 | PARTIAL_M1_ONLY / FULL_NOT_EXECUTED |
| `P1-ECO-001` | 67 | 6 AP，角色A連續普通攻擊兩次，各次成本暫為1AP | 兩次攻擊可成功；只有首個**成功執行**普通攻擊觸發A的MP回復；B的首次獨立計數 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-002` | 68 | A普通攻擊因不足AP/非法狀態拒絕，稍後合法攻擊 | 首次回魔資格不可被遭拒命令消耗；失敗不扣資源 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-003` | 69 | A攻擊、B出牌、A再攻擊、C出牌 | 可以交錯使用共享AP，無每角色固定行動次數限制 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-004` | 70 | 玩家階段末AP=6，無任何花費 | 敵方階段開始 RP=6、AP=0，不截斷到2/3/4 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-005` | 71 | 玩家階段末AP=3 | RP=3，AP=0；總量守恆 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-006` | 72 | 玩家階段末AP=0 | RP=0，任何付費Reaction不可執行 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-007` | 73 | 敵方階段開始RP=4，只花1，然後敵方階段結束 | 無論是否仍有後續攻擊，RP歸零；下輪不能沿用3RP | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-008` | 74 | 敵方階段內兩次不同敵方行動，前者花2RP | 後者看見的是扣費後剩餘RP，不重新轉換AP | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P1-ECO-009` | 75 | 未來額外生成RP的卡未定義 | 應標 `BLOCKED_BY_DECISION`，不可臆測「RP6 cap」或無限產生 | M2 | SUPERSEDED_ORACLE; M-D08_RESOURCE_ONLY_VERIFIED |
| `P1-RXN-001` | 81 | actor手牌無任何Reaction SP、RP=1、合法自身受到攻擊 | Basic Guard仍合法，支付1RP；不消耗任何CardInstance | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-002` | 82 | actor手牌無任何Reaction SP、RP=2、可守護單體隊友受擊 | Basic Protect仍合法，支付2RP；不消耗任何CardInstance | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-003` | 83 | RP=0/1時Protect | 不合法且不扣RP；RP=1時Guard仍可合法 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-004` | 84 | actor沒有該Reaction SP卡、其他隊友有 | actor不能使用別人的SP；基本Guard/Protect不受影響 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-005` | 85 | 同一window A排Guard後又排Protect | 確認前必須要求擇一；不得成功執行兩個反應 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-006` | 86 | 同window A與B各排合法不同Reaction，RP足夠 | 兩人都能執行，不能因全局「一張卡」限制造成第二人被拒 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-007` | 87 | A已在window1反應，另一enemy action開window2 | 在window2若狀態與RP合法可再次反應；計次鍵含window ID | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-008` | 88 | 同window三角都合法、共同資源足夠 | 可三角各反應一次；不可自行設定全局2反應上限 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-009` | 89 | actor為Exhausted | 新基本／特殊Reaction拒絕，零扣費；不把Exhausted等同死亡判定 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-RXN-010` | 90 | actor Concentrating，沒有CAST_COMPATIBLE標籤 | 一般Reaction不合法；隊友仍能合法守護 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-GRD-001` | 96 | DEF計算後HP傷害30，暫時以 Guard率40%測試 | 得到浮點基準18（最後取整 TBD）；不能先對原始攻擊施40%再算DEF | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-GRD-002` | 97 | 兩角色同一原始攻擊但DEF不同 | Guard固定比例相同，仍因自身DEF/RES不同而承受不同數值 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-GRD-003` | 98 | Guard後試圖免費反擊／減BossCastingStability | 不允許；基本Guard僅減損，不產生特殊SP效果 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-GRD-004` | 99 | Guard後受到直接 CastingInstance 干擾 | Guard不自動提供FocusWard／阻斷干擾 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-GRD-005` | 100 | Guard最終取整／真傷最小HP傷害 | `BLOCKED_BY_DECISION`；不得把 fixture 的floor/ceil私自升格 | M3/M5 | REVIEW_SUPERSEDED_EXPECTATION |
| `P1-PRT-001` | 106 | Boss單體物理攻A，B使用Protect | 原攻擊傷害承受者改B，按B的DEF/RES重算；A不受可轉移HP傷害 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-002` | 107 | Boss單體魔法攻A，B使用Protect | 同上但使用B的相應魔法抗性；非只攔物理 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-003` | 108 | A原本承傷45、B自身承傷30（樣本） | Protect後應是B受30，不是B受45；Protect不免費加20%減傷 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-004` | 109 | Boss全體或明示多目標攻擊 | 基本Protect不合法、不可扣2RP；特殊SP按自身定義另論 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-005` | 110 | Boss單體但帶明示`unprotectable`標記 | 基本Protect不合法，UI消費前須顯示理由 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-006` | 111 | A正在Full Chant、Boss單體命中附帶CastingDisruption 15，BProtect | A未承受該命中附帶干擾，Stability保持不變；守護者按實際結算 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-007` | 112 | Boss直接target=A.casting_id施加干擾 | 基本Protect不攔，A的Casting按原干擾規則處理 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-008` | 113 | 同一招有可守護彈體+獨立 Casting Lock | Protect只轉向彈體及其命中附帶效果；直接Casting Lock繼續指向原casting_id | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-009` | 114 | 守護者同窗口又要求自我Guard | 違反每人每窗口一次，不能雙重付款、重算或偷用兩指令 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-010` | 115 | 被保護者本有HP Barrier、Protect改變承受者 | 不可繼續把原Barrier當成守護者的免費Barrier；具體Barrier先後待別章確定 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `P1-PRT-011` | 116 | 複數守護者互相轉向、毒/擊退附帶效果 | `BLOCKED_BY_DECISION`，禁止以偶然的事件排序固定規則 | M3/M5 | REVIEW_SUPERSEDED_EXPECTATION |
| `P1-QUEUE-001` | 122 | 選A Protect、B Ward、拖曳改為B→A，再確認 | 依最終明示順序結算，不按SPD或隱藏固定種類排序 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-002` | 123 | 將SP加入草稿後取消整組 | RP、MP、手牌位置及actor本窗口已反應標記皆維持不變 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-003` | 124 | 同窗口A/B各合法Reaction，確認一次 | 只出現一次總確認，不為B另彈第二個確認；逐步再校驗 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-004` | 125 | A反制成功取消攻擊，B後序Protect依賴該攻擊 | B`SKIPPED_INVALIDATED`：RP/MP零扣、手牌不移、actor不計次 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-005` | 126 | A反制成功取消攻擊，B後序獨立持續護盾SP仍合法 | B照常執行、正常扣費與移區，除非卡面明定必依賴該攻擊 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-006` | 127 | A Protect先執行並扣費，B後來使攻擊最終失效 | A已經執行；不能用D16追溯免除A已付成本 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-007` | 128 | 重複Confirm同window+same command ID | 不得重複扣資源、施法或丟卡 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-008` | 129 | SP排在第二，前序令其觸發失效 | 該SP仍在hand且無棄牌trigger；同名另一CardInstance不受影響 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-009` | 130 | 排隊當時合法，確認時RP不足 | 拒絕提交/要求調整，不能負RP或先扣一半費用 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-010` | 131 | Smart／AlwaysAsk／Quick，輸入同一已確認reaction queue | 引擎狀態／事件/資源計算一致（UI提示數量可不同）；禁止自動花RP | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-011` | 132 | 有合法重大Reaction事件且Smart開啟 | 應提供可用的清楚回應方式；重大分類門檻待UI ADR，不能在未核准超時下自動沒收 | M3 | SPECIFIED / NOT_EXECUTED |
| `P1-QUEUE-012` | 133 | 敵行動無任何合法反應 | Smart/AlwaysAsk皆不可彈出空白阻塞選單 | M3 | SPECIFIED / NOT_EXECUTED |
| `M18-AP-001` | 154 | BaseAP6；SP 花2得8 | CurrentAP=12，不以6截斷 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `M18-RP-002` | 155 | Player Phase 末剩9 AP；RP cap6 | RP=6，多餘3不可延續 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `M19-MP-001` | 156 | 無自然回魔來源的角色跨 Player Phase | MP不因過回合而增加 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `M20-MP-002` | 157 | CurrentMP9 MaxMP10；合法恢復4 | MP=10，超額3消失 | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `M21-CAST-001` | 158 | 同一正常雙模式 SP | Chantless／Full Chant 預設 MP 成本相同、Full 提交支付後延遲生效 | M4 | SPECIFIED / NOT_EXECUTED |
| `M22-CAST-002` | 159 | Full Chant Casting Interrupt 成立 | 立即按配置比例部分退 MP，不退 AP，不消除 Overload Debt；退 MP capped MaxMP | M4 | SPECIFIED / NOT_EXECUTED |
| `M25-HAND-001` | 160 | 手上3/4/7 張且開始新 Player Phase | 分別抽1/0/0；任時手牌不得 >8 | M2 | M2.3 CARD_LOGIC_VERIFIED; M3 PHASE_WIRING_PENDING |
| `M25-HAND-002` | 161 | 手牌7，合法額外抽3且無打牌先移區 | 只抽1，餘下需求不將牌從 draw pile 移除 | M2 | M2.3 CARD_DOMAIN_VERIFIED; FULL_M2_PENDING |
| `M26-SWAP-001` | 162 | 每角色第一次合法免費換牌 | 0 AP/MP、換1卡、扣該角色一次；其他角色不受影響 | M2 | SPECIFIED / NOT_EXECUTED |
| `M27-SWAP-002` | 163 | 抽牌堆空，棄牌堆有其他合法實例 | 重洗也絕不立刻抽回剛換掉的原 CardInstance | M2 | SPECIFIED / NOT_EXECUTED |
| `M29-SWAP-003` | 164 | 除原卡外沒有合法替代實例 | 操作拒絕、手牌/區域/次數不變、不發抽棄牌事件 | M2 | SPECIFIED / NOT_EXECUTED |
| `M30-SWAP-004` | 165 | 有棄牌回 MP + 抽牌 Buff | `CardDiscarded` 及回 MP 先於 `CardDrawn` 及其效果；事件可重播 | M2 | SPECIFIED / NOT_EXECUTED |
| `M31-MP-001` | 166 | 角色各自 BaseMaxMP 不同，特性提高其中一名 | 各自 MaxMP 與回復 cap 獨立；不能改隊友 MP | M2 | RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED |
| `P2-D10-001` | 167 | 同命令、同 seed、同戰鬥資料 | 完整傷害事件與 HP 結果一致，可追溯防禦／暴擊／抗性／盾 | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-D11-001` | 168 | 多階段小數傷害配置 | 僅最終取整；不可在未配置時暗定最低1傷 | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-D12-001` | 169 | 同時有 Barrier 與 Focus Ward | 前者只處理HP傷害、後者只處理詠唱干擾 | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-D13-001` | 170 | 兩種不同 Buff/DoT 配置 | 各自遵守層數／時限／tick／dispellable 規則 | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-D14-001` | 171 | HP0 | 角色進 Incapacitated，不可一般主動行動 | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-D15-001` | 172 | 多段同張 SP 中途令目標HP0 | 不無條件丟棄仍合法結算的其餘效果；在完成合法行動結算後進勝敗檢查 | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-D16-001` | 173 | 相同 seed + command tape + rules version | 狀態與事件雜湊完全一致 | M1/M5 | PARTIAL_M1_ONLY / FULL_NOT_EXECUTED |
| `PRE3-01` | 181 | 單體技能 A 命中原目標低閃避，B 高閃避先合法 Protect | 先重導向 B，再用 B 閃避擲命中並依 B 防禦；不使用 A 已擲結果 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-02` | 182 | 同一 Action 被 B、C 依序排 Protect | B 首次成功、C 的改向失效跳過，不扣後序RP、不可連鎖到 C | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-03` | 183 | Boss 同一 EnemyAction 連續 3 hit；A Guard | A 的該次 1 RP Guard 作用於本 Action 所有合格 HP hits，下一獨立 Action 不帶過去 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-04` | 184 | Boss 單體三段物理傷害對 A；B Protect | 全部 hit 以 B 為承受者；AoE／多目標必拒基本 Protect | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-05` | 185 | Protect 遇上中毒/擊退、命中型詠唱干擾與直接指定施法實例干擾 | 只有標記 follows_damage_recipient 的合法命中依附項轉向；直接 CastingInstance 不轉向 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-06` | 186 | Reaction Queue 2 筆；首筆使次筆 actor HP0 或共享 RP 不足 | 次筆在執行前跳過、無費、無棄牌、不占已執行次數，其他獨立合法後序繼續 | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-07` | 187 | 一筆單體 HP hit：防禦後100，Guard40%，Barrier20 | provisional Guard 後60，Barrier吸20，最後HP傷40；Focus Ward不扣 | M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-08` | 188 | 攻擊經修正得0.8 HP，無保底效果 | final floor0；不得在中間小數階段取整或強制1 HP | M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-09` | 189 | 同一個 phase boundary 多個不同 DoT/HoT/到期 | 逐狀態依明文 tick trigger/priority/instance_id，結果與 seed/指令帶一致 | M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-10` | 190 | 同時有 SetCost、累加折扣、有限次折扣與 Overload | SetCost→數值減費→有效最低→不足差額借 AP；扣次序穩定、trace可重播 | M2 | SPECIFIED / NOT_EXECUTED |
| `PRE3-11` | 191 | 免費換牌預檢無替代牌 | 不棄牌、不抽牌、不耗次數、不發事件（維持 M-D29） | M2 | SPECIFIED / NOT_EXECUTED |
| `PRE3-12` | 192 | 換牌預檢有候選，但 CardDiscarded 觸發拿走最後替代卡 | 原卡末端進 discard，發 CardDrawFailed，不發 CardDrawn，換牌額度消耗且不回滾觸發 | M2 | SPECIFIED / NOT_EXECUTED |
| `PRE3-13` | 193 | 一般 Full Chant 施法者 HP0，並未被合法 CastingInterrupt | 取消並移入discard；不返 AP、不自動套中斷部分退款 | M4 | SPECIFIED / NOT_EXECUTED |
| `PRE3-14` | 194 | Exhausted 角色成 Boss 單體攻擊目標，隊友 Protect 後又受治療 | 允許受擊/保護/治療但不可發新行動，治療不移除 Exhausted | M4 | SPECIFIED / NOT_EXECUTED |
| `PRE3-15` | 195 | Incapacitated 的手牌4，普通治療命中 | 不自動復活／重抽/棄牌；明文 Revive 才能恢復 HP>0與行動資格 | M4 | SPECIFIED / NOT_EXECUTED |
| `PRE3-16` | 196 | Last Spell 已提交但尚未釋放，施法者 HP0 | 立即 `LastSpellInvalidated(CASTER_INCAPACITATED)` 並取消到期效果，**永不死後續放**（USER_APPROVED） | M4 | SPECIFIED / NOT_EXECUTED |
| `PRE3-17` | 197 | Boss 與最後一位我方角色在同一合法行動事件結算後都 HP0 | 行動及必要觸發結算完成後 `VICTORY`（USER_APPROVED，劇情通關） | M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-18` | 198 | Quick UI/動畫加速、seed/state/tape相同 | domain events/outcome 完全一致；不能用真實按鍵延遲決定自動扣費或 Pass | M3/M5 | SPECIFIED / NOT_EXECUTED |
| `PRE3-19` | 199 | 各角色不同MaxMP，普通攻擊回魔2與Casting Interrupt退50% floor | fixture值可調，不超過當前MaxMP；測試 log 必顯示 BALANCE_PROVISIONAL | M2/M4 | SPECIFIED / NOT_EXECUTED |
| `PRE3-20` | 200 | 有9張抽入請求而hand已7張，牌庫中有其他實例 | 最多抽1張至8；不把超出容量的牌從牌庫移除，且不得造出同一CardInstance兩份 | M2 | M2.3 CARD_DOMAIN_VERIFIED; FULL_M2_PENDING |
| `P2-OUT-01` | 208 | 正例 | 同一完整合法多段技能令最後 Boss 與最後可戰鬥隊員 HP0 / 所有應合法結算事件完成後，`VICTORY`（不會 DRAW） | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-OUT-02` | 209 | 對照 | 所有我方 HP0，但仍至少一敵人 HP>0 / `DEFEAT` | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-OUT-03` | 210 | 邊界 | Boss HP0 而仍有我方存活 / `VICTORY`；勝敗檢查不截斷單張技能合法事件 | M5 | SPECIFIED / NOT_EXECUTED |
| `P2-LAST-01` | 211 | 正例 | 甲 PlayerPhase1 啟動 2 回合後生效的 Last Spell；下回合甲 HP0 / 立即 `INCAPACITATED → LastSpellInvalidated`，第3回合到期無傷害 | M4 | SPECIFIED / NOT_EXECUTED |
| `P2-LAST-02` | 212 | 費用 | 上述被強制失效且本回合合法支付 AP/MP/Overload / 不返 AP、MP 或減掉債務，once-per-battle 已使用 | M4 | SPECIFIED / NOT_EXECUTED |
| `P2-LAST-03` | 213 | 復活 | 失效後甲被 Revive，仍在原到期時間之前 / 原 Last Spell 不恢復、不再發動，不能同戰再使用 | M4 | SPECIFIED / NOT_EXECUTED |
| `P2-LAST-04` | 214 | 對照 | 玩家試圖主動 Cancel 尚未生效的 Last Spell / 拒絕；不是合法取消 | M4 | SPECIFIED / NOT_EXECUTED |
| `P2-LAST-05` | 215 | 對照 | 仍有 HP 的施法者 Last Spell 被一般 Casting Disruption / 延遲/削弱而非第一下直接取消（保留特別規則） | M4 | SPECIFIED / NOT_EXECUTED |
| `P2-LAST-06` | 216 | 邊界 | Last Spell 已合法釋放完成，同 Action 後續事件施法者 HP0 / 已釋放效果不回溯取消；結束判定按 `P2-OUT` | M4 | SPECIFIED / NOT_EXECUTED |
| `P2-VIS-01` | 217 | 視覺 | 同一命令/seed 切換 2D 與 2.5D 演出 / Domain event log、HP、資源與勝敗完全一致 | M1/M5 | SPECIFIED / NOT_EXECUTED |
| `P2-VIS-02` | 218 | 負例 | UI 嘗試 Phase 3 自由走位或移動成本操作 / 不存在自由移動指令，不能以 2.5D 換得新增走位 | M1/M5 | SPECIFIED / NOT_EXECUTED |
| `P2-RXN-01` | 219 | 正例 | Quick 開啟、合法 Reaction、玩家停留 120 秒才 Confirm / 不自動 Pass，仍依確認的合法 queue 結算 | M3 | SPECIFIED / NOT_EXECUTED |
| `P2-RXN-02` | 220 | 對照 | Quick 開啟、玩家明確 Pass / 不消耗 RP／手牌；敵方行動續行 | M3 | SPECIFIED / NOT_EXECUTED |
| `P2-RXN-03` | 221 | 負例 | 任意 mode 有合法 Reaction，但未回應／動畫已播完 / 不得 timeout、自動Pass、或自動花費資源 | M3 | SPECIFIED / NOT_EXECUTED |
| `P2-RXN-04` | 222 | 邊界 | 本敵方行動沒有任何合法 Reaction / 可略過空窗口，不強迫使用者開空選單 | M3 | SPECIFIED / NOT_EXECUTED |
| `P2-REPLAY-01` | 223 | 決定性 | 固定 `seed + initial_state + ruleset_version + command_tape`，分別用 2D/2.5D、不同 FPS、同樣人工決策 / domain event trace、state hash、BattleOutcome 完全一致 | M1/M5 | PARTIAL_M1_ONLY / FULL_NOT_EXECUTED |

## 3. 新 Phase 3 M1：30 個實際執行 Case

> [CI Run #38565197994](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38565197994)；Code Commit `ad8333dd1a00c9efa042273f6535accb1ea43e31`；Godot `4.7.2.stable.official.ed1daf0bf`，`M1_TEST_REPORT executed=30 passed=30 failed=0 skipped=0`。

| M1 Case ID | Runner Source | 追溯的核心需求 | 結果 |
|---|---|---|---|
| `PH3-M1-STATE-001` | `tests/test_combat_m1.gd` | G0-R25 / 12-engine snapshot | **VERIFIED** |
| `PH3-M1-STATE-002` | `tests/test_combat_m1.gd` | G0-R25 / 12-engine snapshot | **VERIFIED** |
| `PH3-M1-STATE-003` | `tests/test_combat_m1.gd` | G0-R25 / 12-engine snapshot | **VERIFIED** |
| `PH3-M1-CMD-001` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-002` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-003` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-004` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-005` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-006` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-007` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-EVT-001` | `tests/test_combat_m1.gd` | G0-R25 / P2-D16 (event ordering) | **VERIFIED** |
| `PH3-M1-CMD-008` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-009` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-010` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-011` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-012` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-013` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-CMD-014` | `tests/test_combat_m1.gd` | G0-R25 / 12-command validation / P1-ECO-002 (partial) | **VERIFIED** |
| `PH3-M1-REPLAY-001` | `tests/test_combat_m1.gd` | P2-D16 / P2-REPLAY-01 (scaffold) | **VERIFIED** |
| `PH3-M1-REPLAY-002` | `tests/test_combat_m1.gd` | P2-D16 / P2-REPLAY-01 (scaffold) | **VERIFIED** |
| `PH3-M1-REPLAY-003` | `tests/test_combat_m1.gd` | P2-D16 / P2-REPLAY-01 (scaffold) | **VERIFIED** |
| `PH3-M1-REPLAY-004` | `tests/test_combat_m1.gd` | P2-D16 / P2-REPLAY-01 (scaffold) | **VERIFIED** |
| `PH3-M1-RNG-001` | `tests/test_combat_m1.gd` | P2-D16 / RNG-001 (scaffold) | **VERIFIED** |
| `PH3-M1-RNG-002` | `tests/test_combat_m1.gd` | P2-D16 / RNG-001 (scaffold) | **VERIFIED** |
| `PH3-M1-RNG-003` | `tests/test_combat_m1.gd` | P2-D16 / RNG-001 (scaffold) | **VERIFIED** |
| `PH3-M1-RNG-004` | `tests/test_combat_m1.gd` | P2-D16 / RNG-001 (scaffold) | **VERIFIED** |
| `PH3-M1-SNAP-001` | `tests/test_combat_m1.gd` | G0-R25 / P2-VIS-01 (domain isolation) | **VERIFIED** |
| `PH3-M1-SNAP-002` | `tests/test_combat_m1.gd` | G0-R25 / P2-VIS-01 (domain isolation) | **VERIFIED** |
| `PH3-M1-STATE-004` | `tests/test_combat_m1.gd` | G0-R25 / 12-engine snapshot | **VERIFIED** |
| `PH3-M1-EVT-002` | `tests/test_combat_m1.gd` | G0-R25 / P2-D16 (event ordering) | **VERIFIED** |

## 4. CI 證據與 Boundary

- [新 M1 run #38565197994](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38565197994)：30 PASS／0 FAIL；`M1_REPLAY_PROOF` 含 seed、ruleset/content版本、initial/event/final hashes 與完整 command tape。
- [舊原型回歸 run #38565198000](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38565198000)：舊 `8-card / 2-play / timed Reaction` 回歸屬 **LEGACY baseline**，即使成功也不是新版玩法驗收。
- **M2 必補**：全隊 AP、MP 與 RP、12SP、手牌上限8、免費換牌／APDebt 等。**M3**：無 countdown 的多人 Reaction Guard/Protect。**M4**：雙詠唱、干擾、Last Spell。**M5**：Hit/Damage/Status/Break/Combo/Outcome、全戰 replay。
- 規格測試未明文逐卡配置／平衡數值者依 `BALANCE_PROVISIONAL` 或 `BLOCKED_FIXTURE` 保留，不造假最終 Canon。

## 5. M2.1 Resource-domain cases — verified 38/38

Source runner: `tests/test_m2_resources.gd` @ `5812a8883e87cb5cd30665d100875f7bb75c0e59`. [CI run #38568919479](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38568919479). All cases verified with exit0; some names overlap source13 but they assert **resource-only**, not fully completed gameplay.

| M2.1 actual case ID | Scope | Status |
|---|---|---|
| `M2_1_SETUP` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_JSON_INTEGRAL_FIXTURE` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_FRACTIONAL_COST_REJECTED` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-001` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_ATTACK_INDEPENDENT` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_ATTACK_NO_DAMAGE` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-002` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-003` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-004` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-005` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-006` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-007` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-008` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `P1-ECO-009-UPDATED` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_RP_CAP_OVERRIDE_FIXTURE` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M18-AP-001` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M18-RP-002` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M19-MP-001` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M20-MP-002` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M31-MP-001` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_NO_NATURAL_MP` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_MP_CLAIM_RESETS` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_MP_UNDERFLOW` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_MP_PAY` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_INVALID_AMOUNTS` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_IDEMPOTENCY` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_INVALID_PHASE` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_ACTOR_GUARDS` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_NO_SILENT_BALANCE` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_FULL_MP_CLAIM` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_IMMUTABLE_INPUT` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_DEBT_DEFERRED` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_MP_STATE_INVARIANT` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_PUBLIC_ATTACK_NOT_READY` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_REPLAY_IDENTICAL` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_RNG_PRESERVED` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_EVENT_SEQUENCING` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |
| `M2_1_REPLAY_FAILURE` | `scripts/domain/m2/economy/` + fixture, unit/replay | RESOURCE_LEDGER_ONLY_VERIFIED |

The first CI attempt #38568308477 failed due to Godot JSON parsing integral literals as float; correction added explicit integer-valued JSON handling and two regression cases. The source of gameplay policy remains `docs/combat/03,18,19,20`; fixtures do not approve permanent MP/AP balance values.

## 6. M2.2 verified internal Cost Engine cases

Evidence: [GitHub Actions Run #38571553461](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38571553461), tested `907d406d13dc1fb841e0a52e4364121f5f819fcd`. Godot `4.7.2.stable.official.ed1daf0bf`: **43 PASS, 0 FAIL, 0 SKIPPED**. All rows below are internal fixture tests; complete SP/card/gameplay acceptance is NOT_EXECUTED.

| M2.2 Case ID | Evidence file | Coverage |
|---|---|---|
| `M2_2_CONFIG_AUTHORITY` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_ATOMIC_AP_MP` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_INPUT_IMMUTABLE` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_RECEIPT_NOT_CARD` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_MP_INSUFFICIENT_ATOMIC` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `ECON-001-RESOURCE_ONLY` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_INVALID_ACTOR` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_UNAVAILABLE_ACTOR` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_OVERLOAD_SHORTFALL` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_CARD_BORROW_LIMIT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_TEAM_BORROW_LIMIT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_NO_VOLUNTARY_BORROW` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_BORROW_ONLY_GAP` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_NO_SILENT_DEBT_LIMIT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `PRE3-10-RESOURCE_ONLY` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DISCOUNT_CONSUMPTION` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_VARIABLE_INVESTMENT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_INVESTMENT_REQUIRED` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_INVESTMENT_RANGE` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_FIXED_CARD_NO_INVESTMENT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DUAL_CAST_SAME_MP` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_MIN_AP_COST` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DISCOUNT_FILTER` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_MULTIPLE_SET_COST_TBD` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DUPLICATE_MODIFIER_ID` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_REPLAY_REJECTS_DUPLICATE` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_COST_PLAYER_ONLY` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_NO_UNFUNDED_EFFECT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_AP_REFUND_CURRENT_ONLY` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_EFFECT_CONSUME_ONCE` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_REFUND_DOES_NOT_REPAY` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_REDUCE_DEBT_NO_AP` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DEBT_CLAMP` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_FUTURE_BONUS_NOT_IMMEDIATE` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DEBT_CROSS_PHASE` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DEBT_MULTI_PHASE` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_DEBT_POLICY_EXPLICIT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_AP_BONUS_REPAYS_FIRST` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_NEXT_PHASE_AP_BONUS` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_REPLAY_DETERMINISTIC` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_REPLAY_FAILED_ATOMICALLY` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_NO_GLOBAL_PLAY_LIMIT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |
| `M2_2_NO_PUBLIC_SP_EFFECT` | `tests/test_m2_costs.gd` | COST_DOMAIN_ONLY_VERIFIED |


## M2.5 supplemental test IDs — 2026-10-14

Source-of-truth 128 test IDs above remain unchanged. This new section adds **20 internal resource-only cases**; it does **not** mark `DECK-001..004`, M-D25, M-D26..30, PRE3-R11, or full M2 integration as verified.

- `tests/test_m2_invariants.gd`: 14/14 PASS — `M2_5_RESOURCE_INITIAL_VALID`, `M2_5_OVERLOAD_RESOURCE_INVARIANT`, `M2_5_COST_INPUT_PURE`, `M2_5_DUPLICATE_COST_ATOMIC`, `M2_5_INSUFFICIENT_MP_ATOMIC`, `M2_5_REFUND_DEBT_SEPARATE`, `M2_5_REFUND_NO_REPEAT`, `M2_5_REDUCE_DEBT_NOT_AP`, `M2_5_RP_FROM_REMAINING`, `M2_5_RP_DOES_NOT_CARRY`, `M2_5_AP_DEBT_REPAID_BEFORE_REFRESH`, `M2_5_AP_UNCAPPED_RP_CAPPED`, `M2_5_PROVISIONAL_ZERO_AP_PHASE`, `M2_5_STALE_COMMAND_ATOMIC`.
- `tests/test_m2_replay.gd`: 6/6 PASS — `M2_5_CROSS_RESOLVER_REPLAY_EQUAL`, `M2_5_REPLAY_EVENTS_MONOTONIC`, `M2_5_REPLAY_RNG_UNCHANGED`, `M2_5_REPLAY_AP_RP_DEBT`, `M2_5_REPLAY_DISTINCT_TAPE_HASH`, `M2_5_REPLAY_FAILURE_ATOMIC`.
- Evidence: Godot `4.7.2.stable.official.ed1daf0bf`; seed `20261014`; tested SHA `71b753c5b0eba58bb9b21043e8be95e2d49ac44a`; [Actions run 38576033292](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38576033292). All 20 executed cases passed, **but the full-domain gate failed with exit 2** because M2.3 and M2.4 source/test files were absent. See `PH3_M2_5_ACCEPTANCE_REPORT.md`. The 20 new cases do not cover card identity/zone invariant or swap event ordering.

### M2.3 executed card-oracle supplement (2026-10-14)

Godot4.7.2 M2.3 tests **46/46 PASS** in [run #38580461921](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38580461921), commit de2178e175846c2eeae5aba7f3f96995bb61323c. Exact DECK-003 mixed draw1/discard10 and PRE3-20 hand7/request3 scenarios are included. DECK-002 and M25-HAND-001 execute the M2.3 explicit draw-to-four function, not a real M3 phase reducer. V2 store and PRE3-R16 deck entry validation are verified as independent M2.3 rules.

Do not conflate **PRE3-R16** (deck rule) with **PRE3-16** (existing spec-13 Last Spell HP0 testcase owned by M4). The latter is unexecuted. M2.4 Free Swap and full M2.5 replay remain blocked; legacy G0 behavior is not magically migrated.

### M2.4 independent Free Swap oracle supplement (2026-10-14)

Godot `4.7.2.stable.official.ed1daf0bf`, source commit `7b115720716c5fd155088313d14c9df81344bd74`, [CI #38582070292](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38582070292): **32/32 M2.4 PASS** plus M2.3=46/46, M1=30/30, M2.1=38/38, M2.2=43/43; full workflow success. Source table §2 entries retain their original SPECIFIED statuses as a statement about the **complete** spec13 end-to-end tests; the following maps actually executed domain sub-oracles, not unimplemented MP/BUFF cases.

- `M26-SWAP-001`: per actor/phase quota, independent B/C, zero AP/MP event metadata; no integrated resource debit.
- `M27-SWAP-002`: isolated original, seeded discard reshuffle never returns that exact instance during the operation.
- `M29-SWAP-003`, `PRE3-11` (spec13): no candidate PRECHECK => unchanged zone and quota, no events, retry after actual candidate appears.
- `M30-SWAP-004`: event ordering with **MOVE_CARD** effects only; MP restoration and draw Buff from spec13 remain `NOT_EXECUTED`.
- `PRE3-12` (spec13, equivalent to Library `PRE3-R11`): CardDiscarded effect exhausts pool after successful PRECHECK => `CardDrawFailed(POOL_CHANGED)`; prior effect persists, original discarded and quota consumed, no phantom draw.
- `M2_4-SEEDED_REPLAY`: card-domain seeded event hash `f8003dc11c5831b29a7e07c9fcae1b085c45fdb6d85a95e58933ebd077c5add4`, final state hash `dd5c7d9896614711c522cc17ab3091f05635fb3b7708acacb55a599457cdd3f2`. Full M2.5 replay remains blocked.

`PRE3-12` is not Library `PRE3-R12`, which covers Full Chant Casting.


### M2.5 integrated core Domain: 40 actually executed oracles (2026-10-14)

At [CI #38586164025](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38586164025), Godot 4.7.2, source SHA 418607f954f40a38eff0de0b830eb83bed7080d6, seed 20261014, all **40/40** cases from tests/test_m2_integration.gd PASSED; this adds integration coverage to rather than replacing source spec13's full-gameplay oracles.

| # | Exact case ID in Godot stdout | Source | Status |
|---:|---|---|---|
| 1 | M2_5_INT_INITIAL_36_CARDS | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 2 | M2_5_INT_COST_ZONE_ATOMIC | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 3 | M2_5_INT_COST_BEFORE_ZONE | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 4 | M2_5_INT_INPUT_NOT_MUTATED | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 5 | M2_5_INT_DOUBLE_SP_REJECT | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 6 | M2_5_INT_OWNER_REJECT | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 7 | M2_5_INT_COST_CATALOG_REJECT | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 8 | M2_5_INT_MP_NO_CARD_LOSS | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 9 | M2_5_INT_AP_NO_CARD_LOSS | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 10 | M2_5_INT_ZERO_AP_SWAP | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 11 | M2_5_INT_SWAP_ONCE | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 12 | M2_5_INT_GLOBAL_DUPLICATE_COMMAND | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 13 | M2_5_INT_GLOBAL_STALE_COMMAND | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 14 | M2_5_INT_CASTING_ZONE_EXCLUSIVE | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 15 | M2_5_INT_CASTING_TO_DISCARD | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 16 | M2_5_INT_CASTING_NOT_DRAWABLE | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 17 | M2_5_INT_OVERLOAD_LINKED_CARD | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 18 | M2_5_INT_AP_DEBT_SWAP_FREE | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 19 | M2_5_INT_NO_POOL_FIXTURE_VALID | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 20 | M2_5_INT_PRECHECK_ATOMIC | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 21 | M2_5_INT_PRE3_R11_NOT_ROLLED_BACK | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 22 | M2_5_INT_PRE3_R11_ORDER | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 23 | M2_5_INT_PRE3_R11_NO_RESOURCE_CHANGE | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 24 | M2_5_INT_HAND_CAP8 | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 25 | M2_5_INT_HAND_CAP8_NO_PHANTOM | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 26 | M2_5_INT_INCAPACITATED_DENIED | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 27 | M2_5_INT_COST_DISCARD_TRIGGER_DRAW | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 28 | M2_5_INT_TRIGGER_REPLAY_EXACT_HASH | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 29 | M2_5_INT_TRIGGER_CARD_GLOBAL_CONSERVATION | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 30 | M2_5_INT_PRE3_R11_REPLAY_EXACT | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 31 | M2_5_INT_NEXT_PHASE_REFILL | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 32 | M2_5_INT_FULL_CROSS_MODULE_REPLAY | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 33 | M2_5_INT_REPLAY_EVENT_ORDER | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 34 | M2_5_INT_REPLAY_RNG_EQUAL | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 35 | M2_5_INT_REPLAY_QUOTA_RESET_REUSED | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 36 | M2_5_INT_REPLAY_ZERO_RP | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 37 | M2_5_INT_REPLAY_DISTINCT_INITIAL_SEED | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 38 | M2_5_INT_REPLAY_FAILURE_ATOMIC | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 39 | M2_5_INT_EVENT_SEQUENCE_MONOTONIC | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |
| 40 | M2_5_INT_REPLAY_INITIAL_UNTOUCHED | tests/test_m2_integration.gd | PASS — M2 CORE DOMAIN ONLY |

Historical M2.5 resource-only 14+6 runner comments saying M2.3/M2.4 are missing refer only to original separated test scope; the current combined gate independently executes both suites. Full spec13 M30 MP-on-discard + Buff-on-draw remains NOT_EXECUTED beyond MOVE_CARD trigger ordering, along with M3–M5 gameplay. Integrated replay event SHA256 c26cbea2b560924fb568be1d4dcbadc6c26b26379293f16f6981aa43964fe061; final state SHA256 8118b9cc9dc2c30b0d009934e8a3ab5385909d73ca021e958100b41d9509349a.


### M3.1 Phase Engine: actually executed 61 named cases (2026-10-14)

Godot official 4.7.2, seed 20261014, source SHA 4c5e77fbce21aa354935296e42803019b43133ad, successful GitHub Actions run https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38590076311. M3.1 61/61 PASS and M1–M2 249/249 regression PASS. These are Phase fixture Domain oracles, NOT real enemy damage/Reaction/Status oracles.

| # | Actual case ID | Runner | Verdict |
|---:|---|---|---|
| 1 | M3_1_INITIAL_PHASE | test_m3_phase.gd | PASS / M3.1 ONLY |
| 2 | M3_1_ACTUAL_36_CARDS | test_m3_phase.gd | PASS / M3.1 ONLY |
| 3 | M3_1_NO_PREDECLARED_ENEMY_ACTION | test_m3_phase.gd | PASS / M3.1 ONLY |
| 4 | M3_1_ACTION_ORDER_STABLE | test_m3_phase.gd | PASS / M3.1 ONLY |
| 5 | M3_1_ACTION_IDS_ROUND_SCOPED | test_m3_phase.gd | PASS / M3.1 ONLY |
| 6 | M3_1_NO_HIDDEN_INTENT | test_m3_phase.gd | PASS / M3.1 ONLY |
| 7 | M3_1_DUPLICATE_INTENT_REJECT | test_m3_phase.gd | PASS / M3.1 ONLY |
| 8 | M3_1_ENEMY_OWNERSHIP_REJECT | test_m3_phase.gd | PASS / M3.1 ONLY |
| 9 | M3_1_NEW_ROUND_NEW_IDS | test_m3_phase.gd | PASS / M3.1 ONLY |
| 10 | M3_1_P1_D01_AABA | test_m3_phase.gd | PASS / M3.1 ONLY |
| 11 | M3_1_PLAYER_ACTIONS_IMMEDIATE | test_m3_phase.gd | PASS / M3.1 ONLY |
| 12 | M3_1_NO_AUTOMATIC_END | test_m3_phase.gd | PASS / M3.1 ONLY |
| 13 | M3_1_SEED_INPUT_IMMUTABLE | test_m3_phase.gd | PASS / M3.1 ONLY |
| 14 | M3_1_STALE_NO_MUTATION | test_m3_phase.gd | PASS / M3.1 ONLY |
| 15 | M3_1_DUPLICATE_NO_MUTATION | test_m3_phase.gd | PASS / M3.1 ONLY |
| 16 | M3_1_ILLEGAL_OWNER_NO_PAYMENT | test_m3_phase.gd | PASS / M3.1 ONLY |
| 17 | M3_1_INCAPACITATED_CANNOT_ACT | test_m3_phase.gd | PASS / M3.1 ONLY |
| 18 | M3_1_END_PLAYER_AP_TO_RP | test_m3_phase.gd | PASS / M3.1 ONLY |
| 19 | M3_1_END_BOUNDARY_BEFORE_ENEMY | test_m3_phase.gd | PASS / M3.1 ONLY |
| 20 | M3_1_END_NEEDS_USER_COMMAND | test_m3_phase.gd | PASS / M3.1 ONLY |
| 21 | M3_1_ENEMY_PENDING_BLOCKS_END | test_m3_phase.gd | PASS / M3.1 ONLY |
| 22 | M3_1_ENEMY_CANNOT_PLAY_CARD | test_m3_phase.gd | PASS / M3.1 ONLY |
| 23 | M3_1_DECLARED_0 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 24 | M3_1_DOUBLE_DECLARE_0 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 25 | M3_1_WRONG_ENEMY_ID_0 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 26 | M3_1_ENEMY_FIXTURE_NO_DAMAGE_0 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 27 | M3_1_DECLARED_1 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 28 | M3_1_DOUBLE_DECLARE_1 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 29 | M3_1_WRONG_ENEMY_ID_1 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 30 | M3_1_ENEMY_FIXTURE_NO_DAMAGE_1 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 31 | M3_1_DECLARED_2 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 32 | M3_1_DOUBLE_DECLARE_2 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 33 | M3_1_WRONG_ENEMY_ID_2 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 34 | M3_1_ENEMY_FIXTURE_NO_DAMAGE_2 | test_m3_phase.gd | PASS / M3.1 ONLY |
| 35 | M3_1_ALL_ENEMY_ACTIONS_CONSUMED | test_m3_phase.gd | PASS / M3.1 ONLY |
| 36 | M3_1_NO_REDECLARATION | test_m3_phase.gd | PASS / M3.1 ONLY |
| 37 | M3_1_RP_EXPIRES_AT_ENEMY_END | test_m3_phase.gd | PASS / M3.1 ONLY |
| 38 | M3_1_NO_PLAYER_ACTION_WHILE_AWAITING | test_m3_phase.gd | PASS / M3.1 ONLY |
| 39 | M3_1_PHASE_TWO_RESOURCES | test_m3_phase.gd | PASS / M3.1 ONLY |
| 40 | M3_1_PHASE_TWO_HAND_REFILL | test_m3_phase.gd | PASS / M3.1 ONLY |
| 41 | M3_1_PHASE_TWO_ORDERED_EVENTS | test_m3_phase.gd | PASS / M3.1 ONLY |
| 42 | M3_1_FREE_SWAP_QUOTA_RENEWED | test_m3_phase.gd | PASS / M3.1 ONLY |
| 43 | M3_1_PHASE_REPLAY_CARD_RNG_PRESERVED | test_m3_phase.gd | PASS / M3.1 ONLY |
| 44 | M3_1_SEEDED_FULL_PHASE_REPLAY | test_m3_phase.gd | PASS / M3.1 ONLY |
| 45 | M3_1_REPLAY_EVENT_SEQUENCE | test_m3_phase.gd | PASS / M3.1 ONLY |
| 46 | M3_1_REPLAY_DUPLICATE_STOPS | test_m3_phase.gd | PASS / M3.1 ONLY |
| 47 | M3_1_ZERO_AP_SWAP_STILL_LEGAL | test_m3_phase.gd | PASS / M3.1 ONLY |
| 48 | M3_1_ZERO_AP_STILL_NO_AUTOPHASE | test_m3_phase.gd | PASS / M3.1 ONLY |
| 49 | M3_1_ZERO_AP_CAN_END_EXPLICITLY | test_m3_phase.gd | PASS / M3.1 ONLY |
| 50 | M3_1_FIRST_BASIC_MP_ONLY | test_m3_phase.gd | PASS / M3.1 ONLY |
| 51 | M3_1_B_ACTS_AFTER_A | test_m3_phase.gd | PASS / M3.1 ONLY |
| 52 | M3_1_CASTING_NOT_SILENTLY_RESOLVED | test_m3_phase.gd | PASS / M3.1 ONLY |
| 53 | M3_1_PRE3_R09_CASTING_FIXTURE_FIRST | test_m3_phase.gd | PASS / M3.1 ONLY |
| 54 | M3_1_PRE3_R09_STABLE_FIXTURE_ORDER | test_m3_phase.gd | PASS / M3.1 ONLY |
| 55 | M3_1_UNRESOLVED_REAL_CASTING_BLOCKED | test_m3_phase.gd | PASS / M3.1 ONLY |
| 56 | M3_1_REAL_STATUS_FAIL_CLOSED | test_m3_phase.gd | PASS / M3.1 ONLY |
| 57 | M3_1_CORE_01_VICTORY_PRIORITY | test_m3_phase.gd | PASS / M3.1 ONLY |
| 58 | M3_1_TERMINAL_NO_ACTION | test_m3_phase.gd | PASS / M3.1 ONLY |
| 59 | M3_1_DEFEAT_WITH_SURVIVING_BOSS | test_m3_phase.gd | PASS / M3.1 ONLY |
| 60 | M3_1_ACTUAL_RNG_STABLE | test_m3_phase.gd | PASS / M3.1 ONLY |
| 61 | M3_1_DIFFERENT_SEED_REPLAY_DISTINCT | test_m3_phase.gd | PASS / M3.1 ONLY |

M3.2–M3.5, real Casting ticks, Guard/Protect, Reaction, UI modes and boss damage remain unexecuted.


### M3.2 Reaction Window & Queue — 50 executed headless cases (2026-10-14)

Official Godot 4.7.2 [CI #38594159424](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38594159424) on SHA 3c26267cb2e314cf07e3a6ba269f07133852222e, seed 20261014. All **50/50** named M3.2 cases passed; earlier M3.1 61/61, M1–M2 249/249, four legacy scripts exit0. The executed M3.2 suite uses fixture-only Reaction SP effects, not real Guard/Protect or Spell Counter.

| # | Exact case ID from Godot stdout | Runner | Verdict |
|---:|---|---|---|
| 1 | `M3_2_ENEMY_ACTION_PINNED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 2 | `M3_2_RP_REAL_M2_LEDGER` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 3 | `M3_2_MUST_OPEN_WINDOW` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 4 | `M3_2_WINDOW_ID` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 5 | `M3_2_SINGLE_WINDOW_THREE_HITS` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 6 | `M3_2_WRONG_ACTION_ID_REJECTED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 7 | `M3_2_WRONG_WINDOW_ID_REJECTED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 8 | `M3_2_MULTIACTOR_QUEUE` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 9 | `M3_2_QUEUE_DOES_NOT_PAY` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 10 | `M3_2_PURE_PREVIEW` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 11 | `M3_2_SAME_ACTOR_REPLACES_DRAFT` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 12 | `M3_2_REMOVE_DRAFT_NO_CARD_SPEND` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 13 | `M3_2_INVALID_REORDER_ATOMIC` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 14 | `M3_2_USER_ORDER_NOT_SPEED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 15 | `M3_2_CONFIRM_CLOSES_WINDOW` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 16 | `M3_2_PRE3_R04_JIT_SKIP` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 17 | `M3_2_ONLY_EXECUTED_ACTORS_COUNT` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 18 | `M3_2_ONLY_TWO_REAL_SPENDS` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 19 | `M3_2_ONLY_TWO_CARDS_DISCARDED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 20 | `M3_2_ORDER_CONFIRM_PAY_EXECUTE_SKIP` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 21 | `M3_2_NO_PRECONFIRM_CORE_TRANSACTION` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 22 | `M3_2_AFTER_CONFIRM_REJECTS_EDITS` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 23 | `M3_2_DOUBLE_CONFIRM_ATOMIC` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 24 | `M3_2_DUPLICATE_COMMAND` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 25 | `M3_2_ACTION_COMPLETION_AFTER_WINDOW` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 26 | `M3_2_PRIOR_CANCEL_IS_FIXTURE_ONLY` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 27 | `M3_2_EXPIRED_WINDOW_AFTER_ACTION` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 28 | `M3_2_WINDOW_IDS_NONREUSED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 29 | `M3_2_RP_PERSISTS_BETWEEN_WINDOWS` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 30 | `M3_2_RP_EXPIRES_AT_PHASE_END` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 31 | `M3_2_PASS_NO_COST_OR_CARD` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 32 | `M3_2_PASS_EXPLICIT_ONLY` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 33 | `M3_2_NO_AUTO_PASS_WITH_ELAPSED_DATA` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 34 | `M3_2_WRONG_ACTOR_CARD` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 35 | `M3_2_INVALID_TARGET` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 36 | `M3_2_INCAPACITATED_INVALID` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 37 | `M3_2_EXHAUSTED_INVALID` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 38 | `M3_2_CONCENTRATION_FAIL_CLOSED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 39 | `M3_2_INSUFFICIENT_RP` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 40 | `M3_2_INSUFFICIENT_MP` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 41 | `M3_2_GUARD_PROTECT_NOT_FALSELY_IMPLEMENTED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 42 | `M3_2_CONFIRM_REJECTS_KNOWN_BUDGET_DEFICIT` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 43 | `M3_2_NO_FAKE_RESOURCE_PAYMENT` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 44 | `M3_2_BASIC_GUARD_CANNOT_BE_SILENTLY_SKIPPED` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 45 | `M3_2_NO_LEGAL_OPTIONS_EMPTY_WINDOW` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 46 | `M3_2_SEEDED_QUEUE_REPLAY` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 47 | `M3_2_REPLAY_NO_INITIAL_MUTATION` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 48 | `M3_2_REPLAY_CARD_CONSERVATION` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 49 | `M3_2_REPLAY_EVENT_SEQUENCING` | test_m3_reaction_window.gd | PASS / M3.2 domain |
| 50 | `M3_2_REPLAY_STALE_DUPLICATE_ATOMIC` | test_m3_reaction_window.gd | PASS / M3.2 domain |

Replay event SHA256 a37005b13323e86d4068fef74519adf1c95a1ff03da7b76d6d3e276b51cf414e; final state SHA256 c05baecca6080f83dd15608317d588fde6b2ca5260381ccc9ea8b9f1f6dbb6f7. M3.3 onward still requires its own named suites/CI and real gameplay verification.


### M3.3 Guard and Protect — 54 executed named Domain tests (2026-10-14)

Final official Godot 4.7.2 Actions run https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38596728929, tested SHA 42d0ac055b457f96123b4a669e558b0bcc3bcb65, seed 20261014. Actual M3.3 54/54 PASS + M3.2 50/50 + M3.1 61/61 + M1–M2 249/249 all PASS in this run. Four legacy smoke scripts exit0. The exact 54 observed PASS IDs:

| # | Godot test case | Runner | Verdict |
|---:|---|---|---|
| 1 | M3_3_SP_FREE_GUARD_AVAILABLE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 2 | M3_3_MULTHIT_SINGLE_WINDOW | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 3 | M3_3_QUEUE_GUARD_NO_HAND | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 4 | M3_3_GUARD_PREVIEW_PURE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 5 | M3_3_GUARD_EXACTLY_ONE_RP | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 6 | M3_3_GUARD_NO_MP_OR_CARD | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 7 | M3_3_GUARD_THREE_HIT_COVERAGE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 8 | M3_3_GUARD_NO_DAMAGE_HARDCODE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 9 | M3_3_GUARD_EVENTS_ORDER | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 10 | M3_3_GUARD_EXECUTE_ONCE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 11 | M3_3_GUARD_HANDOFF_SNAPSHOT | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 12 | M3_3_GUARD_NOT_GLOBAL_PERSISTENT | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 13 | M3_3_DOUBLE_PROTECT_DRAFT_IS_PURE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 14 | M3_3_PROTECT_ONE_REDIRECT | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 15 | M3_3_PROTECT_THREE_HITS_SINGLE_REDIRECT | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 16 | M3_3_PROTECT_ONLY_TWO_RP | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 17 | M3_3_SECOND_PROTECT_SKIPPED_NO_CHAIN | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 18 | M3_3_PROTECT_NO_CARD_USED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 19 | M3_3_REDIRECT_BEFORE_HIT_OR_DEFENSE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 20 | M3_3_REDIRECT_NOT_DAMAGE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 21 | M3_3_GUARD_THEN_PROTECT_PAID | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 22 | M3_3_GUARD_NOT_FREELY_REFUNDED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 23 | M3_3_GUARD_AFTER_REDIRECT_SKIPS | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 24 | M3_3_MULTITARGET_PROTECT_REJECTED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 25 | M3_3_AOE_PROTECT_REJECTED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 26 | M3_3_DIRECT_CASTING_NOT_BASIC_REACTION | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 27 | M3_3_UNPROTECTABLE_REJECTED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 28 | M3_3_CAN_GUARD_UNPROTECTABLE_HP | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 29 | M3_3_CANNOT_PROTECT_SELF | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 30 | M3_3_WRONG_PROTECT_TARGET | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 31 | M3_3_GUARD_NONTARGET_REJECTED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 32 | M3_3_INCAPACITATED_CANNOT_PROTECT | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 33 | M3_3_EXHAUSTED_CANNOT_PROTECT | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 34 | M3_3_CONCENTRATING_BASIC_DISALLOWED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 35 | M3_3_CAN_PROTECT_EXHAUSTED_TARGET | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 36 | M3_3_HP0_TARGET_REJECTED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 37 | M3_3_PROTECT_NEEDS_2_RP | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 38 | M3_3_GUARD_WITH_1_RP | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 39 | M3_3_NO_RP_NO_BASIC | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 40 | M3_3_NO_CARD_COST_FROM_BASIC | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 41 | M3_3_BASIC_GUARD_ZERO_RP_AFTER_PAY | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 42 | M3_3_DRAFT_IGNORES_CLIENT_COST_FIELDS | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 43 | M3_3_COST_SOURCE_IS_FIXED_DOMAIN | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 44 | M3_3_PRE3_R04_PROTECT_TRIGGER_GONE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 45 | M3_3_PRE3_R04_NO_PROTECT_CHARGE | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 46 | M3_3_PRE3_R04_REAL_SP_CARD_USED | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 47 | M3_3_SECOND_WINDOW_GUARD_RESETS | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 48 | M3_3_RP_SHARED_BETWEEN_ACTIONS | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 49 | M3_3_GUARD_COST_PER_DISTINCT_ACTION | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 50 | M3_3_RP_EXPIRES_AFTER_ACTIONS | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 51 | M3_3_SEEDED_GUARD_PROTECT_REPLAY | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 52 | M3_3_EVENT_SEQUENCE_MONOTONIC | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 53 | M3_3_REPLAY_CARD_CONSERVATION | test_m3_guard_protect.gd | PASS — M3.3 Domain only |
| 54 | M3_3_REPLAY_DUPLICATE_ATOMIC | test_m3_guard_protect.gd | PASS — M3.3 Domain only |

Canonical replay event hash SHA256 33da67eb4cd91d0e1b3ce0a5ca3d59d76ac6f5ff993f85fd57f5e6593853d077; final state SHA256 153aa594a108b70cecd4bb5e12188429cf636ad555e2727963c508455d6da9fa. Damage, Barrier/Guard mitigation, M4 magic and M3.4–M3.5 remain unexecuted.


### M3.4 Reaction UI Mode Contract — 83 actually executed named cases (2026-10-14)

Official Godot 4.7.2 successful workflow https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38598430159, code SHA 513129fc12c4de8b754041d4547a77f07b17a2f1, seed 20261014. Exactly **83/83** test_m3_ui_modes.gd PASS from actual raw CI stdout. Same run M3.3 54/54, M3.2 50/50, M3.1 61/61, M1–M2 249/249, plus four legacy scripts exit0. These are Domain and simulated time-metadata tests, not a rendered 120-second UI test.

| # | Actual Godot case ID | Test source | Verdict |
|---:|---|---|---|
| 1 | M3_4_DEFAULT_SMART | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 2 | M3_4_INVALID_MODE_REJECTED | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 3 | M3_4_INVALID_STATE_REJECTED | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 4 | M3_4_GUARD_ONLY_WINDOW_REAL | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 5 | M3_4_NO_SP_CATALOGUE_YET_GUARD_ELIGIBLE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 6 | M3_4_SMART_PENDING | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 7 | M3_4_SMART_SAME_WINDOW | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 8 | M3_4_SMART_VIEW_ONLY | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 9 | M3_4_SMART_NO_AUTO_SPEND | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 10 | M3_4_SMART_PRESENTATION_KEY | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 11 | M3_4_SMART_CANNOT_ADVANCE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 12 | M3_4_ALWAYS_ASK_PENDING | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 13 | M3_4_ALWAYS_ASK_SAME_WINDOW | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 14 | M3_4_ALWAYS_ASK_VIEW_ONLY | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 15 | M3_4_ALWAYS_ASK_NO_AUTO_SPEND | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 16 | M3_4_ALWAYS_ASK_PRESENTATION_KEY | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 17 | M3_4_ALWAYS_ASK_CANNOT_ADVANCE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 18 | M3_4_QUICK_PENDING | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 19 | M3_4_QUICK_SAME_WINDOW | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 20 | M3_4_QUICK_VIEW_ONLY | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 21 | M3_4_QUICK_NO_AUTO_SPEND | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 22 | M3_4_QUICK_PRESENTATION_KEY | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 23 | M3_4_QUICK_CANNOT_ADVANCE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 24 | M3_4_SMART_UNKNOWN_SAFER_MODAL | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 25 | M3_4_ALWAYS_ASK_ALWAYS_MODAL | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 26 | M3_4_QUICK_COMPACT_NOT_MODAL | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 27 | M3_4_SMART_MINOR_QUIET_BUT_BLOCKS | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 28 | M3_4_SMART_MAJOR_PROMINENT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 29 | M3_4_SMART_UNKNOWN_HINT_PROMINENT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 30 | M3_4_ALWAYS_ASK_IGNORES_THREAT_LEVEL | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 31 | M3_4_QUICK_IGNORES_THREAT_LEVEL | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 32 | M3_4_STYLES_DISTINCT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 33 | M3_4_SMART_WAIT_0 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 34 | M3_4_ALWAYS_ASK_WAIT_0 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 35 | M3_4_QUICK_WAIT_0 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 36 | M3_4_SMART_WAIT_120 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 37 | M3_4_ALWAYS_ASK_WAIT_120 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 38 | M3_4_QUICK_WAIT_120 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 39 | M3_4_SMART_WAIT_86400 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 40 | M3_4_ALWAYS_ASK_WAIT_86400 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 41 | M3_4_QUICK_WAIT_86400 | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 42 | M3_4_NO_ACTION_ON_ELAPSED_TIME | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 43 | M3_4_FPS_AND_DEVICE_NEUTRAL | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 44 | M3_4_SNAPSHOT_DOES_NOT_STORE_UI_MODE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 45 | M3_4_DRAFT_NO_RP_DEBIT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 46 | M3_4_DRAFT_NO_CARD_MOVE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 47 | M3_4_PREVIEW_UNCHANGED_WITH_MODE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 48 | M3_4_DRAFT_FEE_IS_SAME | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 49 | M3_4_DRAFT_STILL_CANNOT_AUTO_COMPLETE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 50 | M3_4_SMART_REPLAY_EXACT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 51 | M3_4_SMART_FIXED_COST | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 52 | M3_4_SMART_SAME_CARD_ZONES | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 53 | M3_4_SMART_REORDER_JIT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 54 | M3_4_SMART_ENEMY_FINISHES_ONLY_AFTER_CONFIRM | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 55 | M3_4_ALWAYS_ASK_REPLAY_EXACT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 56 | M3_4_ALWAYS_ASK_FIXED_COST | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 57 | M3_4_ALWAYS_ASK_SAME_CARD_ZONES | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 58 | M3_4_ALWAYS_ASK_REORDER_JIT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 59 | M3_4_ALWAYS_ASK_ENEMY_FINISHES_ONLY_AFTER_CONFIRM | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 60 | M3_4_QUICK_REPLAY_EXACT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 61 | M3_4_QUICK_FIXED_COST | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 62 | M3_4_QUICK_SAME_CARD_ZONES | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 63 | M3_4_QUICK_REORDER_JIT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 64 | M3_4_QUICK_ENEMY_FINISHES_ONLY_AFTER_CONFIRM | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 65 | M3_4_THREE_MODES_IDENTICAL_STATE_HASH | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 66 | M3_4_THREE_MODES_IDENTICAL_EVENT_HASH | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 67 | M3_4_THREE_MODES_IDENTICAL_DOMAIN_EVENTS | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 68 | M3_4_THREE_MODES_IDENTICAL_COMMAND_LEDGER | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 69 | M3_4_PASS_EXPLICIT_NO_RP | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 70 | M3_4_PASS_NO_CARD_CHANGE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 71 | M3_4_SMART_CLOSED_NO_PROMPT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 72 | M3_4_ALWAYS_ASK_CLOSED_NO_PROMPT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 73 | M3_4_QUICK_CLOSED_NO_PROMPT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 74 | M3_4_MANUAL_PASS_ENEMY_CAN_COMPLETE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 75 | M3_4_DUPLICATE_PASS_REJECTS | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 76 | M3_4_NO_LEGAL_OPTIONS_DETECTED | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 77 | M3_4_EMPTY_NO_AUTO_RESOURCE_CHANGE | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 78 | M3_4_SMART_EMPTY_SKIPS_PROMPT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 79 | M3_4_ALWAYS_ASK_EMPTY_SKIPS_PROMPT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 80 | M3_4_QUICK_EMPTY_SKIPS_PROMPT | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 81 | M3_4_EMPTY_CAN_FINISH_ACTION | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 82 | M3_4_NO_DECISION_BEFORE_WINDOW_OPENED | test_m3_ui_modes.gd | PASS / M3.4 Domain only |
| 83 | M3_4_PLAYER_PHASE_NO_WINDOW | test_m3_ui_modes.gd | PASS / M3.4 Domain only |

Seed replay event SHA256 1643d46796699e9eea86115bf1cb1960c8aa66f93302659f29f59d5e5b652642; final state SHA256 4cac348cc321900fcb65343ee8420d4ff3cc78f2529ab65ad4e24fa408de421f. M3.5 pending and all true Presentation UI work remains separate.


### M3.5 Integration + Replay — 101 actual Godot test cases (2026-10-14)

Official successful CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38601022642 on tested source SHA e638626a3c9fe44c2c4d172d04e1b409a9af08e0; official Godot 4.7.2, seed 20261014, 47 commands. Exactly **61/61** Integration and **40/40** Replay cases from actual stdout below; total M1–M3.5 named assertions **598/598 PASS**, 4 legacy prototype headless runners exit0. Domain-only fixture: no M4 casting effects, no M5 HP/damage/Guard coefficient, no playable UI.

| # | Exact Godot test ID | Runner | Gate |
|---:|---|---|---|
| 1 | M35-END2END-COMPLETE | test_m3_integration.gd | PASS / M3.5 Integration |
| 2 | M35-END2END-REAL_M2_CARD_ZONES | test_m3_integration.gd | PASS / M3.5 Integration |
| 3 | M35-END2END-ALL_36_INSTANCES | test_m3_integration.gd | PASS / M3.5 Integration |
| 4 | M35-END2END-SEED_IMMUTABLE | test_m3_integration.gd | PASS / M3.5 Integration |
| 5 | M35-END2END-PUBLIC_ORDER | test_m3_integration.gd | PASS / M3.5 Integration |
| 6 | M35-END2END-RP_CAP6_FROM_AP | test_m3_integration.gd | PASS / M3.5 Integration |
| 7 | M35-END2END-PHASE_AWAITING_CONSENT | test_m3_integration.gd | PASS / M3.5 Integration |
| 8 | M35-QUEUE-THREE_DIFFERENT_ACTORS | test_m3_integration.gd | PASS / M3.5 Integration |
| 9 | M35-QUEUE-NO_EARLY_RP_CHARGE | test_m3_integration.gd | PASS / M3.5 Integration |
| 10 | M35-QUEUE-NO_EARLY_MP_OR_CARD | test_m3_integration.gd | PASS / M3.5 Integration |
| 11 | M35-QUEUE-AGGREGATE_BUDGET | test_m3_integration.gd | PASS / M3.5 Integration |
| 12 | M35-QUEUE-CANNOT_PREMATURELY_FINISH | test_m3_integration.gd | PASS / M3.5 Integration |
| 13 | PH3-M3-QUEUE-001 | test_m3_integration.gd | PASS / M3.5 Integration |
| 14 | PRE3-R04-SKIP_WITHOUT_PAYMENT | test_m3_integration.gd | PASS / M3.5 Integration |
| 15 | M35-QUEUE-ONLY_TWO_REAL_PAYMENTS | test_m3_integration.gd | PASS / M3.5 Integration |
| 16 | M35-QUEUE-SKIPPED_B_KEEPS_MP | test_m3_integration.gd | PASS / M3.5 Integration |
| 17 | M35-QUEUE-SPENT_A_C_CARDS | test_m3_integration.gd | PASS / M3.5 Integration |
| 18 | M35-QUEUE-CARD_INSTANCE_CONSERVED | test_m3_integration.gd | PASS / M3.5 Integration |
| 19 | M35-QUEUE-COMMIT_BEFORE_SKIP_AND_CLOSE | test_m3_integration.gd | PASS / M3.5 Integration |
| 20 | M35-QUEUE-INDEPENDENT_SUPPORT_AFTER_CANCEL | test_m3_integration.gd | PASS / M3.5 Integration |
| 21 | M35-QUEUE-CONFIRM_IS_IDEMPOTENT_REJECT | test_m3_integration.gd | PASS / M3.5 Integration |
| 22 | M35-QUEUE-SKIPPED_GUARD_NOT_CONSUMED | test_m3_integration.gd | PASS / M3.5 Integration |
| 23 | M35-ACTION-CANCELLATION_METADATA_ONLY | test_m3_integration.gd | PASS / M3.5 Integration |
| 24 | M35-WINDOW-UNIQUE_ACTION_ID | test_m3_integration.gd | PASS / M3.5 Integration |
| 25 | M35-WINDOW-RP_CONTINUES_AS4 | test_m3_integration.gd | PASS / M3.5 Integration |
| 26 | M35-WINDOW-RESETS_EXECUTED_ACTORS | test_m3_integration.gd | PASS / M3.5 Integration |
| 27 | M35-GUARD_PROTECT-NO_DRAFT_CHARGE | test_m3_integration.gd | PASS / M3.5 Integration |
| 28 | PRE3-R02-GUARD_ALL_HITS | test_m3_integration.gd | PASS / M3.5 Integration |
| 29 | PH3-M3-PROTECT-001 | test_m3_integration.gd | PASS / M3.5 Integration |
| 30 | M35-GUARD_PROTECT-ONLY_3RP | test_m3_integration.gd | PASS / M3.5 Integration |
| 31 | M35-GUARD_PROTECT-NO_MP_CARD | test_m3_integration.gd | PASS / M3.5 Integration |
| 32 | M35-GUARD_PROTECT-CHRONOLOGY | test_m3_integration.gd | PASS / M3.5 Integration |
| 33 | M35-PROTECT-M5_HANDOFF_BEFORE_HIT | test_m3_integration.gd | PASS / M3.5 Integration |
| 34 | M35-PROTECT-ONLY_EXPLICIT_STATUS_TRANSFER | test_m3_integration.gd | PASS / M3.5 Integration |
| 35 | M35-PROTECT-NEVER_FAKES_HP_DAMAGE | test_m3_integration.gd | PASS / M3.5 Integration |
| 36 | M35-AOE-NO_PROTECT | test_m3_integration.gd | PASS / M3.5 Integration |
| 37 | M35-AOE-GUARD1RP | test_m3_integration.gd | PASS / M3.5 Integration |
| 38 | M35-AOE-MULTIHIT_COVERAGE | test_m3_integration.gd | PASS / M3.5 Integration |
| 39 | M35-RP_ZERO-EMPTY_WINDOW | test_m3_integration.gd | PASS / M3.5 Integration |
| 40 | M35-RP_ZERO-NO_PHANTOM_RP | test_m3_integration.gd | PASS / M3.5 Integration |
| 41 | M35-RP_ZERO-NO_FORCED_CONFIRM | test_m3_integration.gd | PASS / M3.5 Integration |
| 42 | M35-END_ENEMY-RP_EXPIRED | test_m3_integration.gd | PASS / M3.5 Integration |
| 43 | M35-PHASE_ROUND2_STARTS | test_m3_integration.gd | PASS / M3.5 Integration |
| 44 | M35-PHASE_REFILL_HAND4 | test_m3_integration.gd | PASS / M3.5 Integration |
| 45 | M35-PHASE_RESETS_REACTION_WINDOW | test_m3_integration.gd | PASS / M3.5 Integration |
| 46 | M35-PHASE_RESETS_SWAP_QUOTA | test_m3_integration.gd | PASS / M3.5 Integration |
| 47 | M35-PHASE_ORDER_RENEW_BEFORE_DRAW | test_m3_integration.gd | PASS / M3.5 Integration |
| 48 | P1-D01-PLAYER_ACTION_ORDER_AABA | test_m3_integration.gd | PASS / M3.5 Integration |
| 49 | M35-PHASE_AABA_AP_ACTUAL_COST | test_m3_integration.gd | PASS / M3.5 Integration |
| 50 | M35-PHASE_AABA_NO_UI_TIMER | test_m3_integration.gd | PASS / M3.5 Integration |
| 51 | M35-PHASE_SECOND_TURN_ALL_PASSED | test_m3_integration.gd | PASS / M3.5 Integration |
| 52 | M35-PHASE_SECOND_TURN_EXPLICIT_PASS | test_m3_integration.gd | PASS / M3.5 Integration |
| 53 | M35-PHASE_FINAL_HP_UNCHANGED_FIXTURE | test_m3_integration.gd | PASS / M3.5 Integration |
| 54 | M35-PHASE_NO_CASTING_STATUS_FAKE | test_m3_integration.gd | PASS / M3.5 Integration |
| 55 | M35-PHASE_36_CARDS_ALSO_ROUND3 | test_m3_integration.gd | PASS / M3.5 Integration |
| 56 | P2-VIS-02-NO_MOVE_COMMAND | test_m3_integration.gd | PASS / M3.5 Integration |
| 57 | M35-REJECT_STALE_COMMAND | test_m3_integration.gd | PASS / M3.5 Integration |
| 58 | M35-REJECT_DUPLICATE_COMMAND | test_m3_integration.gd | PASS / M3.5 Integration |
| 59 | M35-REJECT_DUPLICATE_CARD_ZONE | test_m3_integration.gd | PASS / M3.5 Integration |
| 60 | M35-INVALID_SOURCE_FAIL_CLOSED | test_m3_integration.gd | PASS / M3.5 Integration |
| 61 | M35-INTEGRATION_DOES_NOT_MUTATE_BATTLE | test_m3_integration.gd | PASS / M3.5 Integration |
| 62 | M35-REPLAY-EXACT_FINAL_STATE | test_m3_replay.gd | PASS / M3.5 Replay |
| 63 | M35-REPLAY-EXACT_EVENT_HASH | test_m3_replay.gd | PASS / M3.5 Replay |
| 64 | M35-REPLAY-STATE_HASH_REPEATABLE | test_m3_replay.gd | PASS / M3.5 Replay |
| 65 | M35-REPLAY-TAPE_NOT_MUTATED | test_m3_replay.gd | PASS / M3.5 Replay |
| 66 | M35-REPLAY-INITIAL_STATE_IMMUTABLE | test_m3_replay.gd | PASS / M3.5 Replay |
| 67 | M35-REPLAY-CARD_CONSERVATION | test_m3_replay.gd | PASS / M3.5 Replay |
| 68 | M35-REPLAY-MONOTONIC_EVENT_SEQUENCE | test_m3_replay.gd | PASS / M3.5 Replay |
| 69 | M35-REPLAY-EXACT_EVENT_COUNT | test_m3_replay.gd | PASS / M3.5 Replay |
| 70 | M35-REPLAY-COMMAND_RECEIPTS_1_PER_STEP | test_m3_replay.gd | PASS / M3.5 Replay |
| 71 | M35-REPLAY-FINAL_RECEIPT_HASH | test_m3_replay.gd | PASS / M3.5 Replay |
| 72 | M35-REPLAY-INITIAL_SHA_RECORDED | test_m3_replay.gd | PASS / M3.5 Replay |
| 73 | M35-REPLAY-RECEIPT_COMMAND_IDS | test_m3_replay.gd | PASS / M3.5 Replay |
| 74 | M35-REPLAY-EVERY_RECEIPT_HAS_HASH | test_m3_replay.gd | PASS / M3.5 Replay |
| 75 | M35-REPLAY-FIRST_TURN_RP_ZERO | test_m3_replay.gd | PASS / M3.5 Replay |
| 76 | M35-REPLAY-END_ROUND3 | test_m3_replay.gd | PASS / M3.5 Replay |
| 77 | M35-REPLAY-BOTH_ROUNDS_ENEMY_DECLARED | test_m3_replay.gd | PASS / M3.5 Replay |
| 78 | M35-REPLAY-EACH_ENEMY_ACTION_FINISHED | test_m3_replay.gd | PASS / M3.5 Replay |
| 79 | M35-REPLAY-EMPTY_WINDOW_EVENT_PRESENT | test_m3_replay.gd | PASS / M3.5 Replay |
| 80 | M35-REPLAY-PROTECT_REDIRECT_EVENT_PRESENT | test_m3_replay.gd | PASS / M3.5 Replay |
| 81 | M35-REPLAY-GUARD_EVENT_PRESENT | test_m3_replay.gd | PASS / M3.5 Replay |
| 82 | M35-REPLAY-SP_CANCEL_AND_FREE_SKIP_PRESENT | test_m3_replay.gd | PASS / M3.5 Replay |
| 83 | M35-REPLAY-TWO_PLAYER_RESOURCE_RENEWS | test_m3_replay.gd | PASS / M3.5 Replay |
| 84 | M35-REPLAY-RP_EXPIRY_COUNT | test_m3_replay.gd | PASS / M3.5 Replay |
| 85 | M35-REPLAY-SMART_VIEW_DOES_NOT_MODIFY_DOMAIN | test_m3_replay.gd | PASS / M3.5 Replay |
| 86 | M35-REPLAY-ALWAYS_ASK_VIEW_DOES_NOT_MODIFY_DOMAIN | test_m3_replay.gd | PASS / M3.5 Replay |
| 87 | M35-REPLAY-QUICK_VIEW_DOES_NOT_MODIFY_DOMAIN | test_m3_replay.gd | PASS / M3.5 Replay |
| 88 | M35-REPLAY-THREE_MODES_FINAL_STATE_EQUAL | test_m3_replay.gd | PASS / M3.5 Replay |
| 89 | M35-REPLAY-THREE_MODES_EVENT_HASH_EQUAL | test_m3_replay.gd | PASS / M3.5 Replay |
| 90 | M35-REPLAY-NO_WALL_CLOCK_IN_STATE | test_m3_replay.gd | PASS / M3.5 Replay |
| 91 | M35-REPLAY-STALE_STEP_REJECTED | test_m3_replay.gd | PASS / M3.5 Replay |
| 92 | M35-REPLAY-STALE_STOPS_BEFORE_ANY_LATER_STEP | test_m3_replay.gd | PASS / M3.5 Replay |
| 93 | M35-REPLAY-DUPLICATE_ID_REJECTED | test_m3_replay.gd | PASS / M3.5 Replay |
| 94 | M35-REPLAY-DUPLICATE_FAILS_CLOSED | test_m3_replay.gd | PASS / M3.5 Replay |
| 95 | M35-REPLAY-NO_PREMATURE_ACTION | test_m3_replay.gd | PASS / M3.5 Replay |
| 96 | M35-REPLAY-CONTENT_CHANGE_NOT_SILENT | test_m3_replay.gd | PASS / M3.5 Replay |
| 97 | M35-REPLAY-SEED_DISTINGUISHES_STATES | test_m3_replay.gd | PASS / M3.5 Replay |
| 98 | M35-REPLAY-DIFFERENT_SEED_NOT_IDENTICAL | test_m3_replay.gd | PASS / M3.5 Replay |
| 99 | M35-REPLAY-COST_EVENT_BEFORE_EFFECT | test_m3_replay.gd | PASS / M3.5 Replay |
| 100 | M35-REPLAY-CARD_INSTANCE_NOT_DUPLICATED | test_m3_replay.gd | PASS / M3.5 Replay |
| 101 | M35-REPLAY-NO_REAL_HP_DAMAGE_CLAIM | test_m3_replay.gd | PASS / M3.5 Replay |

Canonical replay seed 20261014; initial SHA256 435fe62907f8f5006bfb5fb201db0a54207bc06694173dc172c2757b94dc5430; event SHA256 05599b881ad2ba6ee37e9cd1b2cc89ce9b6d97ce1e7b53e1ec58ea439ae17717; final SHA256 25ca6dfaee05dc68d175adcea0392a679248b477d8d3bbdc9611a96714611b66. Exact evidence: above CI raw logs. `M3 DOMAIN VERIFIED` applies ONLY to headless fixture scope.


### M4.1 Dual Casting — 47 actual Godot assertions (2026-10-15)

Official PASS: https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38654007627 on tested SHA 8fcd65ee075664593a08448f3d44eede21a5c2bf; M4.1 **47/47** and M1–M3.5 **598/598** pass; four legacy scripts exit0. This is headless casting, not M5 real damage.

| # | Exact Godot stdout case ID | Runner | Result |
|---:|---|---|---|
| 1 | CAST-001-CHANTLESS_ACCEPTED | test_m4_dual_cast.gd | PASS / M4.1 only |
| 2 | CAST-001-CARD_IN_DISCARD | test_m4_dual_cast.gd | PASS / M4.1 only |
| 3 | CAST-001-IMMEDIATE_EFFECT_CONTRACT | test_m4_dual_cast.gd | PASS / M4.1 only |
| 4 | CAST-001-NO_CONCENTRATION | test_m4_dual_cast.gd | PASS / M4.1 only |
| 5 | CAST-001-COST_PAID_ONCE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 6 | M21-CAST-001-IMMEDIATE_NO_HP_DAMAGE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 7 | CAST-002-FULL_ACCEPTED | test_m4_dual_cast.gd | PASS / M4.1 only |
| 8 | CAST-002-CARD_IN_CASTING | test_m4_dual_cast.gd | PASS / M4.1 only |
| 9 | CAST-002-ONE_CASTING_INSTANCE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 10 | CAST-002-CONCENTRATING | test_m4_dual_cast.gd | PASS / M4.1 only |
| 11 | CAST-002-SCHEDULED_NEXT_PLAYER | test_m4_dual_cast.gd | PASS / M4.1 only |
| 12 | CAST-002-COST_PAID_AT_START | test_m4_dual_cast.gd | PASS / M4.1 only |
| 13 | M21-CAST-001-EQUAL_BASE_MP | test_m4_dual_cast.gd | PASS / M4.1 only |
| 14 | CAST-002-OWN_INSTANCE_STABILITY_ONLY | test_m4_dual_cast.gd | PASS / M4.1 only |
| 15 | CAST-002-ZONE_CONSERVATION | test_m4_dual_cast.gd | PASS / M4.1 only |
| 16 | CAST-002-RNG_UNCHANGED | test_m4_dual_cast.gd | PASS / M4.1 only |
| 17 | CAST-002-NO_PREMATURE_EFFECT | test_m4_dual_cast.gd | PASS / M4.1 only |
| 18 | CAST-003-BASIC_ATTACK_DENIED | test_m4_dual_cast.gd | PASS / M4.1 only |
| 19 | CAST-003-SECOND_FULL_DENIED | test_m4_dual_cast.gd | PASS / M4.1 only |
| 20 | CAST-003-CHANTLESS_WHILE_CONCENTRATING_DENIED | test_m4_dual_cast.gd | PASS / M4.1 only |
| 21 | CAST-003-M2_FREE_SWAP_NO_ACTIVE_ACTOR | test_m4_dual_cast.gd | PASS / M4.1 only |
| 22 | CAST-003-OTHER_ACTOR_CAN_ACT | test_m4_dual_cast.gd | PASS / M4.1 only |
| 23 | CAST-003-STILL_INITIAL_UNCHANGED | test_m4_dual_cast.gd | PASS / M4.1 only |
| 24 | CAST-003-NO_CANCEL_COMMAND | test_m4_dual_cast.gd | PASS / M4.1 only |
| 25 | CAST-NEG-DUPLICATE_COMMAND | test_m4_dual_cast.gd | PASS / M4.1 only |
| 26 | CAST-NEG-STALE_EVENT_SEQ | test_m4_dual_cast.gd | PASS / M4.1 only |
| 27 | CAST-NEG-BAD_CAST_MODE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 28 | CAST-NEG-MODE_UNAVAILABLE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 29 | CAST-NEG-WRONG_CARD_OWNER | test_m4_dual_cast.gd | PASS / M4.1 only |
| 30 | CAST-NEG-MISSING_TARGET | test_m4_dual_cast.gd | PASS / M4.1 only |
| 31 | CAST-NEG-INSUFFICIENT_MP_ATOMIC | test_m4_dual_cast.gd | PASS / M4.1 only |
| 32 | CAST-NEG-AP_FAILURE_NO_PARTIAL_COMMIT | test_m4_dual_cast.gd | PASS / M4.1 only |
| 33 | CAST-NEG-NO_CASTING_PROFILE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 34 | CAST-NEG-STABILITY_REQUIRES_PROVISIONAL_FIXTURE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 35 | CAST-NEG-NO_CONFIG_DONT_INVENT | test_m4_dual_cast.gd | PASS / M4.1 only |
| 36 | CAST-002-ENEMY_PHASE_WITH_CONCENTRATION | test_m4_dual_cast.gd | PASS / M4.1 only |
| 37 | CAST-002-RELEASED_ONLY_AT_BOUNDARY | test_m4_dual_cast.gd | PASS / M4.1 only |
| 38 | CAST-002-CAST_TO_DISCARD_ON_RELEASE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 39 | CAST-002-RELEASE_NO_SECOND_PAYMENT | test_m4_dual_cast.gd | PASS / M4.1 only |
| 40 | CAST-002-PHASE2_HAND_REFILLS_FOUR | test_m4_dual_cast.gd | PASS / M4.1 only |
| 41 | CAST-002-EVENT_BEFORE_M2_RENEW_AND_DRAW | test_m4_dual_cast.gd | PASS / M4.1 only |
| 42 | CAST-002-EFFECT_IS_NOT_REAL_DAMAGE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 43 | CAST-002-CARD_CONSERVATION_AFTER_ROUND_CHANGE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 44 | CAST-002-CAST_CAN_RESTART_LATER | test_m4_dual_cast.gd | PASS / M4.1 only |
| 45 | CAST-002-M4_REPLAY_ENTIRE_PHASE | test_m4_dual_cast.gd | PASS / M4.1 only |
| 46 | CAST-002-FAILED_INPUT_PRESERVES_RNG | test_m4_dual_cast.gd | PASS / M4.1 only |
| 47 | CAST-002-NO_FORGED_EFFECT_ON_REJECT | test_m4_dual_cast.gd | PASS / M4.1 only |

Fixed seed 20261014; event SHA256 6225fa6eb9949575437d7305057be8b7ad743d000e42625f8c8df9427118151b; final state SHA256 42b5f311978d20fea048cf5a85e075ff79998d540c7332ae69343ad595794871. M4.2–M4.5 pending.


### M4.2 Casting Disruption & Focus Ward — 59 actual Godot cases (2026-10-15)

Successful official Godot4.7.2 CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38656070665 at tested SHA 8a808cb0ef685fa48633740c6ae4a3f60f370c83. M4.2 **59/59 PASS**; previous stages **645/645 PASS**, cumulative **704/704 named Domain tests**, four prototype headless scripts exit0. These are authorized casting/hit fixtures, not a live M5 damage engine.

| # | Observed Godot test ID | Runner | Verdict |
|---:|---|---|---|
| 1 | M22-CAST-002-PAID_MP_TRACED_FROM_M2 | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 2 | M42-INDEPENDENT_TWO_CASTS | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 3 | M42-BOSS_BREAK_UNTOUCHED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 4 | CAST-004-WARD_NO_HP_ABSORPTION | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 5 | M22-CAST-002-REFUND_QUOTE_FROM_PAID_MP | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 6 | M22-CAST-002-PROVISIONAL_NOT_CANON | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 7 | M22-CAST-002-UNKNOWN_REFUND_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 8 | M22-CAST-002-REFUND_NOT_FULL_RATIO | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 9 | M42-NO_DIRECT_REFUND_WITHOUT_INTERRUPT | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 10 | M42-DIRECT_REQUIRES_WINDOW_RESOLUTION | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 11 | CAST-004-CONCENTRATION_BASIC_GUARD_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 12 | CAST-004-CONFIRM_ONLY_NO_EARLY_FEE | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 13 | CAST-004-QUEUED_CARD_IN_HAND_UNTIL_CONFIRM | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 14 | CAST-004-CAST_COMPATIBLE_EXECUTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 15 | CAST-004-FOCUS_WARD_APPLIED_VIA_M3_QUEUE | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 16 | CAST-004-CONCENTRATING_REMAINS | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 17 | CAST-004-FOCUS_WARD_SP_PAYS_REAL_RP_MP | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 18 | CAST-004-FOCUS_WARD_CARD_DISCARDED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 19 | P1-PRT-006-M3_REDIRECT_FIRST | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 20 | P1-PRT-006-NO_AUTOPASS | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 21 | P1-PRT-006-HIT_NOT_PROVEN_DENIED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 22 | P1-PRT-006-PROTECT_STOPS_ON_HIT_DISRUPTION | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 23 | P1-PRT-007-PROTECT_HP_UNCHANGED_M5_DEFERRED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 24 | P1-PRT-006-NON_MUTATING_PROTECT_CAST | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 25 | CAST-005-INVALID_SOURCE_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 26 | CAST-005-UNTRUSTED_SOURCE_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 27 | CAST-005-UNREGISTERED_POWER_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 28 | CAST-005-DIRECT_CASTING_ID_REQUIRED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 29 | CAST-004-WARD_FIRST_FULLY_ABSORBS | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 30 | CAST-004-DIRECT_BYPASSES_PROTECT | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 31 | CAST-004-FOCUS_WARD_EVENT_NOT_BARRIER | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 32 | CAST-005-DUPLICATE_DISRUPTION_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 33 | CAST-004-WARD_DEPLETED_BEFORE_STABILITY | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 34 | CAST-005-INDEPENDENT_CASTING_STABILITY | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 35 | CAST-005-STABILITY_ZERO_INTERRUPTS | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 36 | M22-CAST-002-IMMEDIATE_MP_REFUND | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 37 | M22-CAST-002-AP_DEBT_NOT_REFUNDED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 38 | CAST-005-REFUND_EVENT_ORDER | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 39 | CAST-005-A_CARD_CASTING_TO_DISCARD | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 40 | CAST-005-A_CONCENTRATION_CLEARED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 41 | CAST-005-B_CAST_STILL_ACTIVE | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 42 | CAST-005-EXACT_CARD_INSTANCE_CONSERVATION | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 43 | CAST-005-NO_HP_OR_BOSS_BREAK_AFFECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 44 | CAST-005-REPEAT_AFTER_INTERRUPT_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 45 | M42-SEEDED_REPLAY_EXECUTES | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 46 | M42-SEEDED_REPLAY_IDENTICAL_STATE_HASH | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 47 | M42-SEEDED_REPLAY_IDENTICAL_EVENT_HASH | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 48 | M42-REPLAY_INPUT_UNCHANGED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 49 | M42-REPLAY_STALE_FAILS_CLOSED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 50 | M22-CAST-002-MP_MAX_CAP | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 51 | P1-PRT-008-REAL_WINDOW_EXPLICIT_PASS | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 52 | P1-PRT-008-UNTRUSTED_HIT_FIXTURE_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 53 | P1-PRT-008-UNPROTECTED_ON_HIT_APPLIES | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 54 | P1-PRT-008-CONTENT_POWER_NOT_CLIENT_OVERRIDE | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 55 | P1-PRT-008-HP_REMAINS_M5_DEFERRED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 56 | P1-PRT-008-DUPLICATE_HIT_EVENT_REJECTED | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 57 | P1-PRT-008-CAST_CARD_REMAINS_IN_CASTING | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 58 | P1-PRT-008-CANNOT_DISRUPT_UNTARGETED_CASTER | test_m4_disruption.gd | PASS — M4.2 headless fixture |
| 59 | M42-NO_ORDINARY_REACTION_FROM_CONCENTRATING | test_m4_disruption.gd | PASS — M4.2 headless fixture |

Seed 20261014, 12 accepted commands, initial SHA256 5aa5e836f5ed4812b932a4d33d64697a6163f3ebc9d41722ef158a64fc651426; event SHA256 d9f3f8781b59e0e61bd82112f9cad5f86e298400aaa1c8bda4b13aa9d4bc919c; final SHA256 fa38ea93d554ea1dc8b63966a07647c2ecd7eb369b50c39709768bf34119e1d7. M4.3–M4.5 not executed.


### M4.3 Last Spell Engine — 55 executed Godot Domain assertions (2026-10-15)

Official full Godot 4.7.2 CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38658279319 on source 12d651289ae85078d166fbc1bf68e83a991bb603: M4.3 **55/55** PASS, M1–M4.2 predecessors **704/704** PASS, total **759/759** named assertions, all four prototype runners exit0. Specific source: tests/test_m4_last_spell.gd. M4.4 HP0 invalidation and M5 damage absent; next task only.

| # | Exact observed Godot stdout case ID | Runner | Result |
|---:|---|---|---|
| 1 | LAST-001-PRECONFIRM_QUOTE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 2 | LAST-001-LOCKED_VARIANT_REJECTED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 3 | LAST-001-WRONG_ACTOR_REJECTED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 4 | LAST-001-CONFIRM_MANDATORY | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 5 | LAST-001-CHANTLESS_FORBIDDEN | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 6 | LAST-001-MISSING_TARGET | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 7 | LAST-001-MP_FAILED_ATOMIC | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 8 | LAST-001-UNLOCK_ENFORCED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 9 | LAST-001-TIMELINE_MUST_BE_AUTHORIZED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 10 | LAST-001-SUBMIT_ACCEPTED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 11 | LAST-001-ONCE_USED_COMMITTED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 12 | LAST-001-NO_CARD_ZONE_MOVEMENT | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 13 | LAST-001-AP_MP_ONCE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 14 | LAST-001-BASE_AP_UNCHANGED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 15 | LAST-001-FULL_ONLY_CONCENTRATING | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 16 | LAST-001-UNIQUE_SLOT_NOT_HAND | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 17 | LAST-001-CANNOT_CANCEL | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 18 | LAST-001-NO_SECOND_ACTIVATION | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 19 | LAST-001-CANNOT_BASIC_ATTACK_WHILE_CONCENTRATING | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 20 | LAST-001-STALE_REJECTED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 21 | LAST-001-DUPLICATE_COMMAND_REJECTED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 22 | LAST-001-RNG_IMMUTABLE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 23 | LAST-002-NOT_EARLY_EFFECT | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 24 | LAST-003-DIRECT_REQUIRES_TARGET_INSTANCE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 25 | LAST-003-DISRUPTION-1-DOES_NOT_CANCEL | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 26 | LAST-003-DISRUPTION-1-NO_REFUND | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 27 | LAST-003-DISRUPTION-1-NO_CARD_ZONE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 28 | LAST-003-ONE_DELAY_USED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 29 | LAST-003-DISRUPTION-2-DOES_NOT_CANCEL | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 30 | LAST-003-DISRUPTION-2-NO_REFUND | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 31 | LAST-003-DISRUPTION-2-NO_CARD_ZONE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 32 | LAST-004-SECOND_DISRUPTION_WEAKENS | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 33 | LAST-003-DISRUPTION-3-DOES_NOT_CANCEL | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 34 | LAST-003-DISRUPTION-3-NO_REFUND | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 35 | LAST-003-DISRUPTION-3-NO_CARD_ZONE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 36 | LAST-004-NO_INFINITE_DELAY_OR_STACKING | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 37 | LAST-004-REJECT_REPLAYED_SOURCE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 38 | LAST-003-NO_RELEASE_IN_ROUND2 | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 39 | LAST-003-DELAY_PREVENTS_ROUND3_RELEASE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 40 | LAST-005-RELEASE_ONCE_AT_ROUND4 | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 41 | LAST-005-RELEASE_BEFORE_PLAYER_RESOURCES | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 42 | LAST-005-ACTOR_EXHAUSTED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 43 | LAST-005-BASE_AP_STILL_SIX | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 44 | LAST-005-ONCE_USED_PERSISTS | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 45 | LAST-005-EXHAUSTED_CANNOT_ATTACK | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 46 | LAST-005-EXHAUSTED_CANNOT_CAST | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 47 | LAST-005-EXHAUSTED_TARGETABLE_ALIVE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 48 | LAST-005-HP_UNCHANGED_M5_ONLY | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 49 | LAST-005-NO_CARD_INSTANCE_CREATED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 50 | LAST-005-NO_MP_PAYMENT_ON_RELEASE | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 51 | LAST-005-ACTOR_B_CAN_STILL_ACT | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 52 | LAST-REPLAY-SAME_SEED_FINAL | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 53 | LAST-REPLAY-SAME_SEED_EVENTS | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 54 | LAST-REPLAY-INITIAL_INPUT_UNTOUCHED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |
| 55 | LAST-REPLAY-STALE_FAIL_CLOSED | test_m4_last_spell.gd | PASS / M4.3 Domain fixture |

Seed 20261014; 25 commands; initial SHA256 a01369270c5d4807e2ca706883d34f15f1d3f2b7a6c6ec6712b5c6a50fd1e2d5; event SHA256 7b62efd51f31a176a309cf65c01c1512d544e5267109cb8f702f064fc86d68c3; final SHA256 2295c874442f8673dd74c6280df37b15f647574237e21756165e886e2ff162ea. Provisional values are NOT authorized balance canon.


### M4.4 — Forced Invalidation CORE-02 (59 actual Godot assertions, 2026-10-15)

Official successful Godot4.7.2 CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38660801424 at source 8030ce5fe8fed346a4612013f5d77cef2913e3d2. New M4.4 **59/59 PASS**; all M1–M4.3 prior **759/759 PASS**, cumulative **818/818** named Domain cases, four legacy headless scripts exit0. Internal fixture only, M5 not implied.

| # | Exact Godot stdout test ID | Runner | Result |
|---:|---|---|---|
| 1 | P2-LAST-01-COMMITTED_ONCE | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 2 | P2-LAST-01-T3_RELEASE_SCHEDULED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 3 | P2-LAST-01-COST_PAID_AT_START | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 4 | P2-LAST-01-NO_CARD_ZONE_FOR_LAST | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 5 | P2-LAST-01-T2_NO_PREMATURE_RELEASE | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 6 | PRE3-13-HP0_NOT_CLIENT_COMMAND | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 7 | PRE3-13-HIT_REQUIRES_PROOF | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 8 | PRE3-13-HIT_SOURCE_MUST_MATCH | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 9 | PRE3-13-UNRELATED_ACTOR_CANNOT_BE_KILLED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 10 | PRE3-13-UNKNOWN_EFFECT_REJECTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 11 | PRE3-13-GATED_FIXTURE_NOT_PUBLIC | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 12 | PRE3-13-ACTIVE_CAST_BEFORE_HIT | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 13 | P2-LAST-02-INSTANT_HP0 | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 14 | P2-LAST-02-HIT_EVENT_CHAIN | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 15 | CORE-02-INVALIDATE_CAUSE | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 16 | CORE-02-PENDING_INSTANCE_ERASED_NOW | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 17 | CORE-02-SCHEDULE_CANCELED_NOW | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 18 | P2-LAST-02-CANONICAL_INVALIDATED_HISTORY | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 19 | P2-LAST-03-ONCE_PER_BATTLE_NOT_REFUNDED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 20 | P2-LAST-03-NO_MP_REFUND | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 21 | P2-LAST-03-NO_AP_REFUND | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 22 | PRE3-14-DEBT_NOT_REFUNDED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 23 | PRE3-13-CARD_ZONES_FROZEN | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 24 | PRE3-13-RNG_UNCHANGED_ON_HP0 | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 25 | P2-LAST-02-M5_DAMAGE_NOT_INVENTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 26 | P2-LAST-02-OUTCOME_STILL_ONGOING | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 27 | P2-LAST-02-A_CANNOT_REACT_OR_ATTACK | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 28 | P2-LAST-02-CANT_REPEAT_HP_ZERO | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 29 | P2-LAST-02-STALE_SEQUENCE_REJECTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 30 | P2-LAST-02-DUPLICATE_COMMAND_REJECTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 31 | P2-LAST-01-NO_RELEASE_T3 | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 32 | P2-LAST-02-HAND_FROZEN_AFTER_ROUND | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 33 | PRE3-13-ORDINARY_HEAL_CANNOT_REVIVE | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 34 | P2-LAST-03-REVIVE_REQUIRES_PROVISIONED_FIXTURE | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 35 | P2-LAST-04-REVIVE_HP_RESTORED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 36 | P2-LAST-04-CANNOT_REVIVE_OLD_SPELL | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 37 | P2-LAST-04-ONCE_USED_STAYS_USED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 38 | P2-LAST-04-INVALIDATED_HISTORY_PERSISTS | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 39 | P2-LAST-04-STILL_NO_MP_REFUND | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 40 | P2-LAST-04-LAST_CANNOT_START_AGAIN | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 41 | P2-LAST-04-CANCEL_NEVER_ACCEPTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 42 | P2-LAST-04-DUPLICATE_REVIVE_REJECTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 43 | P2-LAST-05-REPLAY_ACCEPTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 44 | P2-LAST-05-REPLAY_IDENTICAL_FINAL | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 45 | P2-LAST-05-REPLAY_IDENTICAL_EVENTS | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 46 | P2-LAST-05-INITIAL_SNAPSHOT_UNCHANGED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 47 | P2-LAST-05-STALE_TAPE_FAIL_CLOSED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 48 | PRE3-13-ORDINARY_FULL_HP0_ACCEPTED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 49 | PRE3-13-ORDINARY_FULL_INVALIDATED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 50 | PRE3-13-ORDINARY_CARD_MOVED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 51 | PRE3-13-ORDINARY_NO_MP_REFUND | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 52 | PRE3-13-ORDINARY_EXACT_INVALIDATION | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 53 | P2-LAST-06-SUCCESS_FIRST | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 54 | P2-LAST-06-SUCCESS_EFFECT_ALREADY_PUBLISHED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 55 | P2-LAST-06-EXHAUSTED_CAN_BE_HIT | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 56 | P2-LAST-06-NO_RETROACTIVE_INVALIDATION | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 57 | PRE3-14-EXHAUSTED_PERSISTS_AFTER_REVIVE | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 58 | P2-LAST-06-RELEASE_HISTORY_UNCHANGED | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |
| 59 | PRE3-14-EXHAUSTED_CANNOT_ATTACK_AFTER_REVIVE | test_m4_incapacitation.gd | PASS — M4.4 headless Domain |

Replay Seed 20261014; command tape 17; initial SHA256 a01369270c5d4807e2ca706883d34f15f1d3f2b7a6c6ec6712b5c6a50fd1e2d5; event SHA256 eb269474180802ebb859f6de842e80dbfb2ab4789213810602c51a20fbd8d32e; final state SHA256 361407d3eded12d6688a78fc2bd77a82efd18c4dc0ff9b2da517c411dcbfaa8b. Last Spell forced HP0/Revive tests and successful-release-then-HP0 opposite case verified; M4.5 pending.


### M4.5 integrated acceptance — 79 actually executed Godot assertions (2026-10-15)

Official successful [Godot 4.7.2 CI #38665591370](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38665591370) tested source 7dc487f3f6ad1021f73293d7de222f1700fb819f. M4.5 integration **41/41**, Replay **38/38**, predecessors **818/818**, total **897/897** named Domain PASS, 4 legacy smoke PASS. Headless fixture scope only, not M5 real damage.

| # | Exact actual stdout PASS case | Runner | Result |
|---:|---|---|---|
| 1 | M45-INT-01-EXECUTED_ALL_REAL_COMMANDS | test_m4_integration.gd | PASS |
| 2 | M45-INT-02-VALID_M4_DOMAIN | test_m4_integration.gd | PASS |
| 3 | M45-INT-03-ALL_36_CARDS_CONSERVED | test_m4_integration.gd | PASS |
| 4 | M45-INT-04-ORIGIN_IMMUTABLE | test_m4_integration.gd | PASS |
| 5 | M45-INT-05-THREE_ACTORS_MIXED_FREE_ORDER | test_m4_integration.gd | PASS |
| 6 | M45-INT-06-LAST_USES_NO_CARD_ZONE | test_m4_integration.gd | PASS |
| 7 | M45-INT-07-MIXED_COST_ACTUAL_M2 | test_m4_integration.gd | PASS |
| 8 | M45-INT-08-CHASE_CARD_SINGLE_CAST_ZONE | test_m4_integration.gd | PASS |
| 9 | M45-INT-09-DRAFT_THREE_RP_NO_PAYMENT | test_m4_integration.gd | PASS |
| 10 | M45-INT-10-TWO_ACTOR_REACTION_QUEUE | test_m4_integration.gd | PASS |
| 11 | M45-INT-11-CONCENTRATING_CAST_COMPATIBLE_PAID | test_m4_integration.gd | PASS |
| 12 | M45-INT-12-WARD_ON_LAST_INSTANCE | test_m4_integration.gd | PASS |
| 13 | M45-INT-13-PROTECT_TARGET_IS_C | test_m4_integration.gd | PASS |
| 14 | M45-INT-14-RP_LEGAL_ON_CONFIRM | test_m4_integration.gd | PASS |
| 15 | M45-INT-15-ON_HIT_SUPPRESSED_AFTER_PROTECT | test_m4_integration.gd | PASS |
| 16 | M45-INT-16-DIRECT_BYPASSES_PROTECT | test_m4_integration.gd | PASS |
| 17 | M45-INT-17-FIRST_INSTABILITY_DELAY_ONCE | test_m4_integration.gd | PASS |
| 18 | M45-INT-18-NO_INTERRUPTION_REFUND_ON_LAST | test_m4_integration.gd | PASS |
| 19 | M45-INT-19-B_FULL_RELEASED | test_m4_integration.gd | PASS |
| 20 | M45-INT-20-RELEASE_BEFORE_AP_AND_DRAW | test_m4_integration.gd | PASS |
| 21 | M45-INT-21-B_CARD_EXACT_CAST_TO_DISCARD | test_m4_integration.gd | PASS |
| 22 | M45-INT-22-RENEW_PRESERVES_LAST_CAST | test_m4_integration.gd | PASS |
| 23 | M45-INT-23-R2_PROTECT_FRESH_WINDOW | test_m4_integration.gd | PASS |
| 24 | M45-INT-24-PROTECT_GUARDIAN_INCAPACITATED | test_m4_integration.gd | PASS |
| 25 | M45-INT-25-CASTER_NOT_INVALIDATED_BY_PROTECTED_HIT | test_m4_integration.gd | PASS |
| 26 | M45-INT-26-C_NORMAL_FULL_RELEASED | test_m4_integration.gd | PASS |
| 27 | M45-INT-27-LAST_DOES_NOT_EARLY_RELEASE | test_m4_integration.gd | PASS |
| 28 | M45-INT-28-CORE02_INSTANT_ACTOR_ZERO | test_m4_integration.gd | PASS |
| 29 | M45-INT-29-CORE02_STRICT_CHAIN | test_m4_integration.gd | PASS |
| 30 | M45-INT-30-SCHEDULE_ERASED_AT_DAMAGE_BOUNDARY | test_m4_integration.gd | PASS |
| 31 | M45-INT-31-NEVER_REFUND_AP_MP_OR_USAGE | test_m4_integration.gd | PASS |
| 32 | M45-INT-32-T4_NO_RESURRECTED_LAST_EFFECT | test_m4_integration.gd | PASS |
| 33 | M45-INT-33-T4_INCAPACITATED_HAND_FROZEN | test_m4_integration.gd | PASS |
| 34 | M45-INT-34-REVIVE_NOT_RESTORE_LAST | test_m4_integration.gd | PASS |
| 35 | M45-INT-35-REVIVED_CANNOT_RECAST | test_m4_integration.gd | PASS |
| 36 | M45-INT-36-M5_HP_DAMAGE_NOT_INVENTED | test_m4_integration.gd | PASS |
| 37 | M45-INT-37-REAL_CARD_ZONES_PRESERVED | test_m4_integration.gd | PASS |
| 38 | M45-INT-38-M4_STATUS_LIFETIME_VALID | test_m4_integration.gd | PASS |
| 39 | M45-INT-39-COMMANDS_UNIQUE | test_m4_integration.gd | PASS |
| 40 | M45-INT-40-UNTRUSTED_HP_COMMAND_REJECTED | test_m4_integration.gd | PASS |
| 41 | M45-INT-41-NO_PUBLIC_KILL_COMMAND | test_m4_integration.gd | PASS |
| 42 | M45-REP-01-FULL_TAPE_EXECUTED | test_m4_replay.gd | PASS |
| 43 | M45-REP-02-FINAL_STATE_EQUAL | test_m4_replay.gd | PASS |
| 44 | M45-REP-03-REPEATED_SAME_SEED_STATE | test_m4_replay.gd | PASS |
| 45 | M45-REP-04-REPEATED_SAME_SEED_EVENTS | test_m4_replay.gd | PASS |
| 46 | M45-REP-05-CANONICAL_LOG_MATCH | test_m4_replay.gd | PASS |
| 47 | M45-REP-06-OUTER_EVENT_SEQUENCE_MONOTONIC | test_m4_replay.gd | PASS |
| 48 | M45-REP-07-CARD_INSTANCES_CONSERVED | test_m4_replay.gd | PASS |
| 49 | M45-REP-08-M4_CORE_VALID | test_m4_replay.gd | PASS |
| 50 | M45-REP-09-INPUT_INITIAL_UNCHANGED | test_m4_replay.gd | PASS |
| 51 | M45-REP-10-INPUT_TAPE_UNCHANGED | test_m4_replay.gd | PASS |
| 52 | M45-REP-11-TWO_CONCENTRATING_CASTS | test_m4_replay.gd | PASS |
| 53 | M45-REP-12-ONE_LAST_COMMITTED | test_m4_replay.gd | PASS |
| 54 | M45-REP-13-LAST_NOT_RELEASED | test_m4_replay.gd | PASS |
| 55 | M45-REP-14-ONE_LAST_INVALIDATION | test_m4_replay.gd | PASS |
| 56 | M45-REP-15-ORDINARY_SPELLS_RELEASED | test_m4_replay.gd | PASS |
| 57 | M45-REP-16-PROTECT_TWICE | test_m4_replay.gd | PASS |
| 58 | M45-REP-17-ONE_WARD_GRANTED | test_m4_replay.gd | PASS |
| 59 | M45-REP-18-ONE_DESTABILIZATION | test_m4_replay.gd | PASS |
| 60 | M45-REP-19-NO_LAST_MP_REFUND | test_m4_replay.gd | PASS |
| 61 | M45-REP-20-REVIVE_NO_RECAST | test_m4_replay.gd | PASS |
| 62 | M45-REP-21-EACH_COMMAND_RECEIPT_HASHED | test_m4_replay.gd | PASS |
| 63 | M45-REP-22-RECEIPT_LAST_HASH_MATCHES | test_m4_replay.gd | PASS |
| 64 | M45-REP-23-RECEIPTS_UNIQUE_COMMAND_IDS | test_m4_replay.gd | PASS |
| 65 | M45-REP-24-APPENDING_NO_HIDDEN_COMMANDS | test_m4_replay.gd | PASS |
| 66 | M45-REP-25-SMART_NO_DOMAIN_MUTATION | test_m4_replay.gd | PASS |
| 67 | M45-REP-25-ALWAYS_ASK_NO_DOMAIN_MUTATION | test_m4_replay.gd | PASS |
| 68 | M45-REP-25-QUICK_NO_DOMAIN_MUTATION | test_m4_replay.gd | PASS |
| 69 | M45-REP-26-ALL_UI_MODES_EQUAL_STATE | test_m4_replay.gd | PASS |
| 70 | M45-REP-27-ALL_UI_MODES_EQUAL_EVENTS | test_m4_replay.gd | PASS |
| 71 | M45-REP-28-NO_REALTIME_STATE_FIELD | test_m4_replay.gd | PASS |
| 72 | M45-REP-29-STALE_TAPE_FAILS_CLOSED | test_m4_replay.gd | PASS |
| 73 | M45-REP-30-STALE_DOES_NOT_CHANGE_ORIGIN | test_m4_replay.gd | PASS |
| 74 | M45-REP-31-DUPLICATE_COMMAND_REJECTED | test_m4_replay.gd | PASS |
| 75 | M45-REP-32-HIT_AUTHORIZATION_NOT_SKIPPED | test_m4_replay.gd | PASS |
| 76 | M45-REP-33-VERSIONED_CONTENT_AFFECTS_REPLAY | test_m4_replay.gd | PASS |
| 77 | M45-REP-34-SEED_DISTINGUISHES_INITIAL | test_m4_replay.gd | PASS |
| 78 | M45-REP-35-NO_REAL_BOSS_HP_DAMAGE | test_m4_replay.gd | PASS |
| 79 | M45-REP-36-BOTH_HP0_ACTORS_ACCOUNTED | test_m4_replay.gd | PASS |

Seed20261014; 34 accepted commands; Initial SHA256 38f22585ad007413001f460772cbe2400c0b10e6601d6e03a4f3820490e49bdd; Event SHA256 82dfac4a2ea16cf30382a095d0881d74c5d90995eb01fad6f45fc61297d71a25; Final SHA256 c99b758c59c044c6c9fea8dae5306eac877c1a6b9381e8529578468d3f9ce7f6. Repairs and exclusions: PH3_M4_5_ACCEPTANCE_REPORT.md.


### M5.1 real HP Damage — 44 observed official Godot cases (2026-10-15)

Official completed-success [Godot 4.7.2 CI #38668678354](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38668678354), tested source 407ca2c9e3f7ffc67de45e2150300465420192d1. **44/44 new + 897/897 predecessors = 941/941 named PASS**, 4 legacy pass; all numbers in M5.1 Balance remain PROVISIONAL.

| # | Exact observed stdout PASS ID | Runner | Result |
|---:|---|---|---|
| 1 | M51-01-AUTHORITY_ENFORCED | test_m5_damage.gd | PASS |
| 2 | M51-02-FIXTURE_HP0_NOT_PLAYER_COMMAND | test_m5_damage.gd | PASS |
| 3 | M51-03-M5_DISABLED_FAIL_CLOSED | test_m5_damage.gd | PASS |
| 4 | M51-04-GUARANTEED_NO_RNG | test_m5_damage.gd | PASS |
| 5 | M51-05-CHANCE_PERCENT_RNG_ONCE | test_m5_damage.gd | PASS |
| 6 | M51-06-HIT_CLAMP_95 | test_m5_damage.gd | PASS |
| 7 | M51-07-HIT_CLAMP_05 | test_m5_damage.gd | PASS |
| 8 | M51-08-CONDITIONAL_MISS_NO_RNG | test_m5_damage.gd | PASS |
| 9 | M51-09-CONDITIONAL_MUST_BE_DEFINED | test_m5_damage.gd | PASS |
| 10 | M51-10-INELIGIBLE_CRIT_NO_RNG | test_m5_damage.gd | PASS |
| 11 | M51-11-ELIGIBLE_CRIT_100_PERCENT | test_m5_damage.gd | PASS |
| 12 | M51-12-REAL_HP_DEDUCTED | test_m5_damage.gd | PASS |
| 13 | M51-13-ONE_TRACE_ONE_HP_EVENT | test_m5_damage.gd | PASS |
| 14 | M51-14-DAMAGE_SOURCE_IMMUTABLE | test_m5_damage.gd | PASS |
| 15 | M51-15-MISS_HAS_ZERO_DAMAGE_AND_NO_CRIT_ROLL | test_m5_damage.gd | PASS |
| 16 | M51-16-ELEMENT_BY_ENEMY | test_m5_damage.gd | PASS |
| 17 | M51-17-PROTECT_USES_RECIPIENT_DEFENSE | test_m5_damage.gd | PASS |
| 18 | M51-18-UNAUTHORIZED_REDIRECT_REJECTED | test_m5_damage.gd | PASS |
| 19 | M51-19-GUARD_THEN_BARRIER | test_m5_damage.gd | PASS |
| 20 | M51-20-FOCUS_WARD_NOT_HP_BARRIER | test_m5_damage.gd | PASS |
| 21 | M51-21-ZERO_DAMAGE_NOT_CHIP_ONE | test_m5_damage.gd | PASS |
| 22 | M51-22-MULTIHIT_TWO_REAL_DAMAGE_EVENTS | test_m5_damage.gd | PASS |
| 23 | M51-23-UNKNOWN_ELEMENT_FAILS_CLOSED | test_m5_damage.gd | PASS |
| 24 | M51-24-REAL_HP0_CALLS_M4_INVALIDATOR | test_m5_damage.gd | PASS |
| 25 | M51-25-CHANTLESS_REAL_DAMAGE_BEFORE_OUTCOME | test_m5_damage.gd | PASS |
| 26 | M51-26-CHANTLESS_AP_MP_ONCE | test_m5_damage.gd | PASS |
| 27 | M51-27-CHANTLESS_NOT_DEFERRED | test_m5_damage.gd | PASS |
| 28 | M51-28-FULL_NO_EARLY_DAMAGE | test_m5_damage.gd | PASS |
| 29 | M51-29-BASIC_ATTACK_REAL_DAMAGE | test_m5_damage.gd | PASS |
| 30 | M51-30-BASIC_STILL_ONLY_ONE_M2_RESOURCE_TRANSACTION | test_m5_damage.gd | PASS |
| 31 | M51-31-REACTION_EXPLICIT_PASS_REQUIRED | test_m5_damage.gd | PASS |
| 32 | M51-32-ENEMY_ACTION_REAL_TWO_HITS | test_m5_damage.gd | PASS |
| 33 | M51-33-ENEMY_DAMAGE_BEFORE_OUTCOME | test_m5_damage.gd | PASS |
| 34 | M51-34-ENEMY_INTENT_NOT_REPLACED | test_m5_damage.gd | PASS |
| 35 | M51-35-FULL_RELEASE_DOES_REAL_HP | test_m5_damage.gd | PASS |
| 36 | M51-36-FULL_RELEASE_BEFORE_AP_DRAW | test_m5_damage.gd | PASS |
| 37 | M51-37-FULL_CARD_UNIQUE_DISCARD | test_m5_damage.gd | PASS |
| 38 | M51-38-FULL_NO_SECOND_PAYMENT | test_m5_damage.gd | PASS |
| 39 | M51-39-INITIAL_IMMUTABLE | test_m5_damage.gd | PASS |
| 40 | M51-40-SAME_TAPE_EVENT_HASH | test_m5_damage.gd | PASS |
| 41 | M51-41-SAME_TAPE_FINAL_HASH | test_m5_damage.gd | PASS |
| 42 | M51-42-STALE_REPLAY_REFUSED | test_m5_damage.gd | PASS |
| 43 | M51-43-CONTENT_CHANGE_ALTERS_HASH | test_m5_damage.gd | PASS |
| 44 | M51-44-REAL_DAMAGE_NOT_FREE_FIXTURE | test_m5_damage.gd | PASS |

Replay Seed 20261014, 10 accepted commands; Initial SHA256 ed2a46bfe3d0483d1da78c21ea249bf467219ab775d54415dd5e40dd8e44f609; Event SHA256 62f244f463941b9b9d2d79344bdc53b308554d70571554015f71fafe72810db8; Final SHA256 9988c6cd48b65ab98a5acb269906e52cf9e960d3f79aac23c50dd4b3634608b2. M5.2–5.5 and full playable Boss battle are not verified.


### M5.2 — Registered Status, real HP Barrier and Revive: 48 observed Godot named oracles (2026-10-15)

Official completed-success [Godot 4.7.2 Actions #38670492488](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38670492488), tested SHA **20e2e7da8cc841c73d9a558860681465460754a0**, independent new suite **48/48 PASS**, all prior M1–M5.1 **941/941 PASS**, total **989/989 named Domain PASS** and 4 legacy headless runners PASS. Headless fixture only; not M5.3 Boss strategy or complete M5.

| # | Exact actual Godot PASS case ID | Runner | Result |
|---:|---|---|---|
| 1 | M52-01-NO_UNPAID_STATUS_COMMAND | test_m5_status.gd | PASS |
| 2 | M52-02-TARGET_TEAM_CHECKED | test_m5_status.gd | PASS |
| 3 | M52-03-CARD_IN_HAND_REQUIRED | test_m5_status.gd | PASS |
| 4 | M52-04-SP_COST_ONCE | test_m5_status.gd | PASS |
| 5 | M52-05-REGISTERED_STATUS_CREATED | test_m5_status.gd | PASS |
| 6 | M52-06-STATUS_HAS_SOURCE_AND_VERSION | test_m5_status.gd | PASS |
| 7 | M52-07-NO_PREMATURE_TICK | test_m5_status.gd | PASS |
| 8 | M52-08-AUTHORITATIVE_BARRIER_CAPACITY | test_m5_status.gd | PASS |
| 9 | M52-09-WARD_SEPARATE_FROM_CASTING | test_m5_status.gd | PASS |
| 10 | M52-10-MULTIPLE_REAL_STATUS_INSTANCES | test_m5_status.gd | PASS |
| 11 | M52-11-ONE_AP_PER_PAID_CARD | test_m5_status.gd | PASS |
| 12 | M52-12-ACTUAL_ENEMY_HIT_SHIELD | test_m5_status.gd | PASS |
| 13 | M52-13-ENEMY_ON_HIT_STATUS_ATTACHED | test_m5_status.gd | PASS |
| 14 | M52-14-TICK_PRIORITY_DOT_BEFORE_HOT | test_m5_status.gd | PASS |
| 15 | M52-15-BOSS_DOT_REAL_HP | test_m5_status.gd | PASS |
| 16 | M52-16-FIRST_TICK_REMAINING_ONE | test_m5_status.gd | PASS |
| 17 | M52-17-TICKS_BEFORE_PLAYER_AP_REFRESH | test_m5_status.gd | PASS |
| 18 | M52-18-CARDS_CONSERVED | test_m5_status.gd | PASS |
| 19 | M52-19-HASH_INITIAL_UNCHANGED | test_m5_status.gd | PASS |
| 20 | M52-20-DETERMINISTIC_EVENT_REPLAY | test_m5_status.gd | PASS |
| 21 | M52-21-DETERMINISTIC_STATE_REPLAY | test_m5_status.gd | PASS |
| 22 | M52-22-STABLE_RNG_NOT_FRAME_TIMER | test_m5_status.gd | PASS |
| 23 | M52-23-STALE_TAPE_DENIED | test_m5_status.gd | PASS |
| 24 | M52-24-CONTENT_VERSION_ALTERS_EVENTS | test_m5_status.gd | PASS |
| 25 | M52-25-STACK_CAP_THREE | test_m5_status.gd | PASS |
| 26 | M52-26-STACKED_DOT_REAL_DAMAGE | test_m5_status.gd | PASS |
| 27 | M52-27-STATUS_EXPIRES_AFTER_TWO_TICKS | test_m5_status.gd | PASS |
| 28 | M52-28-IGNORE_NO_RESET | test_m5_status.gd | PASS |
| 29 | M52-29-REFRESH_RETAINS_INSTANCE_ID | test_m5_status.gd | PASS |
| 30 | M52-30-BARRIER_REPLACE_NOT_ACCUMULATE | test_m5_status.gd | PASS |
| 31 | M52-31-DISPEL_TARGETED_BY_TAG | test_m5_status.gd | PASS |
| 32 | M52-32-BARRIER_LIFETIME_EXPIRED | test_m5_status.gd | PASS |
| 33 | M52-33-BUFF_CHANGES_REAL_ATTACK | test_m5_status.gd | PASS |
| 34 | M52-34-DEBUFF_CHANGES_DEFENSE | test_m5_status.gd | PASS |
| 35 | M52-35-LAST_LEGALLY_COMMITS | test_m5_status.gd | PASS |
| 36 | M52-36-DOT_HP0_IN_SAME_BOUNDARY | test_m5_status.gd | PASS |
| 37 | M52-37-CORE02_STRICT_ORDER | test_m5_status.gd | PASS |
| 38 | M52-38-NO_LAST_REFUND_OR_RESTORED_QUOTA | test_m5_status.gd | PASS |
| 39 | M52-39-INCAPACITATED_HAND_FROZEN | test_m5_status.gd | PASS |
| 40 | M52-40-ORDINARY_HEAL_CANNOT_REVIVE | test_m5_status.gd | PASS |
| 41 | M52-41-ACTUAL_PAID_REVIVE | test_m5_status.gd | PASS |
| 42 | M52-42-REVIVE_NEVER_RECREATES_LAST | test_m5_status.gd | PASS |
| 43 | M52-43-REVIVE_PAYMENT_ONLY_ONCE | test_m5_status.gd | PASS |
| 44 | M52-44-ON_HIT_PROTECT_REAL_RECIPIENT | test_m5_status.gd | PASS |
| 45 | M52-45-ON_HIT_SUPPRESSED_UNLESS_TAGGED | test_m5_status.gd | PASS |
| 46 | M52-46-ORIGIN_PRESERVED | test_m5_status.gd | PASS |
| 47 | M52-47-REAL_STATUS_SP_CARD_CONSERVATION | test_m5_status.gd | PASS |
| 48 | M52-48-ENEMY_DIRECT_HP_UNTRUSTED_REJECTED | test_m5_status.gd | PASS |

Seed **20261014**, **10 accepted commands**, initial SHA256 **c31261748b1b82c202a849c3236ef1833982dd00692cc406e7d3cabaf2cbc41c**, canonical events SHA256 **8f4f71a130323e6e8e9a6ccff69ce5310fb642c6baa74bccfd6b8fd920cc7cce**, final state SHA256 **31aa1bf68e6441d623337e2e59a78ba04400a040f2248531bcd290cb69f7e61e**. First CI succeeded without repairs. See PH3_M5_2_ENGINEERING_NOTE.md. M5.3–M5.5 remain NOT VERIFIED.

## M5.3 — 44 named Boss/Break/Exposed/Combo Domain oracles (2026-10-15)

Official [Godot Actions #38674222091](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38674222091) on code SHA `e9e33ce86bd1232aa1323c4a9c8a97ce85ef12b0`: **44/44 PASS**, M1–M5.2 **989/989** regressions PASS, total **1033/1033 Domain**, four legacy scripts success. All remain fixture-only and `BALANCE_PROVISIONAL`.

| # | Named case ID | Runner | Status |
|---:|---|---|---|
| 1 | `M53-01-SINGLE_M5_BASELINE` | `test_m5_boss_combo.gd` | PASS |
| 2 | `M53-02-UNTRUSTED_BREAK_DENIED` | `test_m5_boss_combo.gd` | PASS |
| 3 | `M53-03-CANNOT_STEAL_CARD` | `test_m5_boss_combo.gd` | PASS |
| 4 | `M53-04-INVALID_COMBO_MODE_DENIED` | `test_m5_boss_combo.gd` | PASS |
| 5 | `M53-05-M2_AP_PAID_ONCE` | `test_m5_boss_combo.gd` | PASS |
| 6 | `M53-06-M2_MP_PAID_ONCE` | `test_m5_boss_combo.gd` | PASS |
| 7 | `M53-07-CARD_HAND_TO_DISCARD` | `test_m5_boss_combo.gd` | PASS |
| 8 | `M53-08-MULTI_HIT_BEFORE_BREAK` | `test_m5_boss_combo.gd` | PASS |
| 9 | `M53-09-BREAK_LOCKED_ON_WHOLE_SP` | `test_m5_boss_combo.gd` | PASS |
| 10 | `M53-10-BREAK_DISTINCT_FROM_CASTING` | `test_m5_boss_combo.gd` | PASS |
| 11 | `M53-11-EXPOSED_SINGLE_OPPORTUNITY` | `test_m5_boss_combo.gd` | PASS |
| 12 | `M53-12-COMBO_OFFER_WITH_SOURCE` | `test_m5_boss_combo.gd` | PASS |
| 13 | `M53-13-SOURCE_CANNOT_SELF_COMBO` | `test_m5_boss_combo.gd` | PASS |
| 14 | `M53-14-STILL_ORIGINAL_IMMUTABLE` | `test_m5_boss_combo.gd` | PASS |
| 15 | `M53-15-TWO_DIFFERENT_ACTORS_PAID` | `test_m5_boss_combo.gd` | PASS |
| 16 | `M53-16-EXTRA_COMBO_AP_ZERO` | `test_m5_boss_combo.gd` | PASS |
| 17 | `M53-17-EXPOSED_CONSUMED_BY_NEXT_SP` | `test_m5_boss_combo.gd` | PASS |
| 18 | `M53-18-COMBO_CONSUMED_ONCE` | `test_m5_boss_combo.gd` | PASS |
| 19 | `M53-19-COMBO_DAMAGE_THROUGH_M51` | `test_m5_boss_combo.gd` | PASS |
| 20 | `M53-20-BREAK_LOCK_NO_STOCKPILE` | `test_m5_boss_combo.gd` | PASS |
| 21 | `M53-21-DOUBLE_COMBO_DENIED` | `test_m5_boss_combo.gd` | PASS |
| 22 | `M53-22-BOSS_INTENT_COMMITTED` | `test_m5_boss_combo.gd` | PASS |
| 23 | `M53-23-BREAK_FALLBACK_PUBLIC` | `test_m5_boss_combo.gd` | PASS |
| 24 | `M53-24-BOSS_COMMITTED_TARGET` | `test_m5_boss_combo.gd` | PASS |
| 25 | `M53-25-DECLARED_INTENT_LOCKED` | `test_m5_boss_combo.gd` | PASS |
| 26 | `M53-26-FALLBACK_START_AND_SETTLE` | `test_m5_boss_combo.gd` | PASS |
| 27 | `M53-27-BREAK_GAUGE_RESTORED` | `test_m5_boss_combo.gd` | PASS |
| 28 | `M53-28-FALLBACK_LOWER_HITS` | `test_m5_boss_combo.gd` | PASS |
| 29 | `M53-29-PHASE_ADVANCED` | `test_m5_boss_combo.gd` | PASS |
| 30 | `M53-30-NEXT_INTENT_NO_FALLBACK` | `test_m5_boss_combo.gd` | PASS |
| 31 | `M53-31-SEED_TAPE_REPLAY` | `test_m5_boss_combo.gd` | PASS |
| 32 | `M53-32-EVENT_HASH_REPLAY` | `test_m5_boss_combo.gd` | PASS |
| 33 | `M53-33-STATE_HASH_REPLAY` | `test_m5_boss_combo.gd` | PASS |
| 34 | `M53-34-BREAK_DAMAGE_LOCK_IGNORES` | `test_m5_boss_combo.gd` | PASS |
| 35 | `M53-35-EXPOSED_NOT_REFRESHED` | `test_m5_boss_combo.gd` | PASS |
| 36 | `M53-36-FINISHER_MISS_PAYS` | `test_m5_boss_combo.gd` | PASS |
| 37 | `M53-37-MISS_PRESERVES_EXPOSED` | `test_m5_boss_combo.gd` | PASS |
| 38 | `M53-38-MISS_PRESERVES_COMBO` | `test_m5_boss_combo.gd` | PASS |
| 39 | `M53-39-SELF_CREATED_EXPOSED_NOT_CONSUMED` | `test_m5_boss_combo.gd` | PASS |
| 40 | `M53-40-NEW_PLAYER_PHASE_KEEP_EXPOSED` | `test_m5_boss_combo.gd` | PASS |
| 41 | `M53-41-EXPOSED_EXPIRES_AFTER_NEXT_PLAYER_PHASE` | `test_m5_boss_combo.gd` | PASS |
| 42 | `M53-42-INVALID_FALLBACK_FAIL_CLOSED` | `test_m5_boss_combo.gd` | PASS |
| 43 | `M53-43-REPLAY_BAD_TAPE_STOPS` | `test_m5_boss_combo.gd` | PASS |
| 44 | `M53-44-NO_CARD_DUPLICATION` | `test_m5_boss_combo.gd` | PASS |

Seed **20261014**, **9 accepted commands**, initial SHA256 **c96738c4f4bc66e08aa6c5825648f086baac22d7527acf2275e554c045bfdbde**, events SHA256 **ab66610a558b00751c56920924dddb915b2bc11915768479ceb5cf7d970ff9bc**, final state SHA256 **a4d00e293e09cbb9f39b7a05e3f8eeb776ae972745b37e2f4f97099800fcdf22**. See PH3_M5_3_ENGINEERING_NOTE.md. M5.4–M5.5 NOT VERIFIED; Analyze and Spell Counter content explicitly NOT VERIFIED.
