# G0 Requirements Traceability Matrix — Arbitrium Nexus

> 日期：2026-10-14；程式基準 `c9678782b818f825b85561313bd142130c330fdf`；本表依 GitHub **靜態程式檢視**。除 G0.1、M1 scaffold 與 M2.1 **資源子契約**的已驗證案例之外，完整 **Phase1/2 gameplay** 仍多數 `NOT_EXECUTED`，不把文件指定的 Test ID 等同已跑 PASS。Spec 詳情參見 `../combat/00`～`24`。此表優先盤點工程關鍵不變量；完整逐一展開規格檔 13 的全部 test IDs，列為 M1 RTM 擴充義務。

| RTM | 正式需求 / Source | Legacy code / evidence | 稽核判定 | 新版驗收要求 | 工作包 |
|---|---|---|---|---|---|
| G0-R01 | 3 actors 共享基礎6AP，無2次出牌硬限（03/18/22） | `battle_state.gd: MAX_ORDINARY_PLAYS=2`, `play_card()` | CONFLICT | 合法多張總費用≤可用AP；拒超支時原子狀態不變 | M2 |
| G0-R02 | 獨立 MP 跨回合，首次基本攻擊符合回MP（03/22） | `resolve_enemy_phase() mana=max_mana` | CONFLICT | 無自然回滿；同角多次普攻僅首擊按規則回MP | M2 |
| G0-R03 | APDebt/Overload 明確欄位及合法邊界（18/19/20） | 無 `ap_debt`/`team_ap` | MISSING | 借用差額、不為負AP；可重播 | M2 |
| G0-R04 | AP 1:1 轉 RP，敵方階段末清空（03/07） | 無 RP 欄位，個人 Mana 替代 | MISSING | 6剩AP→6RP，消耗後清零 | M2 |
| G0-R05 | Guard1RP Protect2RP，不抽技能卡（P1 D03/06/10） | `guard.tres` 屬普通 Card；Reaction 需手牌 | CONFLICT | 無對應牌仍可 Guard/Protect；RP合法拒絕 | M3 |
| G0-R06 | 每名角色每窗口最多一次 Reaction（P1-D04） | 單 `interrupt_available: bool` | CONFLICT | 兩角色合法先後回應，同角第二筆拒絕 | M3 |
| G0-R07 | queue→confirm→順序JIT失效跳過（P1-D15/16） | `play_reaction()` 立即單次取消意圖 | MISSING | 失效不扣RP/MP、不棄牌、不計次數 | M3 |
| G0-R08 | 無真實時間強制倒數（CORE-04） | `main.gd: REACTION_WINDOW_SECONDS=1.5` | DIRECT_CONFLICT | 任意等待後仍停住，明示Confirm/Pass推進 | M3 |
| G0-R09 | Protect單體Redirect + defender重新計算（P1-D12~14） | 無 Protect resolver | MISSING | 魔法/物理單體可擋、AoE不可；linked on-hit依規則轉移 | M3/M5 |
| G0-R10 | 起手4、每輪補至4（04） | `_draw_until(...,4)` | PARTIAL | 新12卡起手4、draw8；牌實例守恆 | M2 |
| G0-R11 | 每角12 SP；可依資格混合（04/10） | 8-card deck，`default_deck_ids()` 八張 | CONFLICT | 每角12卡、Loadout資格校驗 | M2 |
| G0-R12 | hand max8（M-D25） | `MAX_HAND=6` | CONFLICT | 第8張可保留、第9張符合例外策略 | M2 |
| G0-R13 | Free Swap每人每玩家階段1次、隔離棄卡再抽（19/20） | 未發現相關命令 | MISSING | 前置沒有替代時不消耗、不可立即抽回自己棄牌 | M2 |
| G0-R14 | Last Spell獨立槽、Full、一次且Exhausted（08） | `CardData` 無此契約 | MISSING | 準備/干擾/正常成功Exhausted測試 | M4 |
| G0-R15 | Last Spell未釋放前caster HP0強制失效（CORE-02） | 無 CastingInstance | MISSING | 取消待效、不退款、不死後續唱 | M4 |
| G0-R16 | Chantless/Full Chant、個人Casting Stability（05） | 單 `play_card()` 立即生效 | MISSING | 完整詠唱延後、Chantless立即，獨立法術實例 | M4 |
| G0-R17 | Full Chant同MP成本（M-D21） | card僅單 `cost` 欄位、無profiles | MISSING | 合法兩模式共用指定 MP、AP可差異 | M4 |
| G0-R18 | Barrier vs Focus Ward分離（05/07） | 無明確雙盾層 | MISSING | HP傷僅Barrier；干擾僅Focus Ward | M4/M5 |
| G0-R19 | Casting Stability vs Break Gauge分離（05/06） | 單 `boss_stability` | CONFLICT | 打斷Casting不等於本體Break | M4/M5 |
| G0-R20 | Hit/evade/damage流水線（11/22） | `_damage_boss(amount)` 直接扣血 | MISSING | redirect→hit→crit/def/res→Guard→Barrier→HP trace | M5 |
| G0-R21 | Combo真正由不同角色合格SP觸發，額外0AP（09） | 無 ComboOpportunity模型 | MISSING | 無第二卡不能免費生成傷害 | M5 |
| G0-R22 | Analyze獨立免費、全隊每戰2次（16/18） | `analysis += card.analysis_gain`,到3清空 | CONFLICT | Analyze無牌、無AP/MP/RP、2次上限 | M2/M5 |
| G0-R23 | HP0 Incapacitated及復活條件（11/20） | heroes.hp被 clamp 0，但無 life-state transitions | PARTIAL | 死亡後不可非法行動；一般Heal不能自動Revive | M5 |
| G0-R24 | Enemy-clear-first VICTORY（CORE-01） | BossHP可0；未發現明確BattleOutcome | MISSING | 同一合法action敵我全滅則Victory | M5 |
| G0-R25 | deterministic PRNG/command tape/state event hash（12/22） | Godot RandomNumberGenerator固定seed，log為中文字signal | PARTIAL | State+seed+commands 重播同 hash，非法命令 RNG unchanged | M1 |
| G0-R26 | domain authoritative independent of animation（12/22） | UI動畫後呼叫 `play_card()`；`test_combat_ui.gd` 以延後扣血為成功 | CONFLICT | 動畫播放不控制 domain 單次結算 | M1/UI adaptation |
| G0-R27 | deck persistence migration（04/22） | `deck_profile_store.gd` version1/8張/NoDuplicates | CONFLICT | 版本化向新版轉換，保護舊資料 | M2 |
| G0-R28 | Godot headless negative failure exit probe（23） | `tests/ci_failure_probe.gd` 的 CI Run #38563701908 明確確認 exit17+marker | **G0.1 VERIFIED** | 負例結果可辨識，不能把命令失敗當 PASS | G0.1 CLOSED |
| G0-R29 | CI與實測版本（23） | workflow `godot-g0-legacy-baseline.yml`，Godot `4.7.2.stable.official.ed1daf0bf`，SHA512/匯入/四組 legacy tests exit0 | **G0.1 VERIFIED — LEGACY ONLY** | 新版 Phase1/2 測試尚 NOT_EXECUTED；留存 run ID + logs | G0.1 CLOSED |
| G0-R30 | 測試 oracle 更新（13/21） | `test_battle_state.gd` 預期8卡/兩次；`test_turn_flow.gd` 預期timeout | CONFLICT | 明確標 LEGACY_SUPERSEDED，新增新版正/負/邊界測試 | M1–M5 |

