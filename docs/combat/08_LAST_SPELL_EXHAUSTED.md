# 08 — Last Spell：不可逆終極詠唱與 Exhausted

## 1. 已批准核心

每個戰鬥Variant有自己配置的Last Spell（可未解鎖）；它位於獨立能力槽，不在12張一般技能卡中，不需要抽取。每角色每場最多啟動一次。只能 Full Chant，**不能破棄瞬發**。啟動時支付 AP+MP 進入 Concentration，並不可由玩家主動取消。成功結算後該角色進入 `EXHAUSTED`，本場不得再普通攻擊、出牌、用道具、Reaction或發動新連攜；**不等於死亡**。

即使該角色耗竭，隊伍原型回合共享AP仍是6，不能自動從6改成4；損失的是角色手牌、技能、MP、專屬連攜及對戰局的支援機會。

## 2. 干擾與「不可取消」的特殊性

Last Spell 不是一般詠唱的「被打斷即取消」。目前採用的設計方向：首次達到干擾門檻→`DESTABILIZED`、延後1次結算；再次達門檻→不能無限延遲、改為削弱最終效果。**最後削弱百分比、各次干擾重置 Stability 等數值仍屬 TBD/PROVISIONAL**；但**施法者尚未釋放就 HP0 → Last Spell 必須強制取消**已由使用者正式核准（2026-10-14），不是待決。

建議建模 `LastSpellInstance {caster_id, spell_id, started_at, planned_resolve_at, delay_used, disrupted_count, resonance_stacks, outcome_modifier, committed_once}`，使多次干擾可重播。

## 3. 支援與共鳴

隊友可施放 Focus Ward / Barrier 及使用Reaction保護。合法共鳴牌可增加固定層數（候選上限2、每層加固定效果）；不得把Last Spell加速成瞬發，不得讓倍率無限制乘算。共鳴卡必須由非耗竭角色合法出牌，成本由其自身AP/MP支付；Concentrating的Last Spell施法者不必/不得額外主動行動。

## 4. 持續效果

角色施放Last Spell後既存的 DoT、Barrier、Buff等是否持續：原則上**已產生的效果依原期限保留**，而不是因Exhausted立刻移除；其來源可追蹤 `origin_actor_id`。Exhausted角色是否仍被Boss選為攻擊目標、能否承傷／被治療、HP0後的影響仍待核准（見11/14）。

## 5. 確認操作（UI）

按下Last Spell後顯示二次確認：AP/MP、詠唱預計時間、受干擾可延遲、成功後本戰不能再動的不可逆後果；玩家在「啟動前」可取消確認，但啟動後不能取消詠唱。勿把兩者混為一談。

## 6. 測試

- 未解鎖／不足AP/MP／已使用過不可開啟，失敗不扣資源。
- 啟動後標記 `committed_once=true`；不進卡牌抽／棄牌。
- 在一般玩家階段無法取消；干擾不可直接套用一般中斷取消。
- 一次失衡後恰延長一次，不可被重複延長無限回合；第二次執行弱化規則。
- 成功後所有發起新行動操作拒絕；現存持續效果可依期限繼續。
- 共鳴不能導致立即成功結算；不允許已耗竭角色發起新共鳴。
- 若本技能在**合法釋放完成後的同一行動結算**使最後敵人與我方同時 HP0，使用者已核准 **VICTORY**。若施法者在釋放前先 HP0，該 Last Spell 應立即失效、不得在到期時生效。


---

## 7. Phase 1 Last Spell、Concentration 與 Reaction 交界

- **APPROVED**：成功執行 Last Spell 後施法者 `EXHAUSTED`，不能參與新的 Guard、Protect 或特殊 Reaction，不受「基本 Guard 無需抽牌」豁免。已提交隊列中角色在其執行前變成不合格時要依引擎合法性政策處理，不能因排隊而自動獲得新行動權。
- **APPROVED**：仍在 Full Chant / Last Spell Concentration 的角色通常不能新執行一般 Reaction，僅允許另有明示 `CAST_COMPATIBLE` 的特殊合法 Reaction；隊友可以在自己的窗口提供 Protect 或 Focus Ward。基本 Guard/Protect 本身不因不需卡而獲得 `CAST_COMPATIBLE`。
- **APPROVED P1-D14**：隊友 Protect 成功攔住針對 Last Spell施法者的單體命中型攻擊，其命中附帶 Casting Stability 干擾轉向守護者；直接以 Last Spell 的 Casting Instance 為目標的魔法干擾仍可作用，Last Spell的第一次/第二次失衡規則照08主節處理。
- **SUPERSEDED 部分**：Exhausted 可受 Boss 攻擊／Protect，Last Spell 施法者釋放前 HP0 必取消（2026-10-14 USER_APPROVED）；**仍 TBD**：失衡減傷數值與細部技能/卡牌效果。

## Phase 1–2 Exhausted 及最後法術事件（PRE3-R14/15；DELEGATED_DEFAULT + CORE_CONFIRM）

Exhausted 不能發新普通動作、使用 SP、Guard、Protect、Reaction、Combo，但本身仍是**合法受擊／治療／Buff／隊友 Protect 目標**；治療不解除 Exhausted。若 HP0 則同時有 Incapacitated 的生命狀態，需明文 Revive 才能解除HP失能，但不還原行動能力。**USER_APPROVED 替代 PRE3-R15 舊假設：** Last Spell 不可由玩家主動取消；但施法者在釋放前 HP0 進入 `INCAPACITATED`，立即 `LastSpellInvalidated(CASTER_INCAPACITATED)`，取消尚未產生的效果及排程，**不會在死後到期釋放**。這是 forced invalidation，不是一般 Casting Interrupt，也不觸發部分 MP refund；既付 AP/MP 與一次使用紀錄不退。普通敵方干擾仍採該法術延遲/削弱規則，不因本修訂變成第一下就取消。雙方在合法完成的行動中同時全滅，正式判定 **VICTORY**。詳見20/21。

## 8. Last Spell 狀態機驗收契約（USER_APPROVED）
- `UNUSED → CASTING`：合法提交立即扣 AP/MP、標 `used_once=true`，鎖住本場再次啟動；在 UI 提交前可關閉確認，提交後不能主動取消。
- `CASTING → DESTABILIZED`：合法魔法干擾依 Last Spell 特有延遲／削弱流程，不冒充一般成功打斷；詳細削弱數值仍為 provisional。
- `CASTING/DESTABILIZED → INVALIDATED`：施法者**釋放前** HP<=0，立即記 `LastSpellInvalidated(reason=CASTER_INCAPACITATED)`，取消到期事件與未釋放效果。之後被 Revive 不會恢復本次施法、不返成本、不恢復本戰已使用額度；此失效不是可選的玩家 Cancel。
- `CASTING/DESTABILIZED → RESOLVED → EXHAUSTED`：只有合法到期且施法者仍可施法才發效果並進 Exhausted。
- **事件先後**：HP0 即時引發失效；勝敗仍於已提交當次合法行動及隨行必要效果結算邊界判定。若最後敵人也於同一結算邊界全滅，我方即使全倒也算 VICTORY。
- **2 回合示例**：甲在第1玩家回合提交 Last Spell，預計第3玩家回合生效；甲第2敵方階段 HP0 → 強制失效；第3玩家回合不能出現甲的 Last Spell 傷害。