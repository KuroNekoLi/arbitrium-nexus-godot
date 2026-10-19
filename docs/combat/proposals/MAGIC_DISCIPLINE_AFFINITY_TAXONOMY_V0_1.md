# 魔法學科、共鳴屬性與法則系統 — 設計提案 v0.1

> **本文件已列為歷史研究（2026-10-19）**：請優先閱讀 [統一魔法系統 v0.4](MAGIC_SYSTEM_INTEGRATED_DESIGN_V0_4.md)。v0.4 整合目前學科、Buff／Debuff、Overload、Weakness、Break、Exposed、Casting 與 Combo 的完整設計；現行 Combat Rules 不變。

> **版本索引提示（2026-10-19）**：本文件保留作歷史設計提案；新的框架重審請優先閱讀 [MAGIC_SYSTEM_ARCHITECTURE_V0_3_REVIEW.md](MAGIC_SYSTEM_ARCHITECTURE_V0_3_REVIEW.md)。v0.2 中使用者已確認的「世界觀深、實戰易懂、優先重用機制」原則仍有效；v0.3 其他調整只是新提案，尚未核准。

> 狀態：**PROPOSED / NOT USER_APPROVED / NOT IMPLEMENTED**  
> 日期：2026-10-19  
> 專案：Arbitrium Nexus / Godot 4.7.2  
> 基準：master `8e16c8f4e7205d256b230953fd9dda07087a90a1`  
> 修改範圍：設計文件；**不改戰鬥規則、卡牌資料、Domain、Godot Scene**。核准前不得將候選分類當成實際法術或倍率實裝。

## 0. 本次要解決的問題

傳統火水風土回答的是「能量或物質的性質」，但不足以涵蓋時間、空間、因果律、記憶、認知與感覺。若把所有名詞直接列成同層 `element`，將出現「治療屬於哪個元素？」、「時間倒流是傷害屬性嗎？」、「奧術為何萬能？」等問題。

**提案：三軸設計，不是單一十八屬性相剋輪。**

- **學科 Discipline**：法術操縱什麼世界現象；定義敘事身份、視覺與可設計的技能機制。
- **共鳴 / 傷害屬性 Affinity**：只有當效果明確造成可辨識的元素或神秘傷害時，才參與敵人**逐個**弱點／抗性。不是每個學科都要對應傷害屬性。
- **效果 Effect Tags**：真正改變 Domain 的機制，如 `DAMAGE`、`BARRIER`、`HEAL`、`CASTING_DISRUPTION`、`STATUS_APPLICATION`，使用現有合法性與事件時點，學科不會自動賦予效果。

此外 `casting_mode` (Instant / Dual / Full Chant)、`eligibility` (Universal / Role / Character / Variant)、`targeting` 等完全獨立；**火系不必然灼燒、時間系不必然跳回合、心智系不必然控制敵人**。

## 1. 正式規則與暫定內容：請勿混淆

當前 `docs/combat/傷害與異常狀態系統.md` 只核准逐個敵人的弱點／抗性與既有傷害管線；數值仍可能為候選。現行 `docs/combat/敵人與Boss圖鑑.md` 的 TEST_BOSS_ARCANE_SENTRY 提供示範候選 `FIRE x1.15`、`ARCANE x0.90`、`NEUTRAL x1.00`，**不是全世界固定相剋表**。卡圖鑑 U01「奧術彈」已有 `ARCANE` 標籤，朱音 A 系列有火系敘事，紬 T 系列有光與治療敘事，但沒有因此核准完整九／十八系傷害系統。

既有多角色通用魔法可用、角色各 12 張 SP、手牌與 AP/MP/RP、Dual 詠唱、Focus Ward、HP Barrier、Casting Disruption、Last Spell、Combo、Break、Exposed 等規則均不變。

## 2. 核心定義：什麼是「奧術」？

推薦定義：

**奧術（Arcane）是「以符文、幾何與魔力場直接操縱魔力結構」的學科與能量形式**，不是「所有魔法的別名」，也不是火冰光闇之外的神秘萬能牌。

- 能做：純魔力彈、術式結構、魔力屏障、施法穩定、術式解析、魔力調律、魔力共振。
- 擅長：一般魔法結構與反制施法，不依賴具體物質元素。
- 不預設能做：倒轉時間、改寫命運、讀心、操縱感官、復活、無條件消除任何狀態。
- 現行 `ARCANE` 作為示範戰**傷害共鳴屬性**繼續保留，不重新解讀已發布傷害紀錄。新學科 `ARCANUM` 與現有 Damage Affinity `ARCANE` 是兩個欄位；名稱可能近似但資料語意不同。
- U01「奧術彈」候選映射 `discipline=ARCANUM`、`affinity=ARCANE`、`effects=[DAMAGE]`；U02「魔力屏障」可以是 `ARCANUM / NONE / BARRIER`；不自動把 U02 變成有 0.9 倍抗性的護盾。

