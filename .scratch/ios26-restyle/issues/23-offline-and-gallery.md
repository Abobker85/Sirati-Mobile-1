# 23: Offline screens and gallery in the new style

**What to build:** screens 15, 23, 36, 53, 77 (offline) and 80 (gallery): the warm bordered "quick tips" card becomes an `AppListSection`; the dark gradient retry button becomes the teal primary capsule (like the error-state retry); "open saved CVs" becomes the grey secondary capsule; the gallery's disabled button uses the grey disabled fill. Delete `BrandGradientButton` if it has no caller left.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-21): flatten the last brand gradients (My CVs header, Premium hero); keep the segmented thumb outline; keep Sirati teal (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept, shipped weights 400/600/700, no Apple branding or copy).

**Owns:** `lib/shared/widgets/offline_view.dart`, `lib/shared/widgets/components/brand_gradient_button.dart`, `lib/features/dashboard/presentation/gallery_screen.dart`, their tests. Cross-ticket edits approved by main (2026-11-21): `lib/shared/widgets/components/app_button.dart` (disabled fill), `lib/shared/widgets/app_list_section.dart` and `lib/shared/widgets/empty_state.dart` (fill follows the page), and `GroupedSurface` wraps for the notifications, profile and settings screens.

**Blocked by:** none

**Status:** done (2026-11-21)

## Acceptance criteria

- [x] Offline: tips in a grouped section, no border or warm fill; retry is the teal capsule and still retries; open-saved is the grey capsule and still opens saved CVs; the reconnect ping still runs
- [x] Gallery disabled button has no warm fill
- [x] No gradient painted on the offline screen (checked on the pumped tree)
- [ ] AR/EN x light/dark; strict contrast (text 4.5:1, icons and boundaries 3:1); no overflow at 320x568, text scale 1.3 and 2.0
- [x] Existing tests updated (not loosened) and green; no schema change, no new dependency, no ARB change

**How to verify:** `flutter test test/shared`, then full `flutter test`.

## Outcome (2026-11-21)

- **Commits:** `3deb152` (code and tests), plus the commit that closes this ticket.
- **Files:**
  - `lib/shared/widgets/offline_view.dart`: tips are an `AppListSection` (header plus one row per tip, no border, no warm fill). Retry is `AppButton` primary (the teal capsule, with a spinner while checking). Open-saved is `AppButton.secondary` (the grey capsule).
  - `lib/shared/widgets/components/brand_gradient_button.dart`: deleted (no caller left).
  - `lib/shared/widgets/components/app_button.dart` (cross-ticket): disabled primary and destructive fill is `PageSurface.fillOf` instead of the warm `surfaceHigh`; loading is unchanged. This change is what fixes the gallery's disabled button; `gallery_screen.dart` itself is unchanged.
  - `lib/shared/widgets/app_list_section.dart` (cross-ticket): the card fill is `PageSurface.fillOf`, so it is white on grouped pages (unchanged) and grey on plain pages.
  - `lib/shared/widgets/empty_state.dart` (cross-ticket): the default `AppStateIcon` circle is `PageSurface.fillOf`, so it shows on both page kinds.
  - `lib/features/settings/presentation/notifications_screen.dart`, `profile_screen.dart`, `settings_screen.dart` (cross-ticket): wrapped in `GroupedSurface`, which replaces the hand-painted `groupedBackground` on Scaffold and AppBar. Settings keeps its explicit Scaffold colour because `settings_test` pins that property. `NotificationInbox` declares `PageSurface(kind: grouped)`, because it always sits on the grey grouped page.
  - `test/shared/offline_view_test.dart`: the matrix is now plain and grouped hosts x AR/EN x light/dark x 5 layouts (adds 320x568 at x1.3). It checks:
    - the section card and the state circle differ from the page; the tips section has no card chrome;
    - nothing paints a gradient or ShaderMask;
    - retry is a teal stadium at 3:1 or more against the page; open-saved is a stadium on the page fill with no side;
    - text is AA, icons are 3:1, tap targets pass.
    It also asserts that the reconnect ping ring appears on retry.
  - `test/shared/widgets/page_fill_follow_test.dart` (new): on plain and grouped pages, light and dark:
    - a disabled primary or destructive button is not warm, differs from the page, and its label differs from its fill;
    - a loading button keeps its colour fill;
    - the list-section card and the state circle differ from the page.
  - `test/gallery_screen_test.dart`: in light and dark, the gallery's "Disabled" button is not warm and differs from the page and from its label.
  - `test/app_components_test.dart`, `test/shared/design_system_contrast_test.dart`: the expected disabled fill changes from `surfaceHigh` to `PageSurface.fillOf`, following the new fill. Every other assertion, including the 4.5:1 checks, is unchanged.
  - `test/shared/widgets/calm_states_test.dart`: the button finder drops `BrandGradientButton`.
- **Tests:** full `flutter test`: 4040 passed, 1 skipped, 0 failed. `flutter analyze`: no issues. `notification_inbox_test`, `settings_test`, `profile_test` and `history_test` pass unchanged.
- **Not covered by a test:** the 3:1 "boundaries" part of the contrast criterion, for the grey fills. The tips card, the state circle and the grey open-saved capsule differ from the page, but they are about 1.1:1, as with every iOS 26 fill in this restyle. The teal retry capsule is 3:1 or more and is tested.
- **Known gaps (not this ticket):**
  - `SubmitButton` still uses the warm `surfaceHigh` disabled fill.
  - Inside a section, `AppListTile`'s pressed fill is still `pressed(groupedCard)`. That only matters for tappable rows in a section on a plain page, and no screen has one today.
  - A disabled primary button inside a `cardFill` card on a plain page now matches its card, as the secondary button already did.

