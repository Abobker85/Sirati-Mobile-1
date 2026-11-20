# 01: Restyle foundation — iOS 26 surfaces, radii, type scale and themed dialogs

**What to build:** every screen picks up the new visual language from one place: a grey grouped page background and a white page background, grey card fill with a darker pressed fill (~14% black over the card), hairline separators, card radius ~18, sheet top radius ~38, capsule buttons, and a type scale of large title 34 / section 22 / body 17 / caption 13 using the shipped weights. Dialogs, dividers, list tiles and switches restyle through the theme. Dark mode gets matching derived values. Custom page transition builders are not touched here (ticket 08).

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** None (can start immediately)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] New tokens exist for light and dark; every text/background pair they create passes 4.5:1 (large text 3:1) with strict assertions, no slack
- [x] Glass stays AA-safe over black or white; high-contrast mode still draws solid
- [x] Dialogs, dividers, list tiles and switches follow the new style in AR/EN, light/dark
- [x] Existing metric/contrast/typography tests updated to the new values (not loosened) and green
- [x] No schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/app_metrics_test.dart test/app_typography_test.dart test/app_contrast_test.dart`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `bae6f03`.
- **Files:**
  - `lib/shared/theme/sirati_colors.dart` (new tokens pageBackground, groupedBackground, cardFill, groupedCard, separator for light/dark; `pressed()` / `cardFillPressed` overlay 10% black light, 6% white dark)
  - `lib/shared/theme/app_contrast.dart` (cross-product pairs: every ink over every new surface, resting and pressed; outline 3:1 on resting surfaces)
  - `lib/shared/theme/app_typography.dart` (largeTitle 34/700, sectionTitle 22/700, headline 17/600, bodyXl 17/400, caption 13; AppRadius.card 18, sheet 38, capsule, cardAll, sheetTop, capsuleAll)
  - `lib/shared/theme/app_theme.dart` (dialogTheme, dividerTheme hairline, listTileTheme, switchTheme, cardTheme radius, bottomSheetTheme)
  - `test/app_metrics_test.dart` (card/sheet radius assertions added)
  - `test/app_typography_test.dart` (scale length 17 and new sizes)
  - `test/shared/theme/restyle_tokens_test.dart` (new: lerp/copyWith, pressed fill, radii, type, themed components in AR/EN x light/dark, RTL dark dialog pump)
- **Tests:** targeted four files 57 passed; full `flutter test` 2905 passed, 0 failed. `flutter analyze` clean on the touched files.
- **Decisions:** press overlay is 10%/6%, not the sampled ~14% (14% puts hint text and brand ink near 4.1:1). Grouped grey is `#F2F2F7` (keeps error ink at 4.5 on it). Switch off track uses `outline` (iOS grey is under 3:1 on white). Scaffold background and textTheme sizes are left as they were: screens adopt the new surfaces in their own tickets.
- **Not covered by a test:** "No schema change, no new dependency, no ARB change" is checked by the commit's file list, not a test. GitHub issue sync is pending (no push in this run).
