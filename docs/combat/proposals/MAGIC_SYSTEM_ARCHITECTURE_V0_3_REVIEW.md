# Arbitrium Nexus — 魔法系統框架重審與修正版 v0.3

> **本文件已列為歷史研究（2026-10-19）**：請優先閱讀 [統一魔法系統 v0.4](MAGIC_SYSTEM_INTEGRATED_DESIGN_V0_4.md)。v0.4 整合目前學科、Buff／Debuff、Overload、Weakness、Break、Exposed、Casting 與 Combo 的完整設計；現行 Combat Rules 不變。

> 日期：2026-10-19
> 狀態：**DESIGN_REVIEW / PROPOSED / NOT USER_APPROVED / NOT IMPLEMENTED**
> 使用者已確認的不變原則：**世界觀可完整複雜；實戰必須易懂；深度主要來自可理解的組合與決策，而非多套隱性公式。**
> 對應歷史文件：v0.1 魔法學科與共鳴初稿、v0.2 雙層複雜度原則、24 學科 Playstyle Matrix v0.1。本文件是上述提案的**新版本取代建議（superseding proposal）**，不是覆寫任何已核准 Combat Rules。
> 實際戰鬥權威：同 repository 的 [docs/combat/README.md](../README.md) → [傷害與異常狀態系統](../傷害與異常狀態系統.md)、[卡牌圖鑑](../卡牌圖鑑.md)、[詠唱與魔法干擾系統](../詠唱與魔法干擾系統.md)、[角色連攜系統](../角色連攜系統.md)、[終式與耗竭系統](../終式與耗竭系統.md) 與最新 USER_APPROVED ADR。**不要以 Archive 裡的舊版耗竭／RP／Combo／命中數值覆蓋目前規格。**
> 本次改動：設計文件與提案索引狀態註記。**不改 Domain、CardDefinition、JSON、場景、Boss、傷害倍率、CI 或 master。**

## 0. 決策摘要：24 種「研究學科」，不是 24 種「互剋傷害屬性」

**建議的產品結構：**

1. **魔法世界觀層（Catalog / Lore）**：24 種研究領域保留作為*候選知識圖譜*；不預設 24 種職業、玩家技能樹、戰鬥機制、抗性或首發卡池。
2. **戰鬥語法層（Combat Grammar）**：僅用少量已有且可信的 Domain 事件／效果構成技能；因果、時間、虛無等 *只有新機制真正產生可辨識選擇* 才需要正式 ADR。
3. **傷害共鳴層（Damage Affinity）**：只有符合條件的**每一段 HP 傷害效果**才帶主要共鳴屬性，抵抗係數由目標敵人逐個配置；不可把學科當弱點表。
4. **角色／施法層（Access & Casting）**：角色資格 UNIVERSAL／ROLE_TAG／CHARACTER／VARIANT 與 INSTANT／DUAL／FULL_CHANT 是正交規則，不因學科標籤默認改動。
5. **玩家顯示層（Presentation）**：優先顯示「做什麼、對誰、花多少、何時生效、能否反制」；學理詳解、術式起源、複合學科放圖鑑與長按檢視。

簡稱：**24 lore topics → small reusable rule vocabulary → curated cards / clear counterplay**。

### 0.1 v0.1／v0.2 存在的具體不足與修正

