# 05: Settings and profile as inset-grouped lists

**What to build:** Settings and Profile use the inset-grouped pattern: grey page, one white rounded card per section with hairline separators between rows, icon at the start, chevron at the end, section headers above each card. A reusable section card makes this one widget other screens can use (ticket 07). The language picker sheet's rows and the sign-out confirmation follow the same style.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): foundation + shell first; keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Blocked by:** 01 (Restyle foundation)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Reusable section card with separators; rows keep the minimum tap target and button semantics
- [ ] Settings, Profile, language sheet restyled in AR/EN, light/dark; chevrons point to the end side in RTL
- [ ] Grey-on-grey secondary text passes 4.5:1 strictly
- [ ] Settings tests updated (not loosened) and green; new test for the section card
- [ ] No schema change, no new dependency

**How to verify:** `flutter test test/features/settings`, the dark-mode walk test, then full `flutter test`.
