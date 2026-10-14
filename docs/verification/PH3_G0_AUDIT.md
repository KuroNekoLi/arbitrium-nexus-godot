# G0 — Arbitrium Nexus 實際 Godot 專案環境與規格差異稽核

> 日期：2026-10-14。狀態：**STATIC AUDIT COMPLETE / EXECUTION GATE NOT VERIFIED**。稽核對象：`KuroNekoLi/arbitrium-nexus-godot` 的 `master`，稽核時 HEAD `c9678782b818f825b85561313bd142130c330fdf`。**沒有執行 Godot CLI、headless tests、UI 自動化或 CI**；本報告是程式碼檢視與需求對照，所有執行結果均 `NOT_EXECUTED`。沒有修改任何 Godot 執行檔、資源或場景。

## 1. 範圍、權威與驗收口徑

- 正式來源：`docs/COMBAT_RULES_V1.md` 作入口，`docs/combat/00`–`24` 由 ChatGPT Library 匯入。最新 USER_APPROVED > APPROVED > DELEGATED_DEFAULT > PROVISIONAL > SUPERSEDED。
- 不將舊 `README.md` 稱「M0–M5 MVP 已完成」的原型里程碑，誤算為**新 Phase 3 M1–M5** 的驗收完成。
- `docs/combat/24_PHASE3_G0_M1_EXECUTION_REPORT.md` 內舊 M1 的「14/14 CI PASS」來源是 **`KuroNekoLi/Astraea-Academy`**，不可移用到本 `arbitrium-nexus-godot`。
- 具體判讀：`PRESENT_LEGACY`=已有功能但規則不同；`PARTIAL`=存在部分構件；`MISSING`=檢查的可見實作中無對應機制；`NOT_VERIFIED`=可能存在但未有執行證據。完整逐條追溯見 [requirements_traceability.md](requirements_traceability.md)。

## 2. 專案環境盤點

| 欄位 | 實際觀察 | 判定 |
|---|---|---|
| 專案 | `KuroNekoLi/arbitrium-nexus-godot`, branch `master` | CONFIRMED |
| 稽核程式基準 HEAD | `c9678782b818f825b85561313bd142130c330fdf` | CONFIRMED |
| Godot project file | `project.godot` 位於 repository 根目錄 | PRESENT |
| 引擎設定 | `config/features=PackedStringArray("4.7")`；`README.md` 概稱 4.x | **宣告 feature 4.7，實際執行二進位及版本未驗證** |
| 主場景 | `res://scenes/main.tscn` | CONFIGURED；未執行 |
| Render / view | 1280×720、`gl_compatibility` | CONFIGURED |
| Domain 現況 | `scripts/domain/battle_state.gd`, `card_data.gd`, `card_catalog.gd`, `deck_profile_store.gd` | LEGACY MVP |
| UI | `scripts/main.gd`, `scripts/ui/`，有可讀互動、牌面、視覺素材 | PRESENT，未實機驗證 |
| 測試 | `tests/test_battle_state.gd`, `test_combat_ui.gd`, `test_deck_builder.gd`, `test_turn_flow.gd` | TEST SCRIPTS PRESENT；NOT_EXECUTED |
| 截圖腳本 | `tests/capture_combat_screenshots.gd`、`capture_deck_builder.gd` | PRESENT；NOT_EXECUTED |
| CI | `.github/workflows/` 路徑查詢為 GitHub 404 | **未發現 repository 內的 Actions workflow** |
| CLI | 本次無可驗證的 Godot binary/version/exit stdout | NOT_VERIFIED |
| Clean tree | 遠端 contents API 不等同本機 `git status --short` | NOT_VERIFIED；不可宣稱本機乾淨 |

## 3. 關鍵現存衝突（實際 source evidence）

### G0-C01 — 牌組與存檔：8 張、不重複、手牌 6

