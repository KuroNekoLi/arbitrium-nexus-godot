# 25 — Astraea Starter Party & Card Content Design v0.2

> **Documentation status · 2026-10-15 — APPROVED_VARIANT_DIRECTION + CONTENT_PROVISIONAL_V0_2**：主角初期固定劍士、未來 Variant 解鎖是 USER_APPROVED；角色名、技能、係數與基本卡組均為內容候選。**26 v0.3 取代 25 的 UNIVERSAL 基礎魔法與三副 Starter Deck 候選**，不可再拿 25 的 U01～U04 當完整最新通用卡池。 導覽：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；未決：[Open Issues](COMBAT_OPEN_ISSUES.md)。M5.5／完整可玩驗證尚未完成。以下保留來源快照，不能解讀為此刻最新驗收。


> 日期：2026-10-15｜狀態：**MIXED — USER_APPROVED 主角 Variant 方向 + CONTENT_PROVISIONAL 角色／卡牌／數值**  
> 用途：Godot 4.x deterministic combat engine 的初始內容資料與後續平衡測試候選；不宣稱已執行、測試 PASS 或正式平衡核定。  
> **唯一規格來源：Library `/docs/combat/00`～`24` 的最新有效 Combat Rules／使用者決議**。不得引用 `Life_RPG_Astraea_GDD_v1.1.md`、舊 `COMBAT_SYSTEM.md` 的過時機制，亦不得使用 `Counter-Function` 作為新版遊戲機制。  
> 若衝突：最新版 USER_APPROVED > P1/P2/M 已核准 > `20` DELEGATED_DEFAULT > 本文件 `BALANCE_PROVISIONAL`。本文件只新增內容定義，不修改現有戰鬥引擎契約。

## 1. USER_APPROVED 新決策：主角初期固定劍士，後期 Variant 擴職能

- 主角朝霧蓮（Asagiri Ren）初始戰鬥形態固定為 `ren_swordsman_v1`，其起始 `role_tags=[SWORDSMAN,VANGUARD]`。
- **後期**可藉解鎖新 `Variant` 獲得不同職能／role tags／基礎能力值／被動／專屬卡使用權及 Last Spell；不是開場即可自由切換所有職能，也不是戰鬥進行中即時切職。
- 轉換 Variant 時執行 `ValidateLoadout`：12 SP／資格／卡牌收藏實例／當前 Variant Last Spell 全部重驗。純 `Skin` 不改戰鬥效能。
- 尚未指定下一個 Variant 的職業、解鎖章節或養成成本；未來設計，不屬 Starter MVP。
- 以下角色名稱、職能、數值及卡牌除上列 C 選擇外，皆標 `CONTENT_PROVISIONAL`，可由平衡測試修改，不得提升為 USER_APPROVED。

## 2. 經查核的外部卡牌 RPG 設計參考（借鏡，不照搬）

| 來源 | 可查核特點 | Astraea 借鏡／取捨 |
|---|---|---|
| Gordian Quest 官方 https://gordianquest.com/ | 三人英雄隊伍、各英雄獨立職業、技能與培養 | 三位角色的牌組能力／出牌手感明確分化；保留未來 Variant 的跨職能空間 |
| Gordian Quest 開發者說明 https://steamcommunity.com/app/981430/discussions/0/2793873197761790021/ | 英雄技能牌組由專長構成，成長可替換、強化與學習技能 | 先做易懂的 starter 套牌，進階 Build 才擴充卡池 |
| Across the Obelisk 開發介紹 https://news.xbox.com/en-us/2024/11/06/discover-across-the-obelisk-the-deckbuilder-that-lets-you-cooperate-with-everyone/ | 四名角色各自管理牌組，需要協同使用 | 保留每人獨立 12 SP；確保一個 setup ＋另一角色 finisher 是真實兩張出牌 |
| Across the Obelisk 官方 https://store.steampowered.com/app/1385380/Across_the_Obelisk/ | 英雄職能、隊伍協作、牌組升級 | 治療／護盾／爆發相互合作，不把治療職能做成只有補血 |

