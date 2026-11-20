# 08: RTL page transitions and back-swipe everywhere

**What to build:** in Arabic, a pushed page enters from the left and the previous page moves right; in English the mirror. The back gesture starts at the start edge (right in Arabic), is interactive and cancellable on every route, including the custom expand and fade-through routes that today have no back-swipe. ~350ms; reduced motion respected.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Push direction correct in AR and EN (widget test pumps real routes in both directions)
- [ ] Back-swipe works and can be cancelled on standard, expand and fade-through routes
- [ ] Reduced motion keeps transitions minimal
- [ ] Routing and transition tests green
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/core/routing test/shared/widgets/transitions_motion_test.dart test/app_router_test.dart`.
