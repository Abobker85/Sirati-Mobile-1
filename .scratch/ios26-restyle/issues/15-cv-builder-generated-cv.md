# 15: CV builder, editors and generated CV

**What to build:** screens 32–33 and the My CVs cards: the builder's tabs and the CV language switch use `AppSegmentedControl`; the section editors (personal, experience/education, skills/languages, section order) use grouped sections and flat rows; the generated CV screen's action bar and cards are borderless grey; `CvDocumentCard` on My CVs matches. The rendered CV document itself (the paper and templates) is not restyled.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/cv_builder/presentation/` except `cv_generator/*`, `cv_generator_screen.dart` and `my_cvs/my_cvs_tools.dart`'s empty state; `lib/shared/widgets/template_preview.dart`.

**Blocked by:** 10 (Theme round 2), 11 (Shared controls)

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Builder tabs and language switch use the shared segmented control; swipe and tap stay in sync
- [ ] Editors in grouped sections; save status badge, reordering, chips and achievement sheet keep working
- [ ] Generated CV screen and My CVs cards borderless; the CV paper and exported PDF unchanged (asserted on the export)
- [ ] AR/EN × light/dark; strict contrast
- [ ] CV builder tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/cv_builder`, then full `flutter test`.
