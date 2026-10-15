# Combat Phase 4 — Godot Presentation / Playable Integration Handoff

> **IMPLEMENTATION PLAN / NOT EXECUTED**（2026-10-15）。文件整理不包含下載資源、不包含 Scene 實作、不宣稱 Phase 4 CI 已通過。M5.5 仍是尚未驗證的獨立前置工作包。

## 1. 執行前讀取

根目錄 [AGENTS](../../AGENTS.md) → [本 Combat 索引](COMBAT_SPEC_INDEX.md) → 00/01/18/19/20/21 最新 USER_APPROVED → [Implementation Contract](COMBAT_IMPLEMENTATION_CONTRACT.md) → [Open Issues](COMBAT_OPEN_ISSUES.md) → [M5 工程](../verification/PH3_M5_EXECUTION_PLAN.md)、最新驗收筆記／CI → [UI 入口](../ui/README.md) 及 `.codex/skills/godot-...` 的實際現有工具技能。

先執行 read-only audit：master SHA、Godot CLI/version、project.godot、Scene tree、UI 圖像／正式設計、CardDefinition、Command/Reducer、最新 Test IDs、固定 Replay、素材授權與雙語資源。不得從舊 `31` 推斷實作位置。

## 2. 工作分層（M5.5 可與不依賴它的 UI 骨架並行）

| Gate | 最小工作 | 必須完成才能宣稱通過 |
|---|---|---|
| P4.1 Scene shell | 橫向 2.5D Battle Scene、三角與 Boss 區、HUD 插槽；只顯示來自 fixture/Domain 的 Snapshot | Godot Scene 可匯入；實際 screenshot 視覺檢查；不暗中修改 Domain |
| P4.2 HUD & localization | 手機/桌面可用 4-card draw / hand UI（依規最大8）、角色頭像切換、AP/MP/HP、已宣告 Boss Intent、Reaction confirm/pass；繁中/英文可切換 | 無硬編碼顯示字串；長文與比例 QA；可用鍵鼠／觸控 |
| P4.3 **Vertical slice** | 玩家點卡 → Controller 轉合法 Command → M5 reducer → Event queue → HP/卡牌/AP/MP 更新＋動畫 | 真的扣 Boss HP，Hand/Discard 守恆；固定 tape/hash 等於 Headless；錯誤命令不改 state |
| P4.4 Gameplay feedback | 詠唱、Interrupt、Protect/Guard、Break/Exposed/Combo/Last Spell、VFX/音效/可讀性 | UI 僅呈現 Domain 結果；確認時序與無 timeout / animation-driven outcome |
| P4.5 Full playable encounter | 正式使用 26 起始 12 SP×3、27 的 Lv40 Boss 候選，一場手動從開場到 VICTORY/DEFEAT | 完成後與 M5.5 headless replay/parity、完整風險盤點；不能靠測試專用秒殺卡 |
| P4.6 Balance & UX | 100 固定 seeds + 多策略和真人 Playtest + 多解析度 UI | 平衡僅可標 `BALANCE_ACCEPTED` 當使用者採納內容值；未批准則仍 `PROVISIONAL` |

## 3. 核心資料流（不可改寫）

```text
Scene input
  → BattleController (command_id, expected_event_seq, actor/card/target)
  → M5 Domain single reducer (M1 State, M2 payment, M3 Reaction, M4 Casting)
  → ordered events + final BattleState (authoritative)
  → Presenter/HUD + non-authoritative animation queue
```

繼承 M1 RNG/Replay 與 event hashing；不自行加第二套 BattleState、Boss 決策、卡區或勝敗判斷。每次新增 Command 必須先查實際 reducer 所支援的 schema；沒有的功能以 feature flag 或 `NOT_IMPLEMENTED` 顯示，禁止用 UI 假資料當完整版。

## 4. Codex 可直接使用的任務

> 請在 `KuroNekoLi/arbitrium-nexus-godot` 延續 Phase 4 P4.1～P4.3，先只完成最小垂直切片：三人/Boss Battle Scene + HUD + 角色頭像切換 + 使用真實 M5 Reducer 出一張合法技能卡，更新 HP、AP/MP、Hand/Discard，播放 Domain event 對應的攻擊動畫。讀取 AGENTS.md 與 docs/combat/COMBAT_SPEC_INDEX.md、COMBAT_IMPLEMENTATION_CONTRACT.md、COMBAT_OPEN_ISSUES.md，查當前 M5.5 的實作/CI 狀態。尊重現有 UI 設計圖，不增設不需要的手牌計數與固定行動順序 UI。所有字串繁中/英文 i18n。先建立讀寫隔離 Adapter，不變更已核准 AP/MP/傷害/Combo/Outcome；遇缺少的能力明列。每完成一個小功能請附實作原理/取捨/測試/面試追問的 Engineering Note，檢查 Godot 4.7.2 CI 與實際畫面，完成後直接 push master、無需 PR。

## 5. 禁止將此 Handoff 當作完成聲明

M1～M5.4 Domain 1,081/1,081（Godot [#38676746490](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676746490)），**不等於 M5.5、Godot Lv40 content parity、畫面、英文繁中 UI、真人遊玩、平衡**都完成。
