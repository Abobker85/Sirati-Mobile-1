# 17: Education, Premium and History tabs

**What to build:** screens 56–63: Education list and detail use grouped sections and borderless cards; the Premium gate's benefits card becomes a grouped section with the teal capsule CTA; History's Material underline tabs move onto `AppSegmentedControl` above round 1's grouped lists.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/dashboard/presentation/education_screen.dart`, `education_detail_screen.dart`, `premium_gate_screen.dart`, `premium_unlocked_mark.dart`, `history_screen.dart` (tabs only), `gallery_screen.dart`.

**Blocked by:** 11 (Shared controls)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Education and Premium have no bordered cards; purchase/restore flows unchanged
- [ ] History tabs on the shared segmented control; round 1's date sections and Load more still pass
- [ ] AR/EN × light/dark; strict contrast
- [ ] Tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/dashboard`, then full `flutter test`.
