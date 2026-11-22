# 24: My CVs header without the gradient band

**What to build:** screens 16, 20, 21, 24: the dark teal gradient header band on My CVs becomes a large title on the plain page that collapses into the top bar on scroll (the Home pattern, `home_large_title.dart`); the slim header that appears on scroll matches it. The CV list, empty state, tools card and their behaviour stay as they are.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-21): flatten the last brand gradients (My CVs header, Premium hero); keep the segmented thumb outline; keep Sirati teal (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept, shipped weights 400/600/700, no Apple branding or copy).

**Owns:** `lib/features/cv_builder/presentation/my_cvs_screen.dart`, `lib/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart` (header and slim header only), their tests.

**Blocked by:** none

**Status:** done (2026-11-21)

## Acceptance criteria

- [x] No gradient band; large title on the page, collapsing into the bar on scroll; header actions and counts unchanged (Latin digits)
- [x] Slim header matches, appears at the same scroll point
- [x] AR/EN x light/dark; strict contrast (text 4.5:1, icons and boundaries 3:1); no overflow at 320x568, text scale 1.3 and 2.0
- [x] Existing tests updated (not loosened) and green; no schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/features/cv_builder`, then full `flutter test`.

## Outcome (2026-11-21)

- **Commits:** `7fbc99d` (restyle and tests), plus the follow-up commit that closes this ticket (swaps a deprecated test matcher).
- **Files:** `lib/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart`: `MyCvsHeader` is now a large title with the hint and bell on the plain page, with no BreathingBand, gradient or `bottomInset`. `MyCvsSlimHeader` is an opaque bar filled with the glass tint over the page, with a centred `headline` title. The bell has no fill and uses `textPrimary` ink. `showAfter` is now `MyCvsHeader.topPadding`. `lib/features/cv_builder/presentation/my_cvs_screen.dart`: the gradient strip behind the tools card and `_toolsOverlap` are gone, and the tools card now sits under the title. `test/features/cv_builder/my_cvs_header_restyle_test.dart`: new test file.
- **Tests:** in the new file, each of AR/EN x light/dark gets four checks:
  - no gradient in any painted box decoration, and no BreathingBand, both at rest and once scrolled to the slim bar;
  - the large title sits on the scaffold page fill, uses the large-title size and is announced as a header;
  - all text is at least 4.5:1 and all icons at least 3:1, at rest and with the slim bar showing;
  - the slim bar is opaque and its title is announced as a header.

  The file also covers Latin digits in AR for three unread/CV count pairs, and 320x568 at text scale 1.3 and 2.0 in AR/EN with no exceptions, full-width bars and 48dp bells. The existing `my_cvs_tab_test.dart` slim-header group (one reachable bell at every scroll step, same switch point) is unchanged and green. The new test fails on the old code (gradient, plain page). Full `flutter test`: +4009 ~1, all passed. `flutter analyze`: no issues.
- **Not covered by a test:** none. The criterion "no schema change, no new dependency, no ARB change" was checked with `git show --stat`: only the three files above changed.