- `scripts/domain/battle_state.gd`：`MAX_HAND = 6`, `DRAW_TARGET = 4`；角色開戰抽4後，測試期望牌庫剩4，證明原型採每角8卡。
- `scripts/domain/card_catalog.gd`：`default_deck_ids()` 固定回傳8個 card id。存在12個**卡牌定義**，不等於每角裝12張。
- `scripts/domain/deck_profile_store.gd`：`is_valid_profile()` 拒絕非8張（`ids.size()!=8`），並拒絕任何重複 ID；存檔 `version=1`。
- `tests/test_battle_state.gd`, `tests/test_deck_builder.gd` 目前正向斷言 **8-card**，屬與新版規格衝突的測試 oracle，應保留為歷史而新建新版斷言。
- **新規格**：各角色12張 SP、起手及玩家回合補至4、手牌上限8；同名重複上限仍依 ADR/卡牌資格規範，不可把舊「一律禁止同卡」直接搬進新版。存檔需有版本化相容/遷移策略，不可破壞舊用戶資料。

### G0-C02 — 共用 AP 被個人能量 + 每回合兩次硬限取代

- `battle_state.gd`：`MAX_ORDINARY_PLAYS = 2`；`play_card()` 的 phase/出牌次數拒絕；`heroes[].mana=max_mana=3`；未有共享 `team_ap`，無 `RP` 或 `APDebt` 正式契約。
- `resolve_enemy_phase()` 每回合 `mana=max_mana`，與新規格「個別 MP 跨回合、非自然全滿」相反。
- `analysis += card.analysis_gain` 到3歸零，與免費獨立 `Analyze` 共通指令（全隊每戰2次）不符。
- **新規格**：共享 BaseAP=6、不以2張為上限，APDebt/Overload 依已核准文件及候選配置區分；每人獨立 MP、正常普攻當回合僅首次符合 MP 回復；AP→RP、在敵方階段可花，期限後清零。

### G0-C03 — Reaction 自動超時與單次一鍵打斷

- `scripts/main.gd`：`REACTION_WINDOW_SECONDS = 1.5`，`_resolve_after_reaction_window()` 以 `create_timer()` 自動執行 Boss 動作。
- `tests/test_turn_flow.gd` 斷言「短暫窗口結束後 Boss 自動行動」，是**違反 CORE-04** 的舊測試。
- `battle_state.gd`：`interrupt_available` 單一 bool，`play_reaction()` 成功便整次 Boss Intent 取消；沒隊伍 RP、基本 Guard/Protect、每人每窗口一次、Queue/Confirm/JIT、單體轉向／防護／失效跳過。
- **新規格**：合法反應只能玩家明示 Confirm/Pass 才繼續；Smart/Always Ask/Quick 不設時間強制 auto-pass。多角色 Queue、自訂順序、提交時驗證、逐項 JIT；先序取消攻擊時，失效後序反應不扣 RP/MP、不棄牌、不記使用次數。Guard1RP；Protect2RP、可保護單體物理／魔法、完整轉移 on-hit。

### G0-C04 — Boss Stability 與傷害規則混搭

- `battle_state.gd`：`boss_stability` 被攻擊減少，歸零後下一傷1.5倍再恢復20；屬舊弱點節點/Break 原型，不是「每個 CastingInstance 的 Casting Stability + 敵本體 Break Gauge」獨立模型。
- 固定 `BOSS_MAX_HP=300`, `BOSS_MAX_STABILITY=50`, 兩意圖輪替、傷害 24/12 皆屬**原型 fixture**，不是新版 Canon 平衡設定。
- 現階段未找到合法 Hit/Evasion、Damage Pipeline（Protect redirect→hit→crit/def/resistance→Guard→Barrier→final HP）、Targeting Tags、Focus Ward 與 CastingInstance 分離的實作。

### G0-C05 — 引擎邏輯由 UI 動畫時序控制

- `scripts/main.gd` 目前含拖曳／動畫時序處理和 `battle.play_card`、`battle.resolve_enemy_phase` 操作；`tests/test_combat_ui.gd` 斷言卡牌飛行/角色衝刺過程 **Boss HP 不先降低**，直到命中特效後才改 HP。
- 新規格要求 Domain 為權威：命令被核准時應依確定性事件順序處理，UI 只播放已提交事件、不可因畫面 FPS、動畫長短或拖曳回呼改變遊戲正式數值。
- **保留素材與可重用動畫、場景/拖曳 UI**，將正式 damage/queue/replay 交給 domain reducer；舊測試需轉為視覺狀態與 domain 事件界線兩類測試。

### G0-C06 — 存在舊 Scene/UI/Deck Builder 成果，不可誤刪