## 3. 魔法學科總覽（18 個候選領域，6 大學派群）

| 學派群 | 候選學科代碼 | 中文 | 核心概念 | 擅長領域，非自動效果 |
|---|---|---|---|---|
| 物質與自然 | `PYROMANCY` | 炎熱 | 熱、火焰、燃燒 | 爆發、持續熱害 |
| 物質與自然 | `HYDROMANCY` | 水流 | 液體、壓力、流動 | 導流、淨化、干擾地形 |
| 物質與自然 | `CRYOMANCY` | 寒霜 | 溫度降低、結晶 | 防護、減速候選 |
| 物質與自然 | `AEROMANCY` | 風氣 | 氣流、氣壓、聲波介質 | 擾亂、擴散、動量 |
| 物質與自然 | `GEOMANCY` | 地脈 | 岩石、晶體、地形 | 防護、固定、破甲候選 |
| 物質與自然 | `FULGURMANCY` | 雷電 | 電流、電磁場 | 爆發、術式干擾候選 |
| 光與影 | `LUMINOMANCY` | 光輝 | 光子、照明、光學現象 | 照明、光束、遮蔽破解 |
| 光與影 | `UMBROMANCY` | 幽影 | 遮蔽、暗影、光線缺席 | 隱匿、視域削弱 |
| 生命與靈魂 | `VITAMANCY` | 生命 | 生理活力、再生、生物過程 | 治療、生命織補 |
| 生命與靈魂 | `SOULCRAFT` | 靈魂 | 身份、靈性聯結、靈魂印記 | 靈魂保護、儀式 |
| 時空法則 | `CHRONOMANCY` | 時間 | 持續時間、時序、局部時間 | 效果期限、時序調整 |
| 時空法則 | `SPATIOMANCY` | 空間 | 距離、位置、界面、拓撲 | 範圍、目標轉移候選 |
| 時空法則 | `CAUSALITY` | 因果律 | 條件、結果、事件因緣 | 延遲條件觸發與風險收益 |
| 心智與感知 | `COGNITION` | 認知 | 理解、記憶、判斷、訊息 | 分析、情報、誤判 |
| 心智與感知 | `SENSATION` | 感覺 | 視、聽、痛覺、觸覺等訊號 | 感知強化、幻痛、幻聽 |
| 心智與感知 | `EMOTION` | 情緒 | 恐懼、激昂、平靜、動機 | 情緒波動、專注候選 |
| 構造與規約 | `ARCANUM` | 奧術 | 純魔力、符文、術式、結界 | 魔力彈、Focus Ward、術式操作 |
| 構造與規約 | `CONTRACT` | 契約 | 誓約、交換、約束、代價 | 誓約防護、代價收益、條件契約 |

**十八種是世界觀分類的廣度，不代表首發要做十八套戰鬥子系統。** 時間／空間／因果律是高概念學科，不能因其敘事名稱而授予全域跳回合、自由移動或撤銷已提交事件的權限。

### 3.1 對容易混淆的分類建立邊界

- 水 vs 冰：水操縱液體／壓力；冰操縱冷卻／結晶。聯合施法可為兩學科，不強迫所有冰法先會水。
- 光 vs 治療：光是輻射／光學；生命是生理修復。既有「守護之光」可用光學美術但機制仍為 BARRIER，學科日後可採 LUMINOMANCY 或 VITAMANCY+LUMINOMANCY。
- 影 vs 情緒：影改變照明或遮蔽，不天生恐懼。恐懼屬情緒效果。
- 認知 vs 感覺：認知是*如何解釋／記住訊息*；感覺是*收到什麼感官訊號*。幻象通常是感覺，錯誤推理／記憶覆寫才是認知；兩者可複合。
- 情緒 vs 認知：恐懼不必然篡改記憶，分析不必然控制情緒。
- 靈魂 vs 生命：靈魂影響身份／精神印記；生命操作生理恢復；兩者均**不得繞過 Revive 合法性**。
- 奧術 vs 因果律：奧術操縱施法結構；因果律約束條件與結果，不是更高級版的奧術。
- 契約 vs 因果律：契約是雙方／法則認可的條件束縛；因果是事件間依存。契約魔法的代價必須有顯式事件與支付規則。

## 4. Affinity（弱點／抗性）建議：少於學科數

**候選一級共鳴屬性（不是最終核准表）：**

`FIRE, WATER, ICE, WIND, EARTH, LIGHTNING, LIGHT, SHADOW, ARCANE, NEUTRAL`

