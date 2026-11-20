# 07: Notifications and history as grouped lists

**What to build:** the Notifications inbox and History use the grouped style from ticket 05: grey page, grouped white cards with separators, date/group headers above each card, no card shadows. Filters and actions keep working.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation), 05 (Settings and profile as inset-grouped lists)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Notifications and History use the shared section card; AR/EN, light/dark
- [ ] Inbox and history tests updated (not loosened) and green
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/features/settings test/features/dashboard`, then full `flutter test`.
