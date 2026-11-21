# 25: Premium hero without the gradient

**What to build:** screens 61-63: the Premium gate's dark teal gradient hero card becomes a grey grouped card (on the grouped page) with the teal primary capsule as its call to action. Purchase, restore and refresh flows and keys stay unchanged.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-21): flatten the last brand gradients (My CVs header, Premium hero); keep the segmented thumb outline; keep Sirati teal (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept, shipped weights 400/600/700, no Apple branding or copy).

**Owns:** `lib/features/dashboard/presentation/premium_gate_screen.dart` (hero only), its tests.

**Blocked by:** none

**Status:** ready-for-agent

## Acceptance criteria

- [ ] No gradient painted on the Premium screen (checked on the pumped tree); hero is a borderless grouped card
- [ ] Purchase, restore and refresh behaviour and keys unchanged
- [ ] AR/EN x light/dark; strict contrast (text 4.5:1, icons and boundaries 3:1); no overflow at 320x568, text scale 1.3 and 2.0
- [ ] Existing tests updated (not loosened) and green; no schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/features/dashboard`, then full `flutter test`.