## 必須延伸的工作

- 第13號規格文內所有 P1/P2/M/PRE3/CORE testcase ID，M1 建立全量 machine-readable mapping（ID、spec source、expected state/event、fixture、runnable test、actual output、status）。
- 禁止把本表 `PARTIAL` 直接升級 `PASS`；需在 **本 Godot repo** 同 Godot runtime 執行 headless，留下 stdout/stderr, exit code, SHA, seed, state hashes。
- 需要新 `docs/verification/PH3_G0_BASELINE_RUN.md` 保存實際二進位、CI、命令與測試結果；未跑前不可產生假紀錄。

## G0.1 實測補充

[Run #38563701908](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38563701908) = `success`，四組舊版測試均 exit0，故意失敗 exit17。這是**環境與既有原型 Regression baseline** 的結果，而非新版功能驗收。G0-R01～27、R30 仍依其 CONFLICT/MISSING/PARTIAL 判定，不因 CI 綠燈而改為通過。詳見 [PH3_G0_CI_SETUP.md](PH3_G0_CI_SETUP.md)。

## 附錄：M1 新 Domain CI 與 Spec13 全量追溯（2026-10-14）

- [新 M1 Domain CI Run #38565197994](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38565197994)：commit `ad8333dd1a00c9efa042273f6535accb1ea43e31`，Godot `4.7.2.stable.official.ed1daf0bf`，30個具名 M1 Domain Case **30 PASS / 0 FAIL / 0 SKIPPED**。
- [同 commit 舊版 Regression Run #38565198000](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38565198000)：completed / success；目前 legacy 系統與 UI 尚**未**切換新版 M1 Domain，不能因此把 G0-R01～24 和 26～30 當成新規格已合格。
- **G0-R25**（決定性 Domain scaffold / Replay）：`M1_SCAFFOLD_VERIFIED`，測到命令驗證拒絕原子性、RNG 純函式、固定 Event Seq/Replay Hash；**全戰 P2-D16/P2-REPLAY-01 仍未完整實作**。
- 來源 `docs/combat/13_TEST_MATRIX_ACCEPTANCE.md` 的 **128個具名 Test IDs 及 30個新M1 ID** 已完整列於 [PH3_PHASE12_TEST_INVENTORY.md](PH3_PHASE12_TEST_INVENTORY.md)，包括來源行號、責任 Milestone、現行狀態；不得把 `SPECIFIED` 誤寫成 `PASS`。

## M2.1 — 新資源模組與受限的驗收範圍（2026-10-14）

[CI Run #38568919479](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38568919479), commit `5812a8883e87cb5cd30665d100875f7bb75c0e59`：Godot 4.7.2，**38/38 M2.1 PASS + 30/30 M1 regression PASS**；同 commit 的 [G0 legacy run #38568920097](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38568920097) 為 success。這證明新 `scripts/domain/m2/economy/` 的 resource-only 合約，**不代表舊 `scripts/domain/battle_state.gd` 已遷移完成**。

| RTM | 新實作檔 | 已驗證的子範圍 | Remaining Gate |
|---|---|---|---|
| G0-R01 | `scripts/domain/m2/economy/resource_ledger.gd` | BaseAP6、共享池、CurrentAP超過6、普通攻擊*資源模擬*不限同人次數 | M2.2 真正 SP 合法性／M5 傷害、UI |
| G0-R02 | `basic_attack_mp_policy.gd` + `resource_ledger.gd` | 每角第一次成功的資源操作才回MP；不自然回滿；MaxMP clamp | M3 正式階段邊界／M5 真正攻擊 |
| G0-R04 | `resource_ledger.gd` | AP→RP按有效cap；敵方階段末RP清零；不可二次轉換 | M3 EnemyAction/Reaction 真正 RP 支出 |
| G0-R25 | `m1/combat_model.gd` + `resource_ledger.gd` | 同 seed/resource command tape 事件及state hash一致，拒絕不動 RNG | M2.5 全卡區不變量／M5 全戰 replay |
| G0-R26 | `m2/economy/*.gd` | Domain 不依賴 UI 動畫/計時器 | 舊 `main.gd` 尚未接新版 Domain |

**驗收級別：`RESOURCE_LEDGER_ONLY_VERIFIED / FULL_GAMEPLAY_NOT_EXECUTED`。** 測試案例詳見 [PH3_PHASE12_TEST_INVENTORY.md](PH3_PHASE12_TEST_INVENTORY.md)；實際證據及失敗後修復原因見 [PH3_M2_1_ENGINEERING_NOTE.md](PH3_M2_1_ENGINEERING_NOTE.md)。
