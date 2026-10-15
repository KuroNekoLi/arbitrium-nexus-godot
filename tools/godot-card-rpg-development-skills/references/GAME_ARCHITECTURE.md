# 遊戲架構與依賴邊界

先讀 Spec Guardian。核心方向：**Gameplay Logic → Game State → Presentation → Animation**。UI 只提交意圖與顯示快照；傷害、成本、目標合法性不在卡牌 view 計算。演出不能是規則唯一來源，動畫是否完成不能決定最終傷害。

## 先重用現況

檢查 `scripts/domain/m1`～`m4`、`scripts/ui`、`scripts/main.gd`、`scenes/main.tscn`、`addons/simple_cards`。M1 的 Command/Result/snapshot、版本化 RNG、canonical hash，以及 M2/M3/M4 的 integration／resolver 已存在。舊 prototype 與新 Domain 同時存在，不能只看檔名 `battle_state.gd` 就把它當最新版權威。先追入口與呼叫路徑，再決定 adapter／小範圍遷移。

CombatController、CombatState、TurnManager、ActionResolver、CardDefinition、DeckRuntime、HandRuntime、TargetValidator、EffectResolver、StatusEffectSystem、EnemyDecisionSystem、CombatEvent、BattlePresentation 是候選責任，不是必建類別清單。用實際 component → 責任 → 依存 → 測試表判斷保留／重用／調整／新增。

## Command / State / Event

意圖至少辨識 command ID、actor、card instance／target、預期狀態版本（依現有契約）；由 Domain 判定 phase、資格、資源及重複提交。拒絕不改 HP／AP／MP／RP／卡區／RNG／排程／事件序號。接受才原子提交狀態與有序事件。UI preview 可呼叫無副作用的 quote／validator，但提交時重新檢查。

維持單一權威狀態；可衍生 UI cache 要綁 state revision 並可重建。事件提供 action/instance/seq、原因、前後值；不要把 Node、UI reference 或 OS 時鐘序列化進 Domain。重播記錄 seed、RNG algorithm/state/draw index、ruleset/content/schema version、初始 state、command tape、事件與 final hash。跨引擎升級不假定 RNG／浮點／序列化相容，先建立遷移 fixture。

Presentation 可依 UX 契約節流下一意圖、跳過演出或恢復場景，但不改變已結算結果。把「Domain 可接受下一指令」與「目前 UI 是否允許提交」分開；pending visual event 不可被重播二次套傷害。視覺 RNG 與 Domain RNG 分離。

## 組合、存檔、輸入

scene tree 所有權按生命周期而非畫面位置決定。優先小型組合、單一責任、低耦合高內聚、必要的 dependency injection；避免 service locator、event bus 或 repository layers 無目的擴張。保留既有路徑和 UID，不自造 `uid://`。

Save/load 使用版本化 DTO、合法值驗證、暫存寫入後替換／恢復策略、明確錯誤；不要直接反序列化不可信 object graph。需涵蓋舊 deck profile → v2、未知卡 ID、損毀存檔、重複載入及失敗不覆蓋可用資料。存檔是否允許戰鬥中與 RNG 恢復依正式規格。

Input Map 將 mouse／keyboard／已列入的 gamepad／touch 轉成相同 command，避免 GUI input 與 unhandled input 重複提交。探索、劇情、角色互動與養成保留各自狀態／存檔責任；它們解鎖卡片或變更資格時仍經正式規格與 Domain boundary。

## 重構驗收

建立現有行為 fixture → 標記與新版衝突的 oracle 廢棄 → 加新版 oracle → 小範圍 adapter／重構 → 同 command replay 比對 → 場景反覆進出／save-load／輸入整合檢查。若公開契約或 serialized schema 改變，記錄 ADR、相容性、回退與 migrate test；不為單一功能重寫戰鬥引擎。

官方依據：[Scene organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html)、[Project organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html)。
