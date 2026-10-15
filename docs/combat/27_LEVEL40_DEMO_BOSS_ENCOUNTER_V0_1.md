# 27 — Level 40 Demo Boss Encounter v0.1（秘紋守衛・零式）

> 2026-10-15｜狀態 **CONTENT_PROVISIONAL / SPECIFIED_NOT_TESTED**。本文件是面向首場完整示範戰鬥的**獨立內容 fixture 與測試契約**，不更新、覆寫任何既有 USER_APPROVED／P1/P2/M 玩法規則。唯一上游是 Library 最新有效 Combat Rules `00`–`24`、`25_STARTER_PARTY_CARD_CONTENT_V0_2.md`、`26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md`。禁止引用舊 `Life_RPG_Astraea_GDD_v1.1.md` 或舊 `COMBAT_SYSTEM.md`，禁止重引 Counter-Function。尚未進行 Godot 或真正遊玩測試；不得宣稱勝率／平衡 PASS。
>
> **範圍**：一場 3v1、等級40、無額外小怪或自由走位的完整戰鬥。三人是朝霧蓮（劍士 Variant）、九條朱音（爆發魔法師）、白石紬（治療支援）；各用 `26` 定義的12張個別卡牌、均可配置通用攻擊／治療／防護魔法。敵人為新建測試原創 Boss `TEST_BOSS_ARCANE_SENTRY`，本地化顯示「秘紋守衛・零式／Arcane Sentry Type-0」。不導入新職業、地圖位置、Revive、商業系統或第二個敵人。

## 1. 參考作品與設計取捨（外部資料僅作為設計參考）

| 作品／可查證來源 | 參考點 | Astraea 的實際處理 |
|---|---|---|
| Slay the Spire — https://slay-the-spire.fandom.com/wiki/Intent 與 https://www.slaythespire.gg/intents/Attack_2_defend | 敵方 Intent 要能看出單體、攻擊／防禦及威脅 | Boss 每次行動前展示招式、攻擊目標、範圍、是否 Protect、蓄力預定時點、估算傷害範圍與合法條件分支；不偷換宣告 |
| Across the Obelisk — https://store.steampowered.com/app/1385380/Across_the_Obelisk/ | 不同職能英雄協作、卡牌攻防與隊伍構築 | 同一場 Boss 戰有攻擊、治療、防護、Reaction、詠唱、連攜等有意義的選擇；不移植該遊戲的傷害與能量數字 |
| Gordian Quest — https://gordianquest.com/ | 三人英雄團隊與各自專業 | 三位40等角色的技能及角色分工清楚，兼容使用通用魔法，不把補師與傷害綁死 |

設計準則：**公開情報、可反應、至少兩條可行對策、失敗可追溯**。Boss 高傷技能必須先有一個合法玩家主動決策窗口；某卡沒抽到也不應讓戰鬥完全無解（普通 Guard/Protect、通用 Barrier/治療仍有用）。

## 2. 首場 Encounter 鎖定與勝利條件

- EncounterID: `demo_lvl40_arcane_sentry_v0_1`；difficulty：`DEMO_NORMAL`；party_level=40；player team：`ren_swordsman_v1`、`akane_burst_mage_v1`、`tsumugi_healer_v1`，同級、無裝備／Buff 額外修正、開戰全員 HP/MP 滿。
- 單敵 Boss；HP 歸零後，在當次**合法行動及必要事件結算**邊界判勝負；同一合格結算中敵方與全隊同時歸零為 `VICTORY`（現行 USER_APPROVED），不在中途多段 SP 立即結束。
- 初始 BaseAP=6 全隊共享；每位個人 MP 不自然每回合回滿。PlayerPhase 結束剩 AP 1:1 → RP，通常 cap6；下個 EnemyPhase 結束清零。
- `Basic Attack` 候選 1AP，角色當回合第一次成功使用回 +2MP（候選，受 MaxMP 限制）；可反覆普通攻擊但當階段不重複回 MP。
- 各角色 `12 SP`、開戰各抽4，PlayerPhase 開始補至4（最多8），每人當階段免費換1；Last Spell 不在12張內。卡面按26來源，不額外在此文件創造新卡。
- 不採用任何獨立玩家走位、自由移動，戰場2D或2.5D只呈現特效。

