# P4 — Card catalogue / localization work package

## 來源、授權與分工

Repository: https://github.com/KuroNekoLi/arbitrium-nexus-godot

- 本工作分支：`handoff/p4-card-localization-chat-20261015`。
- 共同基底：`977a289654e1470bcda83c6c25c14d4cda4c86ab`。請記錄本分支實際 HEAD 再施工。
- 另一位 AI 負責 `handoff/p4-lv40-chat-20261015` 的 Domain；派工時遠端已到 `8b25d7e998a78ff12872f33862d46487a3e0357f`，本分支刻意不合併其施工中改動。
- 使用者已授權另開此分支交給 GPT 聊天／其他 AI 做可並行工作。本次授權是實作翻譯載入與卡面資料、測試，不是只寫計畫。
- 所有玩法／數值維持原權威與 BALANCE_PROVISIONAL 狀態。P4.4尚未正式驗收；本包可以可逆準備，但不能宣稱P4.5或整個P4完成。

主控 Skill 已選擇 UIUX 的雙語／資料顯示工作，避免改動另一位AI的Domain範圍。接手者先完整讀自己的適用Skill與必要references。

## 最小閱讀集合

1. 根 `AGENTS.md`，orchestrator `SKILL.md` / `references/SPEC_GUARDIAN.md`。
2. `.codex/skills/godot-card-rpg-uiux-engineer/SKILL.md` 與其UIUX reference；改GDScript時讀architecture Skill及必要規範，寫測試時讀QA Skill。
3. `docs/combat/COMBAT_SPEC_INDEX.md`、26（卡牌／牌組）、27（Boss名稱／意圖）、29（候選數值的Provisional狀態）、22（工程驗收／重跑上限）；來源不清楚列出，不猜。
4. `docs/ui/02_ARCHITECTURE_DATA_INTERACTION.md` 的 CardAppearance／i18n 契約，及UI01/05相關驗收。
5. 下述可寫檔與只讀直接依存；不必重讀整段聊天或整個美術調研。

## 必須實作

### L1. 載入兩份翻譯表，保留現有API

修改 `scripts/battle/presentation/battle_translations.gd`。

- 現有 `install() -> void` 只讀 `battle_strings.csv`，Lv40卡片keys尚未載入。
- 同時載入 `resources/ui/battle_strings.csv` 和 `resources/ui/lv40_strings.csv`，保留原battle keys與 `en` / `zh_TW`。
- 以locale合併成明確的Translation內容，不靠同locale多個資源的註冊順序碰運氣；重複install不得累加重複資源。
- 欄位／重複key／空key／缺檔／空翻譯須有可測的明確失敗契約；先驗證所有catalogue，再註冊，避免第二檔錯誤卻留下半套全域翻譯或 falsely installed=true。
- 合法的逗號、引號、Unicode與換行使用CSV parser處理，勿以split(',')代替。
- 不改Locale選擇或 `TranslationServer` 之外的遊戲狀態；安裝不擅自切回繁中。需新增可測helper時，回填精確簽名與責任。

### L2. 完成卡片／角色／Boss的雙語資料

修改 `resources/ui/lv40_strings.csv`，必要時修正已存在的26個Lv40 `resources/ui/appearances/*.tres` 的翻譯key。

- 26種ID：U01～U05、R01/R02/R03/R05/R06/R07/R08、A01～A07、T01/T03/T04/T05/T06/T09/T10。不是36種；36是三人12SP實例總數。不要再新增重複卡面。
- 每種保留／完成 `LV40_<ID>_NAME` 和 `LV40_<ID>_DESC`，兩語皆可讀。名稱以有效文件為準；原CSV是暫稿，不代表文案已核准。發現名稱衝突列出來源，不自行改Domain ID或內容。
- 描述須明確區分敵／友／自身、單體／全體、瞬發／完整詠唱、生命Barrier／Focus Ward、治療／復活、普攻／特殊Reaction。不能保證Domain未保證的結果。
- 本輪卡面描述不硬寫可能漂移的Provisional傷害、費用、回合數；費用由權威config顯示。若需動態數值模板，列出所需Domain資料供Codex整合，不另算damage。
- 補足既有config公開的名稱keys，保持拼字不變：`actor.ren.name`、`actor.akane.name`、`actor.tsumugi.name`、`actor.arcane_sentry.name`；`intent.b01.name`～`intent.b11.name`。角色暫定顯示名見config（朝霧蓮、九條朱音、白石紬、秘紋守衛・零式），請與正式內容文檔交叉核對。
- Last Spell的名稱若有已公開key則沿用；若沒有，可新增**僅翻譯表**key，於回填列為尚待Caller使用，不假稱UI已整合。
- 原Artwork／accent不更換、不下載／生成素材、不改CardAppearance schema，不把prototype的Kleya/Nova/Yora規則套入Lv40。

### L3. 新增可執行資料／載入測試

新增 `tests/test_p4_localization.gd`，沿用SceneTree runner，唯一assertion IDs例如 `P4-L10N-*`，最後輸出executed/passed/failed計數與正確exit。

至少涵蓋：原battle keys兩語仍存在；26卡名／描述不回傳rawkey；actor/Boss/B01～B11 keys；appearance ID／key與CSV對應；重複install不增加Translation；呼叫安裝不改當前locale；切換兩語可取得正確內容；CSV重複／空／缺檔失敗不留下半註冊狀態。測試替身需標明，不能把schema檢查說成實際戰鬥或視覺驗收。

測試資料可新增於 `tests/fixtures/localization/`，不要修改現有Domain fixtures。不要以 `TranslationServer.clear()` 清掉整個遊戲翻譯；如測試需隔離，只移除自己註冊資源並還原自己更動的locale。Godot最多三次同群組執行，失敗保留log；沒有工具則交付test code + NOT_EXECUTED。

## 寫入範圍（白名單）

| Path | 允許工作 |
|---|---|
| scripts/battle/presentation/battle_translations.gd | 雙catalogue載入／驗證／冪等 |
| resources/ui/lv40_strings.csv | 完整雙語文案與公開名稱keys |
| resources/ui/appearances/[URAT][0-9][0-9].tres | 只修已存在26份的name_key/description_key，不換圖片／造新ID |
| tests/test_p4_localization.gd | 新runner |
| tests/fixtures/localization/ | 新測試資料 |
| docs/verification/ui/P4_LOCALIZATION_ENGINEERING_NOTE.md | 新工程Note |
| docs/handoff/CODEX_RETURN_LOCALIZATION.md | 新回填檔 |
| outputs/p4_logs/localization/ | 只新增實際測試log，不覆蓋其他套件 |

禁止改：`scripts/domain/**`、`resources/combat/**`、其他tests／fixtures、BattleController／CommandFactory／Screen／HUD／Adapter／CardView、CI、project.godot、battle_strings.csv、RTM、原交接／原回填文件、任何美術素材。需要跨scope改動就寫出caller patch建議，不擅自套用。

## 交付／回填／Git

用 `docs/handoff/CODEX_RETURN_LOCALIZATION_TEMPLATE.md` 建立回填，附精確diff／完整新檔。工程Note解釋Translation／locale、資料與UI／Domain邊界、冪等／原子安裝、Android resources／Locale／repository mapping、測試結果與面試追問。

有Git工具就在**本分支**commit／push，英文commit message；不push master、不force、不改另一分支。不需要建立新專案／PR。無法存取repo就要求使用者提供該分支程式與規格附件，再回傳patch，不虛構讀取結果。

本包不要求真的操作Boss，因此適合GPT聊天產出程式與資料，但沒有Godot就不能聲稱測試PASS或視覺合格。Codex回來會檢查diff、實際執行runner／回歸，並在Domain完成且P4.4放行後接到正式Lv40 UI。不要把研究/提案升成驗收。