這些作品的能量／抽牌／位移／卡牌升級規則不移植。Astraea 的共享 AP6、RP、個別 MP、雙詠唱、Exposed/Break、Combo 和 Last Spell 依現行 Combat Rules。

## 3. 三人角色原型（CONTENT_PROVISIONAL）

| Character ID | 人物 | 初始 Variant ID | Role tags | 定位 |
|---|---|---|---|---|
| `ren` | 朝霧 蓮／Asagiri Ren | `ren_swordsman_v1` | `SWORDSMAN`, `VANGUARD` | 均衡近戰／Break／連攜 setup／保護 |
| `akane` | 九條 朱音／Kujou Akane | `akane_burst_mage_v1` | `BURST_MAGE`, `ARCANE` | 魔法瞬發與完整詠唱的風險收益／敵方施法干擾 |
| `tsumugi` | 白石 紬／Shiraishi Tsumugi | `tsumugi_healer_v1` | `HEALER`, `SUPPORT` | 回復、Barrier、Focus Ward、MP 支援；不可取代普通復活機制 |

### 3.1 戰鬥屬性候選（同等級、無裝備／Buff）

| stat | 蓮 | 朱音 | 紬 | 補充 |
|---|---:|---:|---:|---|
| `max_hp` | 1500 | 950 | 1200 | 非正式數值；戰鬥壓力要看 Boss fixture |
| `max_mp` | 8 | 14 | 12 | 個別 MP，不自然每回合補滿 |
| `p_atk` | 135 | 60 | 55 | 使用既有 PAtk/PDef 傷害流水線 |
| `m_atk` | 70 | 175 | 105 | MaxMP 不直接代表魔法傷害 |
| `p_def` | 110 | 65 | 80 | Protect 用實際承受者防禦重新計算 |
| `m_def` | 90 | 85 | 110 | Barrier 處理 HP，Focus Ward 處理 Stability |
| `accuracy_points` | 105 | 95 | 95 | %命中公式中的 BaseHit/k 留設定檔；此值不是命中率 |
| `evasion_points` | 95 | 90 | 95 | 一般隨機命中 clamp 5%~95%，特殊效果另明文 |
| `crit_rate` | 0.10 | 0.08 | 0.05 | 需命中後才判；逐 SP 設是否可暴擊 |
| `crit_damage_bonus` | 0.50 | 0.50 | 0.50 | 由可成長屬性決定，套合格 HP 傷害 |
| `casting_resilience_multiplier` | 1.00 | 0.90 | 1.20 | 只有 CastingInstance 的穩定度受影響 |
| `disruption_power_multiplier` | 1.00 | 1.15 | 0.95 | 不等於 Break 倍率 |

**候選被動**（Starter 先一人一種，避免疊加過度）：

- `REN_P01 蓄勢劍路`：每 Player Phase 第一次由蓮造成合法 Break damage 的實際命中 SP，額外造成 `+2 Break`；每階段最多1次，不觸發額外 SP 行動／AP。
- `AKANE_P01 強詠決心`：朱音的 Full Chant SP 成功釋放時，僅該張 SP 的合格 HP 魔法傷害乘 `1.10`；不影響 Break/Disruption、不影響 Last Spell（另定）。
- `TSUMUGI_P01 溫柔祈願`：每 Player Phase 第一張成功施放的 `HEAL` SP 對有效生命目標多回復 `60 HP`，受 MaxHP 上限截斷；不能復活 Incapacitated、不能免費產生 Barrier。

數值和是否保留被動需 A/B 測試；不沿用任何舊世界觀固有角色。

## 4. 卡牌資料契約

