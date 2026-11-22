# 25: Premium hero without the gradient

**What to build:** screens 61-63: the Premium gate's dark teal gradient hero card becomes a grey grouped card (on the grouped page) with the teal primary capsule as its call to action. Purchase, restore and refresh flows and keys stay unchanged.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-21): flatten the last brand gradients (My CVs header, Premium hero); keep the segmented thumb outline; keep Sirati teal (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept, shipped weights 400/600/700, no Apple branding or copy).

**Owns:** `lib/features/dashboard/presentation/premium_gate_screen.dart` (hero only), its tests.

**Blocked by:** none

**Status:** done (2026-11-21)

## Acceptance criteria

- [x] No gradient painted on the Premium screen (checked on the pumped tree); hero is a borderless grouped card
- [x] Purchase, restore and refresh behaviour and keys unchanged
- [x] AR/EN x light/dark; strict contrast (text 4.5:1, icons and boundaries 3:1); no overflow at 320x568, text scale 1.3 and 2.0
- [x] Existing tests updated (not loosened) and green; no schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/features/dashboard`, then full `flutter test`.

## Outcome (2026-11-21)

- **Commits:** `34a18c7` (branch `swarm/premium`).
- **Readings agreed with main:**
  - "Grey grouped card" is the grouped page's card fill: `PageSurface.fillOf(context)`, which is `groupedCard`. A literal grey card would disappear on the grey page.
  - "The teal primary capsule as its call to action" is the page's existing primary action: Buy in store mode, Refresh in informational mode. Both are the theme's teal capsule. No hero button was added, because that would need new copy (an ARB change) and would break the button-label allowlist test.
- **Files:**
  - `lib/features/dashboard/presentation/premium_gate_screen.dart`: hero only.
    - The `LinearGradient` (`brandSurface` to `brandSurfaceDeep`) is gone. The hero is a borderless, unshadowed `PageSurface.fillOf` fill with `AppRadius.cardAll`.
    - Icon: `primary`. Title: `textPrimary`. Body: `textSecondary`.
    - New key: `heroKey`.
    - Purchase, restore and refresh flows, the existing keys and ticket 17's layout are untouched.
  - `test/support/no_gradient.dart` (new): `expectNoGradient` walks the pumped tree, root included. It fails on any `BoxDecoration` or `ShapeDecoration` gradient in a `DecoratedBox` or `Ink`, on any `ShaderMask`, and on a walk that checked nothing.
  - `test/support/no_gradient_test.dart` (new):
    - It rejects planted linear and radial `BoxDecoration` gradients, a `ShapeDecoration` gradient, a `Container`, an `Ink` and a `ShaderMask`.
    - It passes flat fills and fails an empty walk.
  - `test/features/dashboard/premium_gate_test.dart`:
    - `walkCards` now also runs `expectNoGradient` at every scroll position. That covers the locked, active, store and success states, AR/EN × light/dark.
    - New, for every `PremiumFeature` and AR/EN × light/dark: the hero is a `groupedCard` fill with no gradient and `AppRadius.card`; it shows the feature's title and body; its texts paint on `groupedCard`; there is no card chrome; all text passes AA and all icons ≥ 3:1.
    - New: Refresh (informational) and Buy (store) are `primary`-filled `StadiumBorder` capsules.
    - New: at 320x568 with text scale 1.3 and 2.0, for both the informational and store pages in AR/EN × light/dark, `inspectPhoneScreen` (strict text 4.5:1, icons and controls 3:1, no exceptions or overflow) and the chrome and gradient walk run at every scroll position.
    - Existing tests are unchanged. On the old gradient hero, the new tests fail (52+ failures).
- **Tests:**
  - `flutter test test/support/no_gradient_test.dart test/features/dashboard/premium_gate_test.dart`: 143 passed.
  - Full `flutter test`: 4046 passed, 1 skipped, 0 failed.
  - `flutter analyze`: No issues found.
- **Not covered by a test / notes:**
  - While plans load, the shared `AppSkeleton` shimmer paints a `LinearGradient`. It is a loading effect, not the hero, and not in this ticket's files, so the no-gradient walk covers the loaded states only (agreed with main).
  - No schema change, no new dependency, no ARB change: checked from the commit's file list.
  - GitHub issue sync is pending (no push in this run).
