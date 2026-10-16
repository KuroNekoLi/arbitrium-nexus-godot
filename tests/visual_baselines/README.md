# Golden Image review registry (P6)

The baseline registry starts with `approved.json: status=pending`. There are **no** approved Golden Images. Previously rendered V2/V3 screenshots and V3.5 target design references are not a substitute for sign-off.

## How to approve (explicit human action; never automated by CI)

1. Run **CI Visual - Real Godot Battle Screenshots** on the intended source commit. Open the `battle-visual-snapshots` Artifact, check all **9 HUD + 3 Boss** PNGs at the original resolutions, both manifest files, the 4-corner composition, language, hand layouts, assets, and scene contents. Confirm expected on-screen data and no unacceptable rendering artifacts.
2. Ensure the captured state is stable and representative. Record the reviewed run URL and reviewer decision. **Do not approve just because the screenshots passed structural CI checks.** A V3.5 target reference JPEG is not a direct pixel baseline.
3. Copy *only those 12 original PNGs* to `tests/visual_baselines/images/<case_id>.png`, preserving exact bytes and filenames. Never copy thumbnails, resized screenshots or generated images. Make a **separate deliberate baseline-change commit**, with the approver name, YYYY-MM-DD approval date and URL to the visual review record.
4. Set `approved.json.status` to `approved`, populate `approved_by`, `approved_on`, `review_reference` and exactly 12 `images` keys mapping to the lower-case SHA-256 of each file. All filenames are implied by `case_ids`; altering this list to suppress a case is not an approval.
5. Require an explicit owner visual review of the baseline-change diff / PNGs before merging or pushing. Prefer a protected review workflow for future Golden Image approvals, even though normal development commits may push directly. This manifest records provenance but cannot cryptographically prove a human signed off.
6. Re-run CI Visual and inspect the report. The first approved run should pass against the reviewed screenshot source; otherwise fix scene state/determinism/renderer differences rather than raising thresholds blindly.

## Comparison contract

- One deterministic, unmasked PNG comparison for all 12 cases. The engine and capture validators require Godot 4.7.2, a non-headless viewport, Xvfb/Mesa software Compatibility output and correct 1280×720 / 1920×1080 capture sizes.
- Only per-pixel RGBA channel differences **above 16/255** count as changes. At most **0.5%** of all pixels may exceed that threshold. Larger changes cause Visual CI to fail and generate a red-on-dark **diff heatmap** per case. These are provisional tolerances, not an assurance of pixel-identical rendering.
- A changed PNG with a matching or nearly matching metric may still be aesthetically wrong; CI should not replace human UX/visual inspection. Animation timing, fonts, images and GPU drivers can vary; stabilize the capture state and software-render environment before treating failure as a game regression.
- SHA-256 protects reference integrity. Approved baseline files are read-only inputs; runner code NEVER writes to this directory or promotes a candidate.
- Pending baseline: a report with 12 SHA-256 candidate hashes is produced, `pending_review` **nonblocking**; do not describe this as visual equivalence passing.
- Approved baseline: missing images, mismatched hashes, missing review fields and unsupported image formats are **fail-closed**. Genuine UI drift beyond tolerance fails the CI step. Diff report is uploaded even on comparison failure.
- To roll back an unintended baseline update, revert its commit and re-run Visual CI. Do not silence the gate through a new unreviewed Golden Image.

See `docs/ci/VISUAL_REGRESSION_P6.md` for CI workflow and limitation details.
