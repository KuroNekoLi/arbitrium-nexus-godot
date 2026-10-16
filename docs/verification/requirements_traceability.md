# G0 Requirements Traceability Matrix — Arbitrium Nexus

2026-10-16 RET-01～05：使用者核准耗竭真正退場、敵存活且無存活在場我方判DEFEAT；新版Lv40配置v3、效果後退場、非法目標原子拒絕、舊配置Replay隔離。來源見 [核准紀錄](../combat/LAST_SPELL_RETIREMENT_APPROVED_20261016.md)，本輪證據及測試次數見 [整合Note](ui/V3_RETIREMENT_INTEGRATION_NOTE_20261016.md)。本條不升級歷史GUI或美術驗收。

2026-10-16 Last Spell 範圍 UI：LST-UI01～05／LST-DOM01／LST-COMPAT01 與新群組 22/22→26/26→26/28→使用者明確追加一次29/29 見 [Last Scope Note](ui/LAST_SPELL_TARGET_SCOPE_ENGINEERING_NOTE_20261016.md)。SCOPED_NATIVE_VERIFIED；既有完整回歸／CI未重跑，非使用者高保真驗收完成。

2026-10-16 V3.5續作：SP拖放／長按、符卡詳情純資訊、右上工具移除與Last cut-in的最新USER_APPROVED來源及實際收據，見 [V35 Current Review](ui/V35_FINAL_REVIEW_REPORT.md)。81f3d94完整Domain／100seeds CI成功；77bd22a導致Lv40三項相容失敗；1861663修復後新Last native25/25 CI成功，但原Lv4032未追加複驗、最新截圖待授權，整體NEEDS_REVISION。保留P4.4 14/16與全部失敗，不升級最終視覺驗收。

## V3.5 quota checkpoint 2026-10-15

V3.5.0 pinned references 1d64ccd；AP部分已實作，new32/32、HUD36/Layout18/Integration31及修正後靜態9PNG30/30本地通過。V3.5.1角色卡與.2–.5未完成；CI_PENDING／NEEDS_REVISION，不宣告High-Fidelity VERIFIED。剩29%按使用者規則交接，詳docs/handoff/V35_QUOTA_HANDOFF.md；master/V2未修改。

## V3.4 Review 2026-10-15

來源53fdbdfec6f5fcdbfb9ae66087cd8c81ea84ac7f；基準master2ce71a2。Hero HP/MP、六Command皮膚保留API；修正legacy沒有catalogue造成格式錯誤，新增獨立元件18條。
V34首輪102/102，但legacy stderr有ERROR而正確紅燈；修正後VERIFIED（技術/headless/靜態畫面）。正式Master89871c9：Fast38751653887／Full38751653715／Render38751653611全success；V34 102/102、legacy18/18、P4 19組937+4Legacy；1238 Domain/100Seeds保持，歷史GUI不重跑。
完整失敗與最終收據見[V3.4審查報告](ui/V3_4_REVIEW_AND_MERGE_REPORT.md)。

## V3.1–V3.3 Review 2026-10-15

來源85d5c64b396145beca43153d66c644ab2497a269；基準master a355d0b。
保留V2穩定wrap/modal；新增Frame成本實際寬度、idle StyleBox還原、Boss Locked/Exposed分行；Domain無差異。
V31/V32/V33與V3 merge90納入canonical Fast，17組817assertions；canonical Render 12PNG；Full保持1238/100Seeds/4Legacy。
狀態VERIFIED（技術/headless/靜態畫面）；Master2ce71a2：Fast38750028130／Full38750028321／Render38750027917全success。GUI_NOT_VERIFIED（原P43/P44/V25/V26皆不重跑）。完整帳本及最終收據見[整合報告](ui/V3_REVIEW_AND_MERGE_REPORT.md)。

## V2 Review 2026-10-15

正式收據：V2來源822b1ce已由d9e6e2a merge；最終程式d1a971a9c4800e04196ba648416f900148ea122d已在master，Master Fast38743758109／Render38743758086／Full38743758255均success。V27 8/8、13組P4契約576、1238 Domain/100seeds保持；V26第三次47/47只在d9e6e2a staged驗證，Master沒有第4次。下表CI_PENDING保留為施工時快照，最終狀態以本收據及V2_REVIEW_AND_MERGE_REPORT為準。

| Requirement | Source | Implementation / evidence | Status |
|---|---|---|---|
| V2 layout/hand/context | V2 notes / user V2 review | 822b1ce reviewed with master adb7582；layout18/context23/hand39本地PASS | CI_PENDING |
| V26 missing UX / modal safety | UI02 / UIUX / user V2 request | HUD input shield/tree order/WeakRef focus suspend+restore；新V26首輪44/47、次輪40/47，最後CI待執行 | IMPLEMENTED_NOT_VERIFIED |
| No Domain drift | CombatImplementationContract §2 | scripts/domain無差異；1238/100seeds保留Full Gate；原P44及V25 NOT_RERUN | CI_PENDING |


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


## M4.1 Dual Casting independent gate — 2026-10-15

