# Combat Phase 4 — Godot Presentation / Playable Integration Handoff

> **PHASE 4 IMPLEMENTATION PLAN / NOT EXECUTED**（2026-10-15）。Phase 3 M5.5 已完成 **Headless Battle Domain** Gate（1,238/1,238，100 fixed seeds + Full Replay），[master 合併](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/9c8b14b873047ca181a229cfaab5d2351541ceab)、[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741) **Success（正式合併後 master 驗收）**。**本文件只規劃 Phase 4**，沒有下載資源、沒有 Scene/HUD/i18n 實作、沒有真人可玩 Gate。

## 1. 執行前讀取

根目錄 [AGENTS](../../AGENTS.md) → [M5 Engine Handoff](../verification/PH3_M5_HANDOFF.md) → [M5.5 Acceptance Report](../verification/PH3_M5_5_ACCEPTANCE_REPORT.md) → [本 Combat 索引](COMBAT_SPEC_INDEX.md) → 00/01/18/19/20/21 最新 USER_APPROVED → [Implementation Contract](COMBAT_IMPLEMENTATION_CONTRACT.md) → [Open Issues](COMBAT_OPEN_ISSUES.md) → [M5 工程](../verification/PH3_M5_EXECUTION_PLAN.md)、最新驗收筆記／CI → [UI 入口](../ui/README.md) 及 `.codex/skills/godot-...` 的實際現有工具技能。

先執行 read-only audit：master SHA、Godot CLI/version、project.godot、Scene tree、UI 圖像／正式設計、CardDefinition、Command/Reducer、最新 Test IDs、固定 Replay、素材授權與雙語資源。不得從舊 `31` 推斷實作位置。

## 2. 工作分層（M5.5 Headless 已通過，開始 Phase 4 仍需逐項驗收）

| Gate | 最小工作 | 必須完成才能宣稱通過 |
|---|---|---|
| P4.1 Scene shell | 橫向 2.5D Battle Scene、三角與 Boss 區、HUD 插槽；只顯示來自 fixture/Domain 的 Snapshot | Godot Scene 可匯入；實際 screenshot 視覺檢查；不暗中修改 Domain |
| P4.2 HUD & localization | 手機/桌面可用 4-card draw / hand UI（依規最大8）、角色頭像切換、AP/MP/HP、已宣告 Boss Intent、Reaction confirm/pass；繁中/英文可切換 | 無硬編碼顯示字串；長文與比例 QA；可用鍵鼠／觸控 |
| P4.3 **Vertical slice** | 玩家點卡 → Controller 轉合法 Command → M5 reducer → Event queue → HP/卡牌/AP/MP 更新＋動畫 | 真的扣 Boss HP，Hand/Discard 守恆；固定 tape/hash 等於 Headless；錯誤命令不改 state |
| P4.4 Gameplay feedback | 詠唱、Interrupt、Protect/Guard、Break/Exposed/Combo/Last Spell、VFX/音效/可讀性 | UI 僅呈現 Domain 結果；確認時序與無 timeout / animation-driven outcome |
| P4.5 Full playable encounter | 正式使用 26 起始 12 SP×3、27 的 Lv40 Boss 候選，一場手動從開場到 VICTORY/DEFEAT | 完成後與 M5.5 headless replay/parity、完整風險盤點；不能靠測試專用秒殺卡 |
| P4.6 Balance & UX | 100 固定 seeds + 多策略和真人 Playtest + 多解析度 UI | 平衡僅可標 `BALANCE_ACCEPTED` 當使用者採納內容值；未批准則仍 `PROVISIONAL` |

## 3. Phase 4 驗收可沿用的 Golden Oracle（不可把 Fixture 當正式角色平衡）

- [M5.5 Acceptance Report](../verification/PH3_M5_5_ACCEPTANCE_REPORT.md) 的 `seed=20261014`：49 筆已接受 Command、5 輪、結局 `VICTORY`；Event SHA256 `588cb04d22911bd9d4b1a4d006eb5aa41fe2b7fa90a02a4fe879086e2928dfb1`，Final State SHA256 `c510227726170562d623b3737226439f3dffa0e4cea1ee9dfc4150117671acdd`。
- Controller 只有在**相同初始狀態、同樣 ContentConfig 與同一完整 Command Tape** 下才可以直接對照該 hash；玩家互動自行選不同命令不應被要求產生相同 digest。
- 測試策略的 100/100 場 VICTORY **不是** Boss 難度／真人操作／Lv40 正式卡牌配置的平衡證明。P4.5 需另用實際要交付的卡牌／敵人與完整 Scene 做 parity 驗證。
- M5.5 由 `m5_domain_resolver.gd` 真正結算，`tests/fixtures/m5_full_battle_driver.gd` **只能作測試政策／CommandTape 參考，不能當玩家輸入控制器或另建第二套 Domain**。

## 4. 核心資料流（不可改寫）

```text
Scene input
  → BattleController (command_id, expected_event_seq, actor/card/target)
  → M5 Domain single reducer (M1 State, M2 payment, M3 Reaction, M4 Casting)
  → ordered events + final BattleState (authoritative)
  → Presenter/HUD + non-authoritative animation queue
```

繼承 M1 RNG/Replay 與 event hashing；不自行加第二套 BattleState、Boss 決策、卡區或勝敗判斷。每次新增 Command 必須先查實際 reducer 所支援的 schema；沒有的功能以 feature flag 或 `NOT_IMPLEMENTED` 顯示，禁止用 UI 假資料當完整版。

## 5. Codex 可直接使用的任務

> 請在 `KuroNekoLi/arbitrium-nexus-godot` 延續 Phase 4 P4.1～P4.3，先只完成最小垂直切片：三人/Boss Battle Scene + HUD + 角色頭像切換 + 使用真實 M5 Reducer 出一張合法技能卡，更新 HP、AP/MP、Hand/Discard，播放 Domain event 對應的攻擊動畫。讀取 AGENTS.md 與 docs/combat/COMBAT_SPEC_INDEX.md、COMBAT_IMPLEMENTATION_CONTRACT.md、COMBAT_OPEN_ISSUES.md，查當前 M5.5 的實作/CI 狀態。尊重現有 UI 設計圖，不增設不需要的手牌計數與固定行動順序 UI。所有字串繁中/英文 i18n。先建立讀寫隔離 Adapter，不變更已核准 AP/MP/傷害/Combo/Outcome；遇缺少的能力明列。每完成一個小功能請附實作原理/取捨/測試/面試追問的 Engineering Note，檢查 Godot 4.7.2 CI 與實際畫面，完成後直接 push master、無需 PR。

## 6. 禁止將此 Handoff 當作完成聲明

M1～M5.5 **Headless Domain 1,238/1,238**（Godot [M5.5 分支 CI #38677695295](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38677695295)，[PR CI #38678188918](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678188918)；正式程式碼已合併 [master 9c8b14b8](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/9c8b14b873047ca181a229cfaab5d2351541ceab)）。正式 [Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741) **completed/success**。**這僅證明版本化 Fixture Domain 的三人 Boss 全戰、100 seeds 和 Replay；Godot Lv40 正式 Content Parity、真正 Scene/Controller、英文繁中 HUD、真人遊玩與平衡依然未完成。**
