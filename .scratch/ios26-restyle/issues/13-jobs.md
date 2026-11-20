# 13: Jobs list, detail and Home's latest jobs

**What to build:** screens 49–55 and Home's latest-jobs section: `JobNewsCard` and `FeaturedJobCard` become borderless grey cards that darken and spring on press (like `HomePressableCard`), the filter bar uses filled capsule chips, and the detail page uses grouped sections (`AppListSection`) instead of bordered/tinted blocks, with apply actions as a teal capsule.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/jobs/presentation/*` (except `EmptyJobNews` behaviour), `lib/features/dashboard/presentation/home/dashboard_jobs_section.dart`.

**Blocked by:** 10 (Theme round 2), 11 (Shared controls)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Job cards have no border or shadow; press darkens the fill and every ink stays ≥ 4.5:1 resting and pressed
- [ ] Filters keep working (region, matched preset, clear); chips are filled capsules
- [ ] Detail page in grouped sections; apply/share actions unchanged in behaviour
- [ ] Latin digits in dates, salaries and counts; AR/EN × light/dark
- [ ] Jobs and home tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/jobs test/features/dashboard`, then full `flutter test`.
