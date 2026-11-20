# 09: Recapture all screens and final check

**What to build:** the 80 screens are recaptured in Arabic/English and light/dark and set beside the "before" captures in a before/after board, so the owner can judge the restyle screen by screen; the full suite and the dark-mode walk pass on the integrated branch.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01, 02, 03, 04, 05, 06, 07, 08

**Status:** ready-for-agent

## Acceptance criteria

- [ ] All-screens capture rerun; before/after board produced
- [ ] Full `flutter test` green, `flutter analyze` clean
- [ ] List of screens still not in the new style (for the next round)

**How to verify:** `flutter test`, `flutter test test_screens/all_screens_capture_test.dart`, open the board.
