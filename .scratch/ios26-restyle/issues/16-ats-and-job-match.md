# 16: ATS scan, results and job match

**What to build:** screens 37–48: the scan form in grouped sections; the results tabs on `AppSegmentedControl`; score, keyword, fix and recommendation cards borderless grey with grouped rows; the loader on the new page; job match form, result and suggestion cards the same way. Score band colours stay meaningful without colour alone.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/ats_scanner/presentation/*`, `lib/features/job_match/presentation/*`, `lib/shared/widgets/score_booster_card.dart`, `animated_ats_score_bar.dart`.

**Blocked by:** 10 (Theme round 2), 11 (Shared controls)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Results tabs on the shared segmented control; swipe and tap in sync
- [ ] Every score band's text and badges ≥ 4.5:1 on their real fills; band also shown by label/icon
- [ ] Latin digits in scores and percentages; AR/EN × light/dark
- [ ] ATS and job match tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/ats_scanner test/features/job_match`, then full `flutter test`.
