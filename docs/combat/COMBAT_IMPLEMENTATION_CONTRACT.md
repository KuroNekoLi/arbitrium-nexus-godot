# Combat Implementation Contract — Codex / Godot 單一引擎整合契約

> **ENGINEERING CONTRACT**（依現行核准玩法整理；不新增遊戲規則）｜2026-10-15｜適用：`KuroNekoLi/arbitrium-nexus-godot`。先讀 [索引](COMBAT_SPEC_INDEX.md) 與根目錄 [AGENTS.md](../../AGENTS.md)。

## 1. 不可更改的玩法邊界

- 3 位玩家角色、**每人 12 張獨立 SP 牌組**，起始 4、Player Phase **不足 4 才補至 4**、手牌上限 8、每人每 Player Phase 免費換牌 1 次（按核准事件順序）；一般 Basic Attack/Guard/Protect/Item 不需從 SP 手牌抽取。通用基本**攻擊／治療／防護魔法**本身仍是需持有的 UNIVERSAL SP，不是無限免費指令。
- 玩家階段隊伍共用 BaseAP 6（特定技能 AP 增加時 CurrentAP 沒有額外全域硬上限）；AP 在回合末 1:1 轉緊接敵方階段的 RP，正常 RP 上限 6（可被已批准技能修改），敵方階段結束 RP 清零。MP 各人獨立；**不會每輪自然回滿**；MaxMP 隨角色/裝備/狀態可不同；普通攻擊每角色每 Player Phase 只首次可回 MP（實際量在版本配置）。
- Chantless 立即合法結算；Full Chant 延遲到下一玩家階段既定時點，預設同張 SP 的兩模式 MP 扣費相同；Casting Interrupt 的合法立即部分 MP 退款不退 AP／Overload（百分比候選，不得硬編 Canon）；Last Spell 不入牌組、不能手動取消、強制 Full Chant、成功釋放後 Exhausted，**釋放前 HP0 強制失效**。
- Boss 先正式公布 intent 再開玩家/Reaction，不得因 Protect 偷換招式；合法 Reaction 無倒數，自主 Confirm/Pass；Break 是整張 SP 結算後、獨立於 Casting Stability、下一次合格未開始 Boss Action 降級；Exposed 必須另一張 SP 才能用、單次有效、期限依 P2-S17；Combo 需不同角色第二張真實支付的 SP，額外 Combo AP=0。
- 傷害順序：Protect 先改實際目標 → Hit → eligible Crit → 對實際承受者套防禦/抗性 → Guard → HP Barrier → HP/Lifecycle，FocusWard **不是 HP Barrier**。完整合法 Action 的必要事件結束後才做 Outcome；敵全 HP0 **VICTORY 優先**（即使同時我方全0）；敵仍活且我方全倒才 DEFEAT；沒有 DRAW。
- **Phase3 不新增自由走位命令**，2.5D 只能 Presentation。可抽象靜態 range tag；不要增加未批准 Position AP/MP 結算規則。

## 2. 唯一 State/Reducer / 單向 UI 交換

```text
Godot Battle Scene / Input
       → BattleController: Command (actor, target, card_instance_id, expected_event_seq)
       → scripts/domain/m5/integration/m5_domain_resolver.gd (apply)
       → Existing M2 payment / card ledger → M3 phase and Reaction → M4 Casting
       → M5 hit/damage/status/Boss/Outcome (existing M1 BattleState + RNG)
       → accepted/rejected + new BattleState + ordered DomainEvents + hashes
       → HUD selectors / animation queue / combat log presenters
```

UI **不能**自行扣 HP/AP/MP/RP、洗牌、刷新 hand、判斷敗勝、跳過合法 Reaction、以動畫延遲改事件順序。動畫完成回調只能確認顯示結束，不能重新提交已結算傷害。Boss/卡牌數值只從**版本化 ContentConfig/Definition**取用；UI 輸入不能攜入 `damage`、`break_damage` 等可偽造效果值。失敗交易不改 State、Event、RNG、卡區或費用。

**整合前程式核對**：目前 M5 只有已驗證的 fixture 範圍，請在當前 HEAD 實讀 [M5 integration](../../scripts/domain/m5/integration/m5_domain_resolver.gd) 、[M5.5 完整對局 Fixture/Command Tape](../../tests/fixtures/m5_full_battle_driver.gd)、[M5.5 Acceptance Report](../verification/PH3_M5_5_ACCEPTANCE_REPORT.md) 與 [M5 Handoff](../verification/PH3_M5_HANDOFF.md)；**不得只照本文件的示意命令格式當作存在的 runtime API**。不同 M2/M3/M4/M5 命令可能有實際字段限制，從現有 tests／replay fixtures 取 schema，再由 Controller 轉接，不要複製 reducer。

## 3. 成果與測試 Gate

| 驗收層 | 必備證據 | 不可誤宣稱 |
|---|---|---|
| Domain Verified | 唯一 reducer 真正結算、負例、回歸、Command Tape／SHA、Godot Headless CI | 不等於 UI 可玩 |
| Integration Verified | 使用真實 Command 操作 2.5D Scene；事件驅動 HP/AP/MP/hand/intents；Scene/headless smoke | 不等於動畫/可用性完成 |
| Playable Verified | 真人可以完成開場→數回合→勝/敗；Reaction、Casting、Boss、Last Spell 依規 | 不等於平衡已完成 |
| Balance Accepted | 多策略、100+ seeds、真人 playtest 及公布配置版本 | Python 單獨跑過不能代替 Godot parity |

**現況（M5.5 已驗證）**：M1～M5.4 **1,081/1,081** + M5.5 **157/157** = **1,238/1,238 命名 Domain assertions**，Godot 4.7.2 [功能分支 CI #38677695295](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38677695295) 與 [PR CI #38678188918](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678188918) Success；100 個固定 Seed 的完整三人 Boss 對局與每場 Replay 全部通過，4 Legacy 回歸成功；[master 合併程式碼 9c8b14b8](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/9c8b14b873047ca181a229cfaab5d2351541ceab)。Scope 限定 **M5 DOMAIN VERIFIED — HEADLESS BATTLE / FIXTURE_ONLY**；原生 Godot Lv40 Demo Content Parity、法術 Counter/Analyze、Scene+Controller、操作 UI、真人可玩性、平衡仍 **NOT VERIFIED**。正式合併後的 [Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741) 已完成且 **success**（執行 Commit `9c8b14b8`，49 Command / 5 rounds 的 Seed 20261014 Golden Battle 與 100 個完整 Replay 均通過）。

## 4. 開發與回報

- 先讀 [22 既有工程約束](22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md) 與 [23 原執行計畫](23_PHASE3_EXECUTION_PLAN.md)，再核對現在真正的 Godot repo、HEAD、代碼和 CI；舊 handoff 的 `Astraea-Academy` 是歷史。
- 每個功能：測試先行、版本化 provisional 配置、固定 Seed Replay、提交含 Engineering Note 的可追溯證據。不得以「CI green」覆寫已核准玩法。
- 在進入 Phase 4 之前，先看 [開放項目](COMBAT_OPEN_ISSUES.md) 的 Blocked/Deferred，決定縮小 MVP 範圍或另外取得批准；不可聲稱缺少 Counter／Analyze 內容的功能已全部驗證。
- 中英雙語 UI：禁止散落硬編碼文字，遵守專案 Godot i18n 規範；操作 HUD 與 Visual Asset Pipeline 依 [UI 入口](../ui/README.md) 與根目錄 AGENTS.md。