## 3. Level 40 Combat Fixture（非正式等級成長曲線）

以下是 **lv40 測試快照**，不暗示1–39等的配點、成長曲線或正式上限。25文件角色能力值直接作Level40 候選以免本輪產生第二套人物數據。

| actor_id | HP | MP | PAtk | MAtk | PDef | MDef | AccuracyPts | EvasionPts | CritRate | CritBonus | CastRes Mult. | Disrupt Mult. |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `ren` | 1500 | 8 | 135 | 70 | 110 | 90 | 105 | 95 | 10% | +50% | 1.00 | 1.00 |
| `akane` | 950 | 14 | 60 | 175 | 65 | 85 | 95 | 90 | 8% | +50% | 0.90 | 1.15 |
| `tsumugi` | 1200 | 12 | 55 | 105 | 80 | 110 | 95 | 95 | 5% | +50% | 1.20 | 0.95 |
| Boss | **3000** | N/A | **245** | **255** | **90** | **85** | **105** | **90** | **0%**（首版） | N/A | N/A | N/A |

Boss：`BreakGaugeMax=30`，`BreakGauge=30`，沒有 Mana 或一般手牌。Boss 的 CastingInstance 有自己的 Stability；Boss 本體的 BreakGauge 不與詠唱穩定度互換。Boss 唯一未打敗時有敵方行動權，預設 **每個 EnemyPhase 一個已公開的 EnemyAction**（開始 Charge 就用掉此次 EnemyAction，不免費附帶普攻）。

### 3.1 公式與展示數字的界線

- 使用已批准的 HP 傷害結構 `(Attack × SkillMultiplier + FlatBonus) × K/(K+Defense)`，**此 Encounter 固定候選 K=200**，FlatBonus=0（除有明文卡牌），最後向下取整，最低傷0（20文件的 DELEGATED_DEFAULT）。
- 真實可隨機的 HP 傷害首輪使用 `±5%` seeded variance（候選），命中判定與傷害亂數分開。表中的傷害是 **係數1.0的中心參考／命中成功／無 Crit／無 Guard/Barrier/其他Buff／無 RNG 浮動**，不是保證實際傷害。傷害 UI 要顯示合格範圍／機率，不能只硬顯表中值。
- 隨機命中候選 `clamp(0.85 + 0.002×(AccuracyPts−EvasionPts),0.05,0.95)`；普通物理 attack 及指定物理 SP 用百分比 RNG。重要蓄力魔法設定 `AUTO_HIT`（只免命中 RNG，不略過法術抵抗、合法目標或 Guard/Barrier）。不是所有魔法都通用必中。
- Boss 自身本版暴擊0%，避免初次教學混入隨機暴擊尖峰；角色暴擊仍按已批准種類與具體 SP 資格適用。元素修正以此敵特定 `element_resistance_profile` 明示，無敵人全域共通元素法表。
- Boss 物理／魔法技能還必須經已有的命中／Guard／Barrier／Focus Ward／Status／Break／Exposed 規則管線。Break、Disruption 不由 HP damage 推導。

## 4. Boss 弱點／抗性與戰術可讀性

