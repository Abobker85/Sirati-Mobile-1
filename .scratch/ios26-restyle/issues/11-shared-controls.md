# 11: Shared segmented control and grey skeletons

**What to build:** one shared segmented control (grey capsule track, white/raised thumb that slides, RTL-aware, 44dp segments, screen-reader tabs semantics) that can drive a `TabController` or a plain value, so the Material underline tabs (ATS results, CV builder, History) and the language toggle can move onto it in their own tickets. Skeleton loaders use the new grey fills instead of beige.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** new `lib/shared/widgets/app_segmented_control.dart`, `lib/shared/widgets/loading/*`, `lib/shared/widgets/language_toggle.dart`.

**Blocked by:** none (round 1 merged)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] `AppSegmentedControl` works with a `TabController` (swipe and tap stay in sync) and with a value + `onChanged`
- [x] Thumb position follows reading direction; reduced motion jumps instead of sliding
- [x] Selected and unselected labels ≥ 4.5:1 on their fills, AR/EN × light/dark; segments ≥ 44dp tall
- [x] Semantics: each segment is a selectable tab with its label and selected state
- [x] Language toggle uses the control; skeleton blocks use `cardFill` (and shimmer stays within the grey family)
- [ ] Production call site: the language toggle (this ticket); tabs in 15, 16, 17
- [x] Tests green; no schema change, no new dependency

**How to verify:** `flutter test test/shared`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `3b80019`, `e08ce2f`, `6c98a3d` (checker fixes) (branch `swarm/controls`).
- **Files:**
  - `lib/shared/widgets/app_segmented_control.dart` (new): `AppSegmentedControl<T>` (value + `onChanged`), `AppSegmentedTabBar` (`TabController` or `DefaultTabController`, a `PreferredSizeWidget` with a required `textScaler`), `AppSegment` / `AppSegmentedTab`, `AppSegmentedPalette`, and the shared `SegmentedTrack`.
    - Track: grey `cardFill` capsule.
    - Thumb: `groupedCard` in light, `surfaceHigh` in dark.
    - Inks: selected `primaryInk` at 600, unselected `textSecondary` at 400.
    - Segments are 44dp or taller and grow with text scale.
  - `lib/shared/widgets/language_toggle.dart`: an AR | EN segmented control in fixed physical order, so the thumb does not jump when the app mirrors. Screen readers hear the language names. Hero overrides map to track, inks and border.
  - `lib/shared/widgets/loading/app_skeleton.dart`: bones paint `cardFill` with a `cardFillPressed` shimmer. The static bone is now opaque (no 0.7 fade).
  - `test/shared/widgets/app_segmented_control_test.dart` (new, 22 tests), covering:
    - thumb under the selected segment and reading order, for 2 to 4 segments × every index × LTR/RTL;
    - a tap slides the thumb mid-way; reduced motion jumps in one frame;
    - tab mode: tap, fling and drag stay in sync, and reduced-motion taps jump;
    - `preferredSize` at text scales 1 to 2;
    - every label ink ≥ 4.5 on both track and thumb, including mid-slide, AR/EN × light/dark, themed and hero toggle;
    - segments ≥ 44dp at 200% on 320dp with no overflow;
    - tab / tabBar semantics roles with label and selected state;
    - the language toggle switching the app both ways.
  - `test/shared/widgets/app_skeleton_grey_test.dart` (new, 8 tests): every bone colour across all screen skeletons, sampled shimmer frames, light/dark, reduced or not and LTR/RTL, is `cardFill` or `cardFillPressed`. No bone fades.
- **Checker fixes (`6c98a3d`):**
  - **Reduced motion, tab mode:** `TabBarView` only jumps when its controller's `animationDuration` is zero. Callers therefore build the `TabController` or `DefaultTabController` with `animationDuration: AppSegmentedTabBar.pageDuration(context)`, which is zero under reduced motion. A debug build reports a controller that would still slide the pages. Tested: the page is hit-testable one frame after a tap, in LTR and RTL.
  - **Language toggle:** both short codes are read through the app's own delegates (`Localizations.override` on the other bundled locale), so published remote overrides show again. Tested with `appLocalizationsDelegates` in ar and en.
  - **Remote-only language (option picked):** it selects neither segment. The thumb is hidden, and tapping AR or EN switches the language, whatever the fallback. `AppSegmentedControl.value` is nullable for this case.
- **Tests:** full `flutter test`: 3216 passed, 1 skipped, 0 failed. `flutter analyze`: no issues.
- **Not covered by a test:** "Production call site: tabs in 15, 16, 17".
  - The tab mode (`AppSegmentedTabBar`) is infrastructure until tickets 15, 16 and 17 adopt it. The language toggle is its only production call site today.
- **Notes for 15, 16, 17:**
  - Pass `textScaler: MediaQuery.textScalerOf(context)`, and build the controller with `animationDuration: AppSegmentedTabBar.pageDuration(context)`.
  - Segments are equal width with an ellipsis. The CV builder's 4 icon + label tabs get about 80dp each on a phone.
  - The old toggle's tooltip strings `switchToArabic` / `switchToEnglish` are now unused.

