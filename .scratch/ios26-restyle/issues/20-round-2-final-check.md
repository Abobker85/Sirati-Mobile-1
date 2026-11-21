# 20: Round 2 recapture and final check

**What to build:** recapture all 80 screens (AR/EN × light/dark), refresh the before/after board against the round 1 "before" captures, run the full suite and the dark-mode walk on the integrated branch, and list anything still in the old style.

**Blocked by:** 10, 11, 12, 13, 14, 15, 16, 17, 18, 19

**Status:** done (2026-11-21)

## Acceptance criteria

- [x] All-screens capture rerun; board `D:\Sirati\docs\screenshots\ios26-before-after.html` refreshed
- [x] Full `flutter test` green, `flutter analyze` clean
- [x] Remaining gaps listed; the iOS back swipe on a real iPhone stays a ready-for-human note

**How to verify:** `flutter test`, `flutter test test_screens/all_screens_capture_test.dart`, open the board.

## Outcome (2026-11-21)

- **Commits:** `3cb4df0`, `c0b3161`, `b7e4aea` (the score ring fix), plus the closing commit (this file).
- **Files:**
  - `lib/shared/widgets/score_ring.dart`: the compact ring on the My CVs and Home cards no longer paints a warm `surfaceLow` track. The new track is `cardFill` pressed twice, a neutral grey at 1.56:1 (light) and 1.44:1 (dark) against the card. The arcs now use `onSuccessContainer`, `onWarningContainer` and `onErrorContainer`, so each band holds at least 3.5:1 against the track and 5.5:1 against the card in both themes.
    - Before this fix, the fair band's `warning` arc measured 2.84:1 against the old track in light mode.
    - In light mode the arcs are now darker; in dark mode they look the same as before. Both callers paint the ring on a `cardFill` card whatever the page, so the track follows that card fill. `PageSurface.fillOf` would give `groupedCard` on grouped pages, which is the wrong layer here.
  - `test/shared/widgets/score_ring_track_test.dart` (new): pumps the real `CvDocumentCard` and `HomeLatestCvSection` at every score-band edge (taken from `ScoreBand.of`), in light and dark, on plain pages and inside `GroupedSurface`. It checks four things:
    - the track's blue value is at least its red value (not a warm grey);
    - the track is at least 1.3:1 against every painted background;
    - the arc is at least 3:1 against the track and against every background;
    - `expectPaintedControlsAa` passes.
  - `test/shared/widgets/score_ring_test.dart` and `test/features/ats_scanner/ats_grade_scale_test.dart`: the expected arc colours now use the band ink tones.
  - Outside this repo, not committed:
    - `D:\Sirati\docs\screenshotsfter-round1\`: round 1's 320 captures, copied before the recapture.
    - `D:\Sirati\docs\screenshotsll-screens\`: the 320 new captures, with `.failures.json` = `{}`.
    - `D:\Sirati\docs\screenshots\ios26-before-after.html`: the board for 80 screens, with three columns per screen (before = `before-ios26/`, round 1 = `after-round1/`, now = `all-screens/`). It opens on AR light, has toggles for AR dark, EN light and EN dark, and an image-width slider. All 960 image paths are relative, and all of them resolve on disk.
- **Tests:**
  - Full `flutter test` on `swarm/final`: 3990 passed, 1 skipped, 0 failed.
    - The first run had 2 failures, and both came from this ticket's ring change. The colour-literal gate matched a `SiratiColors.` reference in a doc comment, and the scale test still expected the old arc colours. Both are fixed in `b7e4aea`.
  - `flutter analyze`: no issues.
  - `flutter test test_screens/all_screens_capture_test.dart`: 320 captured, 0 failed.
    - From a worktree, the test's relative `_outDir` (`../docs/...`) resolves outside the repo. For this run it was pointed at `D:/Sirati/docs/screenshots/all-screens` with an uncommitted edit, which was reverted afterwards.
- **Not covered by a test:**
  - The gap list below was judged by eye: all 80 AR light captures, plus AR dark for 01-20 and 61-80.
  - The board's images were not checked as rendered in a browser: the preview pane renders local files as a data: snapshot, so relative images don't load there. Instead, every path was checked to resolve on disk.

## Still not in the new style / known gaps

Seen in the captures:
- **Offline state (15, 23, 36, 53, 77):** the "quick tips" card is still a warm-tinted, bordered box. The retry button is a dark full-width gradient (unlike the retry pills on the error states), and "open saved CVs" is still an outlined secondary button.
- **My CVs tab (16, 20, 21, 24):** the dark teal gradient header band is still there above the grey tool cards. It may be intended; the owner should decide.
- **Segmented controls (32 language, 39-41 results tabs, 58-60 history tabs, 64-65 appearance):** the selected thumb carries a visible outline. A true iOS segmented thumb is a borderless raised fill.
- **Component gallery (80, debug only):** the disabled button fill is still warm beige.

Known and accepted:
- At 2.0 text scale on a 320dp phone the tab labels shrink: CV builder AR 0.86 / EN 0.73, ATS EN 0.83.
- Disabled IconButtons are below 3:1 (exempt under WCAG for inactive controls).
- The iOS back swipe and the iOS launch screen have not been checked on a real device (ready-for-human).
- The sheets lost their frosted blur and use an opaque grouped pane (ticket 21).
- On the opaque sheet pane, `primary` and `success` text measure under 4.5:1, so sheet text must use `primaryInk` and `onSuccessContainer`.
- `ScoreBoosterCard` and `SiratiAddButton` have no production call site.
- GitHub issue sync is pending (no push in this run).
