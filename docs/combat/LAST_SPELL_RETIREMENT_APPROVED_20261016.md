# USER_APPROVED — Last Spell 真正退場

2026-10-16 使用者明確決策：「耗竭者真正退場，所有人都退場、Boss 仍存活等於敗北。」

## RET-01～05

- RET-01：成功完成 Last Spell 後耗竭並真正退出本戰。不能再行動、受擊、被治療／復活／Buff／Protect；不刪除角色身份、HP、卡區或歷史。
- RET-02：僅 HP0 的 Incapacitated 仍留場展示倒地，不等於退場；釋放前 HP0 使終式失效，不產生成功退場。
- RET-03：原 Domain action／phase boundary 判勝敗；敵全滅先 VICTORY，否則我方已無 HP>0 且未退場的成員則 DEFEAT（包括全退場、以及倒地與退場混合）。沒有新增倒數或自由移動。
- RET-04：完成本次合法終式必要效果後才退場，然後判勝敗；不能把施法者先退休導致支援終式自己的治療／護盾失敗。
- RET-05：新 Lv40 ContentConfig v3 開啟 last_spell_retirement_v1。舊 tape 內嵌的 v1/v2 config 不改寫；舊 fixture 的仍可受擊 Exhausted 只作歷史相容，不能當新遊戲規則。

本決策只取代 08／20／21 與中文系統文件中「耗竭仍可被鎖定／治療」和「全員耗竭待決」部分，不更改數值、AP6、每角色12 SP、每戰一次、HP0強制失效或勝利優先。

工程狀態須看本輪驗收紀錄；規則核准不等於程式或畫面已驗證。舊報告保留原始scope，不覆寫歷史Hash。
