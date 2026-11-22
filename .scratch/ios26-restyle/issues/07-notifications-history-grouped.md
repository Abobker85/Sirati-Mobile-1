# 07: Notifications and history as grouped lists

**What to build:** the Notifications inbox and History use the grouped style from ticket 05: grey page, grouped white cards with separators, date/group headers above each card, no card shadows. Filters and actions keep working.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation), 05 (Settings and profile as inset-grouped lists)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Notifications and History use the shared section card; AR/EN, light/dark
- [x] Inbox and history tests updated (not loosened) and green
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/features/settings test/features/dashboard`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `b41f102`.
- **Files:**
  - `lib/features/settings/presentation/notifications_screen.dart` (grey grouped page and app bar; one AppListSection card per date under its date header; flat rows with no tint, border or shadow; a press darkens the card fill; chips filled with the card white; the empty inbox uses the shared AppEmptyState for the hero, scan action and copy, with the preview rows in a section card and "create CV" under it)
  - `lib/features/dashboard/presentation/history_screen.dart` (grey grouped page; each tab is date sections (today, yesterday, this week, earlier) of white cards in server order; Load more under the last card; `historySections` and `historyPeriodLabel` added)
  - `lib/features/dashboard/presentation/history/history_cards.dart` (rows go flat inside a section and are a borderless, shadowless white card on their own; 40dp icon box and separator indent)
  - `test/features/settings/notification_inbox_test.dart` (the helper paints the grey page; new: for each date, the header sits directly above one white card with its rows in order, rows-1 separators and no shadows, recomputed under the Unread and All filters, AR/EN x light/dark; a pressed row keeps every ink at 4.5:1 on the pressed fill; the unread dot is checked against the real row fill, resting and pressed)
  - `test/features/dashboard/history_test.dart` (new: `historySections` keeps every item once, in order, in runs of one period, over 200 random seeded lists; HistoryScreen AR/EN x light/dark: grey page, date-section headers, rows per card, separators, AA text, and Load more on both tabs adds rows into the sections)
- **Tests:** settings notification tests 52 passed; `history_test` 15 passed; full `flutter test` 3013 passed, 1 skipped, 0 failed. `flutter analyze` is clean on the touched files.
- **Not covered by a test:** "No schema change, no new dependency" is checked from the commit's file list (no pubspec, migration or ARB change). The empty state's look follows ticket 06's restyle of AppEmptyState, which this ticket does not edit. History reuses the inbox's date words (Today / Yesterday / This week / Earlier) from the existing catalog. GitHub issue sync is pending (no push in this run).
