# 02: Floating glass tab bar

**What to build:** the dashboard tab bar is a floating Liquid Glass capsule above the home indicator, not edge to edge. Unselected tabs show a filled icon and label in the primary text colour; the selected tab is Sirati teal on a light grey pill inside the bar. Switching tabs is instant. Sirati keeps its own tabs. Existing scroll-compaction and scroll-end behaviour keep their public shape so Home (ticket 03) is unaffected.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Floating capsule with selected grey pill + teal icon/label, AR and EN, light and dark
- [ ] Tab labels and icons pass contrast over the glass; tap targets at least the app minimum
- [ ] RTL order starts from the right
- [ ] New widget test pins selected/unselected look and instant switching
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/features/dashboard`, `flutter test test_screens/home_board_capture_test.dart`.