- `NEUTRAL`：無特定共鳴，不是「平庸」學科。
- `NONE`：無傷害共鳴欄位，尤其適用回復、護盾、調律；與造成中性傷害 `NEUTRAL` 的事件有區別。
- `PHYSICAL`：物理／魔法的**傷害類別（damage_kind）**，不是元素。
- 生命、靈魂、時間、空間、因果律、認知、感覺、情緒、契約等**預設沒有專屬 HP 抗性欄位**。個別法術可選擇 `ARCANE`、`NEUTRAL` 等已定義共鳴。
- 此階段不採固定「火剋冰／光剋闇」倍率輪；沿用每個敵人獨立 resistance profile。倍率另做平衡 ADR。
- Affinity 在資料結構中可為 `NONE`（無傷害）或單一主要 `primary_affinity`；複合學科≠多重屬性疊乘。日後需要多傷害分段時由多個 Effect 明示每段屬性與事件。

## 5. 高概念學科的硬性設計欄杆

### 時間 CHRONOMANCY
可設計：將某個**已存在、允許修改的狀態**延長／縮短一期；合法延遲下一次效果；下一個合法窗口的時序提示。需使用既有 `expires_at / tick_trigger`，並由 Domain 發出變更事件。

**首發禁止**：重置回合 AP、退還已用卡與 MP、倒轉全體 HP、重播 RNG、插入額外玩家階段。任何時間逆轉都需新 ADR 與 Replay 證明。

### 空間 SPATIOMANCY
可設計：指定合法目標的區域結界、改變已存在的合法目標選擇條件；如允許，建立特殊 Protect 類的目標轉移事件。

**首發禁止**：新增戰棋座標／自由移動、未核准的前後排、繞過 Protect 或直接選失能目標。

### 因果 CAUSALITY
可設計：當一個未來**明確且尚未結算**的事件滿足條件時觸發單次加成；「本次若合法命中，下次獲得護盾」須明示 consume、expires、stack、觸發順序。

**首發禁止**：修改已產生的骰子／亂數值、反轉已結算死亡、事後取消支付、將 Boss 隱藏意圖變成可確定情報。其「看似改寫命運」只能由有上限的未來條件效果表達。

### 認知 COGNITION
可設計：Analyze 加成**僅在 Analyze 既有合法預算內**、顯示公開情報、特定條件的認知 Debuff；不得自動洩漏未公開 Enemy Intent。

### 感覺 SENSATION
可設計：感知強化、遮蔽與錯覺狀態；任何致盲／混亂命中影響都要獨立 Status 效果 schema 與 UX，不能光有「幻覺」學科標籤就偷偷使技能失效。

### 靈魂／生命
可以發展稀有治療與 Ritual，但 `INCAPACITATED`、`EXHAUSTED`、`Revive` 的現行區分絕不可默默改變；生理治療不能自動復活，靈魂法術也不能讓耗竭角色重返戰場。

## 6. 實際法術範例：都是候選，不覆蓋現有 Card ID

| 候選名 | Discipline | Affinity | Effect 方向 | 安全性／權限 |
|---|---|---|---|---|
| 焰痕 | PYROMANCY | FIRE | 單體傷害，個別技能可附 DoT | DoT tick 必須明示 |
| 結晶帷幕 | CRYOMANCY | NONE | 友方 Barrier | 不自動凍結 Boss |
| 迅雷干擾 | FULGURMANCY + ARCANUM | LIGHTNING | HP 傷害與指定 Casting Disruption 分段 | 必須存在合法施法實例 |
| 光域標定 | LUMINOMANCY + COGNITION | NONE | 合法揭示已公開目標資訊 | 不得探知隱藏意圖 |
| 短刻延續 | CHRONOMANCY | NONE | 將可延長 Buff 的 expires_at 延長一次 | 新合法性 ADR 待批 |
| 界面屏障 | SPATIOMANCY + ARCANUM | NONE | 既有防護機制之技能特化 | 不等於新格子座標 |
| 應果誓印 | CAUSALITY + CONTRACT | NONE | 下一次命中時發動預先註記的護盾 | 有效期、優先權、消耗要核准 |
| 記憶折光 | COGNITION + SENSATION | NONE | 限時認知異常狀態候選 | 命中／抗性規則尚未定義 |
| 心音調律 | EMOTION + ARCANUM | NONE | 施法支援／Focus Ward 候選 | 不取消 Concentrating 限制 |
| 生命編織 | VITAMANCY | NONE | HP 治療 | 沒有 Revive 標籤不能救 HP0 |

**複合學科**表示施術原理，不保證兩種共鳴屬性或雙重傷害倍率；每張卡仍逐張設計 AP/MP、Casting、Target、Effect、combo tags。

## 7. 呈現、收藏、配牌與 Godot 資料設計（提案）

