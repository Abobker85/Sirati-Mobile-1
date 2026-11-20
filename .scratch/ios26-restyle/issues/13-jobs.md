# 13: Jobs list, detail and Home's latest jobs

**What to build:** screens 49–55 and Home's latest-jobs section: `JobNewsCard` and `FeaturedJobCard` become borderless grey cards that darken and spring on press (like `HomePressableCard`), the filter bar uses filled capsule chips, and the detail page uses grouped sections (`AppListSection`) instead of bordered/tinted blocks, with apply actions as a teal capsule.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/jobs/presentation/*` (except `EmptyJobNews` behaviour), `lib/features/dashboard/presentation/home/dashboard_jobs_section.dart`.

**Blocked by:** 10 (Theme round 2), 11 (Shared controls)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Job cards have no border or shadow; press darkens the fill and every ink stays ≥ 4.5:1 resting and pressed
- [x] Filters keep working (region, matched preset, clear); chips are filled capsules
- [x] Detail page in grouped sections; apply/share actions unchanged in behaviour
- [x] Latin digits in dates, salaries and counts; AR/EN × light/dark
- [x] Jobs and home tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/jobs test/features/dashboard`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `7f0f9b6` (code and tests), `4c2a239` (ticket close), plus the follow-up that checks chip inks against the pressed fill (branch `swarm/jobs`).
- **Files:**
  - `lib/features/jobs/presentation/widgets/job_pressable_card.dart` (new): `JobPressSurface` (grey page fill, 18dp corners, no edge or shadow, `pressed()` fill and a spring to 0.96 while held, no scale with reduced motion, focus ring outside), `JobPressableCard`, and `JobCardInk` (no splash or highlight). Jobs may not import dashboard (layering test), so this mirrors `HomePressableCard` instead of importing it.
  - `lib/features/jobs/presentation/widgets/job_news_card.dart`: `JobNewsCard` on `JobPressableCard`. `JobChip` is a borderless capsule with a `fill` (the page colour inside a grey card; the emphasis chip is `primaryLight` + `primaryInk`).
  - `lib/features/jobs/presentation/widgets/featured_job_card.dart`: the brand gradient hero became a larger grey card. Its details area drives the darken and spring, and Apply stays a sibling teal capsule, outside the card's tap target. Tags are `JobChip`s.
  - `lib/features/jobs/presentation/widgets/job_apply_actions.dart`: `jobApplyButtonStyle`, a teal (`brandSurface`) capsule with a white label that deepens to `brandSurfaceDeep` when pressed.
  - `lib/features/jobs/presentation/widgets/job_news_filters_bar.dart`:
    - Filter pills are filled capsules with no side: page fill at rest; selected is `primaryLight`, the theme's chip label ink and a checkmark. Pressing darkens the fill. Pills stay 48dp.
    - A preset icon tint that is under 3:1 on the grey fill (light amber, 2.88:1) falls back to the grey icon ink.
    - The search field drops its hard-coded fill and outlines and uses the theme's filled field.
  - `lib/features/jobs/presentation/widgets/matched_preset_note.dart`: no border.
  - `lib/features/jobs/presentation/widgets/job_news_common.dart`: removed the unused bordered `MetaChip`.
  - `lib/features/jobs/presentation/job_news_detail_screen.dart`:
    - `GroupedSurface` page.
    - Five `AppListSection`s:
      - facts, as value-only rows (pay and deadline in primary ink);
      - how to apply (copy email and haptic unchanged);
      - skills;
      - description (direction still follows the post);
      - source.
    - Section headers use existing ARB keys only, and the facts section has no header.
    - Action bar: grouped page colour over a separator hairline. Primary is the teal capsule; Tailor is the grey capsule (`secondaryButtonStyle`). Actions and behaviour are unchanged.
  - `lib/features/jobs/presentation/job_news_screen.dart`, `lib/features/dashboard/presentation/home/dashboard_jobs_section.dart`: expand-route and glint radius `AppRadius.card` (the featured card was 24).
  - `test/features/jobs/jobs_restyle_test.dart` (new, 80 tests). Every case runs on real pumped widgets:
    - `JobNewsCard` (full and compact) and `FeaturedJobCard`, AR/EN × light/dark × reduced motion:
      - no painted border, shadow or elevation;
      - rest fill is `cardFill`, and held fill is `pressed(cardFill)`;
      - scale is 0.96 when held, 1 with reduced motion;
      - all text ≥ 4.5:1 and icons ≥ 3:1, resting and held;
      - a tap fires once.
    - Featured Apply: a teal `StadiumBorder`, ≥ 48dp, not inside the card's ink; holding it leaves the card at rest, and the card's tap does not fire.
    - Filters, every preset selected × AR/EN × light/dark:
      - all pills are filled capsules with no side;
      - exactly one preset and one region are selected, each with a checkmark;
      - every pill's ink highlight paints exactly `pressed(fill)`;
      - its label is ≥ 4.5:1 and its icon ≥ 3:1 on that pressed fill (checked explicitly, since the probe cannot see ink highlights).
    - Filter behaviour is also covered by existing tests:
      - `job_news_controllers_test` "clear resets preset, region and query";
      - `job_news_states_test` "no results for the filters offers clearing them" and "Set job title opens the profile" (the matched note);
      - the contrast/reflow real empty-feed sweep over every preset, region and query, and its 48dp chip-tap test.
    - Detail, link/email/none × AR/EN × light/dark:
      - grouped scaffold and `PageSurface`;
      - 5 sections with their headers;
      - no box edges in the body except separator hairlines;
      - primary is a teal capsule, secondary a grey capsule with no side (absent for none);
      - text and icons AA, including with the primary held;
      - Latin digits.
    - Latin digits: 6 dates (relative and absolute, leap day, year end) × AR/EN on the cards and the detail. No Arabic-Indic digits are rendered, and the salary digits are shown as sent.
- **Tests:**
  - `flutter test test/features/jobs test/features/dashboard` plus the contrast/reflow, shipped-weights and architecture suites: all green.
  - Full `flutter test` after the last change: 3409 passed, 1 skipped (pre-existing), 0 failed.
  - `flutter analyze`: no issues.
  - No schema change, no new dependency, no ARB change.
- **Not covered by a test:** none of the criteria. Notes:
  - Salary text is shown as the server sends it. Display does not normalise digits; per AGENTS §4 that belongs at ingestion if the server ever sends Arabic-Indic digits.
  - The Home latest-jobs section is covered by the existing Home acceptance tests and by the compact-card tests above.
  - Production call sites: `JobNewsScreen` and `DashboardJobsSection`.
