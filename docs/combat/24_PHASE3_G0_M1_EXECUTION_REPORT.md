# 24 — Astraea Phase 3 G0 + M1 Headless Combat Engine 交付與驗證狀態

> **Documentation status · 2026-10-15 — HISTORICAL_M1_ENGINEERING_EVIDENCE**：原 G0/M1 14/14 與 `Astraea-Academy` 路徑是當時工程快照，不代表目前 master 僅完成 M1。現行執行倉庫 `arbitrium-nexus-godot` 已驗證 M1～M5.4，共1,081項 Domain case。 導覽：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；未決：[Open Issues](COMBAT_OPEN_ISSUES.md)。M5.5／完整可玩驗證尚未完成。以下保留來源快照，不能解讀為此刻最新驗收。


> 日期：2026-10-14。本檔是 Phase 3 的**實際工程進度交接**，不替換 Phase 1–2 的正式玩法規格。**最終狀態：`M1 SCAFFOLD VERIFIED`（Godot 4.7.2 CI 14/14 PASS）；M2～M5 尚未開始。本次驗收僅涵蓋 M1 骨架。**

## 1. G0 環境查核與來源

| 項目 | 結果 |
|---|---|
| 規格 SoT | `KuroNekoLi/astraea-combat-rules`，`master`，`docs/combat/00`～`23`；此前核對的 HEAD `1284d249cb334ff13ed8e9cac75d02d8f378859e` |
| **真正的 Godot 程式碼庫** | `KuroNekoLi/Astraea-Academy`，`main`；不是 docs-only 規格庫 |
| Godot 專案 | `godot/project.godot`，`config/features=4.7`，README 指定 Godot **4.7.2** |
| 原有程式 | 學院大門、劇情、存檔、自動載入、`tests/foundation_test.gd`，本輪不可破壞 |
| G0 原始程式 commit | `3b5e5e3086da1eda63b694f0f5e50ce2bec00eb7` |
| ChatGPT 執行容器 | **本地沒有 Godot CLI**；不過 GitHub Actions 成功下載並實際執行 Godot 4.7.2 stable。 |

## 2. 參考其他遊戲後採用的工程架構（來源與推論分開）