| tag／狀態 | Boss 效果／合法條件 | UX 呈現 |
|---|---|---|
| `FIRE`（本場敵特定候選） | Boss 受到具有明文 `FIRE` 的 HP 魔法傷害 ×1.15；標給朱音 `A01/A02/A04/A06/A07` 及其 Last Spell（實際卡牌 tag 要驗證） | Enemy Intel 解鎖後：`火系較有效（+15%）`；尚未解鎖前 Boss Intent 仍顯示必要威脅訊息 |
| `ARCANE` | Boss 受到帶明文 `ARCANE` 的魔法 HP 傷害 ×0.90；如 `U01`；若無元素標籤，倍率1.0 | Enemy Intel 解鎖後：`奧術抗性 +10%`（此處指輸入 HP傷害剩90%） |
| `PHYSICAL`／其他未列 | 倍率1.0；仍受 `PDef=90` 影響 | 不虛構一般物理抗性 |
| `CORE_OPEN`（姿態，非 Exposed） | 由 Boss 的某些**公開技能**設定的短暫狀態。該狀態存在，且蓮 R01 或 R07 在本場的明文 `exposed_trigger_profiles` 條件下真正命中，才建立一次合法 Exposed | HUD 顯示發亮核心、文字 `核心裸露：可用指定劍技製造破綻` |
| `EXPOSED` | 符合現行 P2-S17–S24：一次有效利用機會、期限、不可自身同張 SP 建立又利用、不疊加、不因失敗浪費、不提供自動通用增傷 | 在目標 HP 下方另顯示 Exposed 次數／期限與合法 SP 高亮 |
| `BREAK_GAUGE=0` | 整張 SP 結算完正式 Break → 將 Boss **下一次合格、尚未開始且可替代** EnemyAction 改成公開的 `BREAK_FALLBACK`；不能回頭中斷既已提交/開始的法術 | Gauge 鎖定／下一個可降級動作 UI 及預覽；fallback 結束後按規則重置 gauge30 |
| `CASTING_STABILITY` | 普通 Boss 蓄力實例由 `A05` 等合法 Casting Disruption 卡削減，Focus Ward 先承傷；穩定度歸零取消該次**普通**詠唱；不造成 Boss 本體 Break | 顯示 Casting 條、剩餘 Stability、可干擾性與預計釋放時點 |

**重要**：`FIRE`／`ARCANE` 只是這個 Boss 的敵特定候選標籤，不創造全域新元素規範；Analyze 是獨立、0 AP/MP/RP、全隊每場兩次的情報行動，**不能直接製造 Exposed**。Enemy Intel 的元素弱點與抗性，可由 Analyze 選對類別後得知；攻擊命中時的戰場特效可以提示，但不自行透露尚未解鎖的精確倍率。

## 5. Boss 技能表（DEMO_NORMAL, BALANCE_PROVISIONAL）

下列係數都作用於 `PAtk=245` 或 `MAtk=255`，使用上述 HP pipeline。傷害預估對應 [蓮,朱音,紬]，為**命中成功、無亂數／Buff／Guard／Barrier 的中心值**。

| skill_id | 招式 | HP 類型與倍率 | 目標／Reaction | 中心傷害 Ren/Akane/Tsumugi | 備註 |
|---|---|---|---|---|---|
| `B01` | 鐵拳突襲 | PHYSICAL ×1.35 | 單體；可 Protect；可基本 Guard | `213 / 249 / 236` | 物理命中 RNG；沒有額外干擾 |
| `B02` | 雙刃連擊 | PHYSICAL ×0.80，**兩擊** | 單體兩段、同一 EnemyAction／Reaction Window；可 Protect／Guard | `126×2 / 147×2 / 140×2` | Guard/Protect 依20的 same ActionScope 覆蓋兩擊；每 hit 可各自命中或失手 |
| `B03` | 弧光穿刺 | MAGIC ×1.35 | 單體；可 Protect／Guard | `237 / 241 / 222` | **命中且真實承受者有合格 CastingInstance** 才帶 `ON_HIT_CASTING_DISRUPTION=5`；Protect 的命中型干擾跟隨承受者 |
| `B04` | 共振脈衝 | MAGIC ×1.05 | 全體合法非倒地目標；不可基本 Protect；各人可 Guard | `184 / 187 / 172` | AO​​E；不造成直接 CastingInstance Disruption |
| `B05` | 核心預熱 | 本次 **0 HP 傷害** | Boss 自身，開始普通詠唱 | `0 / 0 / 0` | 建立 `OVERLOAD_BEAM` CastingInstance，初始 Stability=`9`，固定下一 EnemyPhase 合格釋放點；設定 `CORE_OPEN`，讓玩家有完整一個 PlayerPhase 反制窗口 |
| `B06` | 超載光束 | MAGIC ×2.35 | 單體：Charge 時鎖定並公開指定的 `akane`，可 Protect／Guard；若目標已不合法按已展示分支 `FIZZLE` | `413 / 420 / 386` | 僅在 `B05` 有效 pending 且仍合法時釋放；若 A05 等合法打斷，**該次光束不再結算**；Boss本次改為 `COOLDOWN` 無免費追加攻擊 |
| `B07` | 重構護壁 | 0 傷 | Boss 自身 | `0` | 首次進 P2 的一次性行動，獲 `180 HP Barrier`，不疊加（若已有同類護壁取較高剩餘值），不另普攻；盾吸 HP不吸 Stability |
| `B08` | 終末蓄能 | 本次 **0 HP 傷害** | Boss 自身 | `0` | P3 建立 `FINAL_NOVA` CastingInstance，初始 Stability=`15`，下一 EnemyPhase 才釋放，設定 `CORE_OPEN`；單張 A05 不必保證可獨力打斷 |
| `B09` | 終末掃射 | MAGIC ×1.50 | 全體合法非倒地目標；不可基本 Protect，可每人 Guard 或使用合法 Reaction SP | `263 / 268 / 246` | 僅在 B08 pending 且未成功中斷時；達合法中斷條件就不結算，改 `COOLDOWN`；禁止 B08 當回合免費附加 B09 |
| `B10` | 冷卻校正 | 0 傷 | Boss 自身 | `0` | 詠唱已被成功中斷時的公開失效結果；不免費跳到下個傷害技能 |
| `B11` | BREAK 降級攻勢 | PHYSICAL ×0.60 | 單體：可 Protect／Guard | `94 / 110 / 105` | Break 替換下一次**合格尚未開始**的 B01/B02/B03/B04；不能改掉已經開始的 B06/B09 蓄力實例 |

