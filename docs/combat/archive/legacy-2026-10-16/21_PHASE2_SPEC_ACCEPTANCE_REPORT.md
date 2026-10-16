# 21 — Astraea Combat Rules｜Phase 2 文件規格驗收報告（2026-10-14）

> **Documentation status · 2026-10-15 — HISTORICAL_SPEC_REVIEW + USER_APPROVED_CORE**：本文件的 `SPEC ACCEPTANCE CONDITIONAL PASS` 是當時文件規格審核；第1節 USER_APPROVED CORE-01～04 持續有效。當下 Godot 測試需另看 verification 與官方 Actions。 先讀 [Combat Spec Index](COMBAT_SPEC_INDEX.md)；目前未驗證項目見 [Open Issues](COMBAT_OPEN_ISSUES.md)。**M1～M5.5：1,238/1,238 Domain assertions；100 場固定 Seed 完整戰鬥與 Replay 已通過 [Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)。Godot Scene／真人可玩／正式平衡仍未驗證。** 舊正文的「當時狀態」僅供歷史追溯，不得升格為新核准或新 CI。


> **範圍：** 以 ChatGPT Library `/docs/combat/00`～`20` 共 21 份 Markdown 戰鬥規格為規格來源，參考 GitHub `master` 既有的 `19_PHASE2_FINAL_APPROVED_M_D18_D31_P2_D10_D16.md` 與同名模組差異。**本文件是 SPEC REVIEW，不是 Godot 執行或程式測試報告。** 核驗內容為規則的決議來源、文件相容性、事件順序、可撰寫的 oracle／負例與仍需具名設定的事項。所有 Godot/CI/BALANCE 測試狀態均為 `NOT EXECUTED`，不得宣稱 PASS。

## 0. 驗收結論

**Phase 2 設計契約：`SPEC ACCEPTANCE — CONDITIONAL PASS`。** 最重要的用戶未決選項 CORE-01～CORE-04 已全部由使用者親自裁決，且可轉成確定性的 Domain 規則；Phase 3 可以著手純規則／headless 引擎骨架及對應測試。**這不是「完整卡牌與 Boss 數值都已凍結」、也不是「Godot 實作通過」。** 部分數值、逐卡效果、個別狀態、ContentDeckRules 與高難度例外仍需要測試資料或後續規格；完整可玩關卡驗收不能跳過。

- 原 Library 文件：`00`～`20`，**21 份**；舊紀錄中 `M-D18 OPEN`、`DRAW`、`Last Spell 死後續唱` 等應視為 `HISTORICAL / SUPERSEDED`，不可給工程 Agent 作為當前行為。
- 本輪新增可執行規格案例：**16 個**（`P2-OUT-01～03`、`P2-LAST-01～06`、`P2-VIS-01～02`、`P2-RXN-01～04`、`P2-REPLAY-01`）；全部 `SPECIFIED / NOT EXECUTED`。
- 本次核准條款來源為使用者 2026-10-14 四項明示選擇，並非由 Agent 推論；後續修改必須提出新 ADR。

## 1. 最新使用者核准的四個核心決策（APPROVED / CLOSED）

| ID | 核准規則 | 法律邊界／解釋 |
|---|---|---|
| **CORE-01** | 若同一個已完成合法 action／必要事件使最後敵人與所有隊員同時 HP0，**玩家 `VICTORY`，視為劇情通關**。 | Outcome check 按 P2-D15 在合法結算完成後執行；敵人全滅優先於我方全滅；敵人仍存活且我方全失能才 `DEFEAT`；`DRAW` 舊提案作廢。 |
| **CORE-02** | Last Spell 已啟動、預定延後生效，但施法者在**釋放前 HP0**：立即使該 LastSpellInstance **強制失效**並取消排程；不可死後續唱。 | 玩家不能主動 Cancel。一般敵方干擾仍依 Last Spell 專用 **延遲／削弱** 規則，不變成普通 Casting Interrupt；HP0 是 `CASTER_INCAPACITATED` forced invalidation，不套 M-D22 部分 MP 退款。先前合法支付 AP/MP/Overload 與一次啟動次數不返；Revive 不恢復被取消的法術。 |
| **CORE-03** | **Phase 3 不提供自由走位指令**；戰場視覺可以採 2.5D。 | 2.5D 僅 Presentation，仍是回合制戰鬥；既有 range_tag 或 Encounter 靜態位置標籤不等於新增移動 AP 或即時戰鬥。 |
| **CORE-04** | 所有合法 Reaction Window **沒有真實時間強制倒數**；必須由玩家明示 Confirm/Pass。 | Smart/Always Ask/Quick 共用 Domain，Quick 僅縮短動畫／操作。無合法反應時可直接略過空視窗；不能 timeout、auto-pass 或依 FPS 影響結果。 |

