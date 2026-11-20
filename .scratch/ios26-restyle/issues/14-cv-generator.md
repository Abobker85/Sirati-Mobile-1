# 14: CV generator wizard

**What to build:** screens 25–31: grouped grey page, a calm step header (step count + title, thin teal progress), each step's fields in grouped sections, entry cards borderless, the footer as a glass bar with teal Next and grey Back capsules, the draft-restore banner as a grey card.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/features/cv_builder/presentation/cv_generator/*`, `cv_generator_screen.dart`, `lib/shared/widgets/ai_cv_field.dart`, `add_button.dart`, `job_title_picker_field.dart`. Since 2026-11-20 (main's decision) it also owns all of `lib/features/cv_builder/presentation/widgets/skill_chips_selector.dart`, with its public API unchanged.

**Blocked by:** 10 (Theme round 2)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] All four steps, header, footer and banner restyled; validation, autosave, exit dialogs and draft restore unchanged
- [x] Step progress announced to screen readers; Latin digits in the step count
- [x] 320×568 at text scale 1.3, keyboard open: footer stays reachable, no overflow (AR and EN)
- [x] AR/EN × light/dark; strict contrast
- [x] Generator tests updated (not loosened) and green; no schema change, no new dependency

**How to verify:** `flutter test test/features/cv_builder`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `a7ea76e` (code and tests), plus the commit that closes this ticket.
- **Decisions:**
  - **Banner and sections use the grouped card fill, not grey.** That fill is white in light and `#1A201D` in dark. On the grouped page, grey is the page itself (`#F2F2F7`), so a grey card would vanish. The ticket's "grey card" is read as a neutral, borderless card.
  - **The step dots stay,** because jump-back navigation needs them. While the keyboard is open the dots fold away and the title shrinks to one line with an ellipsis. The announced label keeps the full text.
  - **The footer is the last child of the Column, not an overlay.** It is a non-elevated `GlassSurface` with zero radius. An overlay would need measured list padding, or `validateAndReveal` would park fields under the bar.