- `B06/B09` 屬已開始普通 Boss 詠唱的完成事件，不是平白讓 Boss 同階段多做第二次 action。當其完成占用該 EnemyPhase 的 Boss action slot；Phase 轉換／Break 不追溯取消。
- `B01/B02/B03/B04` 的中心值皆不保證命中，也不代表能無視防禦。B03 附帶干擾需 target_casting_id 合法、命中與跟隨語義成立；不是獨立直接指向原施法者的 Disruption。
- `B11` 是替代未開始的合格行動，不是整個 EnemyPhase 自動跳過；若下一個行動為 pending 既有 Casting release 或明定不可替換的 phase-transition event，保留 Break 權利到下一次合格行動。
- 本 Encounter 不含解除 Debuff 的 Boss 招式、召喚、全域治療抑制、站位切換，避免擴充示範範圍。

## 6. 初始行動循環、階段與優先權

### 6.1 階段門檻（Level40 Demo 專用）

| Phase | HP門檻 | 行動模式（每個 EnemyPhase 一個 Boss action slot） |
|---|---|---|
| P1 初始防衛 | `3000–1951`（>65%） | `B01 → B05 → [B06 或 B10] → B04`，循環直到已確認轉階 |
| P2 核心過載 | `1950–901`（≤65%，>30%） | 首次進 P2：`B07` 只做一次；之後 `B02 → B03 → B04` 循環 |
| P3 最終警戒 | `900–1`（≤30%） | `B08 → [B09 或 B10] → B01 → B04` 循環 |

**版本事件順序保護：** 先前已公開且已提交的 Intent 不可因玩家當前造成 HP 降階就無提示替換。依既有 Intent 合約，Boss完成／合法終止這個已提交 EnemyAction 後才啟用新 phase 的下一個 Intent。若已存在未完成的 CastingInstance，依該次 casting 原定排程處理，不能因 P2/P3 門檻偷偷消失或立即免費釋放。轉階本身為 UI/狀態事件，**不消耗額外攻擊，也不免費多做招式**。測試要覆蓋門檻在 player 多段 SP 中途穿越、pending spell、Break pending 等競態。

### 6.2 預定目標與資訊透明

- P1 `B01`: 固定首選蓮；`B05` 開始時展示下一次 `B06` 的預定目標朱音；若朱音在鎖定之後失去合法目標資格，`B06` `FIZZLE`（不暗改瞄準紬）。
- P2 `B02`: 在 Intent 建立時選 **當下 HP 比例最低且 HP>0 的隊員**，平手依 `ren,akane,tsumugi`；建立後目標鎖定，不因玩家治療而無提示轉移。若執行時失效，該動作依公開 `FIZZLE` 路徑處理。
- P2 `B03`: 建立 Intent 時優先選有合法 `Concentrating` 的角色，否則朱音，若其失能依固定 `ren→tsumugi` 備援在**發布意圖時**選取；一旦公布不可事後因 MP/HP改變重選。附帶干擾只在實際合法施法實例與命中條件成立時出現。
- P3 `B08/B09`: 全體攻擊，鎖定 `ALL_ELIGIBLE_AT_RESOLVE` 分類；UI 公開會對當時所有合法非倒地隊友生效、不可基本 Protect（角色可各自 Guard）。
- 所有範圍、已公告合法分支、`is_protectable` 與 `windup_progress/expected_execute_phase` 必須由相同的 Domain intent snapshot 驅動 UI；不存在不顯示的「隱藏換目標」。