| 問題 | 舊版風險 | v0.3 改法 |
|---|---|---|
| 24 平行學科容易變成 24 個 balancing types | 玩家須記 24 種相剋；測試組合膨脹 | 24 只管世界觀與配色；不自帶結算效果 |
| 每個抽象學科都用「護盾」代替獨特特色 | 空間、夢境、存在、秩序看起來都是換皮盾 | **有獨特決策時才開戰鬥實作；否則先保持圖鑑／劇情研究領域**，不得用假多樣性充數 |
| 高概念法術常偷渡不受控機制 | 時間改 AP、命運重擲、混沌亂序、存在復活 | 拆成「可表達的現有規則」與「須新 ADR 的能力」兩欄，未核准能力不得寫入卡 |
| \`ARCANE\` 同時像流派、傷害類型和角色職能 | 讀檔時誤以相同字串具相同權限 | 概念分層：\`ARCANUM\` lore vs \`ARCANE\` affinity vs \`ROLE_TAG:ARCANE\` eligibility；**不更名既有 ID** |
| 依學科分配技能而忘了玩家理解 | 高階卡同時有多種附加條件且文本冗長 | 卡牌資訊預算與「單一卡主動詞」；Combo 以既有真實雙人付費管線串連 |
| 只有示範卡沒有實際反制關係 | Boss 弱點及公開意圖未與魔法分類一起驗證 | 每張新的候選卡都須填「玩家的決策、Boss 反制、合法時點、測試 oracle」 |
| 將 24 個候選都視為日後必備 | 開發成本被人工分類膨脹 | 先做可見有價值的小型切片，剩餘僅世界觀內容，觀察玩家需求再增加 |

## 1. 研究對照：借思路、不移植玩法

| 參考作品（官方／規則原文） | 可查證機制／做法 | 可學之處 | 不採用之處 |
|---|---|---|---|
| [D&D 2024 Basic Rules](https://www.dndbeyond.com/sources/dnd/br-2024/spells/) | 八魔法學派幫助**描述**法術；學派本身通常沒有規則效果 | lore 分類 ≠ 每張卡的狀態機 | 不移植 D&D 施法槽、施法環節、八學派作為硬分支 |
| [Pathfinder 2e Player Core, Spells](https://2e.aonprd.com/Rules.aspx?ID=2221) ＋ [Paizo Remaster errata](https://paizo.com/pathfinder/faq) | 魔法分 Arcane／Divine／Occult／Primal 四傳統；Remaster 將舊「八大學派」從主要規則分類移除 | 傳統、主題、法術效果可採不同維度 | 不照搬四大傳統當角色強制職業 |
| [Magic: The Gathering — The Value of Pie](https://magic.wizards.com/en/news/making-magic/value-pie-2003-08-18-0) ＋ [Council of Colors Revisited](https://magic.wizards.com/en/news/making-magic/the-council-of-colors-revisited) | Color Pie 明定長處、短板與能力範圍；規則文字有統一模板 | 每個可遊玩流派要有「能做、不能做」，而不只色彩 | 不引入五色相剋、額外法力顏色或玩家抽卡成本 |
| [Magicka 2 官方頁](https://www.paradoxinteractive.com/games/magicka-2/about) | 至多五種元素同時組合的動態施法 | 複合術式可以有創造力 | **不**允許玩家任意組 24 學科成數千免費即時法術；只使用手工設計、有合法性和成本的卡與 Combo |
| [Into the Breach 官方頁](https://subsetgames.com/itb.html) | 敵方攻擊都能看到預告，決策來自如何應對 | 高階魔法應以**可理解的反制抉擇**而不是隱藏例外增加策略 | 不複製網格走位／全局完全資訊；現有 Boss Intent 公開範圍以規格為準 |
| [Slay the Spire 開發訪談](https://www.gamedeveloper.com/design/designing-for-deck-building-in-video-games) | 以卡牌增加 JRPG 回合戰鬥的選擇與深度，平衡需依測試而非玩家想像公式 | 少量基礎效果、組合出決策；以數據驗證卡牌價值 | 不直接複製能量、遺物、卡牌升級或每回合抽牌數 |

## 2. 新的概念本體：保留 24，但不強制同一個戰術層級

世界觀學科標籤是**研究对象（What is studied）**，而不是職能、元素抗性或技能法則。每張候選卡可具一個主學科和 0～1 個次學科作敘事註解；這個數量限制**僅為本提案的內容／UX 預設**，不是現行 \`CardDefinition\` schema，也不限制劇情中的混合學說。

### 2.1 七個研究群（舊有名稱保留供討論）

| 群組 | 共 24 學科 | 為何放在一起 |
|---|---|---|
| 自然／物質 6 | 炎熱、水流、寒霜、風氣、地脈、雷電 | 操作物質與能量 |
| 光／影 2 | 光輝、幽影 | 光學、顯示和遮蔽 |
| 生命／靈魂 2 | 生命、靈魂 | 生理修復與靈性身份 |
| 時空／條件 3 | 時間、空間、因果律 | 持續、距離、事件條件 |
| 心智／主觀經驗 4 | 認知、感覺、情緒、夢境 | 知道什麼、感受到什麼、相信什麼、夢到什麼 |
| 術式／規約 3 | 奧術、契約、秩序 | 魔力結構、約束和穩定性 |
| 本體／可能性 4 | 命運、虛無、存在、混沌 | 可能結果、消散、身份、不確定性 |

**這七個群組是圖鑑入口，不是七種角色職業或七種抗性。**

### 2.2 學科身份的測試：範疇不同，不必每科首發一套獨門機制

| 學科群（例） | 世界觀上的「主詞」 | 初期建議 | 真正需要專屬新機制才應啟用的地方 |
|---|---|---|---|
| 火、雷、風等自然 | 熱、電、氣流 | 既有傷害、個別明示 DoT／Casting Disruption | 大量場景連鎖反應／地形系統（目前不做） |
| 生命 | 生理恢復 | 現行 HEAL、Barrier、MP 支援按卡逐張映射 | 強化治療前先評估 AP/MP 效率與治療不可 Revive 邊界 |
| 奧術 | 魔力結構、符文、施法工程 | U01 ARCANE 傷害、U02 Barrier、U03 Focus Ward 的研究歸屬候選 | 結算反制／術式重編需要 ADR |
| 時間 | 持續長短、何時生效 | 圖鑑／Boss 演出；未有獨特決策前不放首發可玩卡 | 有限制、可重播的 Status duration change（ADR） |
| 空間 | 界線、相對位置、作用範圍 | 已有合法目標／Barrier 技能可使用空間敘事 | 非網格的合法 redirect / scope change（ADR） |
| 因果律／契約 | 條件→結果；條件化束縛 | 現有 Combo setup/finisher 只能作**敘事參考**，不自動開新觸發 | 將來條件觸發必須列條件／成本／次數／到期（ADR） |
| 認知、感覺、夢境、情緒 | 資訊理解、輸入、主觀經驗、情緒 | 情緒/靈魂題材可用明示 Focus Ward；認知作圖鑑標籤 | Analyze 擴充、假象、恐懼、致盲、睡眠均需資料／可反制 ADR |
| 秩序、存在、虛無、混沌、命運 | 形式／身份／缺席／不確定／未來可能性 | 高級學理、稀有 Boss／劇情術式先出現；首發可不做玩家卡 | 任何修改規則、隨機、消除身份、復活、封技都需更嚴格 ADR |

**認知 ≠ 感覺 ≠ 夢境**：解讀與記憶 ≠ 感官訊號 ≠ 內在夢中世界。  
**時間 ≠ 因果 ≠ 命運 ≠ 混沌**：時序 ≠ 條件依存 ≠ 可能結果傾向 ≠ 變化幅度。  
**暗影 ≠ 虛無，空間 ≠ 存在，秩序 ≠ 契約**：避免把高概念當成光暗攻擊換色。

## 3. 最少、且彼此獨立的戰鬥層

### 3.1 學科 / Discipline（敘事與識別）
\`ARCANUM\`、\`CHRONOMANCY\` 等主題，只決定圖鑑分類、關鍵字、表現素材與將來*可明示*的角色專長。**沒有直接的傷害倍率或隱藏效果。**

### 3.2 傷害性質 / Damage Kind（現有）
物理／魔法按目前 \`PAtk/PDef\`、\`MAtk/MDef\` 與明示 SP 走各自的流水線。**PHYSICAL 不是元素。** 不新增 \`TRUE_DAMAGE\`、\`MENTAL_DAMAGE\` 等隱藏規則。

### 3.3 HP 傷害共鳴 / Affinity（只有有效 HP Damage）
目前 Lv40 示範候選使用 \`FIRE\`、\`ARCANE\`、\`NEUTRAL\`；已核准的**是逐敵人設定抵抗／弱點，而非這三個是最終全集**。未來元素清單可研究 FIRE、WATER、ICE、WIND、EARTH、LIGHTNING、LIGHT、SHADOW、ARCANE、NEUTRAL；其中除現有示範以外**均未獲核准／不可被程式視為可用**。

\`NONE\` 或欄位缺席代表**本 effect 不做元素 HP 傷害結算**（如 HEAL、Barrier、Focus Ward）；造成無特定共鳴的合法 HP 傷害可用 \`NEUTRAL\`。不可把一張雙學科卡自動當成雙弱點，單張具有多段傷害若未來另行核准，應依各段合法 Effect 的屬性和結算規則，而非混合乘數。

### 3.4 效果語法 / Effect Grammar（**這才是戰鬥結算**）
**優先使用已有能力**：
- HP \`DAMAGE\`／\`HEAL\`
- \`HP_BARRIER\`／\`FOCUS_WARD\`（兩者不互換）
- \`MP_SUPPORT\`
- 每個狀態自己的 \`STATUS_APPLY\` 與 tick/stack/expiry（目前只有個別內容 fixture；非全域萬能異常系統）
- 指向合法 \`CastingInstance\` 的 \`CASTING_DISRUPTION\`
- 合法 \`BREAK\`、\`EXPOSED\`、跨人 \`COMBO\` 等已存在的獨立機制

**不得假設已存在**：任意延長時效的通用效果、隨機重擲、無代價事後撤銷、強制跳過 Boss 行動、分析所有隱藏資訊、精神控制、瞬移座標、任意解除任何 Status。這些要寫新的規格／ADR 才能進入 Domain。

### 3.5 角色與施法權限 / Access & Casting（完全正交）
- 現行 UNIVERSAL / ROLE_TAG / CHARACTER / VARIANT 配牌；職能是專精不是基本魔法的排他限制。
- 依卡為 INSTANT / DUAL 的 Chantless、Full Chant 或 Last Spell 強制 Full；AP/MP/RP、Concentrating、Focus Ward、Casting Stability 不因學科而變。
- 唯一現行戰鬥權威仍是最新 \`docs/combat/README.md\`，含 2026-10-16 已核准**終式成功後真正退場、不能被攻擊／治療／復活，所有在場人員消失或失能會依最新規則判敗**；不可使用 archived 舊文件的 EXHAUSTED 留場設定。
- 現行 Combo 需要真實兩人、真實第二卡、付費和合法目標；不能因「複合學科」字樣讓 Combo 免費觸發。

### 3.6 角色資訊顯示 / UX
一張卡只需要「主要行動效果＋合法目標＋真實成本＋時序／詠唱」，進階註解與世界觀留給圖鑑。大部分卡可以用**一個主要動詞**閱讀，例如「造成傷害」「獲得護盾」「治療」「保護詠唱」「干擾施法」。

## 4. 六至七種玩家視角的動作，非新的引擎分類

建議 UI 使用最多七個易懂的「主要用途」標籤（分類名稱仍可用 Playtest 調整），而不是顯示 24 種學科大徽章：

| 玩家概念 | 可重用的已存在效果 | 主要問題 | 注意 |
|---|---|---|---|
| **攻擊** | DAMAGE、合法 Break | 「打掉多少血／Break？」 | 不是所有攻擊都附元素狀態 |
| **防護** | HP Barrier、Guard／Protect 相鄰展示 | 「如何減傷／誰承受？」 | 基本 Protect 不是自動生成的 SP |
| **恢復** | HEAL、MP_SUPPORT | 「恢復誰、多少？」 | 普通 HEAL 不復活 HP0 |
| **施法支援** | Focus Ward、部分已核准 Buff | 「怎麼保護 Full Chant？」 | Focus Ward 不等於 HP Barrier |
| **干擾** | Casting Disruption、合法 Status | 「打斷哪個有效施法？」 | 不能把 Disruption 當 Break 或 HP 傷害 |
| **戰術情報** | Analyze 的既有情報權限 | 「敵人明示了什麼？」 | Analyze UI/內容可能尚未完成，不得視為已實裝 |
| **連攜／準備** | ComboOpportunity、個別明文條件效果 | 「下一張由誰、何時出？」 | 不新建隨意觸發鏈；第二卡仍需真實付費 |

一張卡的主用途**通常只有一個**；次要效果上限建議 1 個（內容設計 Gate，**不是新增 Domain 強制限制**）。Last Spell 另依現有專用合約，不能因這個 UX 概念弱化其特殊性。

### 4.1 特別避免「24 學科都只放護盾」

如果某學科此階段唯一有意義的玩法只是把現成 Barrier 改名，**不必硬塞一張可玩卡**。可以選：
1. 將其保持為圖鑑／角色研究方向；
2. 讓其出現在既有卡的敘事／美術副標籤，無新戰力；
3. 等到新的合法且可測試的決策產生後，再做有特色的進階卡。

差異主要來自**做什麼、為什麼值得現在做、和誰搭配以及付出什麼代價**，不是只來自色彩或特效。

## 5. 概念難度 ≠ 卡牌強度 ≠ 玩家開發成本

推薦把「學問多深」與「玩家首次遇見時要學多少」分開：

| 導入節點（非等級／稀有度硬規則） | 適合內容 | 合格例子 | 不合格例子 |
|---|---|---|---|
| **P0：現有 Demo** | 現有 Fire/Arcane/Heal/Barrier 等少量技能；不新增 Domain | U01、U02、U03、U05 與 A01 等現有候選（具體標籤仍須核對內容） | 一次開 24 個屬性抗性 |
| **P1：擴充可玩組合** | 用既有機制做新身份、合理 AP/MP 取捨；明示雙人 Combo | 特定角色可選兩種戰術路線：爆發 vs 護唱 | 無限支援、不扣 AP 的額外 Combo |
| **P2：少量新機制** | 每次只引入 1 種真正有獨特抉擇的有限效果 | 有目標、有期限且可測試的預約觸發（需新 ADR） | 直接變更早已結算的回合 |
| **P3：劇情／禁忌學理** | 命運、虛無、存在、秩序、混沌的世界觀展開；可有限制地作 Boss 演出 | 非戰鬥敘事的夢境實驗、命運研究 | 玩家卡一按就取消敵人存在而無反制 |

**新術式是否稀有／高階，不表示傷害必然比較大。** 任何要進行戰鬥結算的時間／命運／因果等效果，先寫獨立 ADR 並驗證 Replay、合法目標、時序與 UI 可理解性；不得將 P3 直譯成新角色等級上限或卡牌稀有度。

## 6. 複合魔法：採「作者設計的組合」而非 Magicka 式自由混搭

區分兩種完全不同的概念：

1. **複合學科（Lore Blend）**：一張卡在敘事上來自兩個研究領域，如「奧術＋雷電」。這只是描述，不產生第二次付費、額外傷害或免費連攜。
2. **角色連攜（Combat Combo）**：兩名不同角色各自持有及真正施放合法 SP，經 Setup → 合法 Finisher，仍需按現行規則支付第二張卡成本。

**不**建立「任意 A 學科 × 任意 B 學科」的全面配對表；24×23÷2=276 種無序兩兩組合（還沒算複數學科和詠唱模式），會造成難以教學與測試的組合爆炸。僅挑少量清楚、有故事／戰術價值的配方逐張手工設計。

### 6.1 對應現有三角隊伍

| 角色定位 | 建議學科呈現（世界觀，不改配牌資格） | 戰鬥身份仍由什麼決定 |
|---|---|---|
| 蓮／劍士 | 劍技主軸＋ UNIVERSAL 基礎奧術；「魔法學科」不替代物理系 | 物理、Break、Combo Setup／Protect |
| 朱音／爆發法師 | 火、奧術（未來可雷／時序進階）；並非每張火卡自帶燃燒 | 高 MP 爆發、Dual／Full Chant、Casting Disruption |
| 紬／恢復支援 | 生命、光輝／靈魂的敘事映射；光輝 ≠ 自動 HEAL | HEAL、Barrier、Focus Ward、支援與進攻卡 |

不用把所有學科平均分配給三人，也不用為了 24 系改三人的 12-card starter deck。新 Variant／學派專精依未來正式授權辦理。

## 7. 四張示意卡：玩家應如何閱讀（絕非新增卡片）

| 卡片示意／學科 | 玩家看到的主說明 | 合法性／技術備註 |
|---|---|---|
| 奧術彈／奧術 | 「對單一敵人造成魔法傷害；完整詠唱威力較高、延後釋放。」 | 現有 U01；具體 AP/MP、瞬發/Full 倍率及 ARCANE 抗性不動 |
| 生命織補／生命 | 「回復隊友生命值；不能復活已失能者。」 | 現有 HEAL 範疇；範例名可能與既有 T06 重合，非另增一張 |
| 閃雷干擾／雷＋奧術 | 「干擾一個正在施法的敵人。」 | 只在有效敵方 CastingInstance 合法；沿用 A05 所需基礎 **Casting Disruption** 的語意，不重標現有 A05 元素 |
| 應果之印／因果 | 「下一次指定合法行動完成後，獲得防護。」 | **UNIMPLEMENTABLE WITHOUT ADR**；要定義費用、到期、觸發、同時事件及 Replay，未核准前不可列在遊戲正式卡池 |

卡片畫面順序建議：**Cost / Target / Immediate or Full Chant / Primary Effect / Optional Condition / Lore Icon**。不讓學科名挤掉合法性資訊。

## 8. 內容與工程的資料合約：這次只提概念，不定新 schema

建議未來**附加的敘事 Metadata**（不是直接替換現有 CardDefinition JSON）：

\`\`\`json
{
  "card_definition_id": "U01",
  "lore": {
    "primary_discipline": "ARCANUM",
    "secondary_disciplines": []
  },
  "combat_reference": {
    "use_existing_effect_schema": true,
    "legacy_damage_affinity": "ARCANE",
    "mechanics_from_existing_card": true
  },
  "ux_primary_verb": "DAMAGE"
}
\`\`\`

- 此 JSON 是**語義範例，不是可直接供 Godot 讀取的正式 schema**；尤其不要讓 UI metadata 成為第二個成本或傷害真實來源。
- \`lore\` 可長期獨立於 gameplay 邏輯；正式若導入，透過完整設計／測試／Migration Gate。
- \`legacy_damage_affinity\` 只展示已有字段概念，是否有該精確字段須查現有實作；不能把名稱當成確定的 API。
- \`CARD:U01\`、\`ROLE_TAG:ARCANE\`、\`AFFINITY:ARCANE\` 三個命名空間必須清楚區分；不可用一個 \`magic_type\` 字串讓它們混成同一種概念。
- 名稱、標籤、Tooltip 需 zh_TW 與 en，顏色不可為唯一區別方式。
- 動畫 / FX / i18n 都是 Presentation，不能觸發兩次 Domain effect；後設知識的更動不應使 Replay／CardInstanceID 改變。

## 9. 新卡「值得存在嗎？」的品質門檻（建議）

每張學科新卡的設計審核至少回答：

1. **可讀性**：沒看圖鑑，玩家能說出此次會做什麼／目標是誰／何時生效？
2. **決策價值**：比同成本已存在 SP 多出哪種實際可考慮的取捨，而非只換色？
3. **角色身份**：是否破壞蓮的 Break 專長、朱音爆發、紬治療等角色間互補？
4. **反制性**：敵方意圖、合法目標、保護／詠唱／Reaction 是否提供合理應對，而非不可逆的隱藏秒殺？
5. **既有規則相容性**：AP/MP/RP、抽牌 12／4／8、詠唱、Last Spell、Exhausted 退場、Break／Exposed 與 Combo 不被暗改？
6. **可重播性**：同 seed/state/commands 應有相同 result/event tape/state hash；每項新增 RNG 或觸發事件都須穩定次序？
7. **雙語 UI**：1280×720 可顯示主效果和主要限制，細節另外進 Tooltip？

**任何關鍵條件不合格，維持候選，不製作該卡**。不要為了達成 24 學科全覆蓋而降低標準。建議從既有兩張卡互相比較以量出新卡是否只有換皮。

### 9.1 分階段的證據 Gate

- **Gate A / 本輪**：經證據研究，提出新版分類和設計原則，僅文檔；不宣稱所有細節已獲使用者核准。
- **Gate B / 校訂**：選少量已有 Domain primitive 且確有身份差異的卡，形成逐卡 design record（目的、成本候選、目標、數據來源、反制、事件）。
- **Gate C / 玩家可讀性**：實際卡牌展示（繁中、英文）、無圖鑑理解測試、長字串測試；必要時調整視覺，而非變更核心規則。
- **Gate D / 新機制 ADR**：對時間／因果／命運／感官異常等一次只申請一個高層概念，必須有完整 event trace、target policies、回放與失效證據。
- **Gate E / 實作**：獨立 Agent 分支，版本化 content data，測試 old fixture 和新內容兩組；經核准才合併 master。

## 10. 跨文件相容性與重要警告

- **本提案不更動已確認的 P2-D09**：敵人逐個配置元素弱點／抗性；仍無全域固定屬性相剋表。
- **不要把精神系當一種自動忽略護盾的 HP damage kind。** 如果只有感官 Debuff，必須先批准其 Status 及對 Boss 的合法性和抵抗機制。
- **不要用「空間」偷加位置欄位**，不要用「時間」偷加回合，不能用「存在」偷加 Revive。若表達不足，可以把它先做成不具有戰鬥效果的故事事件。
- **避免誘導錯誤的「魔法越高級越強」**：術式概念的抽象層次不等於技能的免費 AP/MP、更高命中率或更大傷害。
- 新世界觀圖鑑可擴充，但現有 Lv40 角色數值與已核准的戰鬥互動**維持不變**。
- 每個新的可見特效／魔法卡都要確認**真實戰鬥投影**；不能以圖中彩色特效推測元素倍率。

## 11. 尚待使用者確認的三項重大設計選擇

1. **是否核准「24 個領域作世界觀標籤，但不必每科首發可玩」？** 我推薦「是」，這是本次最重要的新提案。
2. **首發分期是否採：現有 Lv40 既有魔法為核心 → 少量擴充可玩學科 → 時間／空間／因果／命運等新機制逐一 ADR？** 我推薦「是」，不用為了演示而增加一堆不成熟卡片。
3. **奧術三個命名空間要不要保持這次的清晰語義？** \`ARCANUM\` 是學科、\`ARCANE\` 仍為目前的共鳴標籤、\`ROLE_TAG:ARCANE\` 仍為現有角色資格；我推薦保留舊 ID，僅以文件標明其區別。

> 此文件經過 GitHub 可重現的設計評審後提交為 **proposal-only**；未執行 Godot、未修改資料 schema、未宣稱任何新增卡牌或法術已可玩。
