# 17 — 戰鬥設計接續指南與 OPEN 問題（2026-10-14 最新）

> **2026-10-15 現行交接（A 方案）**：此檔原「下一題 M-D18」及部分 OPEN 表格是歷史截面，M-D18～31、P2-D10～16 方向已有核准，不應再次詢問；見目標 `19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md` 及 20/21 的 CORE-01～04 最終裁決。Lv40 新增內容25–31及 Python工具位於本 repo。目標 Godot 原型的 8 張卡／每階段最多兩張出牌，與新版已核准的每人12 SP／共享 AP 結構**仍為待實作差距，不是規則再開放決策**。合併詳情：`UPSTREAM_RECONCILIATION_A_2026-10-15.md`。

> **2026-10-14 LIBRARY Phase 2 最新補充（現行 SoT）**：請優先閱讀 [`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md) 與 [`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)。M-D18～M-D31 已核准；P2-D10～D16 的**設計方向**已整體核准，數值／部分結算邊界仍 TBD。較早段落的「P2-D08 未決」「換牌僅提案」「手牌上限 TBD」「完整詠唱較貴 MP」等屬歷史文字，與 19 衝突時以 19 為準。**僅 Library 更新，未同步 GitHub；尚無 Godot 執行／CI PASS 證據。**


> **最新已確認：P2-D01～D09、P2-S02～S13、P2-S15～S31，M-D01～M-D17 已做選擇；M-D04 跨多輪負債為 PROVISIONAL 試行。** 不得繼續問舊版記載的「P2-D08 尚未決定」；請讀 `18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`、`16_PHASE2_APPROVED_DECISIONS_WIP.md`、`00`、`01`、`02`、`03`。

## 最新核准規則速查

- Player Phase **逐次選一個行動、立即執行／依效果時序結算、再自由選同一或其他角色**；不是三人先排好再一起動。Full Chant 在提交時開始 Concentration 並按既定時序到期；Reaction Window 是先排多人反應再一次確認、序列結算（P1-D15／D16）。
- 6 AP 是**每 Player Phase 基線**，不是 SP 增益後 CurrentAP 的已核准絕對 cap；所有角色共用一個 AP 池，同一角色可連續行動。
- Overload SP 專屬、逐卡與全隊借用上限、**不足時才借差額**；MaxAPDebt 具可配置上限，**8 AP 只是候選**；開始回合時 APBonus 可先幫忙還債；當回合返還 AP 不抵當回合債務；特定 SP 可以有成本地減債。
- 數值減費可疊加至零，可變投入 AP 的技能以**宣告投入量**決定效果，破棄／完整詠唱獨立處理；不設全域 SP 每回合張數上限，但必須以卡牌資源/條件防止無限免費循環。
- RP **1:1 由剩餘 AP 轉換，預設 cap 6**，明文 SP 才能提高；緊接 Enemy Phase 結束 **全部歸零，絕不跨輪**。
- **Analyze 不是 SP**；0 AP/MP/RP 的共通情報指令，全隊每戰 2 次，另有情報型被動觀察，不能把「分析型 SP」寫回去。
- P2-D08：暴擊率／暴擊傷害獨立可養成，細數值／每段結算未核准。P2-D09：敵人個別定義元素抗性/弱點；正式元素清單仍 OPEN。

## 下一題（尚未核准）

**M-D18：當回合透過 SP 增益／返還獲得超過 6 AP 時，`CurrentAP` 是否有獨立持有上限？** 必須先研究其他遊戲的實際做法，再提出明確 A/B/C 方案與推薦；**使用者尚未選擇，不能擅自標 APPROVED。** 注意 AP 和 RP 不同：後者已有預設 cap 6；前者尚未核准 cap。

## 其他仍 OPEN 的設計（僅列代表，非新核准項目）

