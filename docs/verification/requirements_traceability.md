# G0 Requirements Traceability Matrix — Arbitrium Nexus

> 日期：2026-10-14；程式基準 `c9678782b818f825b85561313bd142130c330fdf`；本表依 GitHub **靜態程式檢視**。所有 `Actual Test Result = NOT_EXECUTED`，不把文件指定的 Test ID 等同已跑 PASS。Spec 詳情參見 `../combat/00`～`24`。此表優先盤點工程關鍵不變量；完整逐一展開規格檔 13 的全部 test IDs，列為 M1 RTM 擴充義務。

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
| G0-R28 | Godot headless negative failure exit probe（23） | 現有測試可 quit(1)，未見專用failure probe | NOT_VERIFIED | 實跑失敗必 nonzero；成功必0 | G0/M1 |
| G0-R29 | CI與實測版本（23） | `.github/workflows` 查詢404 | MISSING | Github Actions runtime、logs、artifacts、Godot版本 | G0 |
| G0-R30 | 測試 oracle 更新（13/21） | `test_battle_state.gd` 預期8卡/兩次；`test_turn_flow.gd` 預期timeout | CONFLICT | 明確標 LEGACY_SUPERSEDED，新增新版正/負/邊界測試 | M1–M5 |

## 必須延伸的工作

- 第13號規格文內所有 P1/P2/M/PRE3/CORE testcase ID，M1 建立全量 machine-readable mapping（ID、spec source、expected state/event、fixture、runnable test、actual output、status）。
- 禁止把本表 `PARTIAL` 直接升級 `PASS`；需在 **本 Godot repo** 同 Godot runtime 執行 headless，留下 stdout/stderr, exit code, SHA, seed, state hashes。
- 需要新 `docs/verification/PH3_G0_BASELINE_RUN.md` 保存實際二進位、CI、命令與測試結果；未跑前不可產生假紀錄。