Source 8fcd65ee075664593a08448f3d44eede21a5c2bf; official [Godot4.7.2 CI #38654007627](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38654007627). M4.1 47/47 PASS and full M1–M3.5 598/598 PASS, total 645/645, four legacy smoke runners exit0. Replay hashes and repair record in PH3_M4_1_ENGINEERING_NOTE.md.

| Rule / source | Confirmed executable oracles | Status |
|---|---|---|
| CAST-001 Chantless immediate effect contract, Hand→Discard | CAST-001-CHANTLESS_ACCEPTED, CAST-001-IMMEDIATE_EFFECT_CONTRACT, CAST-001-COST_PAID_ONCE | PASS headless contract; M5 damage deferred |
| CAST-002 Full Chant and Concentration | CAST-002-FULL_ACCEPTED, CAST-002-ONE_CASTING_INSTANCE, CAST-002-CARD_IN_CASTING | PASS one active cast and accurate card zone |
| M-D21 same default MP in Chantless and Full | M21-CAST-001-EQUAL_BASE_MP, CAST-002-COST_PAID_AT_START | PASS authoritative M2 MP quote |
| CAST-003 Concentration action restriction | CAST-003-BASIC_ATTACK_DENIED, CAST-003-SECOND_FULL_DENIED | PASS rejects without mutation |
| PRE3-R09/R12 release before AP/draw | CAST-002-EVENT_BEFORE_M2_RENEW_AND_DRAW, CAST-002-RELEASE_NO_SECOND_PAYMENT | PASS real M3 Boundary and M2 settlement |
| Replay / fail-closed | CAST-002-M4_REPLAY_ENTIRE_PHASE, CAST-NEG-INSUFFICIENT_MP_ATOMIC, CAST-NEG-DUPLICATE_COMMAND | PASS at fixed Seed 20261014 |

**M4.2–M4.5 not executed, overall M4 DOMAIN VERIFIED not claimed.**


## M4.2 Casting Disruption & Focus Ward — independent verified Domain (2026-10-15)

Official Godot4.7.2 https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38656070665 on source **8a808cb0ef685fa48633740c6ae4a3f60f370c83**: **59/59 M4.2**, **47/47 M4.1**, **598/598 M1–M3.5**, grand total **704/704 named assertions**, 4 legacy smoke scripts passed. See PH3_M4_2_ENGINEERING_NOTE.md for actual replay SHA256 and repair history.

| Requirement / decision | Executed Godot test IDs | Bounded outcome |
|---|---|---|
| CAST-004 Ward absorbs before independent Stability; not HP Barrier | CAST-004-WARD_FIRST_FULLY_ABSORBS; CAST-004-WARD_DEPLETED_BEFORE_STABILITY; CAST-004-FOCUS_WARD_EVENT_NOT_BARRIER | PASS M4.2 per-instance, real HP deferred |
| CAST-005 ordinary Full Chant interruption | CAST-005-STABILITY_ZERO_INTERRUPTS; CAST-005-A_CARD_CASTING_TO_DISCARD; CAST-005-A_CONCENTRATION_CLEARED | PASS real CardInstance zone and concentration, Last Spell excluded |
| M-D22–M-D24 partial immediate MP refund without AP/debt refund | M22-CAST-002-PAID_MP_TRACED_FROM_M2; M22-CAST-002-IMMEDIATE_MP_REFUND; M22-CAST-002-AP_DEBT_NOT_REFUNDED; M22-CAST-002-MP_MAX_CAP | PASS M2 ledger; provisional ratio, no canonical percent |
| P1-D14 Protect prevents on-hit interruption, direct disruption bypasses it | P1-PRT-006-PROTECT_STOPS_ON_HIT_DISRUPTION; CAST-004-DIRECT_BYPASSES_PROTECT; P1-PRT-008-UNPROTECTED_ON_HIT_APPLIES; P1-PRT-008-UNTRUSTED_HIT_FIXTURE_REJECTED | PASS authorized hit fixture only, no M5 hit pipeline |
| Explicit CAST_COMPATIBLE Concentrating actor Reaction SP | CAST-004-CAST_COMPATIBLE_EXECUTED; CAST-004-CONCENTRATION_BASIC_GUARD_REJECTED; CAST-004-FOCUS_WARD_SP_PAYS_REAL_RP_MP | PASS actual M3 Queue, M2 payment, card movement on explicit Confirm |
| P2-D12 CastingInstance vs Boss Break & 2 casters | M42-INDEPENDENT_TWO_CASTS; CAST-005-INDEPENDENT_CASTING_STABILITY; M42-BOSS_BREAK_UNTOUCHED | PASS separate independent casting fields |
| Replay and invalid commands | M42-SEEDED_REPLAY_IDENTICAL_STATE_HASH; M42-SEEDED_REPLAY_IDENTICAL_EVENT_HASH; M42-REPLAY_STALE_FAILS_CLOSED | PASS Seed 20261014, 12-command tape |

M4.3/M4.4/M4.5 and full M4 gate remain NOT_VERIFIED; M5 hit/HP/status and UI not complete.


## M4.3 — Last Spell Engine (2026-10-15 independent verified Domain)

Tested SHA 12d651289ae85078d166fbc1bf68e83a991bb603, official successful [Godot4.7.2 CI #38658279319](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38658279319): **M4.3 55/55**, all predecessors M1–M4.2 **704/704**, total **759/759** named Domain tests, four legacy headless scripts exit0. Repair history and canonical Seed/hash proof in PH3_M4_3_ENGINEERING_NOTE.md.

| Source requirement | Actual executed oracle IDs | Verified bounded outcome |
|---|---|---|
| LAST-001 slot, unlocked, once-per-battle, Full-only, actual M2 payment, no card zone | LAST-001-PRECONFIRM_QUOTE, LAST-001-SUBMIT_ACCEPTED, LAST-001-ONCE_USED_COMMITTED, LAST-001-NO_CARD_ZONE_MOVEMENT, LAST-001-AP_MP_ONCE | PASS independent slot and original ledger costs; no phantom SP |
| LAST-002 delayed resolution, no instant M5 damage | LAST-001-UNIQUE_SLOT_NOT_HAND, LAST-002-NOT_EARLY_EFFECT, LAST-003-NO_RELEASE_IN_ROUND2 | PASS scheduled initial round3 and no early effect |
| LAST-003 first destabilization delayed ONCE | LAST-003-ONE_DELAY_USED, LAST-003-DELAY_PREVENTS_ROUND3_RELEASE | PASS first threshold once, still Concentrating |
| LAST-004 further instability weakens, not infinite delay or normal interruption | LAST-004-SECOND_DISRUPTION_WEAKENS, LAST-004-NO_INFINITE_DELAY_OR_STACKING, LAST-003-DISRUPTION-2-DOES_NOT_CANCEL | PASS provisional modifier, no normal MP refund |
| LAST-005 successful release → EXHAUSTED, no BaseAP loss | LAST-005-RELEASE_ONCE_AT_ROUND4, LAST-005-ACTOR_EXHAUSTED, LAST-005-BASE_AP_STILL_SIX, LAST-005-EXHAUSTED_TARGETABLE_ALIVE | PASS headless Domain only; real M5 damage deferred |
| Deterministic Replay and strict command IDs | LAST-REPLAY-SAME_SEED_FINAL, LAST-REPLAY-SAME_SEED_EVENTS, LAST-REPLAY-STALE_FAIL_CLOSED | PASS Seed20261014 / 25 commands |

M4.4 CORE-02 forced HP0 invalidation and M4.5 final complete M4 acceptance remain NOT VERIFIED. These tests do not prove actual Last Spell damage or UI confirmation dialog.


## M4.4 — HP0 Forced Invalidation CORE-02 (2026-10-15, independent verified Domain)

Source tested SHA **8030ce5fe8fed346a4612013f5d77cef2913e3d2**, official [Godot4.7.2 CI #38660801424](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38660801424). **M4.4 59/59 PASS**, previous M1–M4.3 **759/759 PASS**, cumulative **818/818** Domain named assertions, four old prototype runners PASS. Detailed initial failure / correction, seed and SHA256 in PH3_M4_4_ENGINEERING_NOTE.md.

| Requirement | Actual executable oracle | M4.4 verdict (fixture scope) |
|---|---|---|
| CORE-02 & PRE3-R15: caster HP0 instant LastSpellInvalidated before effect | P2-LAST-02-HIT_EVENT_CHAIN, CORE-02-INVALIDATE_CAUSE, CORE-02-PENDING_INSTANCE_ERASED_NOW, CORE-02-SCHEDULE_CANCELED_NOW | PASS ordered same-event forced invalidation; NOT ordinary CastingInterrupt |
| P2-LAST-01/02: T1 commit, T2 HP0, T3 no release | P2-LAST-01-T3_RELEASE_SCHEDULED, P2-LAST-01-NO_RELEASE_T3, P2-LAST-02-INSTANT_HP0 | PASS real M3 phase boundary & M2 payment |
| PRE3-R13 hand/card freeze, ordinary Full Chant HP0 | PRE3-13-CARD_ZONES_FROZEN, P2-LAST-02-HAND_FROZEN_AFTER_ROUND, PRE3-13-ORDINARY_CARD_MOVED, PRE3-13-ORDINARY_NO_MP_REFUND | PASS exact physical CardInstance from Casting to Discard, no MP refund |
| PRE3-R15 MP/AP/Overload/once-used unchanged and Revive cannot resume | P2-LAST-03-NO_MP_REFUND, P2-LAST-03-NO_AP_REFUND, P2-LAST-04-LAST_CANNOT_START_AGAIN, P2-LAST-04-INVALIDATED_HISTORY_PERSISTS | PASS permanent one-use marker, no refund |
| PRE3-R14 late HP0 after successful release | P2-LAST-06-NO_RETROACTIVE_INVALIDATION, PRE3-14-EXHAUSTED_PERSISTS_AFTER_REVIVE | PASS lifetime Exhausted; released effect not canceled |
| Fixture integrity and Replay | PRE3-13-GATED_FIXTURE_NOT_PUBLIC, PRE3-13-UNRELATED_ACTOR_CANNOT_BE_KILLED, P2-LAST-05-REPLAY_IDENTICAL_EVENTS, P2-LAST-05-REPLAY_IDENTICAL_FINAL | PASS exact Seed20261014 / 17 commands, no direct player HP0 override |

**M4.5 final M4 Domain acceptance NOT_VERIFIED. M5 real damage/hit/Revive skills and UI NOT_IMPLEMENTED.**


## Final M4.5 integration and regression gate — verified 2026-10-15

**Supersedes previous earlier phase status "M4.5 NOT_VERIFIED".** Final M4 Domain is VERIFIED **HEADLESS FIXTURE SCOPE ONLY**. Official [Godot 4.7.2 CI #38665591370](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38665591370) tested source SHA 7dc487f3f6ad1021f73293d7de222f1700fb819f: **41/41 M4.5 integration, 38/38 M4.5 replay, 818/818 M1–M4.4 predecessor** named Domain tests; **897/897 total PASS**, 4 legacy smoke scripts exit0.

| Requirement | New real M4.5 oracle(s) | Bounded result |
|---|---|---|
| M2 payments/card conservation and normal Full release before renew/draw | M45-INT-03-ALL_36_CARDS_CONSERVED, M45-INT-07-MIXED_COST_ACTUAL_M2, M45-INT-19-B_FULL_RELEASED, M45-INT-20-RELEASE_BEFORE_AP_AND_DRAW | PASS, damage deferred M5 |
| M3 CAST_COMPATIBLE Ward/Protect payment only on Confirm | M45-INT-11-CONCENTRATING_CAST_COMPATIBLE_PAID, M45-INT-12-WARD_ON_LAST_INSTANCE, M45-INT-14-RP_LEGAL_ON_CONFIRM | PASS |
| ON_HIT interception vs DIRECT instance disruption | M45-INT-15-ON_HIT_SUPPRESSED_AFTER_PROTECT, M45-INT-16-DIRECT_BYPASSES_PROTECT | PASS trusted hit fixture |
| Last Spell one-use/delay and no ordinary refund | M45-INT-06-LAST_USES_NO_CARD_ZONE, M45-INT-17-FIRST_INSTABILITY_DELAY_ONCE, M45-INT-18-NO_INTERRUPTION_REFUND_ON_LAST | PASS provisional stability/weaken |
| CORE-02 caster HP0 immediately invalidates, never refunded or released | M45-INT-28-CORE02_INSTANT_ACTOR_ZERO, M45-INT-29-CORE02_STRICT_CHAIN, M45-INT-30-SCHEDULE_ERASED_AT_DAMAGE_BOUNDARY, M45-INT-31-NEVER_REFUND_AP_MP_OR_USAGE | PASS trusted HP0 fixture |
| Revive cannot restart canceled Last Spell | M45-INT-32-T4_NO_RESURRECTED_LAST_EFFECT, M45-INT-34-REVIVE_NOT_RESTORE_LAST, M45-INT-35-REVIVED_CANNOT_RECAST | PASS fixture |
| Same Seed / Command Tape / ContentConfig / UI modes | M45-REP-02-FINAL_STATE_EQUAL, M45-REP-04-REPEATED_SAME_SEED_EVENTS, M45-REP-25-SMART_NO_DOMAIN_MUTATION, M45-REP-27-ALL_UI_MODES_EQUAL_EVENTS | PASS 34 commands |
| Negative authorization and atomicity | M45-REP-29-STALE_TAPE_FAILS_CLOSED, M45-REP-31-DUPLICATE_COMMAND_REJECTED, M45-REP-32-HIT_AUTHORIZATION_NOT_SKIPPED, M45-INT-41-NO_PUBLIC_KILL_COMMAND | PASS |

Only M4 Domain is verified. Full M5 hit/HP/damage/Status/Boss Break and presentation require independent implementation. See PH3_M4_5_ACCEPTANCE_REPORT.md and PH3_M4_HANDOFF.md.


## M5.1 actual Hit/Crit/Damage traceability — VERIFIED 2026-10-15

Official [Godot 4.7.2 CI #38668678354](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38668678354), source 407ca2c9e3f7ffc67de45e2150300465420192d1, new 44/44 + predecessor 897/897 = **941/941 named Domain PASS** and four legacy smoke PASS.

| Requirement | Godot exact oracle examples (all passed) | Domain-only outcome |
|---|---|---|
| P2-D01–D04 Hit/miss/5–95 clamp/RNG | M51-04-GUARANTEED_NO_RNG, M51-05-CHANCE_PERCENT_RNG_ONCE, M51-06-HIT_CLAMP_95, M51-07-HIT_CLAMP_05, M51-08-CONDITIONAL_MISS_NO_RNG | PASS |
| P2-D07/08 Crit only on eligible hits | M51-10-INELIGIBLE_CRIT_NO_RNG, M51-11-ELIGIBLE_CRIT_100_PERCENT, M51-15-MISS_HAS_ZERO_DAMAGE_AND_NO_CRIT_ROLL | PASS |
| P2-D05/09–11 target element/actual HP/floor0 | M51-12-REAL_HP_DEDUCTED, M51-13-ONE_TRACE_ONE_HP_EVENT, M51-16-ELEMENT_BY_ENEMY, M51-21-ZERO_DAMAGE_NOT_CHIP_ONE | PASS |
| PRE3-R01/R06/R07 Protect/Guard/HPBarrier | M51-17-PROTECT_USES_RECIPIENT_DEFENSE, M51-18-UNAUTHORIZED_REDIRECT_REJECTED, M51-19-GUARD_THEN_BARRIER, M51-20-FOCUS_WARD_NOT_HP_BARRIER | PASS |
| P2-D14/CORE-02 HP0 | M51-24-REAL_HP0_CALLS_M4_INVALIDATOR | PASS |
| P2-D10 M2 real costs and M3/M4 release before resources | M51-25-CHANTLESS_REAL_DAMAGE_BEFORE_OUTCOME, M51-26-CHANTLESS_AP_MP_ONCE, M51-29-BASIC_ATTACK_REAL_DAMAGE, M51-32-ENEMY_ACTION_REAL_TWO_HITS, M51-36-FULL_RELEASE_BEFORE_AP_DRAW, M51-38-FULL_NO_SECOND_PAYMENT | PASS |
| P2-D16 Replay/atomicity | M51-01-AUTHORITY_ENFORCED, M51-39-INITIAL_IMMUTABLE, M51-40-SAME_TAPE_EVENT_HASH, M51-41-SAME_TAPE_FINAL_HASH, M51-42-STALE_REPLAY_REFUSED | PASS |

This is M5.1 **headless fixture scope only**, not M5.2–M5.5 complete battle or Last Spell-specific live damage gate. Seed/hashes/failed CI history in PH3_M5_1_ENGINEERING_NOTE.md.

## M5.2 authentic Status / Targeting / HP Lifecycle — VERIFIED 2026-10-15

**Supersedes prior earlier M5.2 NOT_VERIFIED planning.** Official [Godot 4.7.2 Actions #38670492488](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38670492488), tested SHA 20e2e7da8cc841c73d9a558860681465460754a0; **48/48 new M5.2 PASS**, **941/941 M1–M5.1 prior PASS**, **989/989 cumulative named Domain PASS**, four legacy smoke scripts PASS. Headless fixture scope ONLY.

| Binding rule | Actual named executable Godot cases | Outcome / limit |
|---|---|---|
| P2-D13/PRE3-R03/R08 StatusInstance stack/refill/tick ordering | M52-05, M52-06, M52-07, M52-14, M52-16, M52-17, M52-25–M52-29 | PASS: versioned content and stable priority + id |
| P2-D12 Focus Ward != HP Barrier, Guard→HP Barrier, expiry | M52-08, M52-09, M52-12, M52-30, M52-32 | PASS: registered barrier instance / defined expiration |
| P2-D13 BUFF/DEBUFF/DoT/HoT/dispel | M52-15, M52-26, M52-27, M52-31, M52-33, M52-34 | PASS: actual HP/stat changes, registered fixture only |
| PRE3-R06 Protect/hit-follows policy | M52-13, M52-44, M52-45 | PASS: real EnemyAction M5 verified hit trace, correct recipient |
| CORE-02 DoT HP0 immediate before LastSpell release | M52-35–M52-39 | PASS: exact event ordering + frozen hand, no refund |
| P2-D14 legit tagged Revive and ordinary Heal | M52-40–M52-43 | PASS: actual paid SP, no revived Last quota |
| M2 resources/CardInstances, M3 phase, Replay and fail-closed | M52-01–M52-04, M52-10–M52-11, M52-18–M52-24, M52-46–M52-48 | PASS: unchanged state on denial / deterministic 10-command tape |

Only M5.2 Domain is verified; M5.3–5.5 and full real Boss battle not verified. See PH3_M5_2_ENGINEERING_NOTE.md and PH3_PHASE12_TEST_INVENTORY.md for exact 48 case IDs/Seed/hashes.

## M5.3 — Boss FSM / public Intent / whole-SP Break / Exposed / paid Combo — VERIFIED 2026-10-15

**Supersedes only M5.3 historical NOT_VERIFIED snapshots above.** Official [Godot 4.7.2 Actions #38674222091](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38674222091), tested code SHA e9e33ce86bd1232aa1323c4a9c8a97ce85ef12b0; **44/44 M5.3 new cases PASS** + **989/989 predecessors PASS** = **1033/1033 named Domain assertions**, 4 legacy smoke scripts success. Headless fixture scope only.

| Binding rule / source | Named Godot tests | Verifiable scope / limitation |
|---|---|---|
| 06 Boss FSM, public intent unchanged after Reaction | M53-22–25, M53-30, M53-42 | PASS: deterministic committed single-target Boss policy and next-action published fallback; multi-enemy/conditional hidden branches untested |
| P2-S25–31 whole-SP Break, fallback action and reset | M53-08–10, M53-20, M53-23, M53-26–28, M53-34 | PASS: full two hits before Break, locked Gauge, public fallback, actual resolved action restores Gauge; Counter-cancelled fallback is content-blocked |
| P2-S17–24 Exposed created, one use, no refresh, expiry, Miss | M53-11, M53-17, M53-35, M53-37, M53-39–41 | PASS: no same-SP exploit, successful later SP consumption, retained on Miss, explicit next Player Phase-end expiry |
| 09 COMBO-001～004: different actor and real second SP | M53-12–13, M53-15–19, M53-21, M53-36, M53-38 | PASS: actual M2 paid CardInstance, original AP/MP cost once, 0 additional Combo AP; defensive/casting/resonance content untested |
| M2 payment, M5.1 real HP, M4.4 HP0, M1 replay | M53-01–07, M53-14, M53-29, M53-31–33, M53-43–44 | PASS: no duplicate cards, event and state hash replay, fail-closed rejection, 9 accepted command tape |
| P2-S15/S16 Spell Counter | none | **BLOCKED_CONTENT / NOT VERIFIED**; no approved Counter skill/window; must not be conflated with Casting Interrupt |
| P2-S02～S12 Analyze/Enemy Intel | none | **DEFERRED_CONTENT / NOT VERIFIED** |
| CORE-01 full same-action multi-effect outcome | none | **M5.4 NOT VERIFIED**, existing basic outcome only |
| M5.5 100-seed complete Boss battle | none | **NOT VERIFIED** |

Full source, hashes and limits: [PH3_M5_3_ENGINEERING_NOTE.md](PH3_M5_3_ENGINEERING_NOTE.md). Do not promote whole M5 to VERIFIED based on this M5.3 subgate.

## M5.4 — Action/Status/Casting Outcome CORE-01/02 — VERIFIED 2026-10-15

**Supersedes M5.4-only historical NOT_VERIFIED summaries above, not M5.5.** Official [Godot 4.7.2 CI #38676335088](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38676335088) on SHA `117a41772fcccc193ef9b40dceac595710ccab1f`: **48/48 new M5.4**, preceding **1,033/1,033**, cumulative **1,081/1,081** named Domain assertions; all four legacy runners PASS. Scope **HEADLESS_FIXTURE_ONLY**.

| Requirement | Executed exact Godot oracle ID(s) | Evidence / limit |
|---|---|---|
| USER_APPROVED CORE-01 / P2-D15 / P2-OUT-01: full Action effects then enemy-clear-first VICTORY | M54-04～M54-10, M54-25, M54-31～M54-33, M54-38～M54-39 | PASS: real paid SP + registered recoil, two real DoT ticks, released Last Spell plus recoil; no DRAW |
| P2-OUT-02: Boss lives with all three incapacitated = DEFEAT | M54-26～M54-29 | PASS: declared M3 EnemyAction with M5.1 HP damage |
| PRE3-R09 / P2-D13: Casting→StatusTick→Outcome→AP renewal/draw | M54-30～M54-34, M54-36～M54-40 | PASS: no resources opened on terminal StatusTick; actual Casting release before Outcome |
| USER_APPROVED CORE-02 / PRE3-R13/R15: instant HP0 invalidation of unreleased Last; after actual release cannot retro-cancel | M54-35～M54-45 | PASS: pre-release LastSpellInvalidated + ScheduledEffectCancelled, no refund; post-release LastSpellReleased remains valid |
| Outcome terminality and atomic denial incl RNG/Replay | M54-01～M54-03, M54-11～M54-24, M54-48 | PASS: no forged HP/outcome, one original M2 charge, card conservation, 1-command canonical replay and rejected extra command |
| All-EXHAUSTED HP>0 ambiguity | M54-46, M54-47 | `CORE_RULE_EDGE_PENDING`: explicit event, no arbitrary DEFEAT |
| Full Battle M5.5 100 seeds | none | **NOT_VERIFIED** |
| Analyze/Enemy Intel & Spell Counter | none | **DEFERRED_CONTENT / BLOCKED_CONTENT / NOT_VERIFIED** |

Exact 48 IDs and SHA256 evidence in [PH3_M5_4_ENGINEERING_NOTE.md](PH3_M5_4_ENGINEERING_NOTE.md) and [PH3_PHASE12_TEST_INVENTORY.md](PH3_PHASE12_TEST_INVENTORY.md). Numeric registered recoil and fixture starting HP are explicitly `BALANCE_PROVISIONAL`, not new approved card canon. All existing M2–M5.3 engine integrations are retained.

## M5.5 — True three-person Boss battle, Replay and 100 seeds — VERIFIED in branch CI 2026-10-15

**Source of evidence:** [Godot 4.7.2 Actions #38677695295](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38677695295), tested code SHA `7d6f961d7bcff7e0ae0f1435a02ac013a92f0569`; 32/32 golden integration, 15/15 deterministic Replay, **110/110 for exactly 100 fixed seeded complete battles**, all M1–M5.4 1,081/1,081 regressions PASS, four legacy headless smoke runners PASS. Cumulative **1,238/1,238 named Domain** (fixture-only, not UI). **Final master post-merge CI [#38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741) at code SHA `9c8b14b873047ca181a229cfaab5d2351541ceab` completed/success**: 157/157 new + 1,081/1,081 predecessors = **1,238/1,238**, 100 terminal/100 Replay, four legacy smoke success. Verdict **`M5 DOMAIN VERIFIED — HEADLESS BATTLE / FIXTURE_ONLY`**, not UI/Content/Balance.

| Requirement / authorized source | Actual test IDs | Verified behavior and limitations |
|---|---|---|
| M5.5 full encounter; docs/combat/23 §6, PH3_M5_EXECUTION_PLAN M5.5 | M55-INT-01～M55-INT-09, M55-INT-24～28 | Three ACTIVE actors / three distinct seeded 12-card decks / Boss HP290, true CardInstance payment + draw, multiround terminal outcome, no fake final HP |
| P2-D16-001 / P2-REPLAY-01 / RNG-001 | M55-INT-29～32, M55-REP-01～12, M55-SEED-20261014～M55-SEED-20261113 | Full 49-command golden Command Tape, exact initial/tape/event/final SHA256, 100 independently replayed complete encounters, no event/state/RNG mutations on tampered/stale/terminal replay |
| P2-VIS-01/02, CORE-04 explicit reactions (no auto-pass) | M55-INT-21, M55-REP-13-PRESENTATION_ALWAYS_ASK/SMART/QUICK, M55-INT-31 | Golden Explicit Guard/Confirm or Pass within authorized M3 Reaction window; 3 UI mode configuration values leave Domain traces unchanged, no FPS or timer-driven reaction |
| BREAK-001 / P2-S25～31 | M55-INT-10～14, M55-100-09 | Public Boss Intent, actual M5.1 Boss hits, BreakTriggered, real one-shot BossBreakRecovered; provisional Boss skill profiles |
| COMBO-001～004 / P2-S17～24 | M55-INT-15～17 | Different actors pay distinct SP, Exposed created/consumed in later SP, actual Combo and real HP, retained all prior M53 negatives |
| M4 Full/Last / CORE-02; PRE3-R09 | M55-INT-18～20, M55-INT-27, M55-INT-29 | Real Full Chant and Last Spell release + exhausted, status tick/phase order, no extra payment; prior M4.4 CORE-02 regression still passes |
| P2-D12/13 Status HP Barrier/HoT/DoT / resource properties | M55-INT-22～26, M55-100-04/05, 100 per-seed reports | Registered status with live tick, card zone conservation, nonnegative HP/AP/MP/RP, no invalid policy command |
| 100 fixed-seed engineering resilience / exhaustion safeguards | M55-100-01～10, M55-SEED-20261014～M55-SEED-20261113 | 100 terminal outcomes and full deterministic Replay; 5244 accepted commands / 0 rejects; 100 VICTORY / 0 DEFEAT; max 6 rounds, max 282 events, 100 distinct tapes. No gameplay balance conclusion. |
| Core M5.4 Outcome / VICTORY > DEFEAT / post-terminal atomic | M55-INT-07/28, M55-REP-12, preceding M54-01～48 | Same existing Boundary outcome authority, legal fight end then no post-terminal commands; prior 48/48 M5.4 checks still pass |
| Spell Counter P2-S15/S16 | none | **BLOCKED_CONTENT / NOT VERIFIED**, no approved Counter card/window |
| Analyze / Enemy Intel P2-S02～12 | none | **DEFERRED_CONTENT / NOT VERIFIED** |
| All-party positive-HP but EXHAUSTED edge | M54-46/47 predecessor | **CORE_RULE_EDGE_PENDING**, not silently defeated |
| Presentation/2.5D bilingual playable human verification | none | **NOT VERIFIED**; next Presentation Spike + actual real-player playtest |

**Limit:** seeded-shuffled duplicate SP instances reflect fixture content, not all possible retail skills/Boss patterns. Neither all 100 fixture victories nor 1,238 Domain assertions certify real-game balance or PLAYABLE VERIFIED. See [PH3_M5_5_ACCEPTANCE_REPORT.md](PH3_M5_5_ACCEPTANCE_REPORT.md) and [PH3_M5_HANDOFF.md](PH3_M5_HANDOFF.md) for actual hashes, commands, architecture and future work.

## Phase 4 Presentation（2026-10-15，本輪範圍）

| Requirement | Source | Implementation | Tests / evidence | Status |
|---|---|---|---|---|
| P4.1 / CORE-03 | COMBAT_PHASE4_HANDOFF §2、UI01/04 | scenes/battle/battle_screen.tscn、scripts/battle/presentation/battle_actor.gd | P41-SCENE-01～07（尺寸兩例，共8）；outputs/p4_1_1280.png、p4_1_1920.png、p4_1_sprite3d_spike.png；ui/P4_1_ENGINEERING_NOTE.md | 本機8/8，遠端CI待核對 |
| Single authority / no UI mutation | COMBAT_IMPLEMENTATION_CONTRACT §2 | battle_presentation_adapter.gd | 真M5 fixture snapshot；回歸outputs/p4_logs/p41_regression | 本機驗證中；不變更Domain |
| P4.1 remote gate | P4.1 | 66a8b3faf776ca2d4f8371718e89ea3c89aef4fe | Actions 38681239677 success | VERIFIED |
| P4.2 / UI01-02-05 | Handoff P4.2 | BattleHUD / BattleCardView / BattleCommandFactory / i18n | test_p4_hud 36/36；outputs/p4_2_*；ui/P4_2_ENGINEERING_NOTE.md | 本機驗收通過；遠端待核對 |
| P4.2 remote gate | P4.2 | 961c05061665be1c518d041ce05508c225fdb8ae | Actions 38682762145 success；38682762150 success | VERIFIED |
| P4.3 real transaction / replay | Handoff P4.3 / Contract §2 | battle_controller / battle_screen / animation_director（工作樹） | 三次27/27、27/27、30/31；付款順序oracle修正未重跑；ui/P4_3_ENGINEERING_NOTE.md | NOT VERIFIED / QA_EXECUTION_LIMIT；未push |
| P4.3 actual input / fan reuse | UI02/04/05 | SimpleCards ArcShape / Tween / BattleCardView | test_p4_input_capture 16/16；outputs/p4_3_*；兩尺寸8張旋轉四角 | 本機GUI自動輸入PASS；非真人playtest |
| P4.3 resumed gate | 使用者續作／Handoff P4.3 | 同名runner，修正SPCostReservedOnly oracle | p43_resume_attempt1 31/31；Scene8/8、HUD36/36、GUI16/16 | 本機通過；正式CI待核對 |
| P4.3 official gate | Handoff P4.3 | 5103e40a4b95da82f2561b29c2604e9514fd398b | Actions38685051780 success | VERIFIED（其SHA範圍，非P4.4） |
| CI-EVIDENCE-01 | docs/combat/22 §5.2 / QA | tools/ci/assert_godot_logs.py / M5.5 workflow | 19/19；真Godot exit17；90f2ded3aa673050ba76062a96d0829cfe35d986 / Actions38693224299 success，37logs errors0/warnings0 | VERIFIED，非P4.4 GUI |
| CI-EVIDENCE-02 | docs/combat/22 §5.5 / lifecycle | tests/test_combat_ui.gd | 原assertions保留；第三輪clean shutdown；同SHA雲端4Legacy通過 | VERIFIED（清理scope），非新版Gameplay驗收 |
| CI-EVIDENCE official master | 同上，基建驗收 | 90f2ded3aa673050ba76062a96d0829cfe35d986 | Actions38693953249 / 38693953070 success；37logs errors0/warnings0 | VERIFIED，P4.4 GUI未重跑 |

## P4 reviewed selective promotions (2026-10-15)

| Requirement scope | Master source SHA | Accepted evidence | Status |
|---|---|---|---|
| Lv40 content/M5 adapters, independent M3/M4 fixes, stats/profile pure unit tests | `c2796e31` | staging [#38717257405](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38717257405) and master M5.5 100-seed regression | **HEADLESS VERIFIED ONLY**; content/balance provisional |
| Bilingual name/description and read-only Lv40 projection | `d4d5b998` | 198 localization, 29 ReadModel, P4.1/2/3 regressions; [#38718051812](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718051812) | **HEADLESS VERIFIED ONLY** |
| Scene-component HUD / animation feedback | `f40686cd` | 24 component, 45 feedback, 80 edge; [#38718716573](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718716573) | **HEADLESS VERIFIED; GUI_NOT_VERIFIED** |
| Level40 Stage UI | `f40686cd` | `P4_LV40_UI_STAGING_REPORT 10/10` asserts no live snapshot/controller | **INTENTIONALLY_BLOCKED; NOT PLAYABLE** |
| Real GUI input / balance / human QA | source branch checkpoint | GUI capture 14/16 on third; no authorized fourth | **NOT VERIFIED** |

See [review and outstanding branches](../handoff/P4_APPROVED_MERGES_AND_PENDING_REVIEW_20261015.md) for exact remaining gaps and test-budget boundaries. This is a supplemental status entry; earlier historical Phase4 milestones are retained for traceability.

## All branches integration continuation — 2026-10-15

| Requirement | Source | Implementation/evidence | Status |
|---|---|---|---|
| G0 semantic branch classification | All Branches Review §5 | docs/handoff/BRANCH_SEMANTIC_AUDIT_20261015.md；17 refs、merge-base/cherry/blob/有效替代diff | STATIC_AUDIT_COMPLETE，非runtime保證 |
| G4 new positive Lv40 integration | All Branches Review §6 / UI02 | lv40_playable_battle.tscn / config-aware BattleScreen / Controller / test_p4_lv40_playable32/32首輪 | HEADLESS_PARTIALLY_VERIFIED，等待CI；原staging10保持 |
| SW scoped screenshot writer | All Branches Review §6 | scripts/qa/screenshot_writer.gd / test_screenshot_writer；首輪45/46 FAIL，已修普通檔阻擋，待CI | IMPLEMENTED_NOT_VERIFIED；原GUI14/16未重跑 |
| P45 static scene evidence | 獨立場景檢查、非原GUI runner | capture_lv40_playable_scene.gd；GTX1650、1280繁中/1920英文PNG、主控目視 | STATIC_RENDER_OBSERVED，非真人/完整GUI/效能驗收 |

正式Master收據：f16227c1e67457de53b3547a73462416c32349ef；Actions38726127054（1238 Domain/100seeds/4Legacy）、38726127041（HUD/正向32/writer46）、38726127002（Legacy）均completed/success。GUI14/16及真人/P4.6不升級；詳ALL_BRANCHES_FINAL_MERGE_REPORT。

## Character appearance / Editor Live Preview — 2026-10-16

| Requirement | Actual evidence | Verification |
|---|---|---|
| Last Spell team/single/all targeting (LST-UI01–05, LST-DOM01) | Existing branch native scope batch4 **29/29** and 4 valid PNGs | **SCOPED_NATIVE_VERIFIED**, no rerun; original User Visual Acceptance still pending |
| 3 independent Lv40 appearance resources + registry | 6 PNGs/3 `.tres`, A→Ren/B→Akane/C→Tsumugi, nonuniform atlas regions | **IMPLEMENTED**, editor import and 31 initial QA assertions passed; dedicated suite 35/35 **NOT VERIFIED** |
| Editable actor slots, independent CG/portraits, mock-only editor HUD | `@tool BattleActor/BattleScreen`, real HUD nodes, Registry, no Editor Controller/Domain, character Signal cleanup designed | **IMPLEMENTED_NOT_FULLY_VERIFIED** (strict editor import passed on prior source; native Editor GUI screenshot not executed) |
| Original sprite/portrait relocation | old binary blobs moved under `assets/legacy/`, legacy prototype preload paths updated; current battle resources unaffected | **IMPLEMENTED_PENDING_FAST_CI** until final integration run |
| Final actor art and high-fidelity scene | Six candidate images are AI generated; no final visual user approval | **VISUAL_NOT_VERIFIED / USER_APPROVAL_PENDING** |

Original Last Spell group, old P4.4 GUI group and separate character appearance suite have exhausted their respective authorized attempt budgets. Do not rerun without explicit owner authorization. See [Checkpoint](../handoff/CHARACTER_ATLAS_EDITOR_PREVIEW_CHECKPOINT_20261016.md).

### Current CI regression caveat — 2026-10-16
- [Fast #38837390317](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38837390317) **FAILED** on Last Spell Release GDScript typed-array runtime bug and P4 V35 Resource leak/error. Conditional typed-array fix committed subsequently without rerun; status remains **NOT_VERIFIED**.
- Appearance group [#38836688296](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38836688296) third attempt Editor Import succeeded, initial 31 assertions passed then fixture initialization nil failed; subsequent deferred-run test change not rerun (quota exhausted). **35/35 NOT VERIFIED**.

### Authorized completion / master merge — 2026-10-16

以上 caveat 為保留的歷史快照；本輪使用者明確追加驗證權限後已修復並合併 master `bc057c5b419ee43bec25e5fb179e9f4dbe3f8312`。

| Requirement | New evidence | Status |
|---|---|---|
| Independent Lv40 actors / atlas / CG | appearance39/39 CI38840497344；native character15/15；actual Editor PNG | SCOPED_VERIFIED |
| Editor preview isolation / live appearance / re-entry | no Controller/snapshot in actual editor；Resource changed / re-entry / foot anchor assertions | SCOPED_VERIFIED；不是OS F6按鍵測試 |
| Legacy relocation / playable runtime / scope | Master Fast38843036070成功；P4候選1149＋Legacy4成功；native Last scope29/29 | SCOPED_VERIFIED |
| M1–M5.5 regression | Master Integration38843037835：1128/1128；本機100 seeds runner110/110 | 1238/1238；100完整battle/replay PASS |
| Final visual identity / high-fidelity user acceptance | generated candidate art、Boss placeholder、3-frame actions | USER_APPROVAL_PENDING |

完整SHA／Run URL、失敗與修復、raw logs、截圖、runner重疊造成的次數例外見 [Final Merge Receipt](../handoff/CHARACTER_EDITOR_FINAL_MERGE_REPORT_20261016.md)。沒有修改原測試斷言或清除歷史P4.4 GUI14/16。
