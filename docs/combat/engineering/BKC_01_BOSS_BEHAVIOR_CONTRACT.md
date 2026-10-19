# BKC-01 — Boss 行為資料契約（Break C／Exposed／Intent）

> 日期：2026-10-20｜**DOCUMENT CONTRACT PROPOSED / NOT CODE SCHEMA / NOT IMPLEMENTED**。  
> 父決策：[ADR-BKC-01](../adr/ADR_BKC_01_BREAK_C_20261020.md)；現行權威：[Boss 圖鑑](../敵人與Boss圖鑑.md)、[Break](../失衡與破綻系統.md)、[詠唱](../詠唱與魔法干擾系統.md)。  
> **已決方向**：Boss 可以**沒有任何主動暴露弱點的行動**；Break 仍能創造 Exposed。Boss 另可用特定行動**直接**露破綻，或用姿態提供**玩家觸發**的破綻機會。**未決**：各來源期限、額外增益、fallback、恢復窗口，均需逐項核准。  
> 所有下列欄位名稱、狀態與事件都是**面向 Domain 的擬議語義契約**，不能直接貼進現有 `lv40_content.gd` 當成已支援的 JSON／GDScript API。

## 1. Boss Profile 要表達的能力，不是通用技能程式碼

| 模組 | 責任 | 是否需每隻 Boss 配置 |
|---|---|---|
| `break` | gauge 最大值、Break 後恢復／保護、單 Action 壓制政策 | 使用 Break C 的 Boss 必須有；值仍屬 Boss 內容 |
| `skills[].break_response` | 此招屬 `CANCEL` 或 `DOWNGRADE`、公開 fallback | 每個可被 Break 的行動必填；不可由 UI 根據招式名字猜 |
| `exposed.sources.ON_BREAK` | Break 觸發即建立 **同一份 Exposed** | **Break C 共通規則**，不要求 Boss 重複定義 |
| `exposed.sources.ON_BOSS_ACTION` | 某招式**已成功執行**後直接建立 Exposed | **可選**，預設無 |
| `exposed.sources.ON_POSTURE_AND_SP` | 某姿態開啟後，玩家合格 SP 才能建立 Exposed | **可選**，預設無 |
| `casting` | 有效 CastingInstance、Stability、Focus Ward | 只有此 Boss 的技能在詠唱時才需要 |
| `intent` | 公開招式、目標、合法反應、Break 降級／取消分支 | 每個將執行的 EnemyAction 都需要合法公示 |

**資料模型原則：**沒有 `ON_BOSS_ACTION`／`ON_POSTURE_AND_SP` 並非資料錯誤；Boss 將依賴玩家的 `ON_BREAK`。不能強迫每隻 Boss 有 `CORE_OPEN` 姿態，或將未公開的核心暴露當作可見事實。

## 2. 兩個截然不同的 Boss 範例（語義樣本，非現有 schema）

```yaml
# 範例 A — 重裝騎士：完全不會自己暴露
boss_id: CANDIDATE_ARMORED_KNIGHT
break:
  enabled: true
  gauge_max: CONTENT_PROVISIONAL
  on_zero: NEXT_ELIGIBLE_ACTION_AND_APPLY_EXPOSED
exposed:
  autonomous_sources: [] # 合法；絕不需要 CORE_OPEN
skills:
  - skill_id: CANDIDATE_SLASH
    break_response: CANCEL
    public_break_preview: "失衡時取消這次斬擊"
  - skill_id: CANDIDATE_ULTIMATE
    break_response: DOWNGRADE
    fallback_skill_id: CANDIDATE_WEAK_ULTIMATE
    public_break_preview: "失衡時大招降級為弱化版本"
```