### 6.3 最早3階段示範（非指定 RNG Seed、非已執行結果）

1. PlayerPhase1：玩家已看見 `B01` 會打蓮；可以攻擊或留 AP 轉 RP，反應窗口 Guard/Protect 皆有合法條件。
2. EnemyPhase1：Boss `B01`；隨後發布 `B05` 作為下一行動 Intent。
3. PlayerPhase2：自由攻擊、治療或防護（`B05` 尚未開始，玩家現在不應能攻擊不存在的 CastingInstance）。
4. EnemyPhase2：Boss只使用 `B05` 開始詠唱，Stability=9，`CORE_OPEN` 開啟；公告 `B06` 預計 EnemyPhase3、鎖定朱音。
5. PlayerPhase3：蓮若手持 R01/R07 可以命中建立 Exposed；朱音若手持 A05 施放 Casting Disruption，候選 `floor(8×1.15)=9`，對無 FocusWard 的 Stability9可成功中斷；若未抽到 A05，可以用 Barrier、治療前置、保留 RP 防護（獨立機制，不保證必須打斷）。
6. EnemyPhase3：若 CastingInstance 仍合法，`B06` 釋放，按已公告可 Protect 的單體魔法計算傷害；若合法中斷則 `B10` 冷卻，不附帶攻擊；後續產生下一個 Intent。

**提醒：** 上述只是一條條件分支說明；不代表12卡隨機起手必定抽到 R01/A05。實際劇情引導若需要特定開局卡，需選一個**真正可重播**且驗證過的固定牌庫 Seed／fixture，禁止 UI偷偷生成額外卡。

## 7. 傷害對照、HP 危險程度與反應計算

### 7.1 Boss 對三人（中心值）

| 行動 | 蓮 (1500HP) | 朱音 (950HP) | 紬 (1200HP) | 用意 |
|---|---:|---:|---:|---|
| B01 單體物理 | 213 | 249 | 236 | 教玩家看對象與 Guard |
| B02 兩次物理 | 126×2 | 147×2 | 140×2 | 教同一 Action 多段 Guard/Protect |
| B03 單體魔法 | 237 | 241 | 222 | 教 Casting protection 與 ON_HIT 干擾 |
| B04 全體魔法 | 184 | 187 | 172 | 教不能基本 Protect 全體、可各人 Guard／Barrier |
| B06 強蓄力單體 | 413 | **420** | 386 | 對朱音相當於約44%滿 HP，需正確處理 |
| B09 終末全體 | 263 | 268 | 246 | 若無防護全隊共承受 777 HP 中心值 |

例：朱音受到 `B06` 420 中心傷害；若朱音成功使用基本 Guard（測試比率40%）且先前合法 Barrier=140，候選結果：`floor(420×(1−0.40)−140)=112 HP損失`。此為**中心值示例**，實際在 `variance, Guard, Barrier` 既有流水線下可能不同；Barrier 先於HP扣血耗盡，Focus Ward 不抵此HP傷害。

### 7.2 三人對 Boss（中心值；同樣保留元素與暴擊條件）

| 行動／卡 | 中心有效 HP傷害 | 備註 |
|---|---:|---|
| 蓮 `R01 破勢斬` | 93（命中後） | 另 +6 Break，蓮的首次 Break 被動可 +2；不是93 Break |
| 蓮 `R06 蒼月斬` | 162（命中後） | 另+5 Break，可能 Combo Finisher |
| 朱音 `A01 燐火彈` Chantless | 141（含 FIRE×1.15） | 立即造成，1AP+2MP |
| 朱音 `A01` Full | 233（含 FIRE×1.15） | 下一合法 PlayerPhase 起始點才結算，需 Concentration |
| 朱音 `A06 星墜槍` Chantless | 218（含 FIRE×1.15） | 可依 Combo 配方合法利用 Exposed |
| 朱音 `A06` Full | 331（含 FIRE×1.15） | 2AP+5MP，延時結算 |
| 紬 `T09 光羽彈` Chantless | 66（中性） | 只是基本攻擊，非高爆發 |
| 紬 `T10 祈光脈衝` | 58（中性） | Boss 實際HP減少才可觸發該卡附帶一次治療 |
| 任一角色 `U05 初階治癒術` | HP傷害0；有效治療150 HP | 不靠 MAtk 加成；紬若當階段第一合格HEAL，可按 v0.2 被動候選+60 |

