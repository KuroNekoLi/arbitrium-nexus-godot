# Magic System Design Proposals — 導覽與規格狀態

> 本目錄是待核准的**設計提案**。目前唯一現行戰鬥規格仍為 [上層戰鬥總覽](../README.md) 及其最新核准文件，不可直接當成 Domain 規則。

## 優先閱讀

1. **[v0.3 — 全框架重審（CURRENT PROPOSAL）](MAGIC_SYSTEM_ARCHITECTURE_V0_3_REVIEW.md)**：參考 D&D、Pathfinder、MTG、Magicka、Into the Breach 與 Slay the Spire；重新區分 24 世界觀領域、實際效果、傷害共鳴與玩家操作。**PROPOSED / NOT APPROVED**。
2. **[v0.2 — 使用者已確認的方向及 24 學科候選](MAGIC_DISCIPLINE_AFFINITY_TAXONOMY_V0_2.md)**：「世界觀可完整複雜、實戰應易懂、優先重用機制」已確認；不等於核准全部學科或技能。
3. **[24 學科玩法矩陣 v0.1](MAGIC_DISCIPLINE_PLAYSTYLE_MATRIX_V0_1.md)**：歷史靈感與技能示例；部分抽象學科只有換皮護盾的問題已由 v0.3 批判與改善。
4. **[v0.1 — 原始三軸架構](MAGIC_DISCIPLINE_AFFINITY_TAXONOMY_V0_1.md)**：歷史分類研究。

## 不可混淆

- 「學科」「戰鬥共鳴」「Role Tag」「Effect」不是同一類資料。ARCANUM 是提案中的奧術學科；既有 ARCANE affinity 和 ROLE_TAG:ARCANE 保留不同語意。
- 每名敵人自己的元素弱點與抗性已核准；元素全集、特殊倍率、新時間／命運／心智能力均未核准。
- AP/MP/RP、牌組、雙詠唱、Combo 真實雙人付費、Boss Intent、Last Spell 耗竭真正退場，全部以目前 docs/combat/README.md 為準，不引用封存舊規則。
- 設計分支不代表已合併 master；本目錄無新 Godot Domain、CardDefinitions 或畫面實作。

## 待決

- 是否核准 v0.3 的「24 個學科保留完整世界觀，但不是 24 種必須可玩且互剋的戰鬥分類」？
- 首發少量可玩學科如何在三名角色的既有技能與 Boss 弱點中驗證身份差異？
- 未來時間／空間／因果／認知等何時導入第一項經完整 ADR 核准的全新戰術選擇？
