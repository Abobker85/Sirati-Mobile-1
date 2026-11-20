# 04: Sheets — no grabber, large radius, scaled background

**What to build:** every bottom sheet rises in ~400ms with a ~38 top radius and no grabber; the screen behind scales to ~95% and dims. It closes by swiping down or with a round close (X) button placed consistently per sheet pattern. All existing callers keep working unchanged.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] No grabber; ~38 top radius; background scale + dim, removed under reduced motion
- [x] Swipe-down and X both close; X has a label for screen readers
- [x] All current sheet callers compile and their tests stay green
- [x] New widget test pins the radius, absence of grabber and background scale
- [x] No schema change, no new dependency

**How to verify:** the new sheet test plus `flutter test test/features/dashboard/glass_navigation_test.dart`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `6b45cb0`, `657939a`, `b486d5f`.
- **Files:**
  - `lib/shared/widgets/components/app_sheet.dart` (sheet route subclass whose delegated transition shrinks the screen behind to 95% with 12pt rounded corners, following the sheet's animation and drag; 400ms rise; top radius = AppRadius.sheet 38; grab bar widget removed; new round `SheetCloseButton` at the end side with the localized "Close" label; `showDragHandle` now means "standard top" (the X); new optional `showCloseButton`; `showAppBottomSheet` shows the X)
  - `test/shared/widgets/components/app_sheet_test.dart` (new: AR/EN x light/dark: midway and settled background scale, barrier dim, radius 38, no grab bar by geometry, X position per direction, 44 circle in 48 target, semantics label/button/tap, strict 4.5:1 glyph over fill in rest/pressed/hover/focus, X and swipe-down close, drag partway scales back with the finger, reduced motion with no rise and no shrink; caller compatibility for showDragHandle:false, showCloseButton override, showAppBottomSheet)
  - `lib/shared/widgets/job_title_picker_field.dart` (own grab bar removed; owner decision 2026-11-20)
  - `lib/features/cv_builder/presentation/widgets/achievement_builder_sheet.dart` (own grab bar removed; owner decision 2026-11-20)
  - `lib/shared/widgets/components/app_sheet.dart`, second commit (a sheet that is not scroll controlled keeps 9/16 of the screen for content with the close row on top, and scrolls when taller instead of overflowing; third commit: lists inside without their own physics leave the drag to that one scroll, so a finger on the CV template picker's list reaches its last design)
  - `test/shared/widgets/components/app_sheet_small_phone_test.dart` (new: 320x568, text scale 1.0 and 1.3, AR and EN: the capped keyword advice sheet and a default sheet show no overflow, stay on screen, and the keyword sheet's last button can be scrolled to and closes it; the CV template picker opened as the CV screens open it: a drag on its list reaches and picks the last design, and the X closes it with null)
  - `test/features/dashboard/glass_navigation_test.dart` (sheets group: X shown/hidden, glass blurs, radius, no grab bar)
- **Tests:** `app_sheet_test.dart` 23 passed; `app_sheet_small_phone_test.dart` 16 passed; with `glass_navigation_test.dart` and `app_components_test.dart` 63 passed; full `flutter test` after the third commit: 2943 passed, 1 skipped, 0 failed. `flutter analyze lib` and the touched test files: no issues.
- **Decisions:** the background shrink uses the framework's delegated route transition, so no shell or theme file changed; the whole dashboard route (tab bar included) shrinks. The dim is the existing modal barrier. X sits at the end side (left in Arabic, right in English), the large-title pattern. Reverse (close) animation stays 300ms. The keyword advice sheet overflowed at 320x568 by about 214px before any change, so the fix is the scroll fallback, not only a shorter close row. Trade-off: inside a capped sheet, a nested list or multi-line field without its own physics no longer scrolls by itself (none of today's capped sheets has one that needs to).
- **Not covered by a test:** the grab bars removed from the job title picker and the achievement builder are checked by the diff, not a test (the shared sheet's absence of one is tested). "No schema change, no new dependency" is checked by the commit's file list, not a test. GitHub issue sync is pending (no push in this run).
