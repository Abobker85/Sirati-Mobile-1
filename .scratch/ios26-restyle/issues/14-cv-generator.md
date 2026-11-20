# 14: CV generator wizard

**What to build:** screens 25–31: grouped grey page, a calm step header (step count + title, thin teal progress), each step's fields in grouped sections, entry cards borderless, the footer as a glass bar with teal Next and grey Back capsules, the draft-restore banner as a grey card.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/cv_builder/presentation/cv_generator/*`, `cv_generator_screen.dart`, `lib/shared/widgets/ai_cv_field.dart`, `add_button.dart`, `job_title_picker_field.dart`.

**Blocked by:** 10 (Theme round 2)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] All four steps, header, footer and banner restyled; validation, autosave, exit dialogs and draft restore unchanged
- [ ] Step progress announced to screen readers; Latin digits in the step count
- [ ] 320×568 at text scale 1.3, keyboard open: footer stays reachable, no overflow (AR and EN)
- [ ] AR/EN × light/dark; strict contrast
- [ ] Generator tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/cv_builder`, then full `flutter test`.