- 卡牌為 `CardDefinition`（穩定 ID、i18n 顯示名稱、cost、type、mode、target_policy、tags、eligibility、effect list、state/trigger rules、rarity），戰鬥中有獨立 `CardInstanceID`。3 人各自 12 instances，不能混牌庫或錯誤複製。
- 一般 `SP` 消耗 `AP` 和（若有）自己的 `MP`；Reaction SP 在合法 window 花全隊 `RP` 和自身 `MP`，必須已在本人的 hand；多角色同窗口可以按規則先 queue 再 commit。
- 對有雙詠唱的同一 SP，預設相同 MP；`Chantless` 立即結算，`Full` 到下一合格 Player Phase 起始點（這是一般 SP 時序），不可先產生延遲傷害。Last Spell 另見 §8。
- 下列傷害只給 `skill_multiplier` 與 `flat` 候選。實際 HP 傷害：沿用已批准 `(Attack×skill_multiplier+flat)×K/(K+Defense)` 加後續命中、暴擊、元素、Barrier、Guard 等規則。K、取整、隨機小幅浮動與元素倍率以核心可配置版本為準；不把係數當最後 HP 減量。
- `Break`、`Casting Disruption` 與 HP damage 是**三種分離效果**，不可把 20 HP damage 當 20 Break/20 Disruption。
- `CONCENTRATING` 不能一般主動行動；Reaction 例外只有明示 `CAST_COMPATIBLE` 者。普通 Guard/Protect 不需手牌，仍遵守自己窗口的合法性。
- Exposed 不等於 Analyze；由敵方專屬條件、指定 SP 或事件才合法建立，現有 Exposed 不刷新、不疊層；由後續另一張合格 SP 成功利用；Combo 要兩名不同角色且兩張 SP 皆合法付費。

## 5. 通用卡 4 種：UNIVERSAL（CONTENT_PROVISIONAL）

| ID | 名稱／類型 | Cost | 目標及明確效果 | Mode／限制 |
|---|---|---|---|---|
| `U01` | 奧術彈 `MAGIC_ATTACK` | 1 AP + 2 MP | 敵單；Chantless `m_atk×0.85`，Full `m_atk×1.45` 的技能倍率；魔法屬性標記 `ARCANE`（候選，非已核准元素全集） | DUAL；需命中模式 `AUTO`（僅候選卡自訂），不擅自擴散到所有魔法 |
| `U02` | 魔力屏障 `BARRIER` | 1 AP + 2 MP | 有效友單；給 `140 HP Barrier`，有效至下一個 Enemy Phase 結束；HP 傷害吸收，絕不保 Casting Stability | INSTANT；Barrier 疊加政策使用本內容版本的 `REPLACE_IF_HIGHER` 候選，不改核心通用政策 |
| `U03` | 專注護符 `FOCUS_WARD` | 1 AP + 1 MP | 我方有效 `CastingInstance`；提供 `+8 Focus Ward`，只吸收指向施法穩定度的干擾；至實例結束 | INSTANT；沒有合法 CastingInstance 不得付費或出牌 |
| `U04` | 魔力調律 `MP_SUPPORT` | 1 AP + 0 MP | 有效友單（含自己）恢復 `3 MP`，截斷於該角色 MaxMP；不額外產 AP／RP | INSTANT；該場單張 CardInstance 可正常循環，不額外免費抽牌；若完全無可恢復 MP 則不可用 |

## 6. 蓮：8 種職能／角色技能卡（CONTENT_PROVISIONAL）