```yaml
# 範例 B — 魔導巨像：除了玩家 Break，亦可能自行製造或開啟窗口
boss_id: CANDIDATE_ARCANE_GOLEM
break:
  enabled: true
  on_zero: NEXT_ELIGIBLE_ACTION_AND_APPLY_EXPOSED
exposed:
  autonomous_sources:
    - kind: ON_POSTURE_AND_SP
      posture: CORE_OPEN
      required_sp_rule: CARD_DEFINED_TRIGGER
    - kind: ON_BOSS_ACTION
      successful_action_id: CANDIDATE_OVERHEAT
      when: AFTER_SUCCESSFUL_ACTION
skills:
  - skill_id: CANDIDATE_BEAM
    break_response: DOWNGRADE
    fallback_skill_id: CANDIDATE_WEAK_BEAM
    public_break_preview: "失衡時光束弱化"
```

兩個範例都只使用**一個 Exposed 生命週期**。直接暴露 `ON_BOSS_ACTION` 與姿態式 `ON_POSTURE_AND_SP` 應明確分開；姿態開啟本身不代表 Exposed 已建立。Boss 只要未命中／未成功執行自曝招式，就不能憑空獲得該來源的 Exposed。

## 3. 行動分類／預告與反應邊界

**預告資料不等於「可自由重選的 AI 選招」**：

1. 由現有 BossAI policy 或未來意圖預告階段決定原招與合法目標；
2. 在玩家有能力 Break 之前公開原技能、目標/範圍、時點、Reaction 窗口與 `break_response` 分支；
3. 若玩家造成 Break，鎖定下一個合格、尚未開始的 Action；
4. 在 Action 開始前，依合法分支決定 `NORMAL`／`CANCEL`／`DOWNGRADE`，**公開事件與 UI 必須一致**；
5. `CANCEL` 不再執行原招效果，敵方行動按完成/取消方式消耗，不虛構攻擊 Reaction；`DOWNGRADE` 依當前的合法反應窗口提供真正可用的 Guard/Protect／其他反應；
6. 行動結束後更新 Break 狀態，僅按成功結算的技能生成 `ON_BOSS_ACTION` Exposed；Cancel 不能觸發此來源，Downgrade 使用 fallback 自己的明示政策。

**現行差距：** `m5_domain_resolver.gd::_end_phase_m53()` 才從 `boss_ai_policy.gd::choose()` 選 Boss 單一 Intent；`enemy_action_scheduler.gd` 只能排序**已公布**的多個 Intent，並不負責提前預告，也不能使 `CANCEL` 自動成立。若 BKC-03 要讓玩家提前選 Break 卡，必須先解決前置公示及與 `PhaseEngine` 的相容性。切勿只修改 `BossAI.choose()` 的輸出字串。

### 3.1 Lv40 B01～B11 初步分類審查表（內容待核准）

| Boss Skill | 現有候選意義 | BKC-01 建議回應類型 | 下一步 Boss 契約檢查 |
|---|---|---|---|
| B01 鐵拳突襲 | 單體物攻 | REGULAR / CANCEL | 取消後不得留傷害或假 Reaction |
| B02 雙刃連擊 | 2hit 單一 Action | REGULAR / CANCEL | 取消**整個 Action**，不單獨跳其中一 hit |
| B03 弧光穿刺 | 單體魔法與 on-hit 干擾 | REGULAR / CANCEL | 取消亦不得附加 on-hit Disruption |
| B04 共振脈衝 | 全體魔法 | REGULAR / CANCEL | 取消本次全體效果 |
| B05 核心預熱 | 蓄力／開核心 | MAJOR / DOWNGRADE | **不得無預告變 B11**；建議弱化成無攻擊的冷卻／不建立 CastingInstance，需核准 |
| B06 超載光束 | 蓄力釋放／單體重擊 | MAJOR / DOWNGRADE | 降級後是否仍釋放／需有效 CastingInstance，具體光束弱化版待定 |
| B07 重構護壁 | Boss 自體 Barrier | REGULAR / CANCEL | 不建立180護盾；不預設觸發自主暴露 |
| B08 終末蓄能 | 高階全體蓄力 | MAJOR / DOWNGRADE | 降級為已公佈的安全蓄力失敗／冷卻，不能偷放 B11 |
| B09 終末掃射 | 全體法術釋放 | MAJOR / DOWNGRADE | 減傷版本、有效詠唱、Interrupt 優先權待核准 |
| B10 冷卻校正 | 冷卻姿態 | REGULAR / CANCEL 或 NOT_ELIGIBLE | **有爭議**：取消會不會破壞冷卻機制？需 Boss 實測後正式定案 |
| B11 失衡降級攻勢 | 既有 fallback | FALLBACK_RESULT（非一般預告招式） | 僅合格 fallback 使用；不可把所有重大招式都指向 B11 |

