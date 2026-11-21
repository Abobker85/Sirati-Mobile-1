# 15: CV builder, editors and generated CV

**What to build:** screens 32–33 and the My CVs cards: the builder's tabs and the CV language switch use `AppSegmentedControl`; the section editors (personal, experience/education, skills/languages, section order) use grouped sections and flat rows; the generated CV screen's action bar and cards are borderless grey; `CvDocumentCard` on My CVs matches. The rendered CV document itself (the paper and templates) is not restyled.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/cv_builder/presentation/` except `cv_generator/*`, `cv_generator_screen.dart` and `my_cvs/my_cvs_tools.dart`'s empty state; `lib/shared/widgets/template_preview.dart`.

**Blocked by:** 10 (Theme round 2), 11 (Shared controls)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Builder tabs and language switch use the shared segmented control; swipe and tap stay in sync
- [x] Editors in grouped sections; save status badge, reordering, chips and achievement sheet keep working
- [x] Generated CV screen and My CVs cards borderless; the CV paper and exported PDF unchanged (asserted on the export)
- [x] AR/EN × light/dark; strict contrast
- [x] CV builder tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/cv_builder`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `0d0b3d3` (restyle and tests), `0039a1f` (content-sized tab bar, built on ticket 22), plus the commit that closes this ticket. Branch `swarm/builder`, rebased on `8b7aa26`.
- **Files:**
  - `lib/features/cv_builder/presentation/cv_builder_screen.dart`:
    - The page is a `GroupedSurface` with a white bar.
    - The tabs are `AppSegmentedTabBar`: labels only, content-sized, with 8dp bar and label padding and `heightFor`.
    - The `TabController` uses `pageDuration`. It is rebuilt, keeping the open tab, when reduced motion flips.
    - The preview surround is now `groupedBackground` instead of warm grey.
  - `lib/features/cv_builder/presentation/section_editor_framework.dart`:
    - `SectionCardWrapper` is a collapsible header on the page, with the fields straight on the grouped page. The header is a button with an expanded state, at least 48dp.
    - New `EditorGroupCard`: a white card for row-like controls.
    - `ReorderableEntryList` rows are flat, split by `separator` hairlines.
    - The drag proxy gets an opaque `groupedCard` fill.
  - `lib/features/cv_builder/presentation/personal_details_editor.dart`: the input-language switch is `AppSegmentedControl`, inside a white card. The photo row moved to a white card. Teal text is `primaryInk`.
  - `lib/features/cv_builder/presentation/experience_education_editor.dart`: the calendar switch is `AppSegmentedControl`, inside a white card. Entries are flat rows. Teal text is `primaryInk`.
  - `lib/features/cv_builder/presentation/skills_languages_editor.dart`: entries are flat rows; chips use the theme capsule.
  - `lib/features/cv_builder/presentation/cv_builder/section_order_tab.dart`: the title and hint sit on the page; the rows are flat with hairlines, in one white card.
  - `lib/features/cv_builder/presentation/widgets/achievement_builder_sheet.dart`:
    - Wrapped in `GroupedSurface`; chips, the cancel button and the preset capsules have no outline.
    - `primaryDark` is replaced by `primaryInk`.
    - Insert is the theme's primary capsule.
  - `lib/features/cv_builder/presentation/generated_cv_screen.dart`:
    - The preview, ATS and next-step cards are borderless `cardFill` cards. The next-step cards use `AppSurfaceCard`.
    - The CV keeps a `surface` paper inside the preview.
    - Share has no outline. Busy Download fills with `cardFill`.
  - `lib/features/cv_builder/presentation/my_cvs/cv_document_card.dart`: a borderless, shadowless `cardFill` card. Open is a tinted `primaryLight` capsule. The inner chip and tile use `pageBackground`. The divider is `separator`.
  - `lib/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart`: the tools card is a title plus borderless grey tiles (`MyCvsToolsCard` only; the empty state is untouched).
  - `lib/features/cv_builder/presentation/my_cvs/cv_template_picker.dart`: rows are white `groupedCard`. The chosen row is `primaryLight` with a teal ring.
  - `test/features/cv_builder/cv_builder_restyle_test.dart` (new, 21 tests):
    - Tap and swipe keep the thumb, page and screen-reader selection in sync, AR (RTL) and EN (LTR).
    - Reduced motion jumps the page in one frame. With motion the page slides. Flipping reduced motion at runtime keeps the open tab.
    - No tab label is cut off at 320dp and 130% text, with the real fonts, AR and EN. Segments stay ≥ 44dp.
    - AR/EN × light/dark: a grouped page, a white bar, no warm-grey or outlined boxes, every text AA, on all four tabs.
    - The language switch shows and hides the fields. The calendar switch works. Section order is one white card and reordering works.
    - Entries with content, AR/EN × light/dark: AA, hairlines, an opaque drag row, delete. Sections collapse with and without reduced motion.
  - `test/features/cv_builder/generated_cv_hub_test.dart` (extended), AR/EN × light/dark:
    - Borderless `cardFill` cards and the paper.
    - Share has no outline; busy Download fills with `cardFill`.
    - Text AA.
    - The exported artefact: the shared PDF equals the server bytes and the request is unchanged (`/generated-cvs/<id>/download?language=<cv>`).
  - `test/features/cv_builder/my_cvs_card_contrast_test.dart` (extended), AR/EN × light/dark:
    - CV cards in four states: borderless with no shadow, no inner box in the card grey, Open ink ≥ 4.5 on its fill, AA.
    - The tools tiles.
    - The template picker rows.
  - `test/features/cv_builder/achievement_builder_sheet_test.dart` (extended), AR/EN × light/dark: grouped surface, no outlines, every text AA.
- **Tests:**
  - Full `flutter test`: 3982 passed, 1 skipped (pre-existing), 0 failed.
  - `flutter analyze`: no issues.
  - Contrast checks are strict (≥ 4.5, no offsets). The CV paper (`cv_document_view.dart`, `cv_live_preview_pane.dart`) and its goldens are unchanged.
  - No schema change, no new dependency, no ARB change.
- **Not covered by a test:** none of the criteria. Notes:
  - The CV paper colour inside the hub preview is `surface`. In dark mode it is close to the card grey, by design (the paper is not restyled).
  - `PROJECT_MEMORY` learnings were handed to main to merge:
    - Fields inside a card lose their edge in dark mode, because `cardFill` ≈ `groupedCard`.
    - Buttons animate their text colour, so `pumpAndSettle` before the contrast probe.
    - Call `loadAppFonts` once, in `setUpAll`.
