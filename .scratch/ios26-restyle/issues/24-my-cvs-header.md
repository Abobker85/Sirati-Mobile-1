# 24: My CVs header without the gradient band

**What to build:** screens 16, 20, 21, 24: the dark teal gradient header band on My CVs becomes a large title on the plain page that collapses into the top bar on scroll (the Home pattern, `home_large_title.dart`); the slim header that appears on scroll matches it. The CV list, empty state, tools card and their behaviour stay as they are.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-21): flatten the last brand gradients (My CVs header, Premium hero); keep the segmented thumb outline; keep Sirati teal (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept, shipped weights 400/600/700, no Apple branding or copy).

**Owns:** `lib/features/cv_builder/presentation/my_cvs_screen.dart`, `lib/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart` (header and slim header only), their tests.

**Blocked by:** none

**Status:** ready-for-agent

## Acceptance criteria

- [ ] No gradient band; large title on the page, collapsing into the bar on scroll; header actions and counts unchanged (Latin digits)
- [ ] Slim header matches, appears at the same scroll point
- [ ] AR/EN x light/dark; strict contrast (text 4.5:1, icons and boundaries 3:1); no overflow at 320x568, text scale 1.3 and 2.0
- [ ] Existing tests updated (not loosened) and green; no schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/features/cv_builder`, then full `flutter test`.