| ID／Eligibility | 名稱 | 成本 | 核心效果與限制 |
|---|---|---|---|
| `R01 ROLE_TAG:SWORDSMAN` | 破勢斬 | 1 AP / 0 MP | `PHYSICAL,HIT_CHECK` 敵單 `p_atk×1.00`，成功命中時 `6 Break`；符合 Encounter 專屬弱點條件可造成 Exposed，不能對所有 Boss 無條件標記 |
| `R02 ROLE_TAG:SWORDSMAN` | 連環擊 | 2 AP / 0 MP | 目標敵單物理兩擊，每 hit `p_atk×0.72`；各 hit 依自己的命中，**整張 SP** 只可利用一次 Exposed，Break 在全卡後正式觸發 |
| `R03 ROLE_TAG:SWORDSMAN` | 刺隙一閃 | 1 AP / 1 MP | 敵單 `p_atk×1.15`；若成功利用目標既有 Exposed，**本張合格 HP 傷害×1.25**；失敗不消耗 Exposed |
| `R04 ROLE_TAG:VANGUARD` | 調整架勢 | 1 AP / 0 MP | 自己獲得 `100 HP Barrier` 至下一 Enemy Phase 結束；不視為基本 Guard、不提供免費 Reaction |
| `R05 ROLE_TAG:VANGUARD` | 援護反擊 | 2 RP / 1 MP | Reaction SP；當敵人宣告可 Protect 的單體攻擊指向其他隊友，成功將承受者換成蓮，重算命中／防禦，再先給蓮 `+80 Barrier`；若此次敵方攻擊完成後敵方仍合法在場，追加 `p_atk×0.55` 合格反擊，不額外產生 Reaction window |
| `R06 CHARACTER:ren` | 蒼月斬 | 2 AP / 2 MP | 敵單 `p_atk×1.75`，成功命中另 `+5 Break`，可作已建立不同角色 Combo 的合法 Finisher（逐 recipe） |
| `R07 CHARACTER:ren` | 戰隙誘引 | 1 AP / 1 MP | 敵單 `p_atk×0.75`；僅在敵人 `exposed_trigger_profiles` 明文允許且指定行為條件成立、此 SP 成功命中時建立 Exposed；不保證所有怪物可觸發，不同於 Analyze |
| `R08 CHARACTER:ren` | 守護誓約 | 1 AP / 2 MP | 蓮＋另一有效友軍各得 `90 HP Barrier` 至下一 Enemy Phase 結束；若有另一角色依法再出符合條件的防護 SP，可建立 `DEFENSE` ComboOpportunity；基本 Protect 不自動獲 Combo |

> `R05` 候選反擊結算需額外針對 EnemyAction 被取消／技能目標消失／行動未命中設計 oracle；不允許隊列被 skip 的 Reaction 仍扣 RP/MP/卡。

## 7. 朱音：8 種職能／角色技能卡（CONTENT_PROVISIONAL）

| ID／Eligibility | 名稱 | 成本 | 核心效果與限制 |
|---|---|---|---|
| `A01 ROLE_TAG:BURST_MAGE` | 燐火彈 | 1 AP / 2 MP | DUAL，敵單；Chantless `m_atk×1.00`、Full `m_atk×1.65`；MP 兩模式相同 |
| `A02 ROLE_TAG:BURST_MAGE` | 熾焰潮 | 2 AP / 4 MP | DUAL，敵全；Chantless 對每個合法敵人 `m_atk×0.68`、Full `m_atk×1.15`；AOE 不能用基本 Protect 攔所有人 |
| `A03 ROLE_TAG:BURST_MAGE` | 凝火 | 1 AP / 1 MP | 自己獲得 `SPELL_POWER_NEXT=+20%`，僅下一張成功施放且合格的 HP 魔法傷害 SP 生效，至下一個 Player Phase 結束，最多1層；不加強 Break 或 Disruption |
| `A04 ROLE_TAG:BURST_MAGE` | 灼熱束 | 2 AP / 5 MP | DUAL 敵單；Chantless `m_atk×1.45`、Full `m_atk×2.15`；不額外給 AP 或 Overload；同一 SP 成功才可按卡條件利用 Exposed |
| `A05 ROLE_TAG:ARCANE` | 熾脈干擾 | 1 AP / 2 MP | 對敵方有效施法實例造成 `8 base Casting Disruption`，先抵 Focus Ward 再減 Stability，個人 DisruptionPower 可修正；未施法時目標不合法；不是 Spell Counter |
| `A06 CHARACTER:akane` | 星墜槍 | 2 AP / 5 MP | DUAL 敵單；Chantless `m_atk×1.55`、Full `m_atk×2.35`；破棄模式可作蓮 Setup 的 `OFFENSE` Combo Finisher（依 §10） |
| `A07 CHARACTER:akane` | 紅蓮餘燼 | 1 AP / 3 MP | 敵單合格魔法傷害 `m_atk×0.65`，成功命中後施加 `SCORCH_TEST`：兩次 Enemy Phase 結束各造成 `45` 候選 DoT HP，最多1層、重施刷新剩餘次數、可被標籤 `CLEANSE_FIRE` 驅散；不自動暴擊／觸發額外 Break |
| `A08 CHARACTER:akane` | 超越限界 | 2 AP / 2 MP | 自身下一張合格魔法 SP HP 傷害 +30%，**每場最多成功使用2次**、同名 buff 不疊層且後施放只刷新期限；至下一個 Player Phase 結束，避免無成本無限疊加 |