注意 `U01 奧術彈` 另受本敵方 `ARCANE×0.9` 候選，不把所有帶魔法字眼的攻擊都當 FIRE。Boss HP3000 下，**沒有經真實牌序／AP／MP／命中與 Boss 行動模擬，不能保證是6–10回合**。

## 8. Last Spell 用於單 Boss 戰的內容平衡校正（只屬本 Encounter 候選）

v0.2 原本單體 Boss 上 Ren/ Akane Last Spell HP倍率相較其一般 SP 偏弱，可能難以補償成功後 `EXHAUSTED` 的永久行動損失。這次採**僅本 Demo Fixture 的明文覆寫候選**，不修改 Last Spell 的核心規則或所有角色通用公式：

| Last Spell | 費用／釋放點 | v0.2 倍率 → Demo 候選 | 單體 Boss 中心效果（無其他增益） | 成功後代價 |
|---|---|---|---|---|
| 蓮 `LS_REN_SWORD_V1 終式・蒼天一閃` | 3AP+5MP；預計提交後第2個 PlayerPhase 開始，例 P1→P3 | PAtk×3.60 → **×6.50** | 605物理 HP 傷害（需合格命中）；另+24 Break | 蓮本場 Exhausted；無普攻、持卡、Reaction或新 Combo |
| 朱音 `LS_AKANE_MAGE_V1 終式・紅蓮星墜` | 3AP+9MP；同時序 | MAtk×3.20 → **×6.80** | 單體 Boss 約 960 HP（含 FIRE×1.15，且只有一名敵人時全體等於這一個目標） | 朱音本場 Exhausted；Boss仍可干擾／殺死施術者 |
| 紬 `LS_TSUMUGI_HEAL_V1 終式・白銀之誓` | 3AP+7MP；同時序 | 維持候選 | 每名尚未倒地隊友補35% MaxHP、各+260 HP Barrier，受各自HP上限截斷 | 紬本場 Exhausted；不復活、之後不能再主動治療 |

- 所有 Last Spell 都仍是獨立槽、一場最多啟動一次、強制 Full Chant、不可由玩家提交後取消。Boss 首次對 Last Spell 達合法失衡門檻按原規則延後，之後合法失衡採削弱而**不得無限延長**；削弱百分比仍 Provisional。
- 施術者釋放前 HP0 立即 `LastSpellInvalidated(CASTER_INCAPACITATED)`，沒有死後釋放與補償退款。已釋放完成後變 Exhausted、可能仍被治療／攻擊，但不得再主動行動。
- 例：Boss P3 門檻900 HP，朱音滿足魔法屬性、合法目標、Full Chant正常釋放時的候選960傷害足以收尾；然而施法要等至少到其預定回合，期間可以被中斷／失能，不能把960當隨按即得的免費斬殺。

## 9. Encounter 專屬 Boss AI 決策模型（deterministic FSM）

狀態：`boss_phase`, `cycle_index`, `phase2_barrier_used`, `pending_casting_id`, `committed_enemy_intent`, `core_open_until`, `break_pending`, `break_gauge`, `barrier_hp`, `last_target_id`。

