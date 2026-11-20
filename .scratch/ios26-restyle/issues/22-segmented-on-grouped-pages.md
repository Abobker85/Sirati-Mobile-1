# 22: Segmented control visible on grouped pages; hero palette cleanup

**What to build:** on a `GroupedSurface` page the segmented control's track is `cardFill` #F2F2F7, the same as `groupedBackground`, so the track vanishes (1.00:1) and the thumb is 1.12:1 (dark 1.23 / 1.20). `AppSegmentedPalette` follows `PageSurface`: a grouped page gets a track and thumb that read as a control. The language toggle uses the same rule wherever it sits (no beige default). The dead hero colours in `auth_hero_palette.dart` (only the Google logo colours are still used after ticket 12) are deleted.

Found by the checker reviewing ticket 18 (2026-11-20) and the ticket 12 author.

**Owns:** `lib/shared/widgets/loading/*`, `lib/shared/widgets/app_segmented_control.dart`, `lib/shared/widgets/language_toggle.dart`, `lib/shared/theme/auth_hero_palette.dart` and their tests.

**Blocked by:** 10, 11 (both merged)

**Status:** done (2026-11-21)

## Acceptance criteria

- [x] On plain and grouped pages, light and dark: the thumb is ≥ 3:1 against the track or the track ≥ 3:1 against the page (non-text contrast, WCAG 1.4.11), measured on real pumped widgets
- [x] Labels stay ≥ 4.5:1 on track and thumb; ticket 11's tests still green (not loosened)
- [x] Language toggle has no beige/warm-grey default anywhere it is used
- [x] `AppSkeleton` follows `PageSurface`: on grouped pages bones are visible (bone ≥ 3:1 is not required, but bone ≠ page and shimmer stays in the grey family; found by ticket 17: bones are `cardFill` = `groupedBackground`, invisible on History, Education detail, Premium plans)
- [x] Unused hero constants removed; nothing else changes on the auth screens
- [x] Content-sized segments (added 2026-11-21, from ticket 15): when equal widths would cut a label, widths follow label width; if that still does not fit, labels wrap (segments grow taller); no label is ever ellipsized or clipped; segment padding can shrink (8 instead of 12/16); the thumb tracks a swipe across unequal widths in LTR and RTL; equal-width mode is unchanged when labels fit (real fonts, 2-4 segments, 320dp, text scale 1.0/1.3/2.0, AR/EN)
- [x] Full `flutter test` green; no schema change, no new dependency

**How to verify:** `flutter test test/shared`, then full `flutter test`.

## Outcome (2026-11-21)

- **Commits:** `2a149a8` (page-aware palette), `f9a5e18` (hero colours and toggle override), `13e8e81` (skeletons), `5f3bd51` (content-sized segments), `f3d9dee` (cross-ticket test edit), `5860993` (tab bars wrap only into reserved height). Branch `swarm/controls-22`, rebased on `1e599ba`.
- **Files:**
  - `lib/shared/widgets/app_segmented_control.dart`:
    - `AppSegmentedPalette.of` follows `PageSurface`. Plain pages: `cardFill` track; thumb `groupedCard` in light, `surfaceHigh` in dark. Grouped pages: `groupedCard` track, `cardFill` thumb.
    - Every thumb has a 2dp `outline` edge, which carries the 3:1 boundary. It is 2dp because a 1dp edge on a half pixel rasterizes at 2.56:1.
    - New `SegmentLayout` lays segments out in four modes: equal widths, then apportioned by label width, then wrapped (each segment at least its longest word), then scaled down on one line.
    - New `labelPadding` on the control, the tab bar and the track.
    - New `AppSegmentedTabBar.heightFor` and `height`. A tab bar wraps labels only into a height reserved this way; without one it scales labels instead.
  - `lib/shared/widgets/language_toggle.dart`: `backgroundColor` overrides only the track, and the thumb, edge and inks stay themed. The translucent-hero path (`foregroundColor`, `side`) had no caller left and is removed.
  - `lib/shared/theme/auth_hero_palette.dart`: only the Google mark colours remain.
  - `lib/shared/widgets/loading/app_skeleton.dart`: bones paint the page's control fill (`PageSurface.fillOf`), and the shimmer is that fill's pressed shade.
  - `test/shared/widgets/app_segmented_control_test.dart`: new page-aware group and new non-text contrast check; the hero test is removed.
  - `test/shared/widgets/app_segmented_content_width_test.dart` (new): real fonts, 2-4 segments, 320dp, scale 1.0/1.3/2.0, AR/EN, default and compact padding, with and without a reserved height. Checks:
    - no ellipsis and no clipping: the longest word fits, every line fits, and the paragraph sits inside its segment;
    - no overflow;
    - widths stay equal when labels fit;
    - widths follow content when labels don't fit;
    - the thumb follows the segment rects mid-swipe in LTR and RTL;
    - the run reached all four layout modes.
  - `test/shared/widgets/app_skeleton_grey_test.dart`: plain and grouped × light/dark × reduced/animated × LTR/RTL. Every bone colour is the page fill or its pressed shade, and the fill differs from the page.
  - `test/features/settings/settings_forms_restyle_test.dart`: **cross-ticket edit to ticket 18's test**, approved by the coordinator.
    - The widget keyed `SegmentedTrack.thumbKey` is exempt from "grouped content has no bordered boxes". It is a selection indicator, not a content box.
    - In its place, the thumb's edge must be ≥ 3:1 against its track.
    - The privacy page asserts that the thumb is present.
- **Tests:** full `flutter test`: 3604 passed, 1 skipped, 0 failed. `flutter analyze`: no issues. Before the fix, the new contrast test measured track/page 1.00 to 1.17 and thumb/track 1.12 to 1.20.
- **Not covered by a test:** none.
- **Notes for callers:**
  - Ticket 15 (CV builder): pass `padding` and `labelPadding: AppSpacing.xs`, plus `height: AppSegmentedTabBar.heightFor(context, tabs: ..., padding: ..., labelPadding: ...)` so labels can wrap. Also keep `textScaler` and `animationDuration: AppSegmentedTabBar.pageDuration(context)`.
  - Without a reserved height, labels scale down instead. With the test font this already happens on the ATS results tabs (ticket 16).