> `A05` 屬 Casting Disruption，與 **Spell Counter**（魔法已完成／結算前合法 Reaction SP）不同；本 starter 先不需要同時教授兩者。`SCORCH_TEST` 是逐狀態 content 定義，不代表全遊戲 DoT 一律如此。

## 8. 紬：8 種職能／角色技能卡（CONTENT_PROVISIONAL）

| ID／Eligibility | 名稱 | 成本 | 核心效果與限制 |
|---|---|---|---|
| `T01 ROLE_TAG:HEALER` | 治癒術 | 1 AP / 2 MP | 指定**未 Incapacitated** 的有效友軍恢復 `200 HP`（上限截斷），不能 Revive |
| `T02 ROLE_TAG:HEALER` | 淨化祈禱 | 1 AP / 2 MP | 指定有效友軍移除**一個**具有 `DISPELLABLE` 標記的 Debuff；沒有可驅散 Debuff 則不可施放，不驅散 Exhausted/Incapacitated |
| `T03 ROLE_TAG:HEALER` | 祝福領域 | 2 AP / 4 MP | 全體有效非倒地隊友各恢復 `140 HP`，按 each target MaxHP 截斷；不 Revive、不複製一張卡多次觸發全隊被動 |
| `T04 ROLE_TAG:SUPPORT` | 守護之光 | 1 AP / 2 MP | 一名有效隊友獲得 `190 HP Barrier`，至下一個 Enemy Phase 結束；不能攔截 CastingInstance 直接干擾 |
| `T05 ROLE_TAG:SUPPORT` | 祈光應答 | 1 RP / 2 MP | Reaction SP：EnemyAction 即將對單一有效我方目標造成 HP 傷害，對該承受者先給 `130 HP Barrier`，**不改變攻擊承受者**；對直接 CastingInstance Disruption 不起作用；同人每個 Window 至多執行一次 Reaction |
| `T06 CHARACTER:tsumugi` | 生命織補 | 2 AP / 4 MP | 有效友單恢復 `380 HP` 並給 `100 HP Barrier`；治療與屏障各自有合法目標與上限，非復活 |
| `T07 CHARACTER:tsumugi` | 安定織界 | 1 AP / 2 MP | 我方合法 CastingInstance 獲得 `+10 Focus Ward`；若施法者是不同角色且該 CastingInstance 允許 `CASTING` Combo，可附帶成功釋放時 `+12%` 合格 HP 效果（一次、不能提早結算，效果上限） |
| `T08 CHARACTER:tsumugi` | 魔脈共鳴 | 1 AP / 1 MP | **其他**非失能隊友恢復 `4 MP`，MaxMP clamp；每 Player Phase 最多成功施放一次；0 AP/MP 的自由回復鏈不允許；不可瞄準自己以形成自我無限循環 |

> 採前置防護、治療、MP 支援三軸。治療不是每輪無腦最佳選擇：還要考慮共享 AP、Enemy Intent、是否留 AP→RP。一般治療不得恢復 Incapacitated；`Revive` 另屬未來正式定義內容。

