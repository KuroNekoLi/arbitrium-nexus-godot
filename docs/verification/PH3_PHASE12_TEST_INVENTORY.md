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