**Intent/Reaction/Phase 順序：**
1. 若有既已承諾且合法待完成的 CastingInstance，保留其到期時點與原公開目標；不因HP門檻／Break 新增而回溯換技。
2. 每個 EnemyPhase 只執行一個已預告 EnemyAction slot；若這次預告行動被合法 CastingInterrupt 取消，使用該技能所揭示 `B10 COOLDOWN` 結果，不偷偷換成新攻擊。
3. 未有待決 Casting 的下一新建 Intent，先套用合法 BreakNextEligible downgrade 判斷，若符合則 B11，fallback 完成後重置 BreakGauge，Phase pointer 的 consumed/skipped policy 須可重播（首版候選：B11 取代該正常循環項且消耗它）。
4. 若剛越過P2/P3門檻，依前述既已提交 Intent 優先權，在下一**新建** Intent 才轉 Phase，並顯示 `PhaseChanged`; P2 B07僅在合法 P2第一個新建行動一次觸發。
5. 若所有行動都不合法則用明文 `SAFE_IDLE`（0傷）而非強制挑隱藏目標，記錄 guardrail reason。

必要 Boss Intent 欄位：
```json
{
  "encounter_id": "demo_lvl40_arcane_sentry_v0_1",
  "enemy_id": "boss_type0",
  "skill_id": "B06",
  "targeting_mode": "SINGLE_LOCKED",
  "fixed_target_ids": ["akane"],
  "target_scope": "SINGLE",
  "damage_kind": "MAGICAL",
  "is_protectable": true,
  "on_hit_disruption": false,
  "direct_casting_disruption": false,
  "breakable": true,
  "casting_id": "demo-cast-instance-id",
  "windup_progress": 1,
  "expected_execute_phase": "EnemyPhase3",
  "conditional_branches": ["CAST_INTERRUPTED_TO_B10", "INVALID_TARGET_TO_FIZZLE"]
}
```
上述示例中的 `casting_id` **只是一個資料形狀示例，不是固定真正 instance id**；實例須由 deterministic domain 發出。在 UI 上預估傷害應從目前值與狀態重新計算，不硬編中心表格。

## 10. 驗證／驗收（完成前不能宣稱首場可玩通關）

### 10.1 Core regression 必測（每項以命令 tape / event trace 驗證）

- `DEMO-01`：Level40 party／Boss 進場只含1 Boss、三人各12合法 CardInstances、每人手4、共享6 AP、個人MP正確。
- `DEMO-02`：Boss Intent 揭露後玩家改HP/MP，實際目標與招式不偷偷換；公開合法 FIZZLE 分支一致；P1→P2→P3 門檻前後 Intent 不回溯失效。
- `DEMO-03`：B05 0傷且不附加普攻；E2開蓄力→P3有主動反制窗口→E3可合法釋放 B06 或 B10；無 pending_cast 不可釋放 B06。
- `DEMO-04`：Boss B05 Stability9 無 Focus Ward 時，朱音 A05 合法削減9則被 CastingInterrupted；僅取消該次技能而非永久封鎖 Boss。A05 不得當作 Spell Counter。
- `DEMO-05`：B02 對同一目標兩次物理 hit 仍屬同一 Reaction Window；Guard/Protect 有效 ActionScope 與重算命中防禦；B04/B09 AoE 不可基本 Protect。
- `DEMO-06`：B03 單體命中附帶 Casting Disruption，在合法 Protect 時跟隨真正承受者；不對原施法者再削一次；DirectCastingDisruption 另測，不能被 Protect 擋。
- `DEMO-07`：FIRE ×1.15、ARCANE ×0.90、未知1.00，按卡明文 tag 與敵特定設定；Enemy Intel 資訊揭示不等於自動 Exposed。
- `DEMO-08`：CORE_OPEN 時 R01/R07 合法命中才能 Exposed；同張卡不得立即消耗自己製造的 Exposed；另一張 SP 合法成功利用才消耗。已有 Exposed 不刷新；Break 分離處理。
- `DEMO-09`：Break=0 整張 SP 才觸發，下次合格 Boss EnemyAction 用 B11 而非 skipped EnemyPhase；若 pending cast 已開始不得追溯中斷；合法 fallback 結束後 gauge重置30。
- `DEMO-10`：三人均可合法使用通用 U05 治療；滿血／0MP／HP0／不在 hand／Concentrating／Exhausted 等非法情況均拒絕且不亂扣費。T10 需真的扣敵 HP 才能附帶治療。
- `DEMO-11`：U02 Barrier、U03 FocusWard 分開；Boss B06 從420先Guard40%再Barrier140後中心值112HP（含 variance 測例另驗）；RP當次 EnemyPhase 後清零。
- `DEMO-12`：Last Spell成功後 Exhausted、不在12張；失衡延遲/削弱；HP0 prior-to-release instant invalidated且 no refund；Legitimate mutual KO still victory。
- `DEMO-13`：同 seed+同 command tape+同配置內容版→相同 event trace/state hash；牌區 instance count 永遠12/actor，不複製卡；UI動畫不決定勝負。