## 9. 精確三套 12 張 Starter Deck（36 CardInstances）

> **2026-10-15 v0.3 後續覆寫**：本節 v0.2 卡牌實例配置僅作歷史候選；請以 [26 §5](26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md) 的三副 Starter Deck v0.3 配置作為後續測試候選。兩者均非最終已核准數值。


本版選擇每人 4 UNIVERSAL + 5 ROLE_TAG + 3 CHARACTER，**只是測試副牌**，不是遊戲全域比例或同名卡上限。每種卡在該副牌目前只放1實例，故不需要預先替未核准的重複卡攜帶上限做決策。

```text
REN_STARTER_V0_2    = [U01,U02,U03,U04,R01,R02,R03,R04,R05,R06,R07,R08]
AKANE_STARTER_V0_2  = [U01,U02,U03,U04,A01,A02,A03,A04,A05,A06,A07,A08]
TSUMUGI_STARTER_V0_2= [U01,U02,U03,U04,T01,T02,T03,T04,T05,T06,T07,T08]
```

- `U01` 出現在3個牌組，是3個不同 `CardInstanceID`，且只有1個共用 `CardDefinitionID=U01`。
- 起始手牌每角色各4張、每 Player Phase 不足4才補到4、hand cap8。棄1抽1免費指令每角色每階段一次，不能抽回這次丟棄的同一實例。
- `Guard/Protect/Analyze/BasicAttack/Item/LastSpell` 不在此36實例之中。
- Reaction SP 需要抽到才可用；沒有抽到時基本 `Guard(1RP)`／`Protect(2RP)`（合法條件下）仍可使用。
- 不可對目前 Concentrating 的施法者額外塞一般主動出牌；`U03`／`T07` 是其他合法隊友支援。

## 10. Combo Recipes 候選（有真實 SP、有不同角色、額外 AP=0）

| Combo ID | Setup | 第二次真實 SP/條件 | 成功回報 |
|---|---|---|---|
| `COMBO_REN_AKANE_01` 劍焰追擊 | 蓮 `R01`／`R07` **合法產生 Exposed** 並建立不同角色 finisher 機會 | 朱音 `A06` Chantless 真正付 2AP+5MP，對同一目標成功命中／利用 Exposed | A06 在本次合格 HP 傷害基礎上追加 `+20%` HP 傷害；不另扣 Combo AP、不可由 R01 本張自產自耗 |
| `COMBO_REN_TSUMUGI_01` 雙重護衛 | 蓮 `R08` 合法施放，記一次 `DEFENSE_SETUP` | 紬另以 `T04` 合法出牌付1AP+2MP，且 Setup 未失效 | 紬 T04 的額外 `+75 Barrier`，視為該張卡的專屬 bonus；不能把 Basic Protect 當成第二張 SP |
| `COMBO_AKANE_TSUMUGI_01` 安定詠唱 | 朱音先付費啟動合格 Full Chant，已建立 `CastingInstance` | 紬以 `T07` 合法付費支援 | 詠唱獲 Focus Ward + 在最終成功釋放時按本候選卡效果提高 HP 輸出；**不是立即釋放** |

另須滿足各 setup 的期限（starter fixture 預設最晚下個 Player Phase 結束；Exposed 本身以較新版 `P2-S17` 時限為準）。同時不能假裝3位都要出牌才能成立初版 Combo。

## 11. 三個 Last Spell：三種戰術目的（CONTENT_PROVISIONAL）

全數遵守 core：Variant 獨立槽、不屬12張、每角色每場一次、只能 Full Chant、啟動時付 AP/MP、不可玩家主動 Cancel、Concentration、失衡延遲/削弱、釋放前 HP0 強制失效且不退費、成功後 `EXHAUSTED`（仍可被擊中與治療但不能新主動行動）。

