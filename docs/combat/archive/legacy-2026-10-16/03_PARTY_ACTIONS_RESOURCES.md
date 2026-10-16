# 03 — 三人行動經濟、AP/RP/MP 與基本指令

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + BALANCE_PROVISIONAL**：共享 AP／RP 與個別 MP 的規則以 P1、18/19 為準：CurrentAP 可合法超過 BaseAP6、正常 RP 上限6、MP 不自然回滿。舊表的數值候選／待決須按後續批准與實測區分。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot Domain M1～M5.5：1,238/1,238 通過；100 場固定 Seed 的完整戰鬥與 Replay 已驗證（[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。Scene／真人可玩／正式平衡仍未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。



## 1. 隊伍共享 AP（APPROVED）

玩家方隊伍回合原型配額 `6 AP`。所有 Active 且不受 Concentration 等限制的角色皆可以合法花費它；允許同一角反覆出牌、沒有全局「每人最多兩張」上限。**每張牌可有不同 AP Cost**。不能一人一份 6 AP。

**已核准（P1-D01）**：不限普通攻擊次數、同一角色可重複合法出牌；但每名角色每個玩家回合只有第一次普通攻擊可回 MP（回復量待測）。個別技能自己的冷卻或限制，若存在必須由技能明確指定；不能另加每人行動次數硬上限。

## 2. 基本指令

| 指令 | 抽牌？ | 費用 | 目標與效果 | 狀態 |
|---|---|---|---|---|
| Basic Attack | 否 | 候選1 AP | 物理傷害、首次每回合回 MP；允許合法重複普攻（P1-D01）；唯每角色每 Player Phase 僅首次回 MP | 不需卡：APPROVED；數值: PROVISIONAL |
| Player-phase Guard | 否 | AP費用 TBD | 玩家主動階段的防守指令，效果與成本另定，不與敵方Reaction Guard混為一談 | 存在方向：APPROVED；具體玩法 TBD |
| Item | 否 | 候選1 AP+物品 | HP/MP恢復或特殊效果、受庫存限制 | 不需卡：APPROVED；具體數值TBD |
| Skill Card | 是 | 卡定義 AP/MP | 戰技、魔法、干擾、支援與反擊 | APPROVED |
| Last Spell | 否 | 候選3AP+4MP | 專屬完整詠唱，成功後Exhausted | APPROVED核心/候選數值 |
| Basic Reaction: Guard / Protect | 否 | Guard 1 RP / Protect 2 RP | 合法敵方窗口分別自保減傷／轉移單體攻擊 | APPROVED：P1-D03/LEGACY-Q06/LEGACY-Q10–LEGACY-Q14 |
| Reaction SP | 是，必須持有該SP | 卡明定的 RP／可另付 MP | 僅符合觸發條件、角色合法的敵方窗口 | APPROVED：P1-D03/LEGACY-Q04，實際費率逐卡 TBD |

## 3. MP 經濟

每名角色自己的 MP，跨回合保持，不因玩家階段開始而自動補滿。基礎攻擊為最通用回魔來源，特定卡牌與道具亦可調整 MP。

**候選方案差異**：早期 `MP cap=6, basic attack restore=2`；v0.7.1程式 `MP cap=8, restore=1`；不可混合未經核准的設定。用資料配置參數 `max_mp`, `basic_attack_mp_gain`, `mp_return_on_interruption`；測試1/2/3回魔並追蹤魔法使用率。

保證：MP cost 扣費前校驗；滿 MP 時不能超額回復；零 MP 仍能普通攻擊；MP 如果受到削減後變動，不得少於0。被打斷的普通完整詠唱候選返還已付MP的一半（floor），不退 AP；仍未定案。

## 4. RP 與結束階段

**APPROVED（P1-D09；後續由 M-D08/M-D09 補充）**：玩家階段結束時剩餘 AP 按 1:1 嘗試轉為 RP，**預設 RP cap=6**，明文特殊 SP 可提高相應 Enemy Phase 的 cap；超出有效 cap 的 AP 不轉成可保留 RP。RP 只可用於緊接的 Enemy Phase，該階段結束時無條件歸零。v0.7.1 `carried RP` 是已知錯誤，不得再作規則。若未來道具或卡片另外生成 AP/RP，必須另開ADR處理總容量、上溢及轉換邊界。

## 5. 防止隊伍 AP 一人壟斷

首先藉角色職能、Combo、敵方抗性與特殊行動需求促使分工，不急著新增角色個別AP/出牌硬上限。測試記錄 `%AP by actor`、每回合參與角色數、每張技能邊際傷害/AP。

## 6. 例子（示意非永久平衡）

6AP：克蕾雅崩解斬2、尤拉完整詠唱2、諾瓦Focus Ward1、剩餘1轉RP；同一回合即使三人都行動，仍只使用6點隊伍AP。Magic另扣指定角色MP。確認所持卡與角色狀態後才允許操作。


---

## 7. Phase 1 資源精確合約

### 7.1 全隊 AP（P1-D01 APPROVED）

每個玩家回合開始基線值為 `team_ap=6`，由三位角色共用。**角色沒有自己的可花 AP 池**；UI角色切換不改 AP。多次普通攻擊、兩張以上合格卡牌、由同一角色交錯使用皆可，直到共享 AP/角色 MP/狀態等任一合法性條件不符。卡片本身的可用次數限制須個別寫明，不能在框架默默新增「每人最多兩次」。

### 7.2 首次普通攻擊回魔（P1-D01 APPROVED）

`basic_attack_mp_restore_used_by_actor[actor_id]` 每玩家回合重置false；該角色**第一個成功執行**的 Basic Attack 可觸發一次 MP 回復，再次普攻仍會依費用造成普通攻擊效果但不補 MP。合法性校驗失敗的普攻不可搶先消耗第一次機會。兩人先後出手分別計次；不同卡造成的追擊、反擊是否算 Basic Attack，需由命令種類明定而非技能名稱推斷。`basic_attack_mp_gain` 和 AP成本均為**PROVISIONAL**。同時使用 MP回復上限裁切 `min(max_mp, current_mp+gain)`。

### 7.3 AP→RP（P1-D09 APPROVED）

玩家主動階段結束，令 `remaining_ap=A`（常規 `0≤A≤6`），則 **`team_rp=min(A, effective_rp_cap)`、`team_ap=0`**，轉換比 1:1，預設 cap=6（M-D08），明文 SP 可提高 cap；不可再套舊 2/3/4 RP 裁切。這不是「可從當回合花過的 AP 再換一次 RP」。RP 在隨後敵方階段支出，每次 Reaction 需共享池餘額充足；當敵方階段結束無論有無消耗，`team_rp=0`，絕不帶入新玩家回合。此規則不保證所有6 RP都有合法消費場合：敵方招式、手牌及演算法限制依然存在。

### 7.4 費率（P1-D10 APPROVED）

- `ReactionGuard`: **1 RP**，無手牌成本，合法時減少本人的符合條件傷害；具體固定減傷百分比 TBD。
- `ReactionProtect`: **2 RP**，無手牌成本，合法時攔截一個可守護的隊友單體攻擊；無免費額外減傷。
- `ReactionCard`: `rp_cost` 及可能的 `mp_cost` 由該卡明定且尚無通用數值裁決；不得偷套基本Guard成本。
- `PlayerPhaseGuard`: 玩家主動指令，若既有遊戲UI保留該入口，不能拿 1 RP 反應Guard的定價直接套入其 AP 成本；此指令詳細效果待決。

### 7.5 範例（所有傷害與卡費用均 PROVISIONAL）

假設玩家階段只花3AP，餘3轉RP。Boss 指向正在詠唱的尤拉：克蕾雅 Protect 花2RP，諾瓦防護特殊 SP 如定義耗1RP則尚可再花1RP；兩者在同一 Reaction Window 排隊、確認後依序執行。若同次攻擊被前序反制取消，後序 Protect 自動跳過、不扣2RP；如果玩家沒抽到任何 Reaction SP，仍有RP可使用基本Guard/Protect。

### 7.6 未定量化項目

`max_mp`, `basic_attack_mp_gain`, `basic_attack_ap_cost`, `active_guard_ap_cost`, `reaction_sp_costs`, `extra_rp_production`, `negative_rp/overspend_rejection`, `special_action_ap_refunds`。對負資源的拒絕為工程不變量，對外部RP產生規則的選擇則必須另外通過ADR。不可因 D09「不另設 cap」假設未來卡可無限增加 RP。

## 8. 新核准 AP 經濟擴充（M-D01～M-D17；詳見 18）

**APPROVED**：常態每 Player Phase 基線 6 AP，但卡片可明文增加即時 AP、未來 AP、條件返 AP、數值減費、宣告可變 AP 投入，且只有具資格的 SP 可 Overload。故 `CurrentAP` 並非永遠限制於 6；其他資源仍需逐次合法校驗。M-D06 在階段開始時以 `Pool=max(0,BaseAP+APBonus)` 優先清償 `APDebt`，剩餘才進 CurrentAP；**M-D04 跨回合債務僅為 PROVISIONAL 試行**，`MaxAPDebt` 全隊上限的「8」僅為 PROVISIONAL 候選。當回合即時返還 AP 進 `CurrentAP`，**不直接償還現存 APDebt（M-D16）**；明文 `ReduceAPDebt` 效果降低債務但不增加當前 AP（M-D17）。一般 RP cap=6，只有明文 SP 能提高容量，且無論如何不能跨 Enemy Phase 留存。完整契約／例子／未決邊界統一以 `18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md` 為準。

**Player Phase 執行方式（P1-D01）**：單一角色選擇合法指令 → 即時執行及結算合法部分 → 玩家再自由選同一或其他角色；不先讓全隊預排所有動作。**Analyze 不屬於 SP（P2-S02）**，是零 AP/MP/RP 的獨立情報指令，全隊每場共用 2 次，不應列作抽牌卡或「分析型 SP」。

## Phase 2 最終 AP／MP 收斂（M-D18～M-D24、M-D31）

- **M-D18**：`CurrentAP` 無額外硬 cap；BaseAP=6 只是基線。階段末 AP→RP 時，常規 **RP cap=6**，明文 SP 可升 cap；下一 Enemy Phase 末剩 RP 必清零。
- **M-D19**：每角色獨立 MP 且跨回合保留，**無預設每回合自然恢復**。每角色每 Player Phase 僅第一次普通攻擊可回 MP（回復量 TBD）；SP、道具、特性、Buff 可以按明文條件／時點回 MP。
- **M-D20／M-D31**：MP 回復 clamp 到目前 `MaxMP`；基礎 MaxMP 允許依角色不同，並可透過養成、裝備、Buff 增長；具體值未核准。
- **M-D21～M-D24**：Chantless／Full Chant 預設同一張 SP 相同 MP 成本；提交時扣 AP／MP。因 Casting Interrupt 打斷 Full Chant，**中斷成立時立即退部分 MP（比例 TBD）**，**AP 不退，這次 Overload 債務不取消**。不能把 50% 範例當正式比例。

上述所有本輪新細項與例外見19；即時 MP 恢復不能讓非法 Reaction 變合法插隊。

## Phase 1–2 實作前資源預設（見20）

新授權 DELEGATED_DEFAULT：RP 所有額外來源均 clamp 到當時有效 RP cap，溢出丟棄、Enemy Phase 末清零；特殊 `SetCost/Override` 先定義 AP 基礎有效費，再套合法數值減費（不低於0），最後才由 Overload 補缺額；有限次 discount 按明文 priority/建立次序/instance id 消耗並記錄 trace。BasicAttack 回 MP 2、MaxMP 6/8/12、FullChant Interrupted退款50% floor、MaxAPDebt8 等**均是 BALANCE_PROVISIONAL，必須可配置**，不是此前使用者逐項批准的數字。

## Phase 2 終局裁決與 AP/MP 不退契約（USER_APPROVED）
Last Spell 已提交且未釋放時，施法者 HP0 觸發的 `LastSpellInvalidated(CASTER_INCAPACITATED)` 立即撤銷待釋放效果；**本次已合法支付的 AP/MP 不返還，Overload 債務不取消，once-per-battle 次數仍消耗**。此狀態改變不是 M-D22 因 Casting Disruption 而成立的退款事件。不得用 `EXHAUSTED` 表示 HP0；成功釋放後的 Exhausted 仍保留 HP/受療與 Protect 規則。