### 10.2 平衡試驗矩陣（尚未執行）

至少每種策略100固定 seeds，共4類，並在必要時以固定初始已驗證 seed 做劇情教學：

| 策略 | 偵測問題 | 追蹤指標 |
|---|---|---|
| `BALANCED` | 一般玩家有合理勝率？ | win_rate、phase_count、HP存量、card_use、AP participation |
| `AGGRESSIVE` | 純輸出是否忽視防護就能完封？ | 最快通關、受擊／死亡率、LastSpell使用頻率 |
| `DEFENSIVE` | 防守／治療是否無限拖回合？ | 平均回合數、治療溢補、屏障實吸收、MP枯竭 |
| `CAST_SUPPORT` | 全詠唱和 Last Spell 是否值得保護？ | completion/interrupt rate、FocusWard使用、HP0失效、最終有效傷害 |

**第一輪目標，非實績**：BALANCED 目標勝率 `65–85%`；勝利回合數中位數 `6–10`；AGGRESSIVE 不應在多數種子毫無防護輕鬆獲勝；DEFENSIVE 不應無限循環；至少能實際展示一次合法 CORE_OPEN→Exposed→finisher、一次 Guard/Protect、一次醫療決策及一次 Full Chant。若未通過先調整可配置 Boss／卡牌 **數值**，不要修改已核准的行動、時序或目標資格核心。

真正可交付的 Godot 證據：Encounter fixture JSON/resource、3人 loadout、deterministic simulator test log、100-seed CSV、完整 replay command tape/hash、真人UI選卡與BossIntent驗收。**當前狀態 `SPECIFIED / NOT EXECUTED`，沒有任何實際 Godot / CI / win-rate test log。**

## 11. 交付給 Godot Agent 的執行順序（不擴大 Demo Scope）

1. `Content/CharacterFixtureLv40`：載入25/26的3角色 Variant 與v0.3各12張牌；所有能力值標內容版本。
2. `Content/BossDefinition`：建立 Boss HP/Break/攻魔防/元素抗性/技能 B01–B11／三階段 AI、Targeting、CastingInstance。
3. `EncounterDefinition`：將三人與 Boss、固定 Level40、Phase、初始手牌種子、玩法決策條件綁定。
4. `EncounterGoldenTests`：依 §10 逐條做 Domain／headless 驗收；所有反應與傷害由現有 core event pipeline 結算。
5. `SimulatorBalance`：固定 seed×4策略，調整 K、Boss HP、B係數、Fire倍率、Last Spell 單Boss倍率等 **CONTENT_PROVISIONAL**。
6. `Presenter2D/2.5D`：左三人 HUD、中 Boss、右公開Intent/HP/Break/Casting、下當前選中角色手牌、AP/RP與基本指令。攻擊／治療／技能動畫依 Domain EventTrace 顯示而非產生傷害。
7. `Real Player Demo QA`：確認玩家可理解「為何這招能 Protect/不能 Protect」「何時能 Interrupt」「為何 Last Spell 暫不生效」「已受傷能否通用治療」。

### 實作禁止事項

- 不引入任何舊 `Function Graph` 或 `Counter-Function` 戰鬥機制；新版只有明文 Casting Disruption／Spell Interrupt／Spell Counter。
- 不讓角色每輪 MP 自動滿；不設每人各6 AP；不把卡片當普通攻擊指令；不讓治療免費不抽牌；不允許沒有 Revive 的治療解除 HP0 失能。
- 不讓 Boss 在同一 EnemyAction 免費 `Charge+Hit`、不把 Break 直接清空 Boss 整個 EnemyPhase、不讓 Barrier 吸 Casting Stability、不讓普通 Guard 擋住無合法目標的不可攔截效果。
- 不把本文件任何數字宣稱為 FINAL_BALANCED，不在 Godot simulator logs 生成前宣稱已完成完整 Demo。