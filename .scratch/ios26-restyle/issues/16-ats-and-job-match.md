# 16: ATS scan, results and job match

**What to build:** screens 37–48: the scan form in grouped sections; the results tabs on `AppSegmentedControl`; score, keyword, fix and recommendation cards borderless grey with grouped rows; the loader on the new page; job match form, result and suggestion cards the same way. Score band colours stay meaningful without colour alone.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/ats_scanner/presentation/*`, `lib/features/job_match/presentation/*`, `lib/shared/widgets/score_booster_card.dart`, `animated_ats_score_bar.dart`.

**Blocked by:** 10 (Theme round 2), 11 (Shared controls)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Results tabs on the shared segmented control; swipe and tap in sync
- [x] Every score band's text and badges ≥ 4.5:1 on their real fills; band also shown by label/icon
- [x] Latin digits in scores and percentages; AR/EN × light/dark
- [x] ATS and job match tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/ats_scanner test/features/job_match`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `1791c56` (tabs), `50b9562` (result cards and bands), `ef1b84d` (scan form), `1dbdf47` (job match, loader, booster), `8a78faf` (goldens), plus the closing commit (analyzer fixes and this file). Branch `swarm/ats`.
- **Files:**
  - `lib/features/ats_scanner/presentation/analysis_result_screen.dart`: tabs are `AppSegmentedTabBar` (the first production call site in tab mode), with `textScaler` passed in. The `DefaultTabController` uses `animationDuration: AppSegmentedTabBar.pageDuration(context)`. The docked bar is `pageBackground` with no edge.
  - `analysis_result/score_tab.dart`: changes to the score tab.
    - The score hero is an `AppCard` (borderless page card fill), and the benchmark row has no box.
    - Separators are hairlines.
    - The grade badge carries the band icon, and the criterion % chips carry the criterion-band icon.
    - Bars use the default grey track.
  - `analysis_result/score_band_style.dart`: `ScoreBand.icon` and `CriterionBand.icon`, which are distinct per band.
  - `analysis_result/score_ring.dart`: the ring track is `pressed(PageSurface.fillOf)` instead of the teal-grey `border`.
  - `analysis_result/recommendations_tab.dart`: hairline separators. The upgrade card has no outline.
  - `analysis_result/keyword_group.dart`: keyword chips have no outline.
  - `cv_analysis_screen.dart`: the scan form is changed as follows.
    - It is a `GroupedSurface` page. Section titles sit on the page above themed filled fields, with no card, so no field shares its card's fill. The hard-coded field outline is gone.
    - The CV-source choices are filled capsules: `groupedCard` at rest, `primaryLight` plus a check icon when chosen, with no side.
  - `cv_analysis/analysis_form_sections.dart`: the drop zone and file tile have no outline. The drop-zone disc and the OR pill use the page fill. The OR lines are hairlines.
  - `cv_analysis_loader_screen.dart`: loading and error use `pageBackground`, the same as the result page they fade into.
  - `job_match_screen.dart`: the job match form is changed as follows.
    - It is a `GroupedSurface` page. The intro and fields sit on the page, not in a card.
    - CV options are flat rows inside the white section, with hairlines between them. The choice is shown by the radio icon, with no coloured edge.
    - Gates sit on the page, with no card around their grey capsule.
  - `job_match_result_screen.dart`: the result screen is changed as follows.
    - The advice-failed card is a `JobMatchSection`.
    - The apply bar is `pageBackground` with no edge. The disabled capsule is `cardFill` on the bar, and the busy retry is the pressed card fill.
  - `widgets/job_match_widgets.dart`: `JobMatchSection` is borderless on `PageSurface.fillOf`. Only a highlighted (selected) suggestion gets a 2 px primary-ink ring.
  - `lib/shared/widgets/animated_ats_score_bar.dart`: the default track is the surrounding card fill, pressed one step.
  - `lib/shared/widgets/score_booster_card.dart`: a borderless, unshadowed page card fill.
  - Tests:
    - `test/features/ats_scanner/analysis_result_tabs_test.dart` (new, 8 tests), in en LTR and ar RTL:
      - the segmented bar replaces the TabBar, and the first tab sits at the reading start;
      - reduced motion: tapping 0→1→0→1→0 shows the page in one frame, and the controller duration is zero;
      - a tap slides, and the thumb follows;
      - a fling forward then back changes the tab and the selected segment.
    - `test/features/ats_scanner/score_band_surfaces_test.dart` (new, 5 tests). It covers scores at every band edge (0/49/50/64/65/79/80/100) and criteria in every criterion band, AR/EN × light/dark. It checks:
      - the hero is borderless `cardFill`;
      - the band icon and description are present, and every criterion chip has its band icon;
      - all text is AA and all icons are 3:1 on their real fills, on both tabs;
      - no Arabic-Indic digits are painted.
      - The band icons are distinct.
    - `test/features/ats_scanner/cv_analysis_form_surfaces_test.dart` (new, 8 tests). It covers AR/EN × light/dark × both sources and checks:
      - the page is grouped;
      - fields are filled with no resting outline, and their fill differs from whatever is painted behind them;
      - source capsules have no side, a stadium shape and their own fill, and only the chosen one has the check;
      - the drop zone has no outline;
      - text is AA and icons are 3:1.
    - `test/features/job_match/job_match_surfaces_test.dart` (new, 20 tests). It covers AR/EN × light/dark and checks:
      - the form is grouped, sections are `groupedCard` with no resting border, fields and buttons have their own fills, and CV rows are marked by the radio with no border;
      - the paywall and load-failure gates are on the page, with no section card;
      - completed and failed results are a plain page of `cardFill` sections, the highlight ring is ≥ 3:1, and the apply bar is the page colour;
      - text is AA, icons are 3:1, and digits are Latin.
    - `analysis_result_contrast_test.dart`, `analysis_result_contract_test.dart`, `test/support/app_screens.dart`: they tap segments instead of `Tab`s. The contrast test asserts both segments exist, so the tab-2 check can no longer pass vacuously.
    - `test/features/dashboard/cv_analysis_home_acceptance_test.dart`: changes to the acceptance test.
      - It taps segments.
      - The `Tab` tap-target check is replaced by the segmented track: ≥ 48 tall, and each segment ≥ 48 wide.
      - The OutlinedButton check is now: a drawn side is still ≥ 3:1, every button label is ≥ 4.5:1 on its own fill, and the chosen source shows its check.
    - `test/features/job_match/job_match_states_test.dart`: the score ring's contrast is checked against `cardFill`, the fill it now sits on, instead of `surface`. The thresholds are unchanged.
    - `test/golden/goldens/score_booster_card_{light,dark}_{ltr,rtl}.png`: regenerated, borderless grey card. No other golden changed.
- **Tests:** full `flutter test`: 3370 passed, 1 skipped (pre-existing), 0 failed. The ats_scanner + job_match + dashboard + dark walk + golden subsets also pass. `flutter analyze`: no issues. No schema change, no new dependency, no ARB change.
- **Not covered by a test:** none of the criteria. Notes:
  - `ScoreBoosterCard` has no production call site (goldens only), so its restyle is infrastructure.
  - `lib/shared/widgets/score_ring.dart:61` (not in this ticket) still has the warm-grey fill.
  - `history_cards.dart` uses the `AnimatedAtsScoreBar` default track, so it now gets the grey pressed-card track. The dashboard tests pass.
  - The docked bars have no hairline. A `Divider` paints a `DecoratedBox` border, and the shared non-text probe (`expectPaintedControlsAa`) holds any border to 3:1, while `separator` is decorative.
