# Spec Guardian：規格准入與防漂移

適用：所有七個 Skills。此檔是工程方法，不能取代遊戲正式規格。

## 使用者裁決（2026-10-15）

一切以新版已核准規則為主。與新版衝突的舊規則及舊測試 oracle 一律 `SUPERSEDED_DO_NOT_USE`；只可作為歷史追溯資料，不得用來實作、阻擋新版合法行為或宣稱新版驗收成功。未衝突的既有功能仍依當前有效契約維護。新版未定案項目仍是 TBD，不能以舊版填補。沒有刪除歷史紀錄或重建專案的授權。

## 進入既有專案

1. 確認工作區及 remote；讀取適用的上層與子目錄 `AGENTS.md`、工作樹差異、branch、commit、`project.godot`、addons、現有測試及 CI。保留使用者未提交修改。
2. 執行 `Godot --version`，記錄完整字串與 binary 路徑。`config/features=4.7` 不能證明 patch=4.7.2；現有 CI 固定版本也不能證明本機版本。優先 4.7.2.stable；版本不符先報相容性限制，不自行升降版。
3. 優先找 `docs/combat/COMBAT_RULES_BASELINE_V0_8.md`。不存在時搜尋 Baseline、批准決策、ADR、索引與交接，不建立假的同名規格。
4. Arbitrium Nexus 已檢查的索引為 `docs/combat/00_README_COMBAT_RULES_BASELINE_V0_8.md`；讀 01、涉及模組、18/19、20§7、21，再讀22實作契約及23計畫。重新核對當前版本，不能永久信任套件中的快照。
5. 來源優先序依明示 supersession／核准紀錄判定：最新 USER_APPROVED > 尚有效的 P1/P2/M APPROVED > 授權的 DELEGATED_DEFAULT > PROVISIONAL／CONFIGURABLE。歷史／已取代內容無裁決效力。不是檔名數字或修改日期較新就自動優先。

## 每項任務的規格影響表

記錄 `requirement_id | source file § / decision ID | approval status | current behavior | requested behavior | affected files | oracle | evidence status`。三人、個人牌組／手牌、抽補／換牌、AP、Mana/MP、RP、Reaction、Last Spell、傷害／狀態時序、AI、勝敗、養成、探索與存檔語意皆可能涉及規則。

需求若只是已核准規則的缺陷修正，按授權直接修正，無須再次詢問。若要求變更已核准規則，或現有有效來源彼此矛盾，列出衝突原文位置、影響、最小待決問題；只暫停依賴該問題的部分，其餘可獨立工作繼續。不以 feature flag 將未核准玩法默默設為正式預設。

## 規格遷移

先識別舊 assertion 的真正規則來源；與新版衝突者註明 superseded requirement、替代 requirement 和遷移原因，建立新版正例／負例／邊界 oracle，再調整實作。舊測試通過僅能證明舊行為仍存在；若與新版衝突就是待修缺陷，不能作為綠燈 Gate。不能為了過測試弱化新版 assertion。必要時將歷史案例隔離在不參與有效驗收的 archival 群組。

## 交付 Gate

- 依 repo 的22契約，同一測試群組首次執行加兩次修正重跑，最多三次；第三次失敗停止該里程碑並交付三次證據，不能改名重置計數。
- 各需求有 Source → code → test → evidence。區分 SPEC_ONLY、TEST_WRITTEN、IMPLEMENTED_NOT_VERIFIED、VERIFIED、BLOCKED；快照與過往報告不是本輪執行證據。
- 每階段最小改動；只有全部該階段必要 Gate 真實通過才標 DONE。交付繁體中文工程 Note；檔名、識別字、commit 使用英文。
