# 18: Settings forms and privacy

**What to build:** screens 67, 70–72 and 76: change password, delete account, deleted-account cleanup and avatar crop on the grouped page with fields in grouped sections; the privacy policy's bordered cards become grouped sections; destructive actions keep `onErrorContainer` text.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/settings/presentation/change_password_screen.dart`, `delete_account_screen.dart`, `deleted_account_cleanup_screen.dart`, `avatar_crop_screen.dart`, `privacy_policy_screen.dart`.

**Blocked by:** 10 (Theme round 2)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Listed screens restyled; validation, confirmation dialogs and delete flow unchanged
- [x] AR/EN × light/dark; strict contrast, destructive text included
- [x] Settings tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/settings`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `9c97235` (code and tests), `d39c2cb` (ticket close), `ebf0b70` (border check asserts on painted sides, after rebasing onto ticket 11). All rebased onto `b2e232e`.
- **Files:**
  - `lib/features/settings/presentation/change_password_screen.dart`: `GroupedSurface`; the field labels are grey caption headers (`AppListSection` header style, announced as headings) above filled fields; the banner keeps its fixed slot.
  - `lib/features/settings/presentation/delete_account_screen.dart`: `GroupedSurface`; the warning is a borderless `errorLight` card (`AppRadius.card`) with `onErrorContainer` text; the password field sits under a caption header; the delete action (password or one per provider) is a destructive `AppListSection` row: `onErrorContainer` title, `errorLight` icon, loading label plus spinner and no taps while a request runs. The confirmation dialog's "Delete forever" uses `onErrorContainer` (was `error`). Validation, the second confirmation and the delete flow are unchanged.
  - `lib/features/settings/presentation/deleted_account_cleanup_screen.dart`: `GroupedSurface`; icon and message in one `groupedCard` card; the warning icon uses `onErrorContainer`.
  - `lib/features/settings/presentation/avatar_crop_screen.dart`: `GroupedSurface`; the window shade is the grouped page colour; Cancel is `AppButton.secondary` (grey capsule, no outline) and Use photo is `AppButton.primary` (keeps `doneKey`, disabled while saving).
  - `lib/features/settings/presentation/privacy_policy_screen.dart`: `GroupedSurface`; each bordered card is an `AppListSection` (title as the heading header, body in the card).
  - `test/features/settings/settings_forms_restyle_test.dart` (new, 24 tests): for all five screens in AR/EN × light/dark, on pumped widgets: grouped `PageSurface`, page and app bar painted `groupedBackground`, no box with a painted border side (any side whose style is not none; ticket 11's segmented track carries none sides), every field filled with `groupedCard`, every button a capsule with no outline and at least 48 dp, all text ≥ 4.5:1 and icons ≥ 3:1. It also covers: change-password field headers are headings and the empty-submit errors and banner are AA; delete with password keeps `onErrorContainer` on the warning, the row and the dialog action, shows one dialog, sends one request and ignores taps while loading (spinner ≥ 3:1); delete with providers has one destructive row per provider and no field; the privacy parts are five sections with heading titles.
- **Tests:** after rebasing onto `b2e232e`, `flutter test`: 3353 passed, 1 skipped (pre-existing), 0 failed. `flutter test test/features/settings`: 277 passed before the final import fix; the new file 24/24 after it. `flutter analyze`: no issues. No schema change, no ARB change, no new dependency.
- **Not covered by a test:** none of the criteria. Notes:
  - The privacy screen's `LanguageToggle` (ticket 11's segmented control) has a `cardFill` track that equals `groupedBackground` in light mode, so the track blends into the grouped app bar. Its text is AA. This belongs to ticket 11's area; the checker has reported it to main.
  - The existing EN-only AA loops in `account_security_test` and `notifications_test` were left as they are; the new file covers AR and EN.
