# 02: Floating glass tab bar

**What to build:** the dashboard tab bar is a floating Liquid Glass capsule above the home indicator, not edge to edge. Unselected tabs show a filled icon and label in the primary text colour; the selected tab is Sirati teal on a light grey pill inside the bar. Switching tabs is instant. Sirati keeps its own tabs. Existing scroll-compaction and scroll-end behaviour keep their public shape so Home (ticket 03) is unaffected.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Floating capsule with selected grey pill + teal icon/label, AR and EN, light and dark
- [x] Tab labels and icons pass contrast over the glass; tap targets at least the app minimum
- [x] RTL order starts from the right
- [x] New widget test pins selected/unselected look and instant switching
- [x] No schema change, no new dependency

**How to verify:** `flutter test test/features/dashboard`, `flutter test test_screens/home_board_capture_test.dart`.

## Outcome (2026-11-20)

- **Commits:** `6febb55`, `5cd059e`.
- **Files:**
  - `lib/features/dashboard/presentation/home/dashboard_navigation_bar.dart` (filled icons in both states; unselected ink `textPrimary`, selected `primaryInk` on a grey pill `pressed(surface)` drawn behind the selected tab; capsule radius `AppRadius.capsuleAll`; slide, stretch and breathing glow removed so switching is instant; one label size, weights 600/700; now a StatelessWidget; adds `pillKey`, `pillFill`, `pillInset`; removes `pillSize`, `pillStretch`, `DashboardNavigationBarState.paintedPill`, which only tests used. Constructor, `compact`, `compactAfter`, `order`, `margin`, `compactInset`, `maxWidth`, `capsuleKey` unchanged)
  - `test/features/dashboard/dashboard_tab_bar_test.dart` (new: AR/EN x light/dark x 320/412/1024 x open/compact one pill on the selected tab holding its icon and label; inks read from rendered widgets; strict 4.5 contrast of selected ink on the rendered pill and unselected ink on the glass over black/white/grey; instant switching for every from/to pair; RTL order; Android and iOS tap-target guidelines at 320dp)
  - `test/features/dashboard/dashboard_motion_test.dart` (pill group: slide test replaced by instant-switch test; finders moved off `MotionNavIcon`)
  - `test/features/dashboard/glass_navigation_test.dart` (floating-bar and scrolling groups only: stretch test replaced by one-frame move; fold tests assert the pill holds the selected icon)
- **Tests:** `flutter test test/app_metrics_test.dart test/features/dashboard` 324 passed. Full `flutter test` before the `5cd059e` fix: 2943 passed, 1 skipped, 1 failed (the no-`Colors.*` gate on the bar, fixed in `5cd059e` and re-run green). `flutter analyze` clean on `lib/features/dashboard` and `test/features/dashboard`. `test_screens/home_board_capture_test.dart` writes the four PNGs; its `home dark=false cv=true` case fails with a pending Timer on the base commit `096a8bb` too (not caused by this ticket).
- **Not covered by a test:** "No schema change, no new dependency" is checked by the commits' file lists. Page content still fades in on tab switch through `MotionTabStack` (shared `motion.dart`, outside this ticket): instant switching applies to the bar. `home_screen.dart` and `dashboard_scroll_end.dart` needed no change. GitHub issue sync pending (no push in this run).
