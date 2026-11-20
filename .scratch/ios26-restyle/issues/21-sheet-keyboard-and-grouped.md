# 21: Sheet keyboard focus and grouped surface

**What to build:** (a) in a height-capped sheet with the keyboard open, focusing a text field at the end of a shrink-wrapped list scrolls the sheet so the field shows above the keyboard (bug found by the checker in ticket 19; it already happens on b41e2b8). (b) Once ticket 10 is merged, sheet content sits inside `GroupedSurface`, so cards, fields and chips in a sheet use the grouped fills (white `groupedCard` on `#F2F2F7`).

**Owns:** `lib/shared/widgets/components/app_sheet.dart` and its tests.

**Blocked by:** 19 (merged); part (b) also by 10 (Theme round 2)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Capped sheet with the keyboard open (320×568, text scale 1.0 and 1.3, AR and EN): a focused field anywhere in a shrink-wrapped list is fully visible above the keyboard
- [x] Sheet content uses grouped fills; field, card and chip text and fills are strict 4.5:1, light and dark
- [x] Ticket 19's nested-scroll tests still green (not loosened); no schema change, no new dependency

**How to verify:** `flutter test test/shared/widgets/components`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `f0583f6` (a, keyboard), `f2bda3d` (b, grouped surface).
- **Files:**
  - `lib/shared/widgets/components/app_sheet.dart` (a: the route always gives the full height and a capped sheet applies its own cap, 9/16 of the screen plus the close row, growing by the keyboard's height with its scroll padded to end above the keyboard; scroll controlled sheets unchanged. b: every sheet's glass holds an opaque grouped-background pane (a Material, so row ink paints on it) with the content in GroupedSurface; the glass edge is redrawn over the pane, the firm outline in high contrast or solid mode; the round X fills with the page fill, the grouped card colour on a sheet; new public `appSheetPaneKey`)
  - `test/shared/widgets/components/app_sheet_keyboard_test.dart` (new: 320x568, AR and EN, text scale 1.0 and 1.3; fields first, middle and last in a shrink-wrapped list; focus first, then the keyboard rises: the field sits fully inside the sheet's scroll and above the keyboard, the scroll ends above the keyboard, every scrollable stays in its extent and the sheet still scrolls; without the keyboard the cap is unchanged; the height comes back when the keyboard goes down)
  - `test/shared/widgets/components/app_sheet_grouped_test.dart` (new: light and dark, AR and EN, capped and scroll controlled, normal and high contrast: content is on the grouped pattern; text on the pane is painted on the grouped background only; row ink lands on the pane; the edge is drawn over the pane in the right colour; field, card, chip and X fill with the grouped card colour, which differs from the pane; field, card and chip text sits on that fill; every text on screen strict AA)
- **Tests:** the new tests failed on the old code (fields behind the keyboard; content on the plain pattern). `test/shared/widgets/components` all green, ticket 19's nested-scroll tests unchanged; full `flutter test` 3329 passed, 1 skipped, 0 failed; `flutter analyze` no issues.
- **Decisions:** the pane is opaque grouped background, as the ticket and the design source ask for settings-style sheets ("white groupedCard on #F2F2F7"). A grouped tint at the glass's 88% opacity was tried first and failed strict AA over a dark backdrop (the Premium prompt's "Not now" fell to 4.44:1), so the opacity is not a contrast trade-off any more: text on a sheet reads the same over anything. Cost: the blur behind every sheet no longer shows, although GlassSurface still runs it (glass_navigation_test's "blurs" still passes). If sheets should look frosted again, that needs a fill option on GlassSurface (outside this ticket's file set) and a palette that stays AA. The capped sheet's keyboard handling made the route always scroll controlled at route level; the cap now lives in the sheet.
- **Not covered by a test:** "no schema change, no new dependency" is checked by the commits' file lists. GitHub issue sync is pending (no push in this run).