**時序範例：** 甲在 Player Phase 1 支付成本，啟動預定在 Player Phase 3 釋放的 Last Spell。甲在第 2 回合 HP0：當時立刻 `ActorIncapacitated → LastSpellInvalidated(CASTER_INCAPACITATED) → ScheduledEffectCancelled`，第 3 回合**沒有 Last Spell 的傷害**。若同一張合法已釋放的多段攻擊使敵我最後存活者同時 HP0，這是**另一種情境**，action 結束後 `VICTORY`；兩者不可混淆。

## 2. 跨模組驗收矩陣（文件審核；不是跑測試）

| 檢查 ID | 規則群組 | 已確認的文件契約及優先順序 | 文件狀態 | 未完成的實作／內容 |
|---|---|---|---|---|
| `S-A01` | 戰鬥架構 | 00、02：三人隊伍，Player Phase 每次選一動作即合法提交／結算；Reaction Window 多人佇列後確認 | `SPEC_REVIEWED` | Domain command validation 未實作 |
| `S-A02` | AP 資源 | 03、18、19、20：共享 AP Base6；CurrentAP 無 cap；Overload 只借差額；折扣、AP Debt 依規則 | `SPEC_REVIEWED` | 折扣／覆寫個別卡牌效果、APDebt 8 候選 |
| `S-A03` | RP／Reaction | 03、07、20：Guard=1 RP、Protect=2 RP、預設 RPcap=6；同人每窗口至多實際反應一次、非法後序不扣費 | `SPEC_REVIEWED` | UI 實機驗證、特殊反應卡 |
| `S-A04` | MP／雙詠唱 | 03、05、18、19：每角色 MP，條件回復、MaxMP cap、雙模式同 MP、合法 FullChant Interrupt 部分退款 | `SPEC_REVIEWED` | MP 數值、返還比例與 rounding 候選 |
| `S-A05` | 牌庫／換牌 | 04、19、20：每角恰12 SP、hand cap8、Phase 開始補至4，免費換牌先棄後抽、原實例隔離且有合法替代檢查 | `SPEC_REVIEWED` | 個別牌組、同名重複規則 |
| `S-A06` | Protect 轉向 | 07、20：單體攻擊先重導再按新承受者判命中／防禦、無多次連鎖 Protect | `SPEC_REVIEWED` | 特殊 tag 的個別效果 |
| `S-A07` | Guard／盾層 | 07、11、20：Guard 在 Barrier 之前減 HP；Focus Ward 僅防詠唱干擾，兩層不可混算 | `SPEC_REVIEWED` | 比例、盾容量與期限 provisional |
| `S-A08` | Boss Intent／Break | 06、16：Intent 需忠實預告；Break 在整張 SP 結算後處理，弱化下一合法未開始 Boss 行動 | `SPEC_REVIEWED` | 個別 Boss/弱化卡面 |
| `S-A09` | Exposed／Combo | 09、16：不同施法者連攜、可限時 Exposed／不得憑空產生免成本攻擊 | `SPEC_REVIEWED` | 個別 Combo 配方 |
| `S-A10` | Analyze | 00、16、18：獨立共通命令、0 AP/MP/RP、每戰全隊2次，不占12 SP | `SPEC_REVIEWED` | 對應情報資料/UX |
| `S-A11` | Last Spell 啟動 | 08、20：一次／戰，獨立槽、只 Full Chant、已啟動不可玩家主動取消 | `SPEC_REVIEWED` | 延時/削弱平衡參數 |
| `S-A12` | Last Spell HP0 | 08、20、21：**未釋放前 caster HP0 → INVALIDATED**，取消排程；不退資源、不復活後復用 | `SPEC_REVIEWED` | Godot 狀態機／邊界測試 |
| `S-A13` | Last Spell 成功後 | 08、20：成功後 Exhausted、不能新行動；Exhausted 仍可被治療／擊中/Protect | `SPEC_REVIEWED` | Buff/DoT 特殊例外 |
| `S-A14` | 命中與傷害 | 11、16、19、20：百分比線性命中，適用 5–95% clamp；可追蹤 damage pipeline、最終 floor0 為工程基準 | `SPEC_REVIEWED` | K、元素倍率、暴擊率等均待平衡 |
| `S-A15` | 狀態與倒地 | 02、11、20：HP0 即 Incapacitated、一般治療不自動 Revive、一般未釋放 FullChant 失效 | `SPEC_REVIEWED` | 逐狀態與復活卡面 |
| `S-A16` | 例外同歸於盡 | 02、11、20：整次合法 action 完成，敵方全滅判 **VICTORY 優先**；舊 DRAW 作廢 | `SPEC_REVIEWED` | 劇情獎勵 UI 實作 |
| `S-A17` | Reaction 無倒數 | 07、20：有合法選項則停在等待 Confirm/Pass；Quick 只改表現 | `SPEC_REVIEWED` | Controller/觸控可用性與 UX |
| `S-A18` | 2.5D／零自由移動 | 20：保留 target_scope/range_tag，無玩家移動指令；2.5D 不能改 Domain | `SPEC_REVIEWED` | 實際美術方案 |
| `S-A19` | 可重播事件 | 12、13、20：seed + ruleset_version + initial_state + tape 決定事件/hash，UI 動畫不能改變權威結果 | `SPEC_REVIEWED` | 實際 event trace/log/code |
| `S-A20` | 測試契約 | 13、21：P1/P2/M/PRE3 四系列矩陣含正常／拒絕／事件跨期示例；四項決策新增16例 | `SPEC_REVIEWED` | **全數尚未跑 Godot** |

