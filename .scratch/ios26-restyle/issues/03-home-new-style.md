# 03: Home in the new style

**What to build:** the Home tab is a white page with a large title (greeting) on the start side that collapses into a small pinned title on scroll, and a floating white pill (profile + notifications) on the end side that stays put while scrolling. Home cards are grey, shadowless, ~18 radius; pressing one darkens its fill and springs to ~0.96 then back. The two unused dashboard card widgets are deleted.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Large title collapses on scroll; header pill stays pinned (widget test with a real scroll)
- [ ] Card press darkens and scales, and respects reduced motion
- [ ] AR/EN, light/dark captured on the home board; contrast strict
- [ ] Dead dashboard action/stat cards and their test removed
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/features/dashboard`, `flutter test test_screens/home_board_capture_test.dart`.
