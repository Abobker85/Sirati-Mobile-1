# 12: Start and sign-in screens

**What to build:** screens 02–10 (welcome, login, register, forgot password, email verification, sign-in required, onboarding, session expired) use the new style: white page, large title instead of the teal grid hero header, grouped filled fields, teal primary capsule, grey secondary capsule, social buttons as grey capsules.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/auth/presentation/*`, `lib/features/dashboard/presentation/splash/*`, `lib/features/settings/presentation/onboarding_screen.dart`, `lib/shared/widgets/auth_hero_page.dart`, `password_strength_meter.dart`, `password_visibility_toggle.dart`.

**Blocked by:** 10 (Theme round 2)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] All listed screens restyled; copy, validation, keys and flows unchanged
- [ ] Keyboard open on a 320×568 phone at text scale 1.3: no overflow, submit reachable (AR and EN)
- [ ] AR/EN × light/dark; strict contrast on every text and the strength meter
- [ ] Auth tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/auth test/features/settings`, then full `flutter test`.
