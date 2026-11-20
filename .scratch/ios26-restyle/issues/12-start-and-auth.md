# 12: Start and sign-in screens

**What to build:** screens 02–10 (welcome, login, register, forgot password, email verification, sign-in required, onboarding, session expired) use the new style: white page, large title instead of the teal grid hero header, grouped filled fields, teal primary capsule, grey secondary capsule, social buttons as grey capsules.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/auth/presentation/*`, `lib/features/dashboard/presentation/splash/*`, `lib/features/settings/presentation/onboarding_screen.dart`, `lib/shared/widgets/auth_hero_page.dart`, `password_strength_meter.dart`, `password_visibility_toggle.dart`, and the native launch screens (Android `splash_background` / launch drawables, iOS `LaunchScreen.storyboard` background): they are still cream (#FAF7F2) while the first Flutter frame is now white, so a cold start flashes cream then white (found in ticket 10).

**Blocked by:** 10 (Theme round 2)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Native launch background matches the first Flutter frame in light and dark (no cream flash)
- [x] All listed screens restyled; copy, validation, keys and flows unchanged
- [x] Keyboard open on a 320×568 phone at text scale 1.3: no overflow, submit reachable (AR and EN)
- [x] AR/EN × light/dark; strict contrast on every text and the strength meter
- [x] Auth tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/auth test/features/settings`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `83133e7` (code, native launch, tests), plus this ticket close.
- **Files:**
  - `lib/shared/widgets/auth_hero_page.dart`: the gradient hero, grid painter, overlapping shadowed card and the `breathing` flag are gone. `AuthHeroPage` keeps its API and keys and is now a plain page: `AuthTopBar` (back chevron and language toggle on the page fill), the mark, a start-aligned large title (`largeTitle`, `sectionTitle` when compact below 520 px) and subtitle, then the card and `below`, all in one scroll view. `boxedCard` puts the card in a borderless `cardFill` box at `AppRadius.card` (Welcome's value card). The status-bar style follows the theme (it was always light icons).
  - `lib/features/auth/presentation/login_screen.dart`, `register_screen.dart`: no `breathing`; password eye is `PasswordVisibilityToggle`. Register was re-indented by `dart format` (no logic change).
  - `lib/features/auth/presentation/social_sign_in_section.dart`: Google/Apple are grey filled capsules (`PageSurface.fillOf`, `StadiumBorder`, press overlay, no border); divider uses `separator`.
  - `lib/features/auth/presentation/forgot_password_screen.dart`: the title moves from the app bar to a large title in the page; intro is `bodyXl` secondary; the language toggle sits on the page fill; the `ListView` is a `SingleChildScrollView` so every stage's controls exist on short screens.
  - `lib/features/auth/presentation/email_verification_screen.dart`: `AuthTopBar`, start-aligned icon, large title, subtitle and email.
  - `lib/features/auth/presentation/session_expired_screen.dart`: `BrandGradientButton` -> teal `SubmitButton` capsule; title `largeTitle`; reassurance card, pill, check badge (ticket 10's :362) and CV page are `cardFill` with no shadow; chip has no border; shield (ticket 10's :329) is `pageBackground` inside the teal circle, so its edge is against the circle.
  - `lib/features/auth/presentation/sign_in_required_screen.dart`: unchanged; it follows `AuthHeroPage` (card not boxed, so the grey secondary capsule keeps its edge).
  - `lib/features/dashboard/presentation/splash/welcome_body.dart`: boxed value card, no `breathing`.
  - `lib/features/settings/presentation/onboarding_screen.dart`: Skip is the theme's grey capsule (still an `OutlinedButton`); hero circles lose border and shadow, the brand-mark circle is `cardFill`; language toggle on the page fill.
  - `lib/shared/widgets/password_strength_meter.dart`: track uses `separator`.
  - `android/app/src/main/res/values/colors.xml`: light `splash_background` #FAF7F2 -> #FFFFFF (night was already #121614). `drawable/` and `drawable-v21/launch_background.xml`: comments only.
  - `ios/Runner/Base.lproj/LaunchScreen.storyboard`: background is the named colour `LaunchBackground` (Named colors capability added; LaunchImage line untouched). `ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json` (new, outside the Owns list but needed for dark): #FFFFFF, dark #121614.
  - `test/branding/launch_matches_first_frame_test.dart` (new): pumps `SplashScreen` light and dark, reads the painted page under the boot mark, and asserts the Android launch window, launch drawable and `splash_background` (API 19/21/31/34) and the iOS storyboard's named colour (resolved through the colorset per appearance) equal it.
  - `test/features/auth/auth_keyboard_reflow_test.dart` (new, 20 tests): login, register, forgot password (both stages), email verification x AR/EN x light/dark at 320x568, text x1.3, keyboard 260 px: no exception/overflow, submit `hitTestable` above the keyboard after `ensureVisible`, all text AA before and after.
  - `test/shared/widgets/password_strength_meter_contrast_test.dart` (new): passwords generated from every mix of the four rules (Latin and Arabic letters) plus 40 random ones, covering every level; label AA and each filled segment >= 3:1 on the painted page, AR/EN x light/dark.
  - `test/login_layout_test.dart`: old -> new invariants. Gradient-hero ancestor with white text AA on every stop and full-bleed band -> no gradient or shadow above the mark or title, both painted on `pageBackground`. Centred title/subtitle -> start-aligned; title at the `largeTitle` token (`sectionTitle` when compact), w700, under the mark and sharing its start edge. New: status-bar icon brightness follows the theme; every text AA. Mark 56 / smaller below 520 px and the reachability/keyboard checks are kept as they were.
  - `test/features/auth/session_expired_screen_test.dart`: finds `SubmitButton` instead of `BrandGradientButton`; width <= 440 and reachability asserts unchanged.
  - `test/dark_mode_12_screen_walk_test.dart`: forgot-password intro expected `textSecondary` (now the large title's subtitle) instead of `textPrimary`; its AA check is unchanged.
- **Tests:** `flutter test` full suite: 3321 passed, 1 skipped (pre-existing), 1 failed (the dark walk pin above), fixed and re-run green (13/13). `flutter analyze`: no issues. No schema change, no new dependency, no ARB change; copy, validation, keys and flows unchanged.
- **Not covered by a test:** none of the criteria. Notes:
  - The iOS launch screen was not built on a device (Windows host); the test checks the storyboard and colorset files. iOS caches launch screens, so a reinstall may be needed to see it.
  - `lib/shared/theme/auth_hero_palette.dart` (not owned) still holds the old hero constants (gradient, onHero, pill, grid, card shadow); only the Google colours are used now. Ticket 10's owner can delete the dead ones.
  - `LanguageToggle`'s default fill is `surfaceLow` (beige on white); these screens pass the page fill, other callers do not.