### 7.1 卡牌資料（僅供將來 schema ADR 審查，不可現在改正式資料）

```json
{
  "card_id": "PROPOSAL_CHRONO_01",
  "name_key": "CARD_PROPOSAL_CHRONO_01_NAME",
  "disciplines": ["CHRONOMANCY"],
  "primary_affinity": "NONE",
  "effect_tags": ["STATUS_MODIFY_DURATION"],
  "casting_modes": ["FULL_CHANT"],
  "eligibility": {"type": "ROLE_TAG", "value": "TEMPORALIST"},
  "status_policy_ref": "PROPOSED_DURATION_EXTENSION_V1"
}
```

新 `TEMPORALIST` 也只是占位候選資格，不是已授權的新 Variant 或現存職能。

資料建議：ID 固定英語常數、`name_key` / `description_key` 對應 `zh_TW` / `en`；`discipline` 可多值、`primary_affinity` 單值或 NONE。卡圖、圖示、配色只由資料綁定，不從圖片判別法術種類。既有卡若 migration，需有明確兼容預設、版本與 Replay 歷史測試。

### 7.2 新法術圖鑑的篩選

第一層學科群（元素／光影／生命靈魂／時空／心智／奧術契約）；第二層具體學科；獨立過濾：傷害共鳴、詠唱模式、角色資格、效果類型。可讓「光羽彈」同時出現在光學學科與魔法傷害篩選，但不用從顏色推測傷害公式。

### 7.3 視覺線索

元素採色相與圖示，時空採時計／裂隙／結線，心智採眼／耳／記憶幾何，奧術採符文／魔法陣，契約採封印。**顏色不是唯一辨識方式**；必有短字串與圖示，避免色弱玩家難以分辨。不能把戰鬥規則烘焙到 CG。

## 8. 分階段導入與風險

- **Gate A：本設計概念核准**（目前停留於此）：群組名稱、十八學科數量、ARCANUM 定義、Affinity 集合與是否需要独立情緒／契約。
- Gate B：設計各學科至少 2 張卡的機制與反制，形成成本／身份矩陣，避免時間與因果超模。
- Gate C：選小規模 Vertical Slice：元素兩系＋奧術＋時間＋空間＋認知，共 6 個學科，不要求同時實作十八系。
- Gate D：核准 schema ADR、資料 migration、工具提示、Test Fixture 與 Replay 相容策略。
- Gate E：Codex 在新實作分支更新 Domain、Content、Localization、UI、平衡與 QA。
- Gate F：在固定種子場景與可重播事件驗證後，**才**合併 master。

本設計不宣稱獲得使用者核准、不建立固定抗性表、不偷偷擴充狀態清單、不修改現有卡牌強度。

## 9. 參考遊戲：借鑑結構，不抄遊戲內容

1. **Pathfinder 2e：Arcane / Divine / Occult / Primal**。借鏡「施法傳統／魔法來源」與個別法術效果不是同一件事；本專案把奧術更具體界定為術式與純魔力，而非泛指所有神秘魔法。參考：[Pathfinder SRD Spell Traditions](https://www.pf2.d20pfsrd.com/rules/spells/)。
2. **Magic: The Gathering：Color Pie**。借鏡各系強項／弱點的設計責任，**不**直接搬五色分類／費用。參考官方：[The Council of Colors, Revisited](https://magic.wizards.com/en/news/making-magic/the-council-of-colors-revisited)、[The Value of Pie](https://magic.wizards.com/en/news/making-magic/value-pie-2003-08-18-0)、[Comprehensive Rules](https://magic.wizards.com/en/rules)。
3. 通用時間／空間奇幻作品的高概念能力提醒我們建立**事件與 Replay 限制**；不拷貝具體技能數值與劇情。

## 10. 待使用者決策（重要）

1. **十八學科是否接受？** 也可以先保留 6 大群，但把情緒併入認知／感覺，把契約併入因果，縮為 16 系。
2. **奧術的提議定義是否接受？** 它是魔力工程，不是萬能元素；現有 `ARCANE` 傷害標籤保留。
3. **是否採雙軸（學科 vs 共鳴）？** 我強烈推薦，避免時間系加入無意義的傷害抗性。
4. **時間／空間／因果律的首發權限邊界**：提議一律不改過去事件、不自由走位、不插額外階段。
5. **光與闇**屬光學現象 vs 宗教善惡的世界觀語義：本提案採自然／感知視角，不預設善惡。
6. **先做哪些學科的技能**：建議先做小規模 Vertical Slice，不直接推出十八系各一大套。

> 本文件是可交付討論與後續 ADR 的提案，不是現行戰鬥規格替代品。核准時再同步 Source of Truth、卡牌圖鑑及實作契約。
