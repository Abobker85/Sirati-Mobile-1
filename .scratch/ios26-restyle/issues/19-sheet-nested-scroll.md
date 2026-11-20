# 19: Nested scrolling inside capped sheets

**What to build:** inside a height-capped sheet (ticket 04's scroll fallback), a horizontal list and a multi-line text field scroll on their own again, without breaking the sheet's own vertical scroll or swipe-down close.

Design source: `docs/design/ios26/apple-support-design-prompt.md`. Follow-up of ticket 04's accepted trade-off.

**Owns:** `lib/shared/widgets/components/app_sheet.dart` and its tests.

**Blocked by:** none (round 1 merged)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] In a capped sheet: a horizontal list scrolls sideways, a multi-line field scrolls its text, a vertical list without physics still scrolls the sheet (CV template picker reaches its last design)
- [x] Swipe-down and X still close; AR and EN; 320×568 at text scale 1.0 and 1.3
- [x] Sheet tests green (not loosened); no schema change, no new dependency

**How to verify:** `flutter test test/shared/widgets/components`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `b8158ee`.
- **Files:**
  - `lib/shared/widgets/components/app_sheet.dart` (the NeverScrollable scroll configuration around capped sheet content is gone; the content now gets a primary scroll controller whose positions drop the top-level "always scrollable" physics a primary vertical list gives itself, so a shrink-wrapped list leaves the drag to the sheet while a list with its own overflow, a horizontal list and a text field scroll by themselves)
  - `test/shared/widgets/components/app_sheet_nested_scroll_test.dart` (new: 320x568, AR and EN, text scale 1.0 and 1.3, Android and iOS: a horizontal list scrolls sideways and leaves the sheet still; a multi-line field scrolls its text; a drag on a shrink-wrapped vertical list moves the sheet on every drag until its last row shows while the list itself stays at 0; a vertical drag on the horizontal list scrolls the sheet; a vertical list held shorter than its content scrolls itself; swipe-down and the X close; every scrollable in the sheet stays within its own extent after each drag)
  - `test/shared/widgets/components/app_sheet_small_phone_test.dart` (CV template picker test tightened: the sheet's own scroll moved, and no scrollable sits outside its extent)
- **Tests:** the new and tightened tests failed on the old code (horizontal, field, vertical-list and picker cases); after the change `test/shared/widgets/components` 95 passed; full `flutter test` 3236 passed, 1 skipped, 0 failed; `flutter analyze` no issues.
- **Decisions:** finding: ticket 04's picker case never really worked. A vertical ListView without controller or `primary` is primary and bakes in always-scrollable physics, which overrode the inherited NeverScrollable; the shrink-wrapped list took the drag and drifted past its extent while the sheet stayed put, and the old test only checked that the last design's rect came on screen. A caller that sets `AlwaysScrollableScrollPhysics` on a primary list inside a capped sheet gets it dropped too (give the list a controller or `primary: false` to keep it). The primary controller is inherited on every platform inside the sheet.
- **Not covered by a test:** "no schema change, no new dependency" is checked by the commit's file list, not a test. GitHub issue sync is pending (no push in this run). `docs/agents/PROJECT_MEMORY.md` still says nested scrollables in capped sheets need their own physics; outside this ticket's file set, left for the coordinator.
