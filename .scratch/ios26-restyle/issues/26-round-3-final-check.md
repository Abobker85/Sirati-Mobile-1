# 26: Round 3 recapture and final check

**What to build:** from the main checkout, recapture all 80 screens (AR/EN x light/dark), add a fourth column (round 3) to the board, run the full suite and analyze, confirm no gradient is still visible in the captures, and update the remaining-gaps list.

**Blocked by:** 23, 24, 25

**Status:** done (2026-11-21)

## Acceptance criteria

- [x] Round 2 captures kept as `after-round2/`; all-screens recaptured; board shows before / round 1 / round 2 / round 3
- [x] Full `flutter test` green, `flutter analyze` clean
- [x] Remaining gaps listed

**How to verify:** `flutter test`, `flutter test test_screens/all_screens_capture_test.dart`, open the board.

## Outcome (2026-11-21)

- **Commits:** only the commit that closes this ticket. No app code changed.
- **Files:**
  - `.scratch/ios26-restyle/issues/26-round-3-final-check.md` (this file).
  - Outside this repo, not committed:
    - `D:\Sirati\docs\screenshotsfter-round2\`: round 2's 320 captures plus their `index.md`, copied before the recapture.
    - `D:\Sirati\docs\screenshotsll-screens\`: the 320 round 3 captures, with `.failures.json` = `{}`.
    - `D:\Sirati\docs\screenshots\ios26-before-after.html`: the board for 80 screens, now with four columns per screen: before (`before-ios26/`), round 1 (`after-round1/`), round 2 (`after-round2/`) and round 3 (`all-screens/`). The AR/EN x light/dark toggles and the width slider are unchanged. All 1280 image paths are relative (320 per column), and all of them resolve on disk.
- **Tests** (all run from the main checkout on `feat/ios26-restyle` at `f86dcbf`):
  - Full `flutter test`: 4116 passed, 0 skipped, 0 failed.
  - `flutter analyze`: no issues.
  - `flutter test test_screens/all_screens_capture_test.dart`: 320 captured, 0 failed. It ran from the main checkout, so the relative output path needed no edit.
- **Visual check:** all 80 AR light captures; AR dark for 11, 16, 20, 21, 23, 24, 32, 36, 39, 53, 61-64, 77 and 80. The round 3 targets no longer show a gradient: offline 15/23/36/53/77, the My CVs header 16/20/21/24 and the Premium hero 61-63.
- **Not covered by a test:** the gap list below was judged by eye. The board was checked by resolving its paths on disk, not by rendering it in a browser.

## Still not in the new style / known gaps

Seen in the captures:
- **Tab header avatar (12, 17, 18, 49-54, 56):** `ProfileAvatar` in `lib/shared/widgets/screen_header.dart` is still a small `brandSurface` -> `brandSurfaceDeep` gradient circle. It is the only brand gradient still visible at rest.
- **Session expired badge (10):** the 54dp clock badge in `session_expired_screen.dart` (`_Badge`) paints the same gradient. It is small, but you can see it.
- **Home offline (15):** the retry button sits under the floating tab bar in AR/EN, light and dark, so only its top edge shows. Round 2 had the same overlap, so round 3 did not cause it. The tab-less offline screens (23, 36, 53, 77) are fine.

Follow-ups from round 3:
- `SubmitButton` still uses the warm `surfaceHigh` disabled fill (ticket 23).
- `AppListTile`'s pressed fill inside a section is still `pressed(groupedCard)`. That only matters for a tappable section row on a plain page, and no screen has one today (ticket 23).
- `BreathingBand` (`lib/shared/widgets/ambient_motion.dart`) has no production caller left. Only `ambient_motion_test.dart` and the My CVs header test, which asserts it is absent, refer to it. It can be deleted.
- The `brandSurface` and `brandSurfaceDeep` tokens are still used, so they stay. Flat fills: `job_apply_actions.dart`, `my_cvs_tools.dart` (the primary tools tile), `home_start_card.dart` and the reconnect ping in `offline_view.dart`. Gradients: the two listed above. They are also a gated pair in `app_contrast.dart`.

Known and accepted:
- The `AppSkeleton` shimmer paints a `LinearGradient` while loading. It is a loading effect, not a surface. The ambient sheens (`ambient_motion.dart`, `home_intro.dart`, `greeting_reveal.dart`, `fresh_glint.dart`) only paint while animating, and are off in the captures.
- Segmented controls (32, 39-41, 58-60, 64-65) keep a 2dp `outline` edge on the selected thumb. Ticket 22 kept it on purpose, because it carries the 3:1 boundary against the track.
- At 2.0 text scale on a 320dp phone, ATS results EN draws "Score & Criteria" and "Recommendations" at 0.83 (ticket 22).
- A disabled primary button inside a `cardFill` card on a plain page matches its card, as the secondary button already did (ticket 23).
- Grey iOS 26 fills (tips section, state circle, grey capsule) are about 1.1:1 against the page. Only the teal retry capsule is held to 3:1 (ticket 23).
- Disabled IconButtons are below 3:1 (exempt under WCAG for inactive controls).
- The iOS back swipe and the iOS launch screen have not been checked on a real device (ready-for-human).
- The sheets use an opaque grouped pane with no frosted blur (ticket 21). On it, sheet text must use `primaryInk` and `onSuccessContainer`.
- `ScoreBoosterCard` and `SiratiAddButton` have no production call site.
- GitHub issue sync is pending (no push in this run).
