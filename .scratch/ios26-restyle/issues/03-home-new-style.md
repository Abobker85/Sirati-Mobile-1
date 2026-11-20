# 03: Home in the new style

**What to build:** the Home tab is a white page with a large title (greeting) on the start side that collapses into a small pinned title on scroll, and a floating white pill (profile + notifications) on the end side that stays put while scrolling. Home cards are grey, shadowless, ~18 radius; pressing one darkens its fill and springs to ~0.96 then back. The two unused dashboard card widgets are deleted.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Large title collapses on scroll; header pill stays pinned (widget test with a real scroll)
- [x] Card press darkens and scales, and respects reduced motion
- [x] AR/EN, light/dark captured on the home board; contrast strict
- [x] Dead dashboard action/stat cards and their test removed
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/features/dashboard`, `flutter test test_screens/home_board_capture_test.dart`.

## Outcome (2026-11-20)

- **Commits:** `6b1a035`.
- **Files:**
  - `lib/features/dashboard/presentation/home/dashboard_home_tab.dart` (paints the white page; large title in the tab's own scroll view after the pinned bar; shine radius 18)
  - `lib/features/dashboard/presentation/home/dashboard_home_header.dart` (now the pinned bar: a floating white pill with profile + bell on the end side, and a small title that fades in when collapsed; `subtitle` param removed)
  - `lib/features/dashboard/presentation/home/home_large_title.dart` (new: greeting at the large-title size on the start side, plus the hint)
  - `lib/features/dashboard/presentation/home/home_glass_header.dart` (optional `collapseAfter` key; tells the bar when the large title has scrolled under it)
  - `lib/features/dashboard/presentation/home/home_pressable_card.dart` (grey card fill, no border or shadow, radius 18; pressed fill derived from the resting fill; spring to 0.96, no scale with reduced motion)
  - `lib/features/dashboard/presentation/home/home_premium_card.dart` (a grey pressable card; gold shine .2 to .16 so text keeps AA on the grey fill, resting and pressed, dark)
  - `lib/features/dashboard/presentation/home/home_latest_cv_section.dart`, `dashboard_jobs_section.dart` (section title type; grey CV frame, radius 18)
  - `lib/features/dashboard/presentation/home/home_service_tile.dart` ("soon" tile uses the same grey fill)
  - `lib/features/dashboard/presentation/home/dashboard_action_card.dart`, `dashboard_stat_card.dart`, `test/features/dashboard/dashboard_action_card_test.dart` (deleted, unused)
  - `test/features/dashboard/home_restyle_test.dart` (new: real-drag collapse with the pill pinned, AR/EN x light/dark x text scale 1/2, all text AA, small title AA on the glass over black and white; press fill/scale with and without reduced motion; Premium shine AA on grey)
  - `test/features/dashboard/cv_analysis_home_acceptance_test.dart` (name and hint now read from the large title)
  - `test/features/dashboard/phase2_entry_home_motion_test.dart`, `test/features/settings/subscription_in_profile_test.dart` (dropped the removed `subtitle` arg; the pill has no chevron)
  - `test_screens/home_board_capture_test.dart` (AR and EN, and lets one-shot intro timers end)
- **Tests:** `home_restyle_test` 15 passed; `flutter test test/features/dashboard` plus the premium, ambient, dark-walk and profile tests: 387 passed; full `flutter test` 2913 passed, 1 skipped, 0 failed; `flutter test test_screens/home_board_capture_test.dart` 8 passed (`build/home_board/home-{ar,en}-{light,dark}-{cv,empty}.png`). `flutter analyze` is clean on the touched files.
- **Not covered by a test:** "No schema change, no new dependency" is checked from the commit's file list (no pubspec, migration or ARB change). The latest-jobs cards on Home are the jobs feature's `JobNewsCard` (white, bordered), not restyled here. GitHub issue sync is pending (no push in this run).
