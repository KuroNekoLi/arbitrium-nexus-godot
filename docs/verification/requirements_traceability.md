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

## M2.2 — Cost Engine + Overload verified (2026-10-14)

[CI #38571553461](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38571553461), SHA `907d406d13dc1fb841e0a52e4364121f5f819fcd`: Godot4.7.2 verified M1=30/30, M2.1=38/38, M2.2=43/43. `M2.2_COST_DOMAIN_VERIFIED` is **internal transaction scope only**; real SP, card zone consumption and UI integration remain `NOT_EXECUTED`.

| Requirement | Test evidence | Status / gap |
|---|---|---|
| M-D01/11/13/14, PRE3-R10 | `M2_2_ATOMIC_AP_MP`, `PRE3-10-RESOURCE_ONLY`, `M2_2_VARIABLE_INVESTMENT`, `M2_2_MIN_AP_COST` | Quote, ordered discounts, effective cost, atomic AP+MP payment VERIFIED internally |
| M-D02/03/05/15 | `M2_2_OVERLOAD_SHORTFALL`, `M2_2_CARD_BORROW_LIMIT`, `M2_2_TEAM_BORROW_LIMIT`, `M2_2_NO_VOLUNTARY_BORROW` | Explicit Overload + shortfall caps VERIFIED; 8AP limit PROVISIONAL |
| M-D04/06/07 | `M2_2_DEBT_CROSS_PHASE`, `M2_2_DEBT_MULTI_PHASE`, `M2_2_AP_BONUS_REPAYS_FIRST` | Provisional multi-phase debt repayment VERIFIED as configured |
| M-D16/17 | `M2_2_AP_REFUND_CURRENT_ONLY`, `M2_2_REFUND_DOES_NOT_REPAY`, `M2_2_REDUCE_DEBT_NO_AP` | AP refund vs debt reduction separated; source/effect binding still fixture |
| M-D21 | `M2_2_DUAL_CAST_SAME_MP` | Default shared MP quote verified; real casting deferred |
| G0-R25 Replay | `M2_2_REPLAY_DETERMINISTIC`, `M2_2_REPLAY_FAILED_ATOMICALLY` | Fixed-seed replay VERIFIED for cost fixture only |


## M2.5 partial engineering verification — 2026-10-14

Starting HEAD: `495a2df504135c748cf53e29756fc521b5fad0f7`.
Tested SHA: `71b753c5b0eba58bb9b21043e8be95e2d49ac44a`.
Official Godot `4.7.2.stable.official.ed1daf0bf`.
Evidence: [M2.5 blocked gate run 38576033292](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38576033292), [legacy pass 38576033499](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38576033499).
M1 30/30, M2.1 38/38, M2.2 43/43, partial M2.5 resource invariants 14/14 and partial replay 6/6; **full M2.5 fails closed with exit2 because M2.3/M2.4 do not exist**. These tests were actually executed; the four source-of-truth card/swap modules were **not**.

| Requirement / authority / source | Implementation | Test case IDs (executed at SHA above) | Status |
|---|---|---|---|
| M-D01/02/03/05/15 APPROVED; `18 §2` | `scripts/domain/m2/economy/cost_resolver.gd`; `overload_debt.gd` | `M2_5_OVERLOAD_RESOURCE_INVARIANT`, `M2_5_DUPLICATE_COST_ATOMIC`, `M2_5_INSUFFICIENT_MP_ATOMIC`, `M2_5_STALE_COMMAND_ATOMIC` | RESOURCE_ONLY_VERIFIED |
| M-D06/07/08/09/16/17 APPROVED; `18 §2`; M-D18 `19 §1` | `resource_ledger.gd`, `cost_effect_resolver.gd` | `M2_5_REFUND_DEBT_SEPARATE`, `M2_5_REFUND_NO_REPEAT`, `M2_5_REDUCE_DEBT_NOT_AP`, `M2_5_RP_FROM_REMAINING`, `M2_5_RP_DOES_NOT_CARRY`, `M2_5_AP_DEBT_REPAID_BEFORE_REFRESH`, `M2_5_AP_UNCAPPED_RP_CAPPED` | RESOURCE_ONLY_VERIFIED |
| M-D04 PROVISIONAL; `18 §2`, `20 §4` | `overload_debt.gd` | `M2_5_PROVISIONAL_ZERO_AP_PHASE` | PROVISIONAL_RESOURCE_ONLY_VERIFIED |
| M1 deterministic model / P2-D16 APPROVED DIRECTION; `12`, `19 §4`, `22 §5` | `combat_model.gd`, M2 cost/effect/ledger | `M2_5_RESOURCE_INITIAL_VALID`, `M2_5_COST_INPUT_PURE`, `M2_5_CROSS_RESOLVER_REPLAY_EQUAL`, `M2_5_REPLAY_EVENTS_MONOTONIC`, `M2_5_REPLAY_RNG_UNCHANGED`, `M2_5_REPLAY_AP_RP_DEBT`, `M2_5_REPLAY_DISTINCT_TAPE_HASH`, `M2_5_REPLAY_FAILURE_ATOMIC` | RESOURCE_ONLY_VERIFIED; full card/swap replay BLOCKED |
| M-D25 APPROVED, PRE3-R16 DELEGATED_DEFAULT; `04 §1–4/8`, `19 §3`, `20 §3 D` | **M2.3 missing** | `DECK-001/002/003/004`, `M25-HAND-001/002` | BLOCKED_DEPENDENCY, NOT EXECUTED |
| M-D26–30 APPROVED, PRE3-R11 DELEGATED_DEFAULT; `04 §8`, `19 §3`, `20 §3 C` | **M2.4 missing** | `M26-SWAP-001`, `M27-SWAP-002`, `M29-SWAP-003`, `M30-SWAP-004`, PRE3-R11 valid-precheck/changed-pool negative | BLOCKED_DEPENDENCY, NOT EXECUTED |
| PRE3-R12 DELEGATED_DEFAULT; `20 §3 C` | M4 casting lifecycle future | Casting zone resolution after spell/interrupt | DEFERRED_TO_M4 |

New tests: `tests/test_m2_invariants.gd` and `tests/test_m2_replay.gd`. Test script exit0 on passing partial coverage; the new `.github/workflows/godot-m2-domain.yml` intentionally exits2 on missing dependencies to prevent **M2 DOMAIN VERIFIED** being misreported.
Replay evidence: seed 20261014, event `28de6c96641655057122a210a73f9c3fa77890c0c20eded0417d5e62ebb7ce85`, final state `7389a7975f13b209982a3ba83dd4fd7ceeeb0c4947bda77f3712f4b8da70d9a9`. See `PH3_M2_5_ACCEPTANCE_REPORT.md` for full tape, initial hash, first parse-failure and second execution.

## M2.3 — Independent 12-SP cards and zones verification (2026-10-14)

Executed code on commit de2178e175846c2eeae5aba7f3f96995bb61323c. Evidence: [M2.3 46/46 Godot run #38580461921](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38580461921) (4.7.2, seed=20261014; independent legacy regressions pass). Legacy deck_profile_store.gd remains untouched and serves the older 8-unique-card prototype, not the new domain.

| RTM | Approved source | M2.3 implementation | Executed acceptance | Precise status |
|---|---|---|---|---|
| G0-R10 | Library 04, M-D25 | card_zone_resolver.gd, draw_resolver.gd | DECK-001, DECK-002, M25-HAND-001 | CARD_DOMAIN_VERIFIED, M3 phase wiring deferred |
| G0-R11 | Library 04, PRE3-R16 delegated | card_instance.gd, deck_validator.gd | PRE3-R16-EXACT_12, DECK-004-36_UNIQUE, repeated-definition accepted, eligibility and inventory negative checks | CARD_DOMAIN_VERIFIED, content fixture only |
| G0-R12 | Library 19 M-D25 | draw_resolver.gd, card_zone_resolver.gd | M25-HAND-002, PRE3-20-CAP_SEVEN_REQUEST_THREE, ninth-card rejection | CARD_DOMAIN_VERIFIED |
| G0-R25 | P2-D16 seeded determinism | draw_resolver.gd | DECK-SEEDED_REPLAY, DECK-003-ONE_DRAW_TEN_DISCARD, RNG and zone events | M2.3 seed-only VERIFIED; integrated M2.5 replay still blocked |
| G0-R27 | Library 04, 20 PRE3-R16 | deck_profile_v2.gd | M2_3-PERSIST V1 recognized unchanged, V2 structurally validated read/write, no auto-padding | CARD_DOMAIN_VERIFIED, legacy migration UI deferred |
| G0-R13 | M-D26–30, PRE3-R11 | M2.4 not implemented | None | BLOCKED_DEPENDENCY |
| PRE3-16 (spec-13) | Last Spell caster HP0 | M4 | None | SPECIFIED_NOT_EXECUTED (not loadout PRE3-R16) |

The old M2.5 report's initial missing-M2.3 finding refers only to its historical baseline SHA. Current status: M2.3 independently verified, M2.4 still missing and full cross-card/Free Swap replay not executed. Do not promote the full M2.5 gate to VERIFIED.

## M2.4 — Free Swap + Card Events independent verified domain (2026-10-14)

Source [Library 19 M-D26–30 / Library 20 PRE3-R11], source code `scripts/domain/m2/cards/free_swap_resolver.gd`, `card_trigger_dispatcher.gd`, updated `card_zone_resolver.gd`. Test: `tests/test_m2_free_swap.gd`. Evidence [successful official Godot 4.7.2 CI #38582070292](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38582070292), tested SHA `7b115720716c5fd155088313d14c9df81344bd74`. **32/32 PASS**, M2.3 **46/46**, M1 **30/30**, M2.1 **38/38**, M2.2 **43/43**, legacy scripts exit0. Event/State replay hashes in [PH3_M2_4_ENGINEERING_NOTE.md](PH3_M2_4_ENGINEERING_NOTE.md).

| RTM | Test | Verified scope | Deferred |
|---|---|---|---|
| G0-R13 / M-D26, M-D27 | `M26-SWAP-001`, `M27-SWAP-002`, per actor quota / next phase, seeded reshuffle | CARD_DOMAIN_ONLY_VERIFIED: 1 per actor per phase, isolated no-self-redraw, event 0AP/0MP | Actual M3 phase driver and shared resource ledger |
| M-D29 / PRE3-11 (spec13) | `M29-SWAP-003`, PRECHECK retry | CARD_DOMAIN_ONLY_VERIFIED: no replacement => atomic reject/no event/no consumption | Full battle driver |
| M-D28/30 | `M30-SWAP-004`, `M28-SWAP-EVENT_TRIGGERS_ORDER` | CARD_EVENTS_ONLY_VERIFIED: legal event ordering, finite declarative MOVE_CARD triggers | **Spec13 MP recovery and draw-Buff effects** not implemented |
| PRE3-12 (spec13) / PRE3-R11 (Library20) | `PRE3-11-POOL_CHANGED`, `PRE3-11-EVENT_ORDER` | CARD_DOMAIN_ONLY_VERIFIED: post-trigger depletion => no CardDrawn, CardDrawFailed(POOL_CHANGED), quota spent, no rollback | Full Card/Cost/Status replay in M2.5 |
| G0-R25 / P2-D16 | `M2_4-SEEDED_REPLAY`, `M2_4-EVENT_SEQ_MONOTONIC` | CARD_DOMAIN_ONLY_VERIFIED replay hashes | Integrated M2.5 replay and M3/M4/M5 |

Do not interpret `PRE3-12` (spec13 changed-pool test) as Library `PRE3-R12` (Casting). Existing M2.5 baseline narrative of missing M2.3/M2.4 describes its **historical old SHA**, not the current source tree. The entire M2.5 workflow still deliberately returns exit2 `BLOCKED_M2_FULL_INTEGRATION`; **M2 DOMAIN VERIFIED is NOT claimed**.


## M2.5 verified integrated core Domain — 2026-10-14

Authoritative [CI #38586164025](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38586164025), tested SHA 418607f954f40a38eff0de0b830eb83bed7080d6: official Godot 4.7.2, M1 30/30 + M2.1 38/38 + M2.2 43/43 + M2.3 46/46 + M2.4 32/32 + resource M2.5 14/14 + 6/6 + new integrated M2.5 40/40 = **249 passed, zero failed**, plus four legacy scripts exit0. This supercedes only the historical dependency-blocked baseline; original decision approvals and deferred feature statuses are unchanged.

| Trace / authority | Actual implementation | Executed tests | Honest verdict |
|---|---|---|---|
| G0-R01/R02; M-D01–17; PRE3-R10 | CostResolver + m2/integration/m2_domain_resolver.gd | COST_ZONE_ATOMIC, MP_NO_CARD_LOSS, AP_NO_CARD_LOSS, OVERLOAD_LINKED_CARD | M2 CORE DOMAIN VERIFIED; balance PROVISIONAL |
| G0-R10/R11/R12; DECK-001–004, M25-HAND-001/002 | CardInstance + ZoneResolver + DrawResolver + Integrator | INITIAL_36_CARDS, HAND_CAP8, HAND_CAP8_NO_PHANTOM, CASTING_ZONE_EXCLUSIVE | M2 card instances and conservation VERIFIED |
| G0-R13; M-D26–30, PRE3-R11 | FreeSwapResolver + CardTriggerDispatcher + Integrator | ZERO_AP_SWAP, SWAP_ONCE, PRECHECK_ATOMIC, PRE3_R11_REPLAY_EXACT, COST_DISCARD_TRIGGER_DRAW | M2 event order, bounded MOVE_CARD triggers VERIFIED; real MP/Buff effects deferred |
| G0-R25; P2-D16 | M1 canonical hashes + Integrator unified source-tagged event log | FULL_CROSS_MODULE_REPLAY, TRIGGER_REPLAY_EXACT_HASH, REPLAY_FAILURE_ATOMIC, EVENT_SEQUENCE_MONOTONIC | M2 cross-module replay VERIFIED; M5 full-encounter replay deferred |
| G0-R27 | m2/persistence/deck_profile_v2.gd | M2.3 46 acceptance assertions | 12-card V2 storage VERIFIED; legacy UI migration deferred |
| G0-R14–24/R26 | Future M3/M4/M5 gameplay | No full gameplay assertions | NOT_IMPLEMENTED / NOT_EXECUTED |

Do NOT use the presence of the CI marker M2_DOMAIN_VERIFIED as evidence of M3/M4/M5 gameplay implementation. Detailed execution and replay hashes: [PH3_M2_5_ACCEPTANCE_REPORT.md](PH3_M2_5_ACCEPTANCE_REPORT.md).


## M3.1 Battle Phase Engine — independently verified (2026-10-14)

Code SHA 4c5e77fbce21aa354935296e42803019b43133ad. Godot CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38590076311: M3.1 61/61, preceding M1–M2 249/249, legacy scripts exit0. Detail and replay hashes in PH3_M3_1_ENGINEERING_NOTE.md.

| Approved authority | Source files | Real oracles | Bounded result |
|---|---|---|---|
| P1-D01, 02/03 | m3/phase/phase_engine.gd and M2 integrated resolver | M3_1_P1_D01_AABA, M3_1_PLAYER_ACTIONS_IMMEDIATE, M3_1_NO_AUTOMATIC_END | M3.1 PASS; player action effects fixture only |
| PRE3-R09, public Enemy Intent | m3/enemy/enemy_action_scheduler.gd | M3_1_ACTION_ORDER_STABLE, M3_1_ACTION_IDS_ROUND_SCOPED, M3_1_NO_HIDDEN_INTENT | M3.1 PASS; AI and damage deferred |
| M-D08/09 and M2 resources | phase_engine.gd, existing M2 ResourceLedger | M3_1_END_PLAYER_AP_TO_RP, M3_1_RP_EXPIRES_AT_ENEMY_END | M3.1 PASS; APDebt carry PROVISIONAL |
| PRE3-R09, CORE-01 and M-D25 | m3/phase/phase_boundary_resolver.gd, M2 DrawResolver | M3_1_PRE3_R09_CASTING_FIXTURE_FIRST, M3_1_REAL_STATUS_FAIL_CLOSED, M3_1_CORE_01_VICTORY_PRIORITY, M3_1_PHASE_TWO_HAND_REFILL | M3.1 PASS with fixture hooks; real Status/Casting unresolved |
| P2-D16 and replay | phase_engine.gd, M1 hash adapter | M3_1_SEEDED_FULL_PHASE_REPLAY, M3_1_REPLAY_DUPLICATE_STOPS | M3.1 PASS, integrated Reaction replay M3.5 pending |

M3.2 Reaction Queue, M3.3 Guard/Protect, M3.4 presentation-mode invariants and M3.5 overall M3 regression all remain NOT_EXECUTED. No M3 DOMAIN VERIFIED assertion.


## M3.2 Reaction Window & Queue — verified Domain (2026-10-14)

Final code SHA 3c26267cb2e314cf07e3a6ba269f07133852222e; Godot4.7.2 [CI #38594159424](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38594159424) 50/50 M3.2 PASS, M3.1 61/61 PASS, M1–M2 249/249 PASS; 360/360 total Domain assertions, four legacy smoke scripts exit0. Detail, replay hashes and first parser failure correction: PH3_M3_2_ENGINEERING_NOTE.md.

| Requirement | Source and exact oracles | Bounded verification |
|---|---|---|
| P1-D03/D04/D15 and EnemyAction Window ID | phase_engine.gd, reaction_window_resolver.gd; M3_2_WINDOW_ID, M3_2_SINGLE_WINDOW_THREE_HITS, M3_2_WINDOW_IDS_NONREUSED | M3.2 VERIFIED one action/one window, no repeated declaration |
| P1-D15 draft, ordering, no premature fee | reaction_queue_resolver.gd; M3_2_QUEUE_DOES_NOT_PAY, M3_2_PURE_PREVIEW, M3_2_USER_ORDER_NOT_SPEED, M3_2_REMOVE_DRAFT_NO_CARD_SPEND | M3.2 VERIFIED pure editing and explicit Confirm |
| P1-D16, PRE3-R04 deferred skips | eligibility + Queue + existing M2 atomic ResourceLedger; M3_2_PRE3_R04_JIT_SKIP, M3_2_ONLY_TWO_REAL_SPENDS, M3_2_ONLY_TWO_CARDS_DISCARDED | VERIFIED with fixture-only counter and independent support; real Spell Counter postponed to M4 |
| P1-D03, M-D08/09 RP/MP per window | resource_ledger.gd, m2_domain_resolver.gd; M3_2_RP_PERSISTS_BETWEEN_WINDOWS, M3_2_RP_EXPIRES_AT_PHASE_END, M3_2_CONFIRM_REJECTS_KNOWN_BUDGET_DEFICIT | VERIFIED real RP/MP/card transaction; card spell effect fixture |
| CORE-04 no timeout/no autopass | M3_2_PASS_EXPLICIT_ONLY, M3_2_NO_AUTO_PASS_WITH_ELAPSED_DATA | M3.2 Domain VERIFIED; old UI timer removal M3.4/Presentation deferred |
| Basic Guard/Protect available without SP | M3_2_BASIC_GUARD_CANNOT_BE_SILENTLY_SKIPPED, M3_2_GUARD_PROTECT_NOT_FALSELY_IMPLEMENTED | Historical M3.2 verdict only; now superseded for basic Guard/Protect by the verified M3.3 section below. |

M3.3 Guard/Protect, M3.4 Smart/Always Ask/Quick contract, M3.5 full-phase integrated M3 replay and M4/M5 gameplay remain UNVERIFIED. Do not label M3 DOMAIN VERIFIED.


## M3.3 — Guard/Protect independent acceptance — 2026-10-14

Final tested source SHA 42d0ac055b457f96123b4a669e558b0bcc3bcb65. Successful Godot4.7.2 CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38596728929: new M3.3 54/54 PASS, preceding M3.2 50/50, M3.1 61/61 and M1–M2 249/249, total 414/414 named Domain cases; legacy scripts exit0. Full evidence in PH3_M3_3_ENGINEERING_NOTE.md.

| Approved source / requirement | Code and actual named tests | Current verdict |
|---|---|---|
| P1-D11 / PRE3-R02/R17 Guard basic 1 RP and multihit | basic_guard_resolver.gd, M3_3_GUARD_EXACTLY_ONE_RP, M3_3_GUARD_THREE_HIT_COVERAGE, M3_3_GUARD_NO_MP_OR_CARD | M3.3 Guard eligibility/payment/action coverage VERIFIED; actual damage coefficient still M5/BALANCE_PROVISIONAL |
| P1-D12–14 / PRE3-R01/R02 Protect 2 RP before hit | basic_protect_resolver.gd, M3_3_PROTECT_ONE_REDIRECT, M3_3_PROTECT_THREE_HITS_SINGLE_REDIRECT, M3_3_REDIRECT_BEFORE_HIT_OR_DEFENSE | M3.3 single-target recipient routing VERIFIED; M5 real hit/DEF/HP deferred |
| PRE3-R01, PRE3-R04, P1-D16 no chain and skip | reaction_queue_resolver.gd, M3_3_SECOND_PROTECT_SKIPPED_NO_CHAIN, M3_3_GUARD_AFTER_REDIRECT_SKIPS, M3_3_PRE3_R04_PROTECT_TRIGGER_GONE | No chained redirects or fees on invalidated pending entries VERIFIED |
| PRE3-R03 explicit follows_damage_recipient status routing | phase_engine.gd defense_snapshot, M3_3_REDIRECT_BEFORE_HIT_OR_DEFENSE | Effect routing **metadata** VERIFIED; applying status/knockback/casting effects remains M5 |
| P1-D11–14 / PRE3-R13/R14 guard/protect exceptions | M3_3_AOE_PROTECT_REJECTED, M3_3_MULTITARGET_PROTECT_REJECTED, M3_3_CAN_PROTECT_EXHAUSTED_TARGET, M3_3_CONCENTRATING_BASIC_DISALLOWED | Headless legality VERIFIED; no invented M4 concentration exceptions |
| P1-D03 and M2 resource/card conservation | M2.COMMIT_BASIC_REACTION, M3_3_COST_SOURCE_IS_FIXED_DOMAIN, M3_3_GUARD_PREVIEW_PURE, M3_3_PROTECT_NO_CARD_USED | Shared RP 1/2, 0 MP, 0 card use, no client cost injection VERIFIED |
| P2-D16 seed/event Replay | M3_3_SEEDED_GUARD_PROTECT_REPLAY, M3_3_REPLAY_DUPLICATE_ATOMIC, M3_3_GUARD_COST_PER_DISTINCT_ACTION | Same-seed M3.3 replay and RP across action windows VERIFIED |

M3.4 presentation modes, M3.5 integrated acceptance, M4 spell/casting and M5 real HP damage, and legacy UI replacement remain NOT_VERIFIED. **Do not declare overall M3 DOMAIN VERIFIED at M3.3.**


## M3.4 — Reaction UI Mode Contract independently verified (2026-10-14)

Official Godot 4.7.2 GitHub Actions https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38598430159, tested source SHA **513129fc12c4de8b754041d4547a77f07b17a2f1**, M3.4 **83/83**, M3.3 **54/54**, M3.2 **50/50**, M3.1 **61/61**, M1–M2 **249/249**, grand total **497/497** named Domain cases, plus four legacy scripts exit0.

| Decision | Actual code / Godot oracle | Bounded verdict |
|---|---|---|
| P1-D05 SMART / ALWAYS_ASK / QUICK display policy | m3/reaction/reaction_presentation_policy.gd; M3_4_DEFAULT_SMART, M3_4_SMART_MINOR_QUIET_BUT_BLOCKS, M3_4_ALWAYS_ASK_ALWAYS_MODAL, M3_4_QUICK_COMPACT_NOT_MODAL | M3.4 pure Domain policy VERIFIED; visual HUD and real translation resources deferred |
| CORE-04 time-independent explicit Confirm or Pass | M3_4_QUICK_WAIT_120, M3_4_SMART_WAIT_86400, M3_4_QUICK_CANNOT_ADVANCE, M3_4_PASS_EXPLICIT_NO_RP | VERIFIED with simulated UI time metadata, no actual on-screen 120-second test |
| P1-D03/04/15/16, basic Guard/Protect and SP legality unchanged | M3_4_GUARD_ONLY_WINDOW_REAL, M3_4_DRAFT_FEE_IS_SAME, M3_4_QUICK_FIXED_COST, M3_4_QUICK_REORDER_JIT | Verified same actual M2 RP spend, JIT skip and M3.3 coverage across UI modes |
| P2-D16 deterministic state and event replay | M3_4_THREE_MODES_IDENTICAL_STATE_HASH, M3_4_THREE_MODES_IDENTICAL_EVENT_HASH, M3_4_THREE_MODES_IDENTICAL_DOMAIN_EVENTS | VERIFIED exact cross-mode deterministic command replay |
| No legal option => no empty prompt | M3_4_QUICK_EMPTY_SKIPS_PROMPT, M3_4_EMPTY_CAN_FINISH_ACTION | VERIFIED automatic empty window dismissal does not auto-pass a legal window |
| i18n/Presentation boundary | Policy only provides reaction.mode.* identifier, no UI changes | Real HUD, old scripts/main.gd countdown replacement, translated strings and input modes NOT_IMPLEMENTED in this milestone |

See PH3_M3_4_ENGINEERING_NOTE.md for SHA256 replay evidence. M3.5 complete M3 domain integration remains NOT_EXECUTED and blocks the top-level M3 DOMAIN VERIFIED marker. M4 casting and M5 actual damage remain separate milestones.


## M3.5 — Integrated headless M3 Domain gate (2026-10-14)

Source SHA e638626a3c9fe44c2c4d172d04e1b409a9af08e0. Official Godot 4.7.2 [full M3.5 Actions run](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38601022642): two new suites 61/61 Integration and 40/40 seeded Replay, previous M3.4 83/83, M3.3 54/54, M3.2 50/50, M3.1 61/61, M1–M2 249/249. Total **598/598 named Domain cases PASS**, four legacy smoke scripts exit0.

| Approved or delegated requirement | Actual implementation / tests | Domain outcome |
|---|---|---|
| P1-D01 M3.1 player action order and phase life cycle | m3/integration/m3_domain_resolver.gd delegates PhaseEngine; tests/test_m3_integration.gd P1-D01-PLAYER_ACTION_ORDER_AABA | PASS 2 full rounds, round3 Player opening |
| P1-D03/D04/PRE3-R04 queued reaction JIT, skip/no cost | test_m3_integration.gd PH3-M3-QUEUE-001, PRE3-R04-SKIP_WITHOUT_PAYMENT, M35-QUEUE-ONLY_TWO_REAL_PAYMENTS | PASS real M2 SP/resource/zone transaction with explicit cancellation FIXTURE |
| PRE3-R01/R02/R03/R17 Guard multihit, Protect prior to hit and AOE restrictions | PH3-M3-PROTECT-001, PRE3-R02-GUARD_ALL_HITS, M35-AOE-NO_PROTECT, M35-PROTECT-M5_HANDOFF_BEFORE_HIT | PASS protection metadata (damage M5 NOT_IMPLEMENTED) |
| PRE3-R05/P1-D03 RP cap and expiration | M35-END2END-RP_CAP6_FROM_AP, M35-WINDOW-RP_CONTINUES_AS4, M35-AOE-GUARD1RP, M35-RP_ZERO-EMPTY_WINDOW | PASS real shared M2 RP, empty Window only at truly 0 RP |
| CORE-04 P1-D05 Smart/Always Ask/Quick strict consent/no time based advancement | tests/test_m3_replay.gd M35-REPLAY-THREE_MODES_FINAL_STATE_EQUAL, M35-REPLAY-NO_WALL_CLOCK_IN_STATE | PASS pure Domain output; legacy UI not migrated |
| P2-D16/CardZone invariant fixed seeded Replay | M35-REPLAY-EXACT_EVENT_HASH, M35-REPLAY-CARD_CONSERVATION, M35-REPLAY-DUPLICATE_ID_REJECTED | PASS 47 command tape and canonical event/final-state SHA256 |
| CORE-03 no player movement added | P2-VIS-02-NO_MOVE_COMMAND | PASS fail-closed unsupported MOVE |
| M4/M5 and Presentation boundaries | Report PH3_M3_5_ACCEPTANCE_REPORT.md | Headless Domain PASS; live magic/damage/UI still deferred |

**VERDICT: M3 DOMAIN VERIFIED — HEADLESS FIXTURE SCOPE (M3.1–M3.5)**. Do not call the Godot app PLAYABLE VERIFIED, casting VERIFIED, hit/damage VERIFIED or old countdown removed. See acceptance report for full SHA256 replay proof and exact remaining dependencies.
