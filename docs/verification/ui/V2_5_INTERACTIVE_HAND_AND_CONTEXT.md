# V2.5 — Interactive Eight-Card Hand and Compact Action Preferences

> V2.5 implementation and dedicated real-GUI execution plan; not a declaration of prior P4.4 clearance.

- **Hand test:** sends genuine `InputEventMouseMotion`, `InputEventMouseButton` and physical `KEY_RIGHT` events into an Xvfb-rendered Godot 4.7.2 viewport. Validates each of eight distinct CardInstance IDs can be selected by actual mouse click and each by keyboard navigation; state hashes remain unchanged until an accepted action. Coordinates are derived from current card global transforms, not hard-coded to a single viewport.
- **Footer:** the `PreferencesDisclosure` button is outside the scroll region next to the pinned `ActionButtons`. Animation settings are collapsed by default but retain `hud.reduced_toggle` and `hud.mute_toggle` refs, action signals and 2-language labels.
- **GUI test:** verifies toggling Preferences with real mouse click; confirms Confirm remains inside Context and outside ScrollContainer; Cancel is clicked via real GUI event. Also checks a physical mouse pick at 1920×1080.
- **Scope:** no change to Domain, costs, cards zones, SimpleCards input engine or historical P4.4 test. Existing V1/V2/Domain test oracles remain authoritative. Real-GUI CI is a new scoped gate, **not a relabelled rerun** of old P4.4 14/16. Respect QA attempt history.
- **Pending:** strict renderer CI and review of error logs, screens at 1280/1920 and details scrollbar visibility; document any failures and remediation before moving V2 to master.
- **Engineering learning:** This tests actual GUI event dispatch, not just direct method invocation. Analogous to Android Espresso/Compose UI tests sending user actions rather than calling a ViewModel method and treating that as a click.

