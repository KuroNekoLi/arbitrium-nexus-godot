# 07 — Reaction Window、RP 與保護層

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + HISTORICAL_TBD**：CORE-04 禁止合法 Reaction 的倒數／自動 Pass；Protect → Guard → Barrier/HP 分層已核准且具局部 Domain 驗收。§8.8 舊 OPEN 表屬當時快照，需對照 20/21 和 M5。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot Domain M1～M5.5：1,238/1,238 通過；100 場固定 Seed 的完整戰鬥與 Replay 已驗證（[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。Scene／真人可玩／正式平衡仍未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。


## 1. 目的

Reaction 是敵方階段使用預留 RP 的付費防禦／反制：基本 Guard 與 Protect **不需要手牌**，特殊 Reaction SP 才要求已持有符合觸發條件的卡。玩家階段的主動 Guard 與敵方階段的基本 Guard Reaction 是兩種不同命令，不可混淆。

## 2. 資源與窗口

**APPROVED P1-D03/LEGACY-Q04/LEGACY-Q09**：玩家階段餘 AP 全數1:1轉 RP，不另設 2 RP 上限，RP 敵方階段末歸零；同一敵方行動的單一 Reaction Window 中每名符合資格角色至多**實際執行一次** Reaction，不同角色可在同窗口一起響應。基本 Guard/Protect 不需手牌；Reaction SP 必須在手牌且符合觸發、資源與行動資格。實際敵方行動是否可能開多窗口、連鎖窗口屬 TBD。

**歷史衝突已裁決**：v0.7.1 的 `carried RP` 與 `max_rp=2` 均屬過期實驗行為；正式規則是敵方階段末清零、正常最多6 RP，見03與 P1-D09。

## 3. 推薦精準事件鏈（候選）

`EnemyActionDeclared → ReactionWindowOpened → ValidateReaction → PayRP/MP → ApplyPreDamageEffects(Interrupt/Redirect/FocusWard) → ResolveEnemyActionIfStillValid → ApplyHPDamage/Statuses → ReactionWindowClosed`。每個窗口識別 `window_id` 防雙重觸發。若敵方施法被中斷，取消其預定傷害事件；不應既打斷又受到同次原法術全額傷害。

## 4. Barrier 與 Focus Ward

| | Barrier | Focus Ward |
|---|---|---|
| 作用 | 吸收 HP 傷害 | 吸收詠唱干擾 |
| 生命週期 | TBD | 候選於該次施法結束消失 |
| 相互替代 | 不可 | 不可 |
| 例外 | 某技能可明示提供雙層效果 | 必須兩個獨立效果事件 |

不要以「Ward 每層減HP8且擋一次干擾」當正式規則；這是 v0.7.1 模擬器的混合護盾假設，與 v0.6 分離方向衝突。

## 5. Concentration 與 Last Spell

Concentrating caster 通常不能執行一般Reaction；僅具 `CAST_COMPATIBLE` 且符合技能費用的反應可用。隊友 Active 可提供 Focus Ward 或干擾敵方。Last Spell 必須保留原本的不可主動取消／可受干擾延遲或削弱的特殊結算（見08）。

## 6. UI

Smart 為預設：僅重大合法 Reaction 時阻塞暫停；Always Ask 對每次有合法反應的敵方攻擊詢問；Quick 以更簡潔交互呈現。開窗後顯示意圖、RP、可用基本Guard/Protect與合格SP、預覽、排隊／調序／確認或略過，最後一次結算。所有模式必須遵守相同的領域規則，且不能未經玩家核准自動扣資源。若沒有合法反應，跳過彈窗，顯示記錄，不應顯示空彈窗阻塞流程。RP是否保留／清空需寫入提示文字；UI字串透過i18n key。

## 7. 測試

無RP時不能反應；沒持卡不能反應；同張卡同一窗口不能兩次使用；過期窗口操作拒絕且無扣費；詠唱被打斷原技能不得傷害；Focus Ward不被普通HP傷害錯誤削減；Barrier不直接減Casting干擾；多敵方行動窗口隔離。


---

## 8. Phase 1 完整 Reaction 規格（P1-D03～D16 中已通過事項）

### 8.1 行動資格與費用（APPROVED）

| 反應類別 | 抽牌條件 | 價格 | 合法目標/主要目的 | 不能做什麼 |
|---|---|---|---|---|
| 基本 Guard | 不需要持卡 | **1 RP** | 自己受到符合條件的攻擊時，降低自己的HP承傷 | 不免費反擊/阻止全部狀態/自動減Casting干擾 |
| 基本 Protect | 不需要持卡 | **2 RP** | 攔截隊友受到的可守護單體物理／魔法攻擊 | 不攔AOE/多目標；不免費減傷；不攔直接詠唱干擾 |
| 特殊 Reaction SP | 該角色手牌中有合法 `CardInstance` | 逐卡定義 RP、可能另需MP | 依卡提供Barrier、Focus Ward、反制、反擊等技能 | 不因已持卡就自動執行；無合法觸發不能用 |

若角色已 Exhausted、Incapacitated 或 Concentrating，合法性依08/05及後續待決規則；**Concentration 的有限例外仍須 `CAST_COMPATIBLE` 明示**，不得因基本Guard免費可用就忽略狀態。每位合格角色同窗口最多**實際執行一次**，包含基本與SP反應；基本Guard與Protect不可讓同一角色同窗口先後各用一次。不同角色可同時參與，無全局單張上限。

### 8.2 Protect 轉移流程（P1-D12/D13/D14 APPROVED）

1. 敵方已提交特定攻擊；顯示單體目標、物理／魔法與可守護標示。若是全體、指定多名角色、直接 詠唱 干擾或明示 `UNPROTECTABLE`，基本 Protect 不合法，不能讓玩家花RP才發現。
2. 玩家在 Reaction Window 中選擇守護者以及將被保護的隊友；必須是兩名不同合格角色，是否允許保護特定失能/Exhausted角色仍待TargetPolicy決策。
3. 已確認隊列輪到此 Protect 執行時，再驗證隊友與攻擊事件仍合法、剩餘RP≥2、守護者仍具 Reaction 資格及未在該窗口實際反應。
4. 支付2 RP，**把該次單體攻擊的承受目標指向守護者**，按守護者現時自身防禦與抗性重新計算HP傷害，**Protect 沒有免費乘數減傷**。被保護者不是「先承傷再轉帳」；不可使用被保護者已算好的最終傷害。
5. 命中觸發的 Casting Stability 干擾跟著此次命中承受者轉移；如果原施法者被保護，**此命中型干擾不應再影響其 Casting Instance**。直接針對 `casting_id` 的干擾是另一獨立效果，不被轉移。
6. 防禦系統仍按自身順序處理抗性、Barrier及生命值。對毒、標記、擊退、命中計算中的轉向、AOE一部分能否轉移等尚未批准；請參閱01 §8 與14的待決項。

### 8.3 Guard 減傷流程（P1-D11 APPROVED）

先計算角色的防禦與抗性得到 `D_after_defense`，再套Guard固定比例 `g`：`D_after_guard = D_after_defense × (1-g)`。**計算順序是 APPROVED；g 的具體值和最終取整是 TBD / PROVISIONAL**，示範可用 `g=0.40` 測試但不得稱正式。Guard不能無條件消去所有HP傷害，也不直接形成 Focus Ward 或打斷敵方法術。Barrier與Guard的相對計算先後、穿透/真傷例外、傷害取整依11等待後續確認。

### 8.4 同窗口 Reaction 佇列與確認（P1-D04/D15 APPROVED）

反應 UI **先排所有選擇，最後一次提交**：玩家在界面選擇某角色 Basic Guard/Protect 或其手牌中的Reaction SP，選擇合法目標，拖曳變更隊列順序，必要時刪掉方案或跳過。提交前可以反覆預覽與調整，**不能提前扣費或移走卡牌**。系統須顯示預算與預期合法性；同角色兩項意圖不得一起提交（編輯時可替換）。確認後依玩家自選順序依次結算，與角色SPD無關；不需要對每一張反應 SP 再彈一次確認。

**二次校驗**：編輯時測試與預覽為**不改狀態**的驗證，確認時驗證所有已可知條件，真正執行**每一筆前再次驗證**。原因是前序反應可能取消敵方攻擊、改變目標、生成屏障、改變MP等。對於非資源不足而是因前序效果致使觸發/目標消失，採 P1-D16 的 `SKIPPED_INVALIDATED`。若是其他原因（例如本來就費用不足、提交無效隊列），應在確認前阻止並引導修改，而非當作免費跳過逃避費用驗證。異常狀態在執行中突然變更如何拒絕需要事件層明確診斷；此為工程待細化，不改D16原則。

### 8.5 無效後續反應（P1-D16 APPROVED）

舉例：玩家排 `①諾瓦：反制魔法 SP → ②克蕾雅：Protect`；前者成功取消了此次 Boss 攻擊。此時 `②` 失去攻擊事件及合法觸發：引擎記錄 `ReactionSkipped(reason=TRIGGER_GONE)`，**不扣2 RP、不扣任何MP、不把卡丟進discard、不把角色標記為已反應**；不要求再開一個窗口，也不強迫浪費技能。如果②本是獨立合法的持續護盾 SP，且仍能作用於合法目標，則正常支付並執行。前面①既然實際執行，後續攻擊取消不應倒退返還①已付成本。

**這不是後悔藥**：已執行的Protect即使後來 Boss 攻擊未造成實際HP傷害，該次Protect仍然算執行並消耗資源。只有尚未到執行點、失去合法事件的後續反應享有跳過免耗。記錄事件需明確區分 `DECLARED`、`QUEUED`、`EXECUTED`、`SKIPPED_INVALIDATED`。

### 8.6 Smart / Always Ask / Quick（P1-D05 APPROVED）

- **Smart（預設）**：對可能致命、威脅正在詠唱的魔法、Boss高危險狀態／範圍技等**重大且有合法應對**之事件，提供明確的阻塞式一次 Reaction 窗口；較低優先級可用非阻塞提示。具體重大判定閾值與時間規格 TBD。
- **Always Ask**：對每次具合法 Reaction 的敵方攻擊都提供明確詢問；當無任何合法反應不可顯示空彈窗。
- **Quick**：簡化顯示及點擊路徑，但不得修改合法反應集合或成本，不能把未回覆視作授權自動支出 RP。無障礙、鍵盤/手把/觸控支援需UI階段定案。
- **共用領域邏輯**：UI mode 只能影響 `should_block_prompt`、提示頻率與動畫；`ReactionEligibility`, `ResolveReaction` 不得從顯示設定讀取不同傷害/成本/限制。錯過非阻塞提示不等於默認執行SP；公平性政策仍 TBD。

### 8.7 重大不變量（工程驗收）

1. 當前窗口同角色 `ReactionExecuted` 計數 ≤1；`ReactionQueued` 和 `ReactionSkipped` 不增加計數。
2. RP不得小於0、不同角色共享同一RP池；已支付反應的成本不得重複扣除。
3. 基本Guard/Protect永遠不查CardInstance；SP 不能跨角色拿牌。
4. 同次攻擊已被取消時，不得殘存原攻擊傷害或其命中型 Casting 干擾。
5. Protect不適用全體/多目標及直接 詠唱 干擾；不可守護提示在購買行動前可見。
6. 角色的防禦/抗性會影響自身 Guard/Protect 後的最終 HP；不應先以被保護者屬性求值。
7. 同一 queue 執行結果不可依 UI 動畫速率、使用者切換頁籤或裝置 FPS 而變。

### 8.8 待決（不得自行補成 Canon）

(1) Guard 最終減傷率/取整/最小傷害；(2) 暴擊/命中與轉向時點；(3) Barrier與Guard次序；(4) 多段/多目標事件粒度；(5) 多人 Protect/轉向鏈；(6) HP0/Exhausted 被保護資格；(7) 命中附帶毒/位移等轉移白名單；(8) SP每張費用、SP與敵方詠唱回合生命週期；(9) Smart威脅門檻與非阻塞UI公平超時；(10) 將來額外RP的來源／上溢處理；(11) 前序效果令後序費用不足的細部規劃UX。見14待決清單。

## Phase 1–2 基本防禦精確結算（PRE3-R01～R05、R17；DELEGATED_DEFAULT）

**Protect 先重導向，再依守護者命中/防禦/抗性結算**；同一 EnemyAction 只有第一個成功 Protect 可改主要目標，不接受無限 Protect 接力。單目標多 hit 作一個 Window；合法 Guard 一次持續覆蓋該 Action 對本人的合格 HP hit，基本 Protect 可攔此 Action 同一目標的多 hit，但不可攔 AoE／多目標或直接針對 CastingInstance 的干擾。附帶狀態/擊退/干擾要逐效果標 `follows_damage_recipient`，不能全部自動轉移。先 Guard 再扣 Barrier；Focus Ward 只保護詠唱。已確認 Queue 每筆執行前重驗，資源不足、倒地、原事件失效均跳過免耗；RP 超出動態 cap 則溢出捨棄。Guard 40% 僅測試候選。舊 §8.8 中已由本段及20解決的內容是歷史 TBD，其他仍見20。

## Reaction 無真實時間倒數（2026-10-14 USER_APPROVED）
`Smart / Always Ask / Quick` 在 Domain 上共用同一 `REACTION_PENDING` 狀態：只要存在合法選項，**一律等玩家明示 Confirm 或 Pass** 才能結算敵方行動；Quick 只縮短點擊流程、提示密度和動畫，沒有倒數、沒有 timeout、自動 Pass 或時間決定的 RP 變化。Smart 允許較不顯眼的提示，但在有合法選項時不能邊播敵方攻擊邊無聲錯過反應。無合法反應的空窗口可直接略過。Controller、觸控、FPS 差異不改決策輸出。