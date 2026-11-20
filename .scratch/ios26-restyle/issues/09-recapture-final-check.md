# 09: Recapture all screens and final check

**What to build:** the 80 screens are recaptured in Arabic/English and light/dark and set beside the "before" captures in a before/after board, so the owner can judge the restyle screen by screen; the full suite and the dark-mode walk pass on the integrated branch.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01, 02, 03, 04, 05, 06, 07, 08

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] All-screens capture rerun; before/after board produced
- [x] Full `flutter test` green, `flutter analyze` clean
- [x] List of screens still not in the new style (for the next round)

**How to verify:** `flutter test`, `flutter test test_screens/all_screens_capture_test.dart`, open the board.

## Outcome (2026-11-20)

- **Commits:** `fb9896e`, plus the closing commit (this file).
- **Files:**
  - `test/features/settings/notification_inbox_test.dart`, `test/features/dashboard/history_test.dart` (top-level `tearDown` puts `AppLocale.languageCode` back after each test)
  - `test_screens/all_screens_capture_test.dart` (lint only: unneeded `dart:typed_data` import, import order, braces on an `if`)
  - `test_screens/cv_tab_capture_test.dart` (lint only: ignore comment on `SharedPreferences.setMockInitialValues`, which is fine in a capture test)
  - `.scratch/ios26-restyle/issues/06-empty-error-offline-states.md` (Notifications empty-state criterion ticked; points at 07's `b41f102`)
  - Outside this repo, not committed: `D:\Sirati\docs\screenshots\before-ios26\` (the 320 "before" captures, copied before recapture), `D:\Sirati\docs\screenshots\all-screens\` (320 "after" captures), `D:\Sirati\docs\screenshots\ios26-before-after.html` (board: 80 screens, before/after side by side, AR light by default with toggles for AR dark, EN light, EN dark, and an image-width slider; relative image paths)
- **Tests:** full `flutter test` on the integrated branch (a388b07 + the tearDowns): 3181 passed, 0 failed. `flutter analyze`: no issues (it reported 5, all in `test_screens/`, fixed in `fb9896e`). `flutter test test_screens/all_screens_capture_test.dart`: 320 captured, 0 failed. No integration breakage needed fixing.
- **Not covered by a test:** the board and the list below are judged by eye from the AR light captures (AR dark spot-checked).

## Still not in the new style (next round's scope)

- **Page background:** most pushed screens still sit on the old warm beige scaffold background instead of `pageBackground` / `groupedBackground` (auth, generator, ATS, job match, jobs, education, premium, change password, delete account, privacy, shared error / not found / offline). Home, Settings, Profile, Notifications and History already use the new surfaces.
- **Home:** the latest-jobs cards (`JobNewsCard`) are still white with a border.
- **Jobs (49-55):** list cards white and bordered; filter chips still Material outlined pills; detail page (55) uses the old bordered/tinted blocks.
- **Start and auth (02-10):** teal grid hero headers, outlined text fields and outlined secondary buttons; onboarding (03) and session expired (10) unchanged.
- **CV generator (25-31):** outlined fields, step header, beige page; dialogs are already the new style.
- **CV builder (32) and generated CV (33):** outlined fields and bordered cards; the language segmented control is still Material.
- **ATS scan and results (37-44), job match (45-48):** bordered cards, Material underline tabs on results.
- **Education (56-57):** bordered cards.
- **History (58-60):** Material underline tabs above the grouped lists.
- **Premium (61-63):** bordered benefits card.
- **Settings forms (67, 70, 71, 72) and privacy (76):** outlined fields; bordered privacy cards.
- **Skeleton loaders (13, 22, 50, 59, 74):** beige blocks, not the new grey fills.
- **Sheets:** inside a capped sheet, horizontal lists and multi-line fields without their own physics don't scroll.
- **Back swipe:** the iOS edge back swipe is only proven by widget tests; it has not been checked on a real device.
- GitHub issue sync for 01-09 is pending (no push in this run).
