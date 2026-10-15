# 06 — Boss 行為、意圖、蓄力與 Break Gauge

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + EXTENSION_UNVERIFIED**：M5.3 已驗證單 Boss 公開 Intent、整張 SP Break、下一次合格 Boss Action 降級及恢復；這不代表所有蓄力、AoE、複數 Boss 和 Spell Counter 行為已驗證。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot domain M1～M5.4：1,081/1,081 已有 CI 證據；M5.5、完整可玩戰鬥未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。


## 1. Boss 行為架構（APPROVED）

初版 FSM + 條件式優先權/權重，不需要ML。Boss可使用普通攻擊、蓄力魔法、防禦姿態、召喚/標記等特殊招式；有 Phase 轉換和公開意圖。**正式公開的招式／目標不得在玩家做出反應後無提示偷換**。合法變招條件必須在預告時展示。

## 2. Intent contract

`EnemyIntent {enemy_id, skill_id, targeting_mode, fixed_target_ids?, windup_progress, expected_execute_phase, damage_range?, breakable?, casting_id?, conditional_branches[]}`。戰場 UI 顯示玩家能做出策略的最小資訊：何時生效、打誰、可否/如何干擾、當前穩定度。若技能仍隱藏完整細節，資訊提示仍不得誤導。

## 3. 蓄力

普通 Boss Magic 與超大型法術可有不同等待回合數；必須允許玩家至少一個明確可用的主動干擾窗口，必要時 Reaction 提供最後補足。候選：法術穩定度25/50/80；測試報告使用18，屬未核准原型數值。

「Boss開始蓄力」可能是敵方當次行動，不應同時免費執行額外完整普通攻擊。若召喚物另行攻擊，使用獨立 unit/意圖記錄。

## 4. 打斷後的 AI

打斷某次 CastingInstance 只取消該次魔法，不等於 Boss 永久無法施法。打斷後可能選擇其他招式，或暫不重複相同蓄力（候選兩次 Boss 行動 cooldown），但不可毫無理由直接完全免疫干擾。應支持高干擾角色、保護型角色和破防型角色各有對策。

## 5. Break System

`Break Gauge` 與當前 Casting Stability 分開。前者歸零使 Boss 失衡、進入可見輸出/控制窗口，恢復時間與所受效果待決；後者歸零一般只取消當前蓄力。某特殊卡可同時造成兩者，但必須分別定義 `break_damage` 與 `casting_disruption`。

## 6. 待決 Boss AI 問題

- 同場多名敵人各自意圖與行動順序；蓄力目標是否鎖定或在宣告時已定。
- 敵人如何選擇角色、嘲諷、HP低優先等；Exhausted能否被選。
- Phase 切換時已預告的技能如何處理；是否打斷既有Casting。
- 失衡持續多久、是否同時打斷正在施法、是否有過度削減溢出。
- 以何方式防止被高干擾角色永久封鎖，不能只任意調高穩定度。
- 難度曲線、多人範圍技能、召喚物意圖和反應的先後順序。

## 7. 測試

Intent commitment（公開後不得偷換）、同一seed決策重現、Casting被打斷後無重複結算、Break獨立生效、Phase變化合法、敵人多行動是否明示。驗收條件詳見13。


---

## 8. Phase 1 Boss Intent 的可反應性標示（P1-D05/D13/D14）

所有已公開的敵方行動計畫應具有足以進行 Reaction 的資訊：`target_scope`（單體／多體／全體／Casting Instance）、`damage_kind`（物理/魔法等）、`is_protectable` 或不可守護理由、是否存在 `on_hit_disruption` 以及 `direct_casting_disruption` 的可辨別標誌。**顯示資訊是設計契約，欄位名稱與協定格式屬工程建議**。

基本 Protect 可應對合法單體物理/魔法攻擊，但不能攔截全體或多目標技能；Boss技能若標記不可守護，必須在玩家消費RP之前明確顯示。若 Boss實際決定的行動與預告行動不一致，必須來自已公告的合法條件分支；不能在玩家選了Protect後暗改成AOE來繞過防守。Boss有直接作用 Casting Instance 的技術時，也應明白告訴玩家「基本 Protect 無效」，避免將攻擊命中干擾與Casting Lock 混稱。

Smart UI 模式是否開啟阻塞式窗口的「致命威脅、關鍵詠唱受阻、Boss高威魔法／控制」門檻目前只確認原則，**尚未確定數字、概率與無障礙時間設定**。Always Ask與Quick只能調整提示密度和界面，不可改 Boss行動、免費增加/扣除 RP 或讓玩家無法反應本應合法的重要事件。其他 Boss 能否拆成多個 Reaction Window、每個 hit 之觸發點仍為 TBD。