此表只是在 BKC-01 給後續 Agent 的設計檢查列表；**不是 B01～B11 已核准的新招式資料**。

## 4. Exposed 單一機制／來源資料要求

Exposed instance（候選）至少可追溯：`target_boss_id`、`source_kind`、`source_event_id`、`source_command_id`／`source_enemy_action_id`、`created_at_order`、`expires_at_rule`、`consumed`。實際新欄位要由 BKC-02 的版本化 schema 審核後決定。

- 任何來源只建立**最多一份** Exposed；已存在時不再疊加、不刷新。
- **同一 SP 不能建立／消耗它剛建立的 Exposed**。
- Break 來源與 Boss 自曝來源同時成立時，建立一份即可，需有固定事件優先序與去重。
- 對 Boss 自行顯露姿態，必須區分 **“目前可利用的姿態”** 與 **“已建立的 Exposed”**；玩家 UI 不能把兩者畫成同一個持續時間。
- 若直接自主露弱點是 Boss 某招的負面代價，不應反過來在該招被 Break Cancel 後還讓 Boss 露弱點（除非 fallback 特別明示可露）。
- 若此種 Boss 完全沒有自主來源，**遊戲仍需讓玩家使用 Break 製造破綻**。
- Exposed 不可免費產生 Combo；R01/R07 的 ComboOpportunity 不須 CORE_OPEN，維持 2026-10-17 規則。

## 5. 校驗器與測試必須拒絕

- 沒有 `ON_BOSS_ACTION` 就當 Boss 缺少 Exposed 機制：**錯，應合法**。
- 任意提供不存在的 `fallback_skill_id` 或 fallback 目標／範圍不符，卻允許開戰：**拒絕配置**。
- REGULAR 標成 DOWNGRADE 但未附合法 fallback 或未公開：**拒絕配置／Intent**。
- MAJOR 標成 CANCEL 而沒有已核准例外與告知：**拒絕配置**。
- Boss Intent 尚未公告便允許 UI 預知下一個技能與 Break 分支：**拒絕 UI 假資料**。
- `ON_BOSS_ACTION` 在該動作 CANCEL／Interrupt 後還成立：**拒絕**。
- `CORE_OPEN` 直接當 Exposed 而未由指定 SP 觸發：**拒絕**。
- R01/R07 Combo 被重新加回 CORE_OPEN 門檻：**拒絕**。
- Full Chant／Last Spell／反應窗口被重算成本或無回應時自動 Pass：**拒絕**。

## 6. 分階段遷移／不可因為本文件改動既有資料

1. **BKC-02**：版本化 Tactical Resolver：Break 後一次 Exposed、來源去重、效期與 Replay；先用一個「完全不自主暴露」Boss fixture，驗證只靠 Break 即可建立破綻。
2. **BKC-03**：BossAI／Intent 預告、技能分類、Action CANCEL／DOWNGRADE、Casting 衝突；再用原 `TEST_BOSS_ARCANE_SENTRY` 的 `CORE_OPEN` 條件驗證第二來源。
3. **BKC-04**：HUD 讓玩家看懂未來招式與失衡後果、Exposed 一次性機會、詠唱時才顯示 Stability；跑雙語、Replay、Boss 實機手動操作。
4. 舊 Replay 與舊 `m53` fixture 應保留原版解碼／事件語意；**不能為了讓新測試綠燈就回寫舊紀錄的 hash**。
5. 各 Phase 的 Godot/CI 真的跑過才能稱 VERIFIED；BKC-01 文件完成不能代替它們。

> **BKC-01 交付判定：** Boss Profile 模式、三來源邏輯、預告行動契約、B01～B11 待審矩陣及 BKC-02／03 轉換要求已文件化；**仍不是 Godot 已使用的新 schema**。
