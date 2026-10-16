# V3 Retirement Integration — Engineering Note

## Source / Approval / Ownership

來源V3：726644347793f4c358169a77cb958da0abf4fa5d；本輪master起點3be0e5e（實際merge記錄會保留完整parents）。2026-10-16使用者明確核准耗竭真正退場、全退場且Boss存活判敗北，見RET-01～05。先前審查RET-R01/R02規格Blocker解除；不是用merge授權替代玩法核准。

同一位整合者擁有Domain／Adapter／Actor／Roster／CI／文件，避免共用檔案競爭；其它工作樹、資產與未提交修改不動。Skills：orchestrator／Spec Guardian核對裁決，Combat串接原M5，Architecture保留新版Resource／@tool生命週期，QA分層驗證與執行帳本。沒有新增素材／外部插件或更換renderer。

## 實作與修復

1. 正常merge來源10筆commit；Actor／Roster／Lv40 cast effect三處衝突以master最新元件為基底逐項移入功能，不整檔套用舊角色實作。
2. `retired_from_field_by_actor` 是Domain的場上資格，不刪除allies／cards，不將HP改0。Target、Damage、Healing、Revive、Status、Barrier、Protect、Reaction及Boss候選排除退場者；既存狀態仍維持期限，但不再對退場目標做HP tick。
3. `PhaseBoundary.outcome` 在敵全滅優先後，計算HP>0且未退場的我方。全退場／混合倒地與退場為DEFEAT；活著Concentrating仍算在場，不以能否此刻操作誤判失敗。
4. Lv40支援終式先完成heal/barrier再mark_retired，ActorExhausted事件在效果後；避免原分支先退場造成自己治療被拒絕。原M5 action/phase boundary統一判勝敗，不在UI／Tween判。
5. ContentConfig v3由Encounter直接給出開關，不再由BattleScreen注入。舊配置無開關保留舊Exhausted語義與原Golden Hash；本輪不擅自升級BALANCE_PROVISIONAL數值。
6. 新單體分支測試抓到LastTargets.recipients三元運算返回untyped Array，指派Array[String]失敗；改為明確typed array append。首輪log保留，不改assertion掩蓋。
7. Actor以獨立Appearance／Atlas腳底對齊為底，KO停格傾倒、retired隱藏；retired由Adapter傳真實旗標，不能把舊Replay的EXHAUSTED視為新退場。Roster保留現有狀態pill／badges／焦點API，再加灰階／叉號／禁用。

## 測試帳本（每runner去重，不重跑歷史P4.4 GUI）

| Group | Local | Candidate CI | Master CI |
|---|---|---|---|
| 26 Domain suites +100 seeds | 1 PASS：1238/1238，100/100 | 2待驗證 | 3待驗證 |
| Source retirement29 / HUD36 / Component24 / Lv40Playable32 | 1 PASS | 2待驗證 | 3待驗證 |
| Lv40Content37 / Domain83 / Edges37 / Legacy4 | 未執行 | 1待驗證 | 2待驗證 |
| 新RET-01～05 | 1 FAIL typed-array；2 PASS22；新增atomic/target/event order後26項待CI | 3（最後一次） | 不重跑，須與候選受測runtime tree相同 |
| 原生capture | 1 PASS20；2 PASS29（增加真Controller敗北／Replay／tape） | 3（最後一次） | 不重跑，同源重用證據 |

原生PNG是Godot Compatibility／GTX1650，不是AI重繪。KO／retired圖為Domain-backed fixture，敗北圖為準備額外AP／Boss高HP的**FIXTURE_ONLY**起始邊界，再由真M5／Controller釋放終式到DEFEAT，非宣稱真人打完正式平衡Boss。Tape自該fixture開始，不能冒充整場人手對局。Master與candidate相同runtime時重用新測試／原生證據，防止第四次執行；master仍跑完整Domain regression及原29-case契約。

## 學習／取捨／Rollback

Domain map像Kotlin不可變State的場上成員集合，和HP生命狀態分開；Adapter像StateFlow→UiState，只把真正旗標投影給Node。Actor hide是結果，不是規則。勝敗判定像Reducer在完整transaction末檢查，不是Compose動畫callback改state。

保留舊配置是版本化Replay，不是讓新玩家任意切換新舊規則。與「直接移除allies」相比，旗標不破壞CardInstance、事件引用與保存錄影；代價是所有目標入口都需排除與驗證。可普通revert整合與修復commit回退，不reset／force push；來源ref只在master包含完整tip後刪除。

面試追問：為何全耗竭不是HP0？為何施法完成與退場順序影響支援魔法？如何保留舊Replay又不讓UI開關規則？如何避免CI重複執行同runner超預算？

限制：KO是既有CG變換，不是專門重繪倒地動畫；美術仍候選。沒有後備隊員、自動替補、VC、換位AP或真人usability／GPU benchmark。最終CI及merge收據後續回填，不把本Note的待驗證當PASS。