| ID / Variant | 名稱 | Cost | 成功釋放效果（候選） | 戰術與約束 |
|---|---|---|---|---|
| `LS_REN_SWORD_V1` / `ren_swordsman_v1` | 終式・蒼天一閃 | 3 AP + 5 MP | 敵單物理 `p_atk×3.60`，合法命中則額外 `24 Break`（與 HP 傷害分開）；保證暴擊／必中**不默認** | 單體斬殺／Break，有機會在 Boss 下次合法行動前完成 BreakFallback setup，但不取消已開始的施法 |
| `LS_AKANE_MAGE_V1` / `akane_burst_mage_v1` | 終式・紅蓮星墜 | 3 AP + 9 MP | 敵方全體各自魔法 `m_atk×3.20`；各敵人防禦與元素設定各自計算，不假設全體必然弱火 | 全隊最大輸出；長詠唱的風險與最終 Exhausted 為核心代價 |
| `LS_TSUMUGI_HEAL_V1` / `tsumugi_healer_v1` | 終式・白銀之誓 | 3 AP + 7 MP | 對所有**非 Incapacitated** 有效隊友恢復 `35% MaxHP`（上限 clamp），各自得到 `260 Barrier`，至下一 Enemy Phase 結束 | 全隊瀕危拯救；**不是全隊復活**，成功後失去唯一主要治療師的主動治療能力 |

`planned_resolve_point` 的此內容版候選：若在 Player Phase N 成功提交，正常在 **N+2 Player Phase 開始**釋放（例：N=1 → Player Phase 3）；合法失衡首次延後一次，不得無限延長；第二次依配置削弱。失衡削弱候選 `outcome_modifier=0.80` 僅供模擬，不寫成核心規則，需單獨測。已釋放後效果持續依自身 timer，不因施法者 Exhausted 立刻清除。

### 11.1 最低限度 Last Spell UI

二次確認顯示：目前 AP/MP、預計釋放點、會受干擾、**成功後本場失去此角色行動能力**、釋放前 HP0 即失效、不返 AP/MP 與每戰一次額度。按確認前可返回，提交後不可主動取消。

## 12. 素材與 Godot 實作契約

- `CharacterDefinition/VariantDefinition/CardDefinition/LastSpellDefinition/ComboRecipe/StatusDefinition` 應資料驅動，可用 JSON/Resource 後再由嚴格 parser 驗證，使用穩定 ID。顯示用 zh-TW/en i18n keys，不把文字名稱當判斷鍵。
- `CombatDomain` 決定全部屬性／成本／合法性／事件，2D/2.5D Presenter 只根據 EventTrace 播動畫，不能改戰鬥權威狀態。
- 不依圖片畫面上的 6 格 AP、HP值或文字抄寫實際卡牌；圖片只參考 HUD 資訊位置和卡牌交互模式。
- 本 Starter 不開放玩家在戰鬥中任意換 Variant、不發放未解鎖職能卡、也不為初始劍士帶職能以外的 `ROLE_TAG` 牌。
- 初期可提供 3 組 preset deck，正式獨立牌組編輯依 `ValidateLoadout` 實作；新 Variant 引起資格變動要重新配置。
- 本檔為 Content Draft，不暗中設定全域元素全集、通用同名卡上限、稀有度硬上限或免費復活規則。

### 12.1 最小資料契約示例（候選 schema）

```json
{
  "content_version": "starter-party-v0.2-provisional",
  "character_id": "ren",
  "variant_id": "ren_swordsman_v1",
  "role_tags": ["SWORDSMAN", "VANGUARD"],
  "deck_card_definition_ids": ["U01", "U02", "U03", "U04", "R01", "R02", "R03", "R04", "R05", "R06", "R07", "R08"],
  "last_spell_id": "LS_REN_SWORD_V1"
}
```

此 schema 為內容規劃，尚非 Godot 最終序列化欄位。實際戰鬥需建立唯一 `CardInstanceID`，以 instance ID 而非 definition ID 進行移區與 Replay。

## 13. 平衡與測試（未執行）

### 13.1 初版 Encounter Fixture（全部 PROVISIONAL）

