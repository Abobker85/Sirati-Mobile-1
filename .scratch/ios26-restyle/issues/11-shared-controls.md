# 11: Shared segmented control and grey skeletons

**What to build:** one shared segmented control (grey capsule track, white/raised thumb that slides, RTL-aware, 44dp segments, screen-reader tabs semantics) that can drive a `TabController` or a plain value, so the Material underline tabs (ATS results, CV builder, History) and the language toggle can move onto it in their own tickets. Skeleton loaders use the new grey fills instead of beige.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** new `lib/shared/widgets/app_segmented_control.dart`, `lib/shared/widgets/loading/*`, `lib/shared/widgets/language_toggle.dart`.

**Blocked by:** none (round 1 merged)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] `AppSegmentedControl` works with a `TabController` (swipe and tap stay in sync) and with a value + `onChanged`
- [ ] Thumb position follows reading direction; reduced motion jumps instead of sliding
- [ ] Selected and unselected labels ≥ 4.5:1 on their fills, AR/EN × light/dark; segments ≥ 44dp tall
- [ ] Semantics: each segment is a selectable tab with its label and selected state
- [ ] Language toggle uses the control; skeleton blocks use `cardFill` (and shimmer stays within the grey family)
- [ ] Production call site: the language toggle (this ticket); tabs in 15, 16, 17
- [ ] Tests green; no schema change, no new dependency

**How to verify:** `flutter test test/shared`, then full `flutter test`.
