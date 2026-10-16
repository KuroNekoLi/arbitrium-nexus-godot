# Basic Attack Target Flow — 2026-10-16

Status: IMPLEMENTED; focused headless gate 12/12 PASS. GUI mouse input for a real two-enemy encounter remains NOT_VERIFIED because current production scenes contain one enemy.

## Requirement and source

User-approved interaction decision (2026-10-16): ordinary attack against one enemy commits immediately. Against multiple legal enemies, the remembered target is highlighted; clicking a different target only changes selection; clicking the selected target commits. Domain controls legality, AP, damage, events and replay. Card, Reaction and Last Spell interactions retain their own contracts.

The earlier V3.5 ordinary-command confirmation assertion is superseded by this decision. `test_p4_v35_convergence.gd` now asserts immediate single-enemy damage and no confirmation modal. The historical V3.5 test group was not rerun because its three permitted executions were exhausted.

## Architecture

`BattleScreen` checks each enemy target through `BattleCommandFactory.preview`, remembers the last legal ordinary-attack target, and submits an existing M5 command only on the required click. `TargetHitRegions` shows a small target choice row when more than one enemy is legal. Target switches do not mutate Domain state. `BattleHUD` only forwards presentation updates. No resource or damage calculation was added to UI.

Godot `signal` delivery from `CommandMenu` and `TargetHitRegions` corresponds to Android callbacks/Flow events. The reducer and BattleState serve the role of a single unidirectional state store; the HUD re-renders from the resulting snapshot rather than calculating HP itself. An alternative was keeping a Confirm dialog for every attack; it adds an unnecessary step to the approved single-target flow. An automatic attack immediately after switching to a different multi-target enemy would risk accidental actions.

## Evidence and limits

Godot: `4.7.2.stable.official.ed1daf0bf`.

Command: `Godot --headless --path . --script res://tests/test_p4_basic_target_flow.gd`.

- Run 1: 6/12, fixture's second enemy lacked configured element resistance.
- Run 2: 6/12, Domain reported `M51_ELEMENT_NOT_CONFIGURED`.
- Run 3: 12/12, exit 0 after copying Boss's fixture element resistance to the test-only second enemy.

Cases BTF-01–04 cover one-click damage, AP payment, no confirmation modal and replay. BTF-05–12 cover a second Domain-legal enemy, target memory, selection without mutation, repeat-click commitment and replay. Godot reported ObjectDB/resource cleanup warnings after the final runner; these do not appear in the assertions and need separate lifecycle investigation. The repository's newly added Git editor plugin reported a `GitPlugin` initialization error during headless editor import, while import exited 0; it is outside this input change.

No actual two-enemy art/scene exists yet, and no claim of visual two-enemy verification is made. Rollback is limited to the BattleScreen ordinary-attack branch, TargetHitRegions choice row, HUD forwarding, string, and focused test. No Domain schema or replay format changed.

Interview follow-up: explain why target selection must not pay AP, why the preview cannot replace reducer acceptance, and how a remembered target is invalidated when it is no longer legal.

Further reading: Godot Control input and signals; Godot GDScript static typing; existing `docs/combat/COMBAT_IMPLEMENTATION_CONTRACT.md`.
