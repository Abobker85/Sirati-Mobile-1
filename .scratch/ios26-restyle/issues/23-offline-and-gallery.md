# 23: Offline screens and gallery in the new style

**What to build:** screens 15, 23, 36, 53, 77 (offline) and 80 (gallery): the warm bordered "quick tips" card becomes an `AppListSection`; the dark gradient retry button becomes the teal primary capsule (like the error-state retry); "open saved CVs" becomes the grey secondary capsule; the gallery's disabled button uses the grey disabled fill. Delete `BrandGradientButton` if it has no caller left.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-21): flatten the last brand gradients (My CVs header, Premium hero); keep the segmented thumb outline; keep Sirati teal (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept, shipped weights 400/600/700, no Apple branding or copy).

**Owns:** `lib/shared/widgets/offline_view.dart`, `lib/shared/widgets/components/brand_gradient_button.dart`, `lib/features/dashboard/presentation/gallery_screen.dart`, their tests.

**Blocked by:** none

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Offline: tips in a grouped section, no border or warm fill; retry is the teal capsule and still retries; open-saved is the grey capsule and still opens saved CVs; the reconnect ping still runs
- [ ] Gallery disabled button has no warm fill
- [ ] No gradient painted on the offline screen (checked on the pumped tree)
- [ ] AR/EN x light/dark; strict contrast (text 4.5:1, icons and boundaries 3:1); no overflow at 320x568, text scale 1.3 and 2.0
- [ ] Existing tests updated (not loosened) and green; no schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/shared`, then full `flutter test`.
