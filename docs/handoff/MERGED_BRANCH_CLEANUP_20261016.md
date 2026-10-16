# Merged Branch Cleanup — 2026-10-16

使用者明確要求刪除已合併到 master 的分支。本輪以最新 origin/master 的 Git ancestry 判斷，不把「曾合併舊版」當作「最新分支已完整合併」。

## 遠端刪除清單

每個以下 tip 均通過 git merge-base --is-ancestor TIP origin/master。只刪除 branch ref，commit 仍存在 master 歷史；可用 SHA 重新建立分支。沒有刪除檔案、未合併 commit 或 worktree。

| Branch | Preserved tip SHA |
|---|---|
| ci/fast-p4-parallel-coverage-20261015 | adb758206787aac62f1dd1109f5bbf1c67a3c095 |
| ci/three-tier-fast-integration-full-20261015 | 038ecc33b92fa77de1016dbd6f81a1a2633d7b04 |
| engineering/ci-evidence-gate-20261015 | e4468a75657a7a17e030d95bb955118249f75b25 |
| integration/p4-approved-headless-slice-20261015 | c2796e312317baaf4bdcebbb6295927b00ff364a |
| integration/p4-approved-hud-headless-20261015 | f40686cda795aa61035f7473b08c8730409655b6 |
| integration/p4-approved-presentation-contracts-20261015 | d4d5b9986fc4d8d51227566dccc7573ddbae87df |
| integration/p4-final-playable-20261015 | 29837a897e30e2c9d81728c44496cef3cba62f41 |
| integration/v2-reviewed-20261015 | a355d0b97374295fe731cd48f148eb4f2c8e3014 |
| integration/v3-reviewed-20261015 | 2ce71a2f2d88b425ccfc9e99d5e65a15363b35b8 |
| integration/v34-reviewed-20261015 | e1f506159fd90f14a1872a248d96e33493c7f894 |
| ui/last-spell-target-scope-20261016 | 0436dc54a3ac40e13288663e6f254b242937cedf |
| ui/v2-layout-fidelity-20261015 | 822b1ce6d573cad6634b11c161634d5360eda456 |
| ui/v35-convergence-final-20261016 | 275af838d5fd44d21feaca0c1ebf04a7a62ef55d |
| ui/v35-hud-convergence-20261015 | e237143d2d79590572f1d2f8aab73c25385fa55a |

## 保留

ui/v3-visual-foundation-20261015 最新 tip 為 726644347793f4c358169a77cb958da0abf4fa5d；舊 V3.1～V3.4 已整合，但最新新增 10 筆 commit 不在 master，包含 KO／Last Spell retirement／Replay migration／畫面證據。git cherry 的10筆皆為 +，因此保留，沒有擅自合併或刪除。

其餘非 master ancestor 的遠端分支保留。歷史報告中的 SUPERSEDED／selectively-integrated 不等於整個 ref 已合併；本輪不擴張為刪除那些歷史獨有 patch／logs。

正在其他工作樹使用的本地 branch 保留；不移除 checkout，不覆寫未提交修改。此為 Git reference 清理，不變更遊戲程式、不重跑受限 Godot suites。

## 復原方式

對表中任一 branch，可執行 git branch BRANCH SHA，接著 git push origin BRANCH；commit 由 master 保持可達。分支刪除不會撤銷已合併功能。

## 執行收據

14個遠端分支均已透過 git push --atomic origin --delete 成功刪除。刪除前重新核對每個遠端tip未變更且為master ancestor；刪除後fetch/prune確認 --merged origin/master 僅剩 origin/master（及symbolic HEAD）。最新master在清理期間增加文件提交 d3a4c8807e0a3b21c2ae4f793bf9310451d69707，已正常同步，沒有覆蓋。

同時以非強制 git branch -d 刪除4個未被工作樹使用且已合併的本地分支：engineering/ci-evidence-gate-20261015、integration/v35-master-20261016、ui/last-spell-target-scope-20261016、ui/v35-convergence-final-20261016。其它worktree使用的本地refs保留。本工作樹停在detached HEAD，不為清理再新增遠端分支。

