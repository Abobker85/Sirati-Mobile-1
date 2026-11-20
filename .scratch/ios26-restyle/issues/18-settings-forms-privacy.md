# 18: Settings forms and privacy

**What to build:** screens 67, 70–72 and 76: change password, delete account, deleted-account cleanup and avatar crop on the grouped page with fields in grouped sections; the privacy policy's bordered cards become grouped sections; destructive actions keep `onErrorContainer` text.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/settings/presentation/change_password_screen.dart`, `delete_account_screen.dart`, `deleted_account_cleanup_screen.dart`, `avatar_crop_screen.dart`, `privacy_policy_screen.dart`.

**Blocked by:** 10 (Theme round 2)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Listed screens restyled; validation, confirmation dialogs and delete flow unchanged
- [ ] AR/EN × light/dark; strict contrast, destructive text included
- [ ] Settings tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/settings`, then full `flutter test`.