- Encounter ID: `TEST_BOSS_ARCANE_SENTRY`；Boss HP=3000、PDef=90、MDef=85、BreakGaugeMax=30。
- 依現有 Boss Intent 合約提供確定性預告：物理單體可守護、魔法單體附 on-hit disruption、direct casting-instance disruption、蓄力魔法、可受 BreakFallback 的行動（各段真正傷害均需另列 config）。
- Encounter-specific Exposed：若 Boss 正在顯示 `ARCANE_CORE_OPEN` 姿態，蓮 `R01` 或 `R07` 合法命中，且該 enemy 的 `exposed_trigger_profiles` 明文允許，才可建立一個符合期限的 Exposed。未符合條件不能每次 R01 無條件創造破綻。
- 規範 `SCORCH_TEST` tick 與 `BARRIER_TEST` 剩餘期限，測回放事件一致。

### 13.2 自動化測試與策略測量

每種策略最少100個固定 seeds（不是僅跑100場隨機抽牌就宣布平衡）：

1. Balanced：Boss Intent 情報→治療/防護/攻擊動態分配。
2. Aggressive：優先朱音短施法與蓮的 Combo Finisher。
3. Casting：試著讓朱音 Full Chant/Last Spell 受到合理援護。
4. Defensive：優先紬的 Barrier／治療／RP 保留。
5. Ablation：逐一禁用特定角色或卡牌，不當作正式3人隊平衡比較，而是辨識功能缺口。

輸出：實際勝率、回合數、各角色 `%AP by actor`、MP 花費／恢復／溢補、每張卡使用率、換牌成功率、手牌卡住比例、治療有效率／過量、Barrier 實際吸傷、詠唱完成與中斷率、BreakFallback 次數、Exposed 合法利用率、Combo 達成率、Last Spell 啟動成功／HP0失效／Exhausted 後隊伍存活率、每場 seed/command tape/event log/state hash。

必測負例：
- 反應卡沒在 hand／其他角色手上→禁止；Reaction queue skipped 不能扣費；無 RP 不能打 Reaction。
- Barrier 吸 HP 不吸 Stability；Focus Ward 吸 Stability 不吸 HP；基本 Protect 不攔 direct casting_id disruption。
- Exposed 單張自產自用不允許；同目標有 Exposed 不刷新；不同角色 Combo 第二張正常付費。
- 朱音完整詠唱中不能一般出牌；同張 Full/Chantless 同 MP；普通 CastingInterrupt 部分 MP 返還 AP 不退。
- Last Spell 釋放前施術者 HP0 即 invalidated，不返成本、Revive 不恢復；成功後 Exhausted 無新行動；雙方合法同 action 全滅 VICTORY。
- 紬治療 Incapacitated 不等於 Revive；Healing/Barrier 上限與時序追蹤。
- 36 CardInstances 守恆；hand cap8，補至4；免費換牌不可原卡當次立即抽回；同 seed/state/commands hash 相同。

**測試狀態：SPECIFIED / NOT EXECUTED。** 沒有真實 Godot CLI logs 前，不得報 PASS，不得把任何技能係數升級為 FINAL_BALANCED。

## 14. 未來真正需要使用者另行核准的重大題目

- 初始主角身分／名字是否固定還是玩家可輸入名字（目前本檔用「朝霧蓮」做內容 ID／顯示範例；遊戲產品決策另定）。
- 未來 Variant 是純職能換牌，還是同一角色的故事／戰鬥形態大幅變化（影響美術及角色養成）。
- 治療／復活是否納入新手最初3人卡池，以及 Revive 的完整合法性；本版保守不提供。
- 戰鬥結束後 HP/MP／消耗品如何接續下場（屬 Encounter／RPG progression 跨戰鬥規格）。

其他本文件卡面、數值、duration、稀有度暫取 R/初始基本級、首次 Boss fixture 係數等均由設計者先行提出候選、交自動測試，並不需要每個項目都向使用者重新投票。