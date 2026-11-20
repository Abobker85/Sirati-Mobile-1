# 05: Settings and profile as inset-grouped lists

**What to build:** Settings and Profile use the inset-grouped pattern: grey page, one white rounded card per section with hairline separators between rows, icon at the start, chevron at the end, section headers above each card. A reusable section card makes this one widget other screens can use (ticket 07). The language picker sheet's rows and the sign-out confirmation follow the same style.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Reusable section card with separators; rows keep the minimum tap target and button semantics
- [x] Settings, Profile, language sheet restyled in AR/EN, light/dark; chevrons point to the end side in RTL
- [x] Grey-on-grey secondary text passes 4.5:1 strictly
- [x] Settings tests updated (not loosened) and green; new test for the section card
- [x] No schema change, no new dependency

**How to verify:** `flutter test test/features/settings`, the dark-mode walk test, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `fdf575e`, plus the closing commit (doc-comment fix + this file).
- **Files:**
  - `lib/shared/widgets/app_list_section.dart` (new: AppListSection, inset-grouped card with header, hairline separators inset from the start, footer; AppListTileMetrics)
  - `lib/shared/widgets/app_list_tile.dart` (flat row inside a section: no own border, 32 px icon box, pressed fill `pressed(groupedCard)` instead of PressScale; `titleDirection`, `selected`; public AppListIcon; standalone look unchanged)
  - `lib/features/settings/presentation/settings_screen.dart` (grouped page and app bar; five sections; switch rows aligned with tile rows; centred sign-out dialog with onErrorContainer confirm)
  - `lib/features/settings/presentation/settings/settings_widgets.dart` (profile summary as a one-row section card; SettingsSectionLabel removed, replaced by section headers)
  - `lib/features/settings/presentation/settings/language_picker_sheet.dart` (rows as a grouped card, selected row announced, larger title)
  - `lib/features/settings/presentation/profile_screen.dart` (grouped page and app bar; photo source sheet as a grouped card)
  - `test/shared/widgets/app_list_section_test.dart` (new: separators n-1 for 1..6 rows, empty section, icon start / chevron end / separator inset per direction, one button node per row, static row not a button, header semantics, pressed fill, inks AA on resting and pressed card; AR/EN x light/dark)
  - `test/features/settings/settings_test.dart` (every row in a section, pressed-row text AA, chevrons at the end side, full-screen AA, sign-out dialog AA; AR/EN x light/dark)
  - `test/features/settings/language_picker_test.dart` (rows in one card, selected semantics, 48 px rows, AA; light/dark)
- **Tests:** settings + section + dark-mode walk + design-system contrast + localization: 562 passed. Full `flutter test`: 2953 passed, 1 skipped, 1 failed (`app_metrics_test` matched `SiratiColors.x` in a doc comment); comment fixed, `app_metrics_test` 9/9 passed. `flutter analyze` clean on touched files.
- **Decisions:** destructive titles (sign out, delete account, remove photo) use onErrorContainer: error is 4.08:1 on the pressed light card. Rows inside a section press with a fill, not a scale.
- **Not covered by a test:** "No schema change, no new dependency" is checked by the commit's file list (no pubspec, migration or ARB file touched). GitHub issue sync is pending (no push in this run).

