# 21: Sheet keyboard focus and grouped surface

**What to build:** (a) in a height-capped sheet with the keyboard open, focusing a text field at the end of a shrink-wrapped list scrolls the sheet so the field shows above the keyboard (bug found by the checker in ticket 19; it already happens on b41e2b8). (b) Once ticket 10 is merged, sheet content sits inside `GroupedSurface`, so cards, fields and chips in a sheet use the grouped fills (white `groupedCard` on `#F2F2F7`).

**Owns:** `lib/shared/widgets/components/app_sheet.dart` and its tests.

**Blocked by:** 19 (merged); part (b) also by 10 (Theme round 2)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Capped sheet with the keyboard open (320×568, text scale 1.0 and 1.3, AR and EN): a focused field anywhere in a shrink-wrapped list is fully visible above the keyboard
- [ ] Sheet content uses grouped fills; field, card and chip text and fills are strict 4.5:1, light and dark
- [ ] Ticket 19's nested-scroll tests still green (not loosened); no schema change, no new dependency

**How to verify:** `flutter test test/shared/widgets/components`, then full `flutter test`.
