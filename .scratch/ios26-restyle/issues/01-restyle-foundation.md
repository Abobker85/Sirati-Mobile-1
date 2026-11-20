# 01: Restyle foundation — iOS 26 surfaces, radii, type scale and themed dialogs

**What to build:** every screen picks up the new visual language from one place: a grey grouped page background and a white page background, grey card fill with a darker pressed fill (~14% black over the card), hairline separators, card radius ~18, sheet top radius ~38, capsule buttons, and a type scale of large title 34 / section 22 / body 17 / caption 13 using the shipped weights. Dialogs, dividers, list tiles and switches restyle through the theme. Dark mode gets matching derived values. Custom page transition builders are not touched here (ticket 08).

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] New tokens exist for light and dark; every text/background pair they create passes 4.5:1 (large text 3:1) with strict assertions, no slack
- [ ] Glass stays AA-safe over black or white; high-contrast mode still draws solid
- [ ] Dialogs, dividers, list tiles and switches follow the new style in AR/EN, light/dark
- [ ] Existing metric/contrast/typography tests updated to the new values (not loosened) and green
- [ ] No schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/app_metrics_test.dart test/app_typography_test.dart test/app_contrast_test.dart`, then full `flutter test`.
