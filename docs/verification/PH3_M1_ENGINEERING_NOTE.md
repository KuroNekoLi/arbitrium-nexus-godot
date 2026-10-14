# Phase 3 — M1 Engineering Note：獨立 Domain Engine 骨架

> 2026-10-14。Repo：`KuroNekoLi/arbitrium-nexus-godot`；Scope=**M1 only**。
> 狀態：`IMPLEMENTED_NOT_VERIFIED`（GitHub Actions Run 確認前）。正式交付需 M1 domain CI PASS，G0 legacy baseline PASS；不代表 M2–M5 Gameplay 已完成。

## Scope / source of truth

- 規格：`../combat/12_ENGINE_ARCHITECTURE_EVENTS.md`、`22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md`、`23_PHASE3_EXECUTION_PLAN.md`。
- 既有 Godot 程式 `scripts/domain/battle_state.gd`，Scenes，`scripts/main.gd`、手牌 UI/資產均保持不動。
- 新增 `scripts/domain/m1/combat_model.gd`（BattleState Dictionary + snapshot / canonical SHA-256 / validation）。
- 新增 `scripts/domain/m1/combat_rng.gd`（確定性 Park–Miller 48271，固定演算法版本與 RNG draw index）。
- 新增 `scripts/domain/m1/combat_resolver.gd`（Command Validation、Transaction、DomainEvent、Replay）；僅 `SELECT_ACTOR` 可合法提交。
- 新增 `tests/test_combat_m1.gd`，與 `.github/workflows/godot-m1-domain.yml`。

## Engineering decisions (not new Gameplay ADR)

1. 將新 M1 domain 放在 `scripts/domain/m1/`，避免直接覆蓋舊 `BattleState` 造成 Scene／存檔／原型測試失效；M2 必須決定舊新 Domain 接合的遷移方式。
2. 正式命令具有 `command_id` 與 `expected_event_seq`；同 ID 第二次提交拒絕 `DUPLICATE_COMMAND`，過期快照拒絕 `STALE_STATE`。未知命令 `UNKNOWN_COMMAND`。已認識但未實作的 M2–M5 命令明確回 `FEATURE_NOT_IMPLEMENTED`。
3. Domain 狀態以穩定 ID + 深複製 JSON-compatible Dictionary/Array/number/string 儲存；無 Godot Node/Scene/Animation/Timer/Frame/OS clock。
4. `SELECT_ACTOR` 先檢查版本、phase、角色、status/hp、command_id、event_seq；接受才在**新快照**設 selected actor、順序遞增 Action/Event seq 並 append DomainEvent。此命令不扣 AP/MP、不抽牌、不消耗 RNG。
5. Replay 接收 `initial_state` 和全部 command tape；回傳 `accepted, state, events, state_hash, event_hash`。Canonical serialization 對 Dictionary Keys 排序，避免插入順序影響 hash。RNG 使用 Park–Miller 明確常數；所有 RNG API 自動在 copy 上演進，舊 snapshot 不被改。
6. M1 初始 `hp=100`、`max_mp=0`、`content_version=m1-placeholder-content-v1` **全為 FIXTURE_ONLY**。沒有真實 12 張卡牌或 Boss 技能，絕對不能被稱為玩法 Canon。
7. 既有 `README.md` 所謂 M0–M5「MVP 完成」只指**另一套舊版原型**，不是新版 Phase3 M1/M2/M3/M4/M5 的結果。

## M1 mandatory positive / negative / boundary / replay

`PH3-M1-STATE-001..004`、`PH3-M1-CMD-001..014`、`PH3-M1-EVT-001..002`、`PH3-M1-REPLAY-001..004`、`PH3-M1-RNG-001..004`、`PH3-M1-SNAP-001..002`，合計 **30 cases**；測試腳本逐 case print PASS/FAIL 和退出碼。

- Positive：三個 ally / 一個 enemy 能建立狀態；唯一 actor ID；`SELECT_ACTOR` 成功與事件遞增；同人選擇第二次仍合法（沒有偷加角色硬限制）。
- Negative：未知 Actor、失能 Actor、非法 Phase、未知動作、未實作動作、缺 command ID、缺預期 EventSeq、重複 command ID、過期 EventSeq、壞規則版本。
- Replay：相同 seed + command tape 的 event/state hashes 一致；異 seed state hash 不同；合法一個後非法一個的部分重播誠實失敗、不提交失敗命令。
- RNG：初始1→第一值48271→第二值182605794、draw index 遞增、呼叫不改入參、拒絕未知演算法、`SELECT_ACTOR` 不動 RNG。
- Snapshot/State：深複製、Key順序不影響 hash、負 AP debt shell validation 失敗。

## Evidence / reproducible commands

```bash
# Needs genuine Godot 4.7.2 binary and project import.
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_combat_m1.gd
# G0 legacy regression remains in:
# .github/workflows/godot-g0-legacy-baseline.yml
```

CI 需回報 Godot 版本、SHA512 校驗、各 test ID、exit code、`M1_REPLAY_PROOF` 的 seed/ruleset/content/initial_hash/event_hash/final_state_hash/tape，並與 commit SHA 綁定。失敗若三輪（首次＋兩次修正）未修復，停止 Gate，列出 block。

## Remaining boundaries

- M2：AP/MP/RP、12-card zones、deck profile v2、免費換牌、Analyze、APDebt 的**真正行為**未實作。
- M3：EnemyPhase、Reaction Queue、Guard/Protect、無時間自動Pass未實作（舊 UI 仍有舊 timeout）。
- M4：完整詠唱、CastingInstance、Interrupt/LastSpell未實作。
- M5：Damage/Status/Break/Combo/Boss/Outcome未實作。
- RTM：`requirements_traceability.md` 尚需逐一展開 spec13 所有 Test IDs 及其 `SUPERSEDED / DEFERRED / BLOCKED_FIXTURE / M1_COVERED`。
