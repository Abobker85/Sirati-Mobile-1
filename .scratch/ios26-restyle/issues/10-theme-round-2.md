# 10: Theme round 2 — page backgrounds, filled fields, capsule buttons, cards

**What to build:** pushed screens stop using the warm beige scaffold. Form and list screens sit on `groupedBackground`, content screens on `pageBackground`. Text fields become grey filled fields with no outline (focus shows a teal ring that passes 3:1). Secondary/outlined buttons become grey filled capsules. Shared bordered cards (`AppCard`) become borderless grey or grouped-white cards. Material chips (filter/choice) become filled capsules via the chip theme. Every screen still in the old style changes through the theme alone, before its own ticket touches it.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/shared/theme/*`, `lib/shared/widgets/form_fields.dart`, `lib/shared/widgets/components/app_input.dart`, `app_button.dart`, `app_card.dart`, `lib/shared/widgets/auth_form_constraint.dart`.

**Blocked by:** none (round 1 merged)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Scaffold background is `pageBackground`; screens that are forms or lists can ask for `groupedBackground` through one documented API
- [ ] Text fields: filled with `cardFill`, no resting outline, focus ring ≥ 3:1 against the fill, error state still visible without colour alone; label, hint, helper and error text ≥ 4.5:1 on the fill
- [ ] Outlined/secondary buttons are grey filled capsules; primary stays teal; 48dp targets kept
- [ ] `AppCard` has no border or shadow; chips are filled capsules (selected = teal tint that keeps text ≥ 4.5:1)
- [ ] AR/EN × light/dark widget tests on real pumped fields, buttons, cards and chips; strict contrast, no offsets
- [ ] Full `flutter test` green; no schema change, no new dependency

**How to verify:** `flutter test test/shared`, then full `flutter test`.
