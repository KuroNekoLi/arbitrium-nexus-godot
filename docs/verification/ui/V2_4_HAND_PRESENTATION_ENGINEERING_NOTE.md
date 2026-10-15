# V2.4 — Selected Card / Fan Inspect / Empty Hand

> Source implementation pending CI. Branch ui/v2-layout-fidelity-20261015. Do not merge to master without review.

V2.4 addresses the real-render defects recorded in V2_3_REAL_RENDER_REVIEW.md. In the HandView, EmptyState has full-rect bounds, horizontally centered zh/en text and no wrapping. The fan uses SimpleCards ArcShape with more visible curvature. The original CardInstance IDs, 0–8 cards and unchanged Domain remain authoritative.

A card on hover/focus moves its visual face in front of the fan, while selection applies a persistent, gold glow/lift keyed by the instance ID. The face moves, not the SimpleCards hit rectangle, preserving legacy mouse drag behavior. BattleScreen sets/clears presentation selection through the existing HUD facade and does not modify state. Inspectability is a necessary improvement, not a claim all eight titles are simultaneously visible.

A new V2.4 headless suite checks no-hand alignment, selection/cancel, focus flags, all eight unique Card IDs, state hashes, resize geometry and locale rebuilding. Existing test oracles remain unchanged. The new tests do not replace the existing exhausted P4.4 GUI click suite; mouse/keyboard access and actual visual fidelity still require evidence from a separate scoped test.

Learning: Think of CardInstanceID as the stable Compose LazyRow key, preventing UI-only selected state from becoming a gameplay state mutation. SimpleCards still owns click/drag, and Domain still owns card zones and payment.

