# 06: Calm empty, error and offline states

**What to build:** every empty, error and offline state looks the same: a grey icon inside a soft circle, a bold title, a two-line grey explanation, and a single action only where one is needed (retry). The shared state widgets carry this style, and the three screens that draw their own empty card (My CVs, Jobs, Notifications empty) move onto the shared widget.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Shared empty/error/offline widgets restyled; existing copy unchanged
- [x] My CVs, Jobs and Notifications empty states use the shared widget
- [x] AR/EN, light/dark; contrast strict
- [x] State tests updated (not loosened) and green
- [x] No schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/shared test/features/jobs test/features/cv_builder`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `1795ade`, plus the closing commit (this file).
- **Files:**
  - `lib/shared/widgets/empty_state.dart` (AppEmptyState: grey glyph in a soft cardFill circle, bold title, grey explanation wrapped at 300 px, capsule action only when given, optional quieter second action and button keys, no idle nudge or float; new AppStateIcon; AppErrorState drops its red tint)
  - `lib/shared/widgets/offline_view.dart` (shared circle replaces the CV illustration, still pinging on each reconnect attempt; title size matches; ring sized from the circle)
  - `lib/features/jobs/presentation/widgets/job_news_common.dart` (EmptyJobNews renders AppEmptyState; clear filters / all regions stay its one action)
  - `lib/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart` (MyCvsEmptyCard renders AppEmptyState: create as the action, upload as the quieter second; keys kept; dashed-page illustration removed)
  - `test/shared/widgets/calm_states_test.dart` (new: every error type with and without retry, offline, three job-news empties, My CVs, plain empty; each has one grey circle, the expected button count, 48 px buttons, bold title, text and icon AA; AR/EN x light/dark)
- **Tests:** `test/shared`, `test/features/jobs`, `test/features/cv_builder`, localization, router, components and contrast/reflow suites: 1667 passed. Full `flutter test`: 3028 passed, 1 skipped, 0 failed. `flutter analyze` clean on touched files.
- **Decisions:** My CVs keeps two actions (create, upload) because both are first-CV paths; the second is a text button. Offline keeps its retry button type, tips card and open-saved button (copy unchanged); only its picture and title size changed. `app_async_body.dart` and `not_found_screen.dart` needed no change: they route to the restyled widgets.
- **Follow-up (2026-11-20):** the Notifications empty state moved onto `AppEmptyState` in ticket 07 (`b41f102`), so the second criterion is now ticked.
- **Not covered here:** "No schema change, no new dependency, no ARB change" is checked by the commit's file list. GitHub issue sync pending (no push in this run).

