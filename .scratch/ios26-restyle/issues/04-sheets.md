# 04: Sheets — no grabber, large radius, scaled background

**What to build:** every bottom sheet rises in ~400ms with a ~38 top radius and no grabber; the screen behind scales to ~95% and dims. It closes by swiping down or with a round close (X) button placed consistently per sheet pattern. All existing callers keep working unchanged.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] No grabber; ~38 top radius; background scale + dim, removed under reduced motion
- [ ] Swipe-down and X both close; X has a label for screen readers
- [ ] All current sheet callers compile and their tests stay green
- [ ] New widget test pins the radius, absence of grabber and background scale
- [ ] No schema change, no new dependency

**How to verify:** the new sheet test plus `flutter test test/features/dashboard/glass_navigation_test.dart`, then full `flutter test`.
