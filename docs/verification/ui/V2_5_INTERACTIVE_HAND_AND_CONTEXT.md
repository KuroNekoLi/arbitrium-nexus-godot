# V2.5 — Interactive Eight-Card Hand and Compact Action Preferences

> V2.5 implementation and dedicated real-GUI execution plan; not a declaration of prior P4.4 clearance.

- **Hand test:** sends genuine `InputEventMouseMotion`, `InputEventMouseButton` and physical `KEY_RIGHT` events into an Xvfb-rendered Godot 4.7.2 viewport. Validates each of eight distinct CardInstance IDs can be selected by actual mouse click and each by keyboard navigation; state hashes remain unchanged until an accepted action. Coordinates are derived from current card global transforms, not hard-coded to a single viewport.
- **Footer:** the `PreferencesDisclosure` button is outside the scroll region next to the pinned `ActionButtons`. Animation settings are collapsed by default but retain `hud.reduced_toggle` and `hud.mute_toggle` refs, action signals and 2-language labels.
- **GUI test:** verifies toggling Preferences with real mouse click; confirms Confirm remains inside Context and outside ScrollContainer; Cancel is clicked via real GUI event. Also checks a physical mouse pick at 1920×1080.
- **Scope:** no change to Domain, costs, cards zones, SimpleCards input engine or historical P4.4 test. Existing V1/V2/Domain test oracles remain authoritative. Real-GUI CI is a new scoped gate, **not a relabelled rerun** of old P4.4 14/16. Respect QA attempt history.
- **Pending:** strict renderer CI and review of error logs, screens at 1280/1920 and details scrollbar visibility; document any failures and remediation before moving V2 to master.
- **Engineering learning:** This tests actual GUI event dispatch, not just direct method invocation. Analogous to Android Espresso/Compose UI tests sending user actions rather than calling a ViewModel method and treating that as a click.


## Verification receipt — actual CI

- **SUCCESS:** [V2.5 isolated real GUI Run #38738911236](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38738911236), `completed/success`, tested commit `6b2f7e8312ac7559763fe772299d25c2d0d1e804`. Godot 4.7.2 under Xvfb + Mesa software Compatibility renderer, Dummy audio, strict import and log checks. Exact runner summary: `V25_GUI_REPORT executed=31 passed=31 failed=0`.
- **Physical 1280 GUI proof:** `V25-MOUSE-REAL-CLICK-0..7`, `V25-KEYBOARD-SELECT-0..7` and `V25-KEYBOARD-ALL-EIGHT` all PASS, with unchanged Domain hash. This is actual event dispatch, not direct `select_card()` for those eight checks.
- **Context proof:** `V25-PREFERENCES-MOUSE-OPEN/CLOSE`, `V25-CONFIRM-OUTSIDE-SCROLL`, `V25-CONFIRM-VISIBLE-EXPANDED`, `V25-CONFIRM-PINNED`, `V25-PREFERENCES-COMPAT-ALIASES`, `V25-FOOTER-CANCEL-REAL-MOUSE` all PASS.
- **1920 GUI proof:** `V25-MOUSE-1920-LAST-CARD` and unchanged Domain hash PASS after mapping GUI physical window pixels to the 1280×720 logical viewport.
- Prior scoped attempts: [#38738260585](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38738260585) = 30/31, failed only the 1920 mouse case; [#38738610105](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38738610105) = diagnostic 30/31, revealed that after changing native window size to 1920, `root.get_visible_rect()` and `screen.size` still represented the **1280×720 logical canvas_items viewport**. The tested fix changes the input simulation coordinate transform; **no Gameplay/production geometry changes** were made in that correction. None of these CI failures have been erased from history.
- Existing P4.4 GUI input suite is **NOT rerun**. Its historical `14/16` status remains independent.
- **Other accepted evidence:** V2.4 real renderer nine PNG variants (Run [#38736209253](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38736209253)); latest prior V2.4 headless and 9-shot renderer suites after Context disclosure change also passed at commit `f09916e...` (Runs [#38737970934](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38737970934), [#38737970800](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38737970800)). Newest GUI-only test patches did not alter runtime UI after `f09916e...`.

## Current limits and promotion gate

V2.5 mouse + keyboard access to all eight card IDs is verified at 1280, but at 1920 this dedicated case asserts **the last card** rather than all eight, by design. Actual dragging through a successful Drop/Confirm, scrollbar wheel navigation to the individual reduced-motion/mute options, and Reaction Modal focus handling are **not** newly verified by the scoped V2.5 runner. Their legacy behavior is preserved in source; further end-to-end testing needs a separately approved QA scope.

Do not claim user-approved commercial visual fidelity or merge directly into master: the latest approved concept PNG still needs a stable repository-pinned source/hash; the high-fidelity Theme/art/Boss HP+Break design remains V3 work. Before merging, reconcile V2 branch workflows with newer master CI and review the complete branch diff against master.
