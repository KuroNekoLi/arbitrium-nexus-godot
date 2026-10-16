# V3 KO / Last Spell Retirement — Review Gate

## Source / status

審查來源：`ui/v3-visual-foundation-20261015@726644347793f4c358169a77cb958da0abf4fa5d`，10個master尚未包含的commit（58de60e 至7266443）。Master審查基準：`242de0cf22c2ca7cc4387194c712d21186acbedc`。
狀態：**REVIEWED / MERGE_BLOCKED_BY_RULE_DECISION**。使用者授權review、必要修復、驗證後merge並刪除；沒有將一般merge授權推定為改變已明示戰鬥規則的核准。

使用 orchestrator / Spec Guardian、Combat及QA Skill核對來源／權威／測試scope。此輪為靜態審查，不執行受限測試，不把分支報告中的歷史PASS當整合後證據。

## Findings

| ID | Severity | Finding / evidence | Required action |
|---|---|---|---|
| RET-R01 | BLOCKER | master `docs/combat/終式與耗竭系統.md` 明確說耗竭者仍可受擊／治療／Buff／Protect，視覺退場不改Domain targeting；08末段同樣保留合法目標。來源 `BattleScreen._ready` 卻對lv40_playable開啟 last_spell_retirement_v1；LastSpell.settle改成still_targetable=false、heal/revive/damage/AI拒絕retired。 | 使用者選擇維持現行Domain，只做視覺；或明確核准新的真正退場規則並更新規格。不可直接merge預設啟用。 |
| RET-R02 | BLOCKER for real retirement | 分支自己的KO_EXHAUSTED_RETIREMENT_IMPLEMENTATION明列「all_exhausted / no front-line survivors」勝敗未定。三人HP仍大於0但都退休時，Boss候選池可為空，不能藉舊HP勝敗測試宣稱完整流程。 | 若核准真正退場，另確認敵存活而我方全退場的結果；同結算敵全滅仍優先VICTORY。 |
| RET-R03 | HIGH integration gap | master已有Last Spell單／全體 recipients helper；來源分支基於更早Lv40 cast effect。新retired guard與master helper只檢查HP的候選清單不一致，合併後可能列出已被新heal/damage拒絕的目標。 | 若採真正退場，集中資格規則並驗證 AoE／延後釋放／已退休目標；不能整檔覆蓋master最新target-scope功能。此項尚未runtime重現。 |
| RET-R04 | HIGH integration risk | 來源Actor為早期動態Sprite版本，沒有master新增@tool、Appearance Resource、非等高frame基準、Resource signal重入與tint cache。KO的body.position/rotation會和新frame alignment互相覆蓋。 | 小範圍整合KO pose與reset，保留master公開API／腳底anchor／editor隔離；做KO→revive、skip、Resource.changed與frame切換測試。 |
| RET-R05 | MEDIUM content/replay boundary | 來源只在UI加config flag，Lv40Encounter.config直接取得的同版本ContentConfig仍是舊行為；29-case測試直接Last.settle並指定true，不證正式M5全回合與完整三人退出。 | 若核准玩法改動，移到版本化ContentConfig，保留舊tape語義，新增真M5／Controller／Outcome／Replay正例。 |

## Decision proposal

**A（建議的規格一致修復）**：保留目前核准Domain；整合HP0倒地姿勢、耗竭灰階／叉號及純視覺退場，撤回來源新增的Domain不可鎖定／不可治療邏輯與UI配置開關。耗竭角色仍能成為現行規則允許的受擊／治療／Protect目標。驗證後merge，刪V3遠端ref。

**B（需要玩法核准）**：採真正退場，不能受擊／治療／復活／被選取；補齊所有targeting／casting／reaction／outcome／content version與replay契約。需同步確認「Boss仍活而三人皆退場」是否DEFEAT。這不是只改演出。

不可用flag在正式場景預設開啟新規則來繞過核准，也不可為刪分支而空merge或吞掉尚未審查的變更。取得決策前保留來源分支與全部commit，遊戲程式不變。

## Next verification contract

2026-10-16後續裁決：使用者明確選擇真正退場，並核准所有人退場且Boss存活判敗北。RET-R01/R02解除；RET-R03～05按 [Integration Note](V3_RETIREMENT_INTEGRATION_NOTE_20261016.md)修復並驗證。上文保留審查當時狀態，不是最新核准的否定。

選定A/B後，按最小diff整合；建立runner-level執行帳本，避免Fast與Integration重疊造成超次數。需要新的KO/退場契約、1280/1920實際Godot圖、完整M5 regression／seeded replay及master CI。沿用既有assertions，不將fixture PASS當真人驗收。
