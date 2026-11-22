# 17: Education, Premium and History tabs

**What to build:** screens 56–63: Education list and detail use grouped sections and borderless cards; the Premium gate's benefits card becomes a grouped section with the teal capsule CTA; History's Material underline tabs move onto `AppSegmentedControl` above round 1's grouped lists.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/dashboard/presentation/education_screen.dart`, `education_detail_screen.dart`, `premium_gate_screen.dart`, `premium_unlocked_mark.dart`, `history_screen.dart` (tabs only), `gallery_screen.dart`.

**Blocked by:** 11 (Shared controls)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Education and Premium have no bordered cards; purchase/restore flows unchanged
- [x] History tabs on the shared segmented control; round 1's date sections and Load more still pass
- [x] AR/EN × light/dark; strict contrast
- [x] Tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/dashboard`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `6c59bb7`, `3724943` (History text scale) and a checker2 fix to the chrome helper (branch `swarm/edu`).
- **Files:**
  - `lib/features/dashboard/presentation/education_screen.dart`: the tab paints the grey `groupedBackground` page (full-bleed `ColoredBox`) inside `GroupedSurface`.
    - "What's coming" is one `AppListSection`: three flat rows with `AppListIcon` and the full description, never truncated.
    - The hero and the CV CTA are borderless, unshadowed `groupedCard` fills with `AppRadius.card`.
    - Both buttons take the theme's teal capsule.
    - New keys: `pageKey` and `upcomingKey`.
  - `lib/features/dashboard/presentation/education_detail_screen.dart`: `GroupedSurface`, with the scaffold colour coming from the grouped theme. The article is a borderless `groupedCard` card (`bodyCardKey`).
  - `lib/features/dashboard/presentation/premium_gate_screen.dart`:
    - `GroupedSurface` page.
    - Benefits are a heading plus an `AppListSection`, with flat rows and full bodies. The lead-benefit order is kept.
    - Informational plan cards are borderless page fills.
    - Store plan choices are borderless filled `Material`s with a pressed overlay. The choice reads through the radio mark (≥ 3:1), the selected semantics and the halo. The halo radius now follows `AppRadius.card`.
    - The active card radius is `card`. New key: `benefitsKey`.
    - Purchase, restore, refresh, keys and state logic are untouched.
  - `lib/features/dashboard/presentation/history_screen.dart`: `GroupedSurface`. `AppSegmentedTabBar` (with `textScaler: MediaQuery.textScalerOf(context)`) replaces the Material `TabBar`. `DefaultTabController` is built with `animationDuration: AppSegmentedTabBar.pageDuration(context)`.
  - `test/support/card_chrome.dart` (new): `expectNoCardChrome` walks the pumped tree under a screen. It fails on:
    - any `BoxDecoration` or `ShapeDecoration` side or shadow. A solid width-0 side is a hairline and counts.
    - any `Material` outline or elevation, canvas included; only a Scaffold's own page is exempt;
    - any elevated `PhysicalModel` / `PhysicalShape`;
    - a walk that checked nothing (Materials count).
    - It skips buttons, list separators, segmented controls and excluded subtrees.
  - `test/support/card_chrome_test.dart` (new, from checker2's review):
    - It rejects all 12 chrome kinds: border, hairline, width-0 side, shadow, Card elevation and outline, Material outline, ShapeDecoration side and shadow, PhysicalModel, PhysicalShape and canvas elevation.
    - It passes plain fills, separators and buttons, a Materials-only page, and excluded subtrees.
  - `test/features/dashboard/education_test.dart`: new grouped tests, run AR/EN × light/dark, registered or not. They cover:
    - the grey page and the grouped `PageSurface`;
    - one white section: its header, the three rows in order, 2 separators and untruncated bodies;
    - the hero and CTA painted on `groupedCard`;
    - no card chrome (excluding `ScreenHeader`) and capsule CTAs;
    - all text AA and all icons ≥ 3:1;
    - the detail page: grouped scaffold, borderless `groupedCard` article, no chrome, text AA.
  - `test/features/dashboard/history_test.dart`: new tests, en/ar × reduced motion or not. They cover:
    - the grouped page, no `TabBar`, an `AppSegmentedTabBar` with the context's text scaler, and the controller duration (zero under reduced motion);
    - a tap to CVs and back: one frame later the pages have jumped under reduced motion and are still sliding otherwise; both settle on the right page.
    - At 1x and 2x text scale (en/ar), the bar reserves `heightFor(live scaler) + padding`, and 2x is taller than 1x. Both labels are hit-testable and switch the page at 2x.
    - Ticket 07's date-section and Load more test is unchanged and passes.
  - `test/features/dashboard/premium_gate_test.dart`: new grouped tests, AR/EN × light/dark. They cover:
    - the grouped scaffold, and the benefits section (white card, 5 rows, 4 separators, untruncated bodies);
    - informational plans as borderless `groupedCard` fills;
    - for each store plan chosen in turn: every card is a `groupedCard` Material with no outline, exactly the chosen one has the checked radio and selected semantics, and the halo sits on the chosen card;
    - no card chrome across the whole scrolled page in the locked, active, store and success states.
    - The existing purchase, restore and contrast tests are unchanged and pass.
- **Tests:** `flutter test test/features/dashboard` plus the related suites all pass. Full `flutter test`: 3389 passed, 1 skipped, 0 failed. `flutter analyze`: No issues found.
- **Production call site:** History is the first production call site of `AppSegmentedTabBar`. This closes ticket 11's open item for 17.
- **Not covered by a test / notes:**
  - The segmented track's visibility on History's grey page depends on ticket 22. `AppSegmentedPalette` will follow `PageSurface`, and History now sits in `GroupedSurface` for that. No track colour is hard-coded here.
  - Shared, not in this ticket's files: `AppSkeleton` bones paint `cardFill`, which equals `groupedBackground`. So skeletons on grouped pages are invisible: History, the Education detail and the Premium plan skeletons. Reported to main.
  - `premium_unlocked_mark.dart` and `gallery_screen.dart` are unchanged; no criterion needed them.
  - "No schema change, no new dependency" is checked from the commit's file list: no pubspec, migration or ARB change, and no new strings.
  - GitHub issue sync is pending (no push in this run).