以上 `SPEC_REVIEWED` **僅表示人工文件交叉核對後具有明確預期與對應來源，不是所有實際 test cases PASS**。因 `01`、`16`、`17` 等保留歷史快照，全文內仍可能看見早期 OPEN/TBD；實作應按最新核准優先順序：**本輪使用者 CORE-01～04 > 已核准 P1/P2/M > 20 的 DELEGATED_DEFAULT > 候選值及早期歷史敘述**。所有明文修正均不能推翻先前未被衝突的新規則。

## 3. 尚未關閉的數值／內容／技術風險（不再詢問已確認的四題）

| ID | 風險／待完成 | 是否阻塞 headless 骨架 | 推薦動作 |
|---|---|---|---|
| `BAL-01` | `MaxAPDebt=8`、跨回合 APDebt M-D04「試試看」 | 否 | 以 provisional 配置做多 seed 對照，回報 0 AP 連續回合概率 |
| `BAL-02` | Guard 40%、首攻回 MP2、FullChant 干擾退50%、MaxMP6/8/12 | 否 | 集中於 versioned balance config，對照至少100 seeds |
| `BAL-03` | 傷害式常數 K、命中係數、元素倍率、基礎 Crit、特殊直傷、最低傷例外 | 否（可用 provisional fixture） | 不寫死在各 SP，記完整 trace |
| `CNT-01` | 逐 SP 卡面 AP/MP/效果、12 張實際牌組、個別 Boss AI／Break fallback | **阻塞完整可玩戰鬥內容**，不阻塞 engine skeleton | 選一組垂直切片資料包再驗收 |
| `CNT-02` | Buff/DoT/Barrier/Focus Ward 各獨立層數、期限、tick、逐卡免疫 | **阻塞對應完整效果驗收** | 資料表逐個建立合法 fixture |
| `ENG-01` | Last Spell 先 HP0 後觸發取消、已釋放／未釋放判定、對應 event ordering | **必測；阻塞 Last Spell 實作驗收** | `P2-LAST-01～06` 正反例與 Action Boundary 測試 |
| `ENG-02` | Outcome enemy-clear-first、同次 Action 範圍／多段觸發及 delayed effects | **必測；阻塞勝敗模組驗收** | `P2-OUT-01～03`，另測敵方與我方不同 tick 的界線 |
| `ENG-03` | Smart 非高危低優先事件有合法 Reaction 時的 UI 等待方式 | 否（Domain 先強制明示 Pass） | UI 實機驗證選項永遠可達，不因 Quick 偷跑 |
| `ENG-04` | Phase3 2.5D 視覺渲染與靜態 range_tag 定義 | 否 | UI/內容資料分離，可先 headless 驗證 |

## 4. Phase 3 開始前的規格 Gate 與後續關卡

**Spec Gate（本次）：`CONDITIONAL PASS`**
1. 四項 CORE 全部 `USER_APPROVED / CLOSED`，且已建立狀態機、事件邊界和對應 oracle。
2. P1/Phase2 合約與受託 PRE3 的先後相容；沒有必要因普通平衡係數暫缺就停掉 engine skeleton。
3. 舊文件若與最新正式決策矛盾，必須標 `SUPERSEDED` 並引導至最新文檔，不得直接採用。
4. 當前沒有任何 Godot 測試日誌、CI 成績或實際 replay hash。本文件不提供虛假的 PASS。

**Implementation Gate（後續，尚未通過）：** Domain command validation、資源守恆、事件處理、完整測試矩陣，須以真實 Godot/headless log + commit + seed + ruleset_version + command tape + state hash 驗證；後續最少先實作測試 `P2-LAST-01/02/03/05/06`、`P2-OUT-01/02`、`P2-RXN-01/03`、`P2-VIS-01/02`，並以 13 的既有 P1/P2 維持回歸。

**Playable Gate（後續，尚未通過）：** 至少1組真實12 SP×角色、Boss Encounter、可解釋的技能卡與狀態資料、2D/可選2.5D 呈現與 i18n/可操作 Reaction UI，在固定 seed 實際跑通首場戰鬥；不得用只有文件 PASS 宣稱可玩。

## 5. 同步與驗證原則

本文記載設計已核准與規格級檢核結果；**Library 是否儲存成功、GitHub 是否提交成功，須由工具的寫入結果與實際讀回確認**。GitHub 若有相異較新內容，語意合併，禁止盲目強制覆蓋；本報告不是檔案同步成功或 CI 通過的證據。