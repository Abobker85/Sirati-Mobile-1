# 06: Calm empty, error and offline states

**What to build:** every empty, error and offline state looks the same: a grey icon inside a soft circle, a bold title, a two-line grey explanation, and a single action only where one is needed (retry). The shared state widgets carry this style, and the three screens that draw their own empty card (My CVs, Jobs, Notifications empty) move onto the shared widget.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Shared empty/error/offline widgets restyled; existing copy unchanged
- [ ] My CVs, Jobs and Notifications empty states use the shared widget
- [ ] AR/EN, light/dark; contrast strict
- [ ] State tests updated (not loosened) and green
- [ ] No schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/shared test/features/jobs test/features/cv_builder`, then full `flutter test`.
