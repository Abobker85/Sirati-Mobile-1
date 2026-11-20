# 19: Nested scrolling inside capped sheets

**What to build:** inside a height-capped sheet (ticket 04's scroll fallback), a horizontal list and a multi-line text field scroll on their own again, without breaking the sheet's own vertical scroll or swipe-down close.

Design source: `docs/design/ios26/apple-support-design-prompt.md`. Follow-up of ticket 04's accepted trade-off.

**Owns:** `lib/shared/widgets/components/app_sheet.dart` and its tests.

**Blocked by:** none (round 1 merged)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] In a capped sheet: a horizontal list scrolls sideways, a multi-line field scrolls its text, a vertical list without physics still scrolls the sheet (CV template picker reaches its last design)
- [ ] Swipe-down and X still close; AR and EN; 320×568 at text scale 1.0 and 1.3
- [ ] Sheet tests green (not loosened); no schema change, no new dependency

**How to verify:** `flutter test test/shared/widgets/components`, then full `flutter test`.
