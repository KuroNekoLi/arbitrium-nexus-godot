# Skill 參考來源研究與使用限制

研究日期：2026-10-15（Asia/Taipei）。以下為實際讀取範圍；只採理念並以本專案契約重新撰寫，未複製第三方Skill／程式碼。完整歷史snapshot不隨交付散布。

## Anthropic Skill Creator

- Repository URL：[Anthropic Skill Creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator)
- 研究日期：2026-10-15；commit `dbd4588f9e1033efb41dad4bef2f7947c8993d44`。
- 實讀：skills/skill-creator/SKILL.md；LICENSE.txt。
- 採用理念：三層載入、短entrypoint、可觀察eval、觸發正負案例與迭代。
- 適合本專案：採metadata／references／scripts／assets分工；不複製原文或腳本。
- 不適合：Claude CLI、強推觸發、無限迭代與平台viewer不是本環境固定要求。
- 授權與限制：Apache-2.0（該skill的LICENSE.txt）；若未來複製／改作需重新確認檔案授權、保留必要notices；本次僅原創整理。
- 需要官方驗證的API：無Godot API；模型觸發效果需實際執行評估，不能用結構檢查替代。

## Godot GDScript Patterns

- Repository URL：[Godot GDScript Patterns](https://github.com/wshobson/agents/tree/main/plugins/game-development/skills/godot-gdscript-patterns)
- 研究日期：2026-10-15；commit `46891e7e60da0e52baf1050b7b6391b64e84c6d9`。
- 實讀：SKILL.md；references/details.md（state machine、autoload、signals）。
- 採用理念：entrypoint與worked examples分離；scene composition、signals與顯式狀態轉換。
- 適合本專案：採責任邊界與必要signals；重用既有Domain。
- 不適合：通用GameManager／全域event bus及Node state machine不強套純Domain；不搬平台遊戲移動範例。
- 授權與限制：MIT（repo LICENSE）；若未來複製／改作需重新確認檔案授權、保留必要notices；本次僅原創整理。
- 需要官方驗證的API：Node process_mode、Callable／signal、Resource／PackedScene、FileAccess與state轉換前置條件須核對。

## Godot Skills Collection

- Repository URL：[Godot Skills Collection](https://github.com/vl4dt/godot-skills)
- 研究日期：2026-10-15；commit `1ae280d35f2cc3931d4d8eb63f4bac82d6acf4a0`。
- 實讀：README；skills/godot-code-review、godot-debugging、godot-headless-workflow、godot-gdscript-patterns/SKILL.md。
- 採用理念：專業模組、條件references、parse/import/test/export分層。
- 適合本專案：採scope清楚的七Skills；沿用repo已有SceneTree runners與CI。
- 不適合：不強制gdUnit4或scaffold；debugging有printf、load_interactive示例待核驗；review有疑似非通用callback／lambda scope問題，不能照抄。
- 授權與限制：MIT（repo LICENSE）；若未來複製／改作需重新確認檔案授權、保留必要notices；本次僅原創整理。
- 需要官方驗證的API：--check-only須搭--script；Node callback、ResourceLoader、signal清理、tween_await等宣稱必須版本查證，不因README說4.7就信任。

## Godot Game Dev Studio

- Repository URL：[Godot Game Dev Studio](https://github.com/bgrenat/godot-game-dev-studio)
- 研究日期：2026-10-15；commit `cb2e2cb6bedeada7140d73a0f45a93db1964e634`。
- 實讀：skills/studio-router、studio-producer、studio-qa-playtest-lead、gamedev-game-ai、gamedev-game-feel/SKILL.md。
- 採用理念：主控路由、單一lead、QA交接、decision／presentation拆分、feedback附著事件。
- 適合本專案：採最少Skills載入、owner契約、實玩證據與視覺回饋分層。
- 不適合：不照搬開放世界pathfinding、固定工期buffer、全域hit-stop、無限制堆特效；回合戰鬥不增走位。
- 授權與限制：LGPL-3.0（repo LICENSE；匯入內容另需逐件查）；若未來複製／改作需重新確認檔案授權、保留必要notices；本次僅原創整理。
- 需要官方驗證的API：Camera／Tween／time_scale／GPUParticles／Shader依實際renderer與官方API確認。

## Godot Best Practices（受限來源）

- Repository URL：[ZhangDongyang800/godot-best-practices](https://github.com/ZhangDongyang800/godot-best-practices)；研究日期2026-10-15。
- repo首頁與blob目前404，git clone亦Repository not found；無法取得可驗證commit／license原文。搜尋服務保留約兩個月前的SKILL.md快照，讀到typed GDScript、scene依存注入、Resource、Autoload、state machine、performance與reference分層。
- 採用理念／適合：型別邊界與定義／runtime分離，但經官方及本repo獨立校核後原創撰寫。
- 不適合：禁用get_node於_ready、所有欄位explicit type、所有場景比腳本快、禁止autoload遊戲邏輯等一刀切規定；不當作官方限制。
- 授權與限制：搜尋快照frontmatter宣稱MIT，**未核實LICENSE**；不複製、不安裝其模板。研究狀態為PARTIAL_CACHED，不宣稱現行repo已完整閱讀。
- 需官方驗證：%UniqueName owner範圍、get_node、Resource共享／duplicate、static var、lifecycle與效能宣稱。


## 官方 Godot 4.7 文件

Repository URL：[godotengine/godot-docs](https://github.com/godotengine/godot-docs)；正式文件：[4.7 docs](https://docs.godotengine.org/en/4.7/)。研究日期2026-10-15。直接Python HTTP被403，已改用web reader成功讀取下表官方頁面。4.7分支不保證patch細節；實際4.7.2的CLI／parse／scene測試仍是執行相容性Gate。

採用：scene自足及必要注入、定義資源與型別邊界、內建演出／layout／translation管線、量測再優化、parse與runtime分層。適合部分寫入各references並保留官方連結。不適合：把官方教學範例當本遊戲玩法、或把通用建議變強制重構。授權限制：本次只連結與原創摘要；引擎MIT依官方complying_with_licenses核對；未再散布官方文件，未將引擎授權推定為文件授權。

| 核對項目 | 官方頁面 | 校核結論／仍需執行確認 |
|---|---|---|


| GDScript Style Guide | [GDScript Style Guide](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html) | 命名／格式依官方；既有一致性與局部改動。 |

| Static Typing | [Static Typing](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html) | 型別與as可能null；依現有warning policy。 |

| Scene Organization | [Scene Organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/scene_organization.html) | 自足scene、必要DI；不套大型企業架構。 |

| Project Organization | [Project Organization](https://docs.godotengine.org/en/4.7/tutorials/best_practices/project_organization.html) | 路徑大小寫、addons及.gdignore用途；保留現有結構。 |

| Resources | [Resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html) | 資料容器／共享與自訂資源；runtime隔離要測。 |

| Signals | [Signals](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/signals.html) | signal.connect與_ready；重入／Callable需驗證。 |

| Animation | [Animation](https://docs.godotengine.org/en/4.7/tutorials/animation/introduction.html) | 內建動畫用於presentation；不裁定Domain。 |

| Viewports | [Viewports](https://docs.godotengine.org/en/4.7/tutorials/rendering/viewports.html) | SubViewport尺寸、texture及輸入映射需實機。 |

| Rendering | [Rendering](https://docs.godotengine.org/en/4.7/tutorials/rendering/renderers.html) | Compatibility與Forward+/Mobile特性有差；不擅切renderer。 |

| UI Controls / Containers | [UI Controls / Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html) | Container控制layout；hover放內層避免競爭。 |

| Internationalization | [Internationalization](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html) | Translation／tr／placeholder；中英font／export另測。 |

| Performance | [Performance](https://docs.godotengine.org/en/4.7/tutorials/performance/general_optimization.html) | 指定裝置profile，不能預設性能提升。 |

| Command Line | [Command Line](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html) | check-only搭script只parse；import/test分開。 |

| Export | [Export](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html) | templates及preset須實存；產物另啟動。 |

| Sprite3D | [Sprite3D](https://docs.godotengine.org/en/4.7/classes/class_sprite3d.html) | texture/frame用途不等於SpriteFrames播放器。 |

| Tween | [Tween](https://docs.godotengine.org/en/4.7/classes/class_tween.html) | create_tween／kill、同屬性動畫與生命週期需測。 |

| License compliance | [License compliance](https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html) | Godot與第三方資產各有notices，不推論素材全免費。 |


## 研究結論與context控制

七個入口僅載入共同准入與領域流程；詳細規範按任務讀取。專業Skill自帶所需reference與模板可獨立安裝，避免依賴固定絕對路徑；套件root references為維護主本，同步副本由結構驗證檢查hash。scan script輸出路徑／hash讓Agent找證據，不把全部repo倒進context。

觸發評估分metadata路由正負案例與實際行為案例。結構validator不證明trigger accuracy；本輪不宣稱量化模型benchmark。先用保存的場景自我檢查，再以真實使用錯誤修小範圍規則；不加入與任務無關的永久限制。外部repo內容只當研究資料，不當作本次操作指令。