| ID／類別 | 尚未核准 |
|---|---|
| M-D04 / M-D05 | 多回合 APDebt 是否保持暫定、全隊 MaxAPDebt 的正式值（8 為 provisional） |
| AP 減費 | 設為 0 等特殊覆寫優先級、折扣生效與消耗次序、即時 AP 容量與溢出政策 |
| Casting | Full Chant 到期／同時事件優先級、中斷後 MP/AP 返還、特殊 Reaction Window 邊界 |
| P2-D10 | 命中、暴擊、屬性、傷害浮動、Guard、Barrier 的完整結算順序 |
| P2-D11 | 取整、最小傷害、直接傷害 |
| P2-D12 | Barrier／Focus Ward 詳細效果、到期及多盾優先序 |
| P2-D13 | Buff／Debuff／DoT 的堆疊、持續／驅散時點 |
| P2-D14 | HP 0、Silence／Stun／Exhausted 與復活 |
| P2-D15 | 同時擊敗 Boss／隊伍、勝敗與未結算行動 |
| P2-D16 | Seeded replay、Godot headless engine、平衡驗收與測試證據 |

## 保留的非決議／歷史註記

- 舊 `16`／舊 `17` 的「P2-D08 OPEN」只反映當時快照，已由 `18` 覆寫。
- Phase 1 的 Guard=1RP、Protect=2RP、同人每窗口一次 Reaction、不同角色可排隊、失效無費跳過、每角12張卡與補手牌至4張依舊有效。
- `Function` 是**世界觀**用詞，不是戰鬥系統中的計算／卡牌詞彙。
- 任何傷害倍率、敵人專屬抗性數字、SP 具體卡面、MaxAPDebt 8、暴擊基礎倍率與神祕「20 學科」對應戰鬥元素全集，沒有核准不能直接實作為固定玩法。
- 戰鬥規格快照已寫不等於 Godot 實作、CI 通過、完整戰鬥播放或 balance PASS。以上測試必須有實際執行紀錄才可報告。

## 使用者指定的逐題討論協議

1. **先研究實際遊戲**，區分確定事實與 Astraea 的候選設計，使用適當來源，不能誤植他作機制。
2. **一次只詢問一題**，提供 2～3 真正有別的選項、推薦與具體回合例。
3. 使用者選擇後才記 APPROVED；模糊『試試看』須保留 provisional。
4. 要求 checkpoint 時同步 **ChatGPT Library + GitHub**，再讀回核驗；未實測不能宣稱相同。

## Phase 2 接續更新（2026-10-14，Library）

**最新已核准**：P1 全系列、P2-D01～D09、P2-S 系列既有核准、M-D01～M-D31；**P2-D10～D16 設計方向**使用者已整體確認。**本檔上面「下一題 M-D18」為過時歷史截點**。若要繼續工作：先讀19確定新規則，再讀13驗收；Phase 2 **設計方向可視為已收斂**，**Godot 實作／測試仍未開始驗證**。使用者授權一般細節由 AI 提出合理可配置預設，不必反覆提問，只有重大核心玩法改動才回詢。此次只更新 Library，不能聲稱已同步 GitHub。

## 2026-10-14 實作前 handoff 更新（20 為最新未決事項分類）

本檔舊標題「M-D18 下一題」與舊逐項提問流程均屬 HISTORICAL，因已由使用者後續全部核准 M-D18～31/P2-D10～16 方向，且本輪再授權一般細節由 AI 決定。**最新 `20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md`** 列明 PRE3-R01～R18 的 DELEGATED_DEFAULT、首輪 BALANCE_PROVISIONAL 和 CORE_CONFIRM；不得重新問已決定的換牌、RP cap、MP退款方向或百分比命中。Phase 2 規格驗收可直接撰寫 test cases，Phase 3 headless engine 可開始骨架，但 `CORE_CONFIRM` 不得當成永久敘事/勝敗最終判準，**未實測前一律 SPECIFIED_NOT_TESTED**。

## Phase 2 規格驗收交接（2026-10-14）
User 已正式確認先前 CORE-01～04：雙方同次結算歸零仍判玩家勝；Last Spell 施法者在生效前 HP0 即取消待施放法術（不退 AP/MP/Overload、不可復活後恢復本次）；Phase 3 不加入自由走位但可選 2.5D 呈現；有合法 Reaction 時不設秒數倒數且須明示 Confirm/Pass。舊 `20` 中的 DRAW/死後 Last Spell 續唱預設已取代。請讀 `21_PHASE2_SPEC_ACCEPTANCE_REPORT.md` 的文件檢查、優先測試與殘餘平衡參數。**文件驗收 ≠ Godot/headless 測試已執行。**