- `scenes/main.tscn`, `scripts/ui/card_view.gd`, `scripts/ui/deck_builder.gd`、角色立繪與音效已是有價值的 UI 原型，不應因戰鬥規則更新而整批刪除。
- 測試檔中對 UI 視覺元素（例如 Frame、卡牌拖曳）之驗證可按新版架構調整後保留。舊「8卡」「兩次出牌」「1.5秒倒數」斷言不可作為新版成功標準。

## 4. 既有測試與結果

| 腳本 | 舊版意圖 | 新規格適用性 | 本次執行 |
|---|---|---|---|
| `tests/test_battle_state.gd` | 起手/8卡剩4、最多2出牌、固定意圖 | 其中多項 **SUPERSEDED_ORACLE** | NOT_EXECUTED |
| `tests/test_turn_flow.gd` | 1.5秒 reaction timeout、自動 Boss 行動 | **CORE-04 CONFLICT**；應反轉正負例 | NOT_EXECUTED |
| `tests/test_deck_builder.gd` | 8-card 編輯/存載/匯出 | 可重用 IO 骨架，Deck Validator 必須重做 | NOT_EXECUTED |
| `tests/test_combat_ui.gd` | 拖曳動畫、HP 在 impact 後才結算 | 素材測試可保留；HP 時序與 Domain 決議衝突 | NOT_EXECUTED |
| `tests/capture_* ` | 截圖輸出 | 可保留做視覺回歸 | NOT_EXECUTED |

沒有本次 terminal stdout、Godot runtime version、exit code 或 Actions run URL。**即使所有舊測試曾通過，也只證明舊原型規格；不是新 Phase 1–2 spec 的驗收。**

## 5. G0 Gate 結論：STATIC AUDIT COMPLETE / ENVIRONMENT EXECUTION BLOCKED

**已具備：** 正確 Repo、branch、HEAD、Godot `project.godot`、domain/UI/testing 入門定位、明確的重大規格衝突、遷移路徑。  
**缺少：** 實測 Godot binary 4.x 版本、可用 CI（目前 workflow 目錄不存在）、test runner 之故意失敗非0 probe、CI可重跑證據、本 repo 的完整 Phase1–2 RTM test execution。  
因此 **G0 不應標 `VERIFIED`**。下一步先補最小 headless CI bootstrap + 可重現 runner（視 Phase3 M1.4 工作包），在實際環境跑原版 smoke 作 legacy baseline，再開始 M1 domain 遷移；舊版測試預期需標 `LEGACY_EXPECTED`，不可改 assert 為放水。

## 6. 交付後的精準工作順序

1. **G0.1**：確認 Godot binary 實際 `--version`、repo root `project.godot` 是否解析成功；建立 Actions headless job + negative exit probe + 基礎 smoke。若 CI 無法獲得已確認相容的 4.7 runtime，先標 BLOCKED_ENVIRONMENT。
2. **G0.2**：以 [RTM](requirements_traceability.md) 將 P1/P2/M/PRE3/CORE 規格逐條連結真正程式與測試，依類別 LEGACY_CONFLICT/MISSING/PARTIAL 估工作量，避免一次改爆 Godot。
3. **M1**：保留 UI 資產與 deck editor 可用部分；在 Domain Engine 新增明確 `BattleState`/Command/Result/Events、原子 Validation、明確 RNG State/replay/hash；未實作的 M2～M5 Command 回 `FEATURE_NOT_IMPLEMENTED`。
4. **M2**：共享 AP／APDebt／獨立 MP／RP，12-card Zones、hand max8、換牌與舊 profile 遷移；先跑 domain headless 契約測試。
5. **M3**：合法敵方 Window、多角 Queue、Guard/Protect/Cancel/Skip、移除 timeout；不讓 UI 計時器驅動 Domain。
6. **M4**：Chantless/Full/Concentration/CastingInstance/LastSpell forced invalidation。
7. **M5**：Damage/Hit/Status/Break/Exposed/Combo/Outcome、跨整場 deterministic replay。

**停損界線：** 在 headless runner 實測可重現以前，不宣稱 Phase3 M1/2/3/4/5 VERIFIED。這份報告只授權工程稽核結案，不代表允許把 Provisional 係數改成新 Canon。
