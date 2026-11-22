# 08: RTL page transitions and back-swipe everywhere

**What to build:** in Arabic, a pushed page enters from the left and the previous page moves right; in English the mirror. The back gesture starts at the start edge (right in Arabic), is interactive and cancellable on every route, including the custom expand and fade-through routes that today have no back-swipe. ~350ms; reduced motion respected.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Push direction correct in AR and EN (widget test pumps real routes in both directions)
- [x] Back-swipe works and can be cancelled on standard, expand and fade-through routes
- [x] Reduced motion keeps transitions minimal
- [x] Routing and transition tests green
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/core/routing test/shared/widgets/transitions_motion_test.dart test/app_router_test.dart`.

## Outcome (2026-11-20)

- **Commits:** `011aa39`.
- **Files:**
  - `lib/core/routing/edge_back_swipe.dart` (new: back swipe from the start edge, 20dp strip, follows the finger through the route's public back-gesture hooks, goes back past half way or on a flick of at least 1 width/s toward the end edge, otherwise settles back in; refused when `popGestureEnabled` is false, e.g. `PopScope(canPop: false)`)
  - `lib/shared/widgets/motion.dart` (`SiratiPageTransitionsBuilder` is now a full-width slide along the reading direction (`CupertinoPageTransition`), 350ms each way, wrapped in `EdgeBackSwipe`; reduced motion: page appears at once, swipe kept. `MotionTabStack` switches tabs instantly: the tab fade (`_TabEnterTransition`) is removed, `TabVisitScope` kept)
  - `lib/shared/theme/app_theme.dart` (pageTransitionsTheme: `SiratiPageTransitionsBuilder` on every platform, iOS and macOS included)
  - `lib/core/routing/expand_page_route.dart` (back swipe added; `delegatedTransition` keeps the page below still so the card it grows from does not move)
  - `lib/core/routing/fade_through_page_route.dart` (back swipe added when not the first page; `delegatedTransition` veils the page below with the app background)
  - `test/core/routing/rtl_page_transitions_test.dart` (new, 44 tests: push and back direction in RTL and LTR on Android and iOS; for standard, expand and fade-through routes in both directions: swipe follows the finger and goes back, early release cancels and the route still pops normally after, a flick goes back, the end edge does nothing, a blocking screen refuses; the page below an expanding page stays put; reduced motion: page in place on the first frame and the swipe still works)
  - `test/shared/widgets/transitions_motion_test.dart` (shared-axis group replaced by the full slide: theme gives every platform the builder, direction in both directions, reduced motion)
  - `test/ui_components_test.dart` (one test, approved by main: MotionTabStack paints the first tab and a newly selected tab at full effective opacity on the very next frame, computed over every opacity render object above the text)
- **Tests:** `flutter test test/core/routing test/shared/widgets/transitions_motion_test.dart test/ui_components_test.dart` green; full `flutter test` 2988 passed, 1 skipped, 0 failed. `flutter analyze` reports 5 issues, all in `test_screens/` and present before this ticket; none in touched files.
- **Not covered by a test:** "No schema change, no new dependency" is checked by the commit's file list (no pubspec or migration). `app_router.dart` and `sirati_route_table.dart` needed no change: they already pick standard, expand and fade-through routes, which now all get the swipe. Android's system predictive back is not used (the in-app edge swipe works on Android too). GitHub issue sync pending (no push in this run).