《殺戮尖塔》風格的可重播戰鬥模擬器 [mini-spire](https://github.com/rob-pitkin/mini-spire) 公開描述其 `CombatState / Card / Enemy / TurnLoop`、顯式 action queue、seeded RNG 與不依賴 UI 的戰鬥邏輯。這是參考的**工程解法**，不是宣稱 Astraea 使用《殺戮尖塔》的同一套戰鬥規則。

《Monster Train》的固定樓層／戰鬥階段顯示決定性的行動順序能維持戰術可預測性；Astraea **不引入**它的樓層移動、敵人自動攀樓或新位置經濟。

採用的工程決議：**Godot 4.7.2 / typed GDScript**；domain 使用不依賴 Node 的 `RefCounted` 靜態 pure-ish helper + `Dictionary` 快照；`BattleState + Command -> Validation + State + DomainEvents + ErrorReason`，統一 `action_id/event_seq`；`Park–Miller` 明確 seed 與 canonical state hash。未定 AP/RP/牌卡完整行為嚴格延後對應 M2～M5，收到命令先回 `FEATURE_NOT_IMPLEMENTED`，不得製造假的戰鬥效果。

這是最小 **M1 骨架**，不是卡牌戰鬥全功能完成。未採取如 `Node3D + Sprite3D` 或 `Node2D + YSort` 等 2.5D 唯一選型；依 CORE-03 不新增自由走位。

## 3. M1 程式交付清單（實際 Godot repo）

```text
godot/core/combat/combat_rng.gd
                           # 確定性 Park–Miller seed/state
godot/core/combat/combat_model.gd
                           # BattleState / deep-copy snapshot / canonical SHA256
godot/core/combat/combat_resolver.gd
                           # 原子拒絕、合法 SELECT_ACTOR、事件序號 / replay
godot/tests/combat_m1_test.gd
                           # PH3-M1 指令/快照/RNG/replay 正反例
godot/tests/combat_m1_failure_probe.gd
                           # 故意退出碼 17，驗證 CI 不能將失敗報成功
.github/workflows/godot-combat-m1.yml
                           # 安裝 Godot 4.7.2、執行 headless 與原 foundation smoke
docs/verification/requirements_traceability.md
docs/verification/PH3_M1_ENGINEERING_NOTE.md
```

唯一已提供之 gameplay command resolver：`SELECT_ACTOR`；其他已列出的命令在 M1 **必須拒絕 `FEATURE_NOT_IMPLEMENTED`**。M1 尚未落實完整 Phase 時序、成本扣除、抽牌、Guard/Protect、Last Spell、傷害與勝敗，不能用假的 test pass 取代真正 M2～M5。

## 4. 最小測試與執行指令

需在真正 Godot 專案 `KuroNekoLi/Astraea-Academy` checkout 下執行：

```bash
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64
"$GODOT_BIN" --version
"$GODOT_BIN" --headless --path godot --script res://tests/combat_m1_test.gd
"$GODOT_BIN" --headless --path godot --script res://tests/combat_m1_failure_probe.gd
"$GODOT_BIN" --headless --path godot --script res://tests/foundation_test.gd
```

- 正常 M1 測試必須 exit `0`；故意失敗 probe 必須 exit `17`，任何不符即拒絕 Gate。
- 必須記錄 PH3-M1-CMD-001..007、EVT-001、REPLAY-001/002、RNG-001、SNAP-001 共 **14 個**測試結果（另有 `PH3-M1-STATE-001/002`），以及 Godot 版本、實際 stdout/stderr、退出碼、Git SHA。
- 同 Seed + 同命令 tape 重播要同 event/state hash；拒絕命令前後的 state hash 與 RNG 狀態必須完全一致。
- 原本 Foundation 測試不能被新戰鬥模組弄壞。
- 若 CI 無法下載 Godot，請回報 `BLOCKED_TEST_ENV`，**不要誤判成通過**；可用可信的本機 Godot 4.7.2 重現並保留測試 log。
- 同一 failing group **最多首次＋兩次修正重跑**，第三次仍失敗停止，不可降低測試標準或刪除 Assertion。

## 5. 覆蓋率、風險與下一步

| Gate | 目前狀態與要件 |
|---|---|
| G0 — code repo / project | 已識別實際 Godot 專案；CLI binary 是否可在 CI 執行仍待驗證 |
| M1 — Domain scaffold | **M1 SCAFFOLD VERIFIED**：GitHub Actions Godot 4.7.2，14/14 tests PASS，failure probe=17，foundation regression PASS |
| M2 — AP/MP/RP / Cards / Free Swap | **未開始**；需 M1 VERIFIED 才可執行 |
| M3 — Phases / Guard / Protect / Reaction | **未開始** |
| M4 — Cast / Last Spell / Interrupt | **未開始**；USER_APPROVED：施法者生效前 HP0 必取消，施法者存活時一般干擾只延遲/削弱 |
| M5 — Damage / Break / Exposed / Outcome | **未開始**；USER_APPROVED：最後敵人與我方同時全滅時玩家勝利 |
| Presentation / 2.5D | 尚未執行，不提供自由走位，不設 Reaction 秒數強制倒數 |

**文件同步與 runtime test 是不同的 Gate**。GitHub/Library 成功寫入文件，只代表工程交付物已存放；不代表已通過 Godot CI。

## 6. 最終實際 CI 驗證與 Gate 裁決（2026-10-14）

- **程式代碼版本：** [`a8c96b8ed83d334a2818642e3e83ea3266a2a0f7`](https://github.com/KuroNekoLi/Astraea-Academy/commit/a8c96b8ed83d334a2818642e3e83ea3266a2a0f7)。
- **實際 CI：** [Godot Combat M1 / run 38548346979](https://github.com/KuroNekoLi/Astraea-Academy/actions/runs/38548346979)，job `115799891429`，**conclusion=success**。
- **Engine：** `Godot Engine v4.7.2.stable.official.ed1daf0bf`。
- **14/14 PASS：** PH3-M1-STATE-001/002、PH3-M1-CMD-001～007、PH3-M1-EVT-001、PH3-M1-REPLAY-001/002、PH3-M1-RNG-001、PH3-M1-SNAP-001。
- **Replay：** seed=12345，ruleset=`phase3-m1-0.2`，`event_hash=cc29acd624fda40ddcc6f08763fea9c40a080a9480eb57ae076422438d9d6553`，`state_hash=eaa5cdfe146b64625b1aa242c38df67d80aa1e6e68653485c08cc161e7266048`。
- **可信失敗探針：** intentional test exit code **17**，CI 斷言符合預期；原 `foundation_test.gd` **PASS**。
- **正式裁決：** `G0 VERIFIED / M1 SCAFFOLD VERIFIED`，允許**未來另行啟動 M2**；本輪未實作 M2～M5，沒有完整對戰、Last Spell、傷害、2.5D、實機或平衡測試的通過證據。
- **追溯完整性：** 真正 Godot repo `docs/verification/requirements_traceability.md` 另外逐項列出 `13_TEST_MATRIX_ACCEPTANCE.md` 的 **128 個 spec case ID** 路由到後續里程碑；M1 的 14 個可執行測試**不能替代**其餘仍待執行的 spec cases。