- **Files:**
  - `lib/features/cv_builder/presentation/cv_generator_screen.dart`:
    - Wraps the screen in `GroupedSurface`.
    - Moves the draft banner into the step's scroll.
    - Reads `keyboardOpen` above the Scaffold and passes it to the header.
  - `lib/features/cv_builder/presentation/cv_generator/wizard_header.dart`:
    - No `background` band (fixes `:150`).
    - The title with "Step X of N" (Latin digits) sits in a live-region `Semantics` (`statusKey`).
    - A thin `primaryInk` line on a `separator` track.
    - The active dot is teal (`primaryLight` + `primaryInk`) instead of amber. Future labels use `textSecondary`; connectors use `separator`.
    - The dot row (`dotsKey`) folds while the keyboard is open.
  - `lib/features/cv_builder/presentation/cv_generator/wizard_footer.dart`: a glass bar (`glassKey`) with no border or shadow. The Back capsule label stays on one line.
  - `lib/features/cv_builder/presentation/cv_generator/draft_restore_banner.dart`: a borderless card (`cardKey`) with a grey "Start fresh" capsule and a teal "Restore" capsule.
  - `lib/features/cv_builder/presentation/cv_generator/wizard_widgets.dart`:
    - New `NestedFillScope`: inside a card, fields, outlined buttons and chips switch to the other page fill.
    - New `WizardSection`: a borderless grouped card.
    - `SectionHeading` drops the bordered icon box.
  - `lib/features/cv_builder/presentation/cv_generator/entry_list_field.dart`:
    - Entry cards are borderless on the page fill, wrapped in `NestedFillScope`.
    - The Add button uses the theme's capsule.
    - `MonthYearButton` is drawn as a filled field, with an error ring only in error.
    - Error text uses `AppFormStyles.errorTextStyle`.
  - `lib/features/cv_builder/presentation/cv_generator/steps/personal_step.dart`:
    - Three sections: contact, target role, CV language.
    - The language picker is a filled-capsule segmented control.
    - Hint ink is `textSecondary`.
  - `lib/features/cv_builder/presentation/cv_generator/steps/skills_step.dart`: the summary sits in a section.
  - `lib/features/cv_builder/presentation/cv_generator/steps/experience_step.dart`: the XYZ builder button is a teal-tint capsule with no outline.
  - `lib/features/cv_builder/presentation/cv_generator/exit_dialogs.dart`: Discard ink is `onErrorContainer`.
  - `lib/shared/widgets/ai_cv_field.dart`:
    - The character track is `separator` (`:106`).
    - The result card is borderless on `PageSurface.fillOf` (`:246`); claim chips use the page fill.
    - Count text is `textSecondary`, because success green is 4.48:1 on the grouped page. The bar still shows the met state.
  - `lib/shared/widgets/job_title_picker_field.dart`:
    - The hard-coded `surface` fill is gone; it uses the theme's filled field.
    - Its padding and empty-line height match an unlabelled `AppTextFormField`.
    - The sheet divider is `separator`.
  - `lib/shared/widgets/add_button.dart`: flat, no shadow. `SiratiAddButton` has no production caller (only `phase1_core_motion_test`), so this is infrastructure only (AGENTS.md section 6).
  - `lib/features/cv_builder/presentation/widgets/skill_chips_selector.dart`. This is a cross-ticket edit; ticket 14 owns the file on main's approval, and ticket 15 has been told. The public API is unchanged, and most of the diff is `dart format` of the whole file.
    - **Fixes found by the tests:** the count row and the "Suggested" heading Text are now `Flexible`; on the base they overflowed by 19–77 px. The selected chip label, remove icon and suggested heading use `primaryInk` instead of `primaryDark`, which was 3.73:1 in dark.
    - **Restyle:**
      - The card is borderless (`cardKey`) and wrapped in `NestedFillScope`.
      - The add-skill field is the theme's filled field, with no hard-coded outline or fixed height.
      - Selected chips are filled teal capsules; suggested chips are filled capsules on the page fill.
      - The Add button is a capsule; Clear all uses `onErrorContainer`.
  - `test/features/cv_builder/cv_generator_restyle_test.dart` (new), on the full pumped screen, AR/EN × light/dark:
    - **Colours and shapes:** the grouped page with no header band; the banner card against its capsule; the glass footer; capsule shapes; the Back fill.
    - **Cards:** every step's fields sit in borderless cards, and each field's fill differs from its card.
    - **Contrast:** strict AA for text, icons and progress indicators at every scroll stop through all four steps. The progress line holds 3:1 on its track.
    - **Screen readers:** a live region with the title and Latin digits on every step.
    - **Behaviour:** autosave, Start fresh and restore still work.
    - **Small phone (320×568, text scale 1.3), keyboard open:** no overflow at any scroll stop on any step. The footer stays reachable and advances, or validates an empty form.
    - **Small phone, keyboard closed:** the dots come back and nothing overflows.
  - `test/features/cv_builder/cv_generator_parts_restyle_test.dart` (new):
    - The exit dialogs are AA and return each choice.
    - On plain and grouped pages, the picker's fill is `PageSurface.fillOf`, its border is a `FilledFieldBorder` with no side, and its height equals an `AppTextFormField`'s.
    - The AI result card, with all sections, is borderless and AA.
  - `test/features/cv_builder/skill_chips_layout_contrast_test.dart` (new):
    - Matrix: 320/390 px wide × text scale 1.0/1.3 × AR/EN × light/dark × plain/grouped, with 120 selected skills plus suggestions.
    - Asserts no overflow and AA on every selected and suggested chip label.
    - Asserts a borderless card and capsule chips with no side.
    - Asserts an add-skill field with no resting outline and a fill distinct from the card.
- **Tests:** full `flutter test`: 3373 passed, 1 skipped (pre-existing), 0 failed. `flutter analyze`: no issues. No existing test was edited or loosened. No schema change, ARB change or new dependency.
- **Not covered by a test:** none of the criteria.
- **Durable learnings for `PROJECT_MEMORY.md`** (outside this ticket's files; main to add):
  - A `Scaffold` body's `MediaQuery` has the keyboard inset removed. Read `viewInsets` above the Scaffold and pass it down.
  - Inside a card on a grouped page, wrap the contents in `NestedFillScope` (`cv_generator/wizard_widgets.dart`). Otherwise themed fields and grey capsules take the card's own colour and vanish. It may be worth moving to `lib/shared/theme`.
  - The `app_metrics` gate also flags `[SiratiColors.x]` in doc comments outside the theme layer.
- **GitHub:** not pushed and the issue not synced; main does that.
