# 22: Segmented control visible on grouped pages; hero palette cleanup

**What to build:** on a `GroupedSurface` page the segmented control's track is `cardFill` #F2F2F7, the same as `groupedBackground`, so the track vanishes (1.00:1) and the thumb is 1.12:1 (dark 1.23 / 1.20). `AppSegmentedPalette` follows `PageSurface`: a grouped page gets a track and thumb that read as a control. The language toggle uses the same rule wherever it sits (no beige default). The dead hero colours in `auth_hero_palette.dart` (only the Google logo colours are still used after ticket 12) are deleted.

Found by the checker reviewing ticket 18 (2026-11-20) and the ticket 12 author.

**Owns:** `lib/shared/widgets/loading/*`, `lib/shared/widgets/app_segmented_control.dart`, `lib/shared/widgets/language_toggle.dart`, `lib/shared/theme/auth_hero_palette.dart` and their tests.

**Blocked by:** 10, 11 (both merged)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] On plain and grouped pages, light and dark: the thumb is ≥ 3:1 against the track or the track ≥ 3:1 against the page (non-text contrast, WCAG 1.4.11), measured on real pumped widgets
- [ ] Labels stay ≥ 4.5:1 on track and thumb; ticket 11's tests still green (not loosened)
- [ ] Language toggle has no beige/warm-grey default anywhere it is used
- [ ] `AppSkeleton` follows `PageSurface`: on grouped pages bones are visible (bone ≥ 3:1 is not required, but bone ≠ page and shimmer stays in the grey family; found by ticket 17: bones are `cardFill` = `groupedBackground`, invisible on History, Education detail, Premium plans)
- [ ] Unused hero constants removed; nothing else changes on the auth screens
- [ ] Full `flutter test` green; no schema change, no new dependency

**How to verify:** `flutter test test/shared`, then full `flutter test`.
