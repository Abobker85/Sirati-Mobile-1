# 10: Theme round 2 — page backgrounds, filled fields, capsule buttons, cards

**What to build:** pushed screens stop using the warm beige scaffold. Form and list screens sit on `groupedBackground`, content screens on `pageBackground`. Text fields become grey filled fields with no outline (focus shows a teal ring that passes 3:1). Secondary/outlined buttons become grey filled capsules. Shared bordered cards (`AppCard`) become borderless grey or grouped-white cards. Material chips (filter/choice) become filled capsules via the chip theme. Every screen still in the old style changes through the theme alone, before its own ticket touches it.

Design source: `docs/design/ios26/apple-support-design-prompt.md` (+ images). Owner decisions (2026-11-20): keep Sirati teal as the accent (no iOS blue); repo invariants beat the prompt (Latin digits only, dark mode kept with derived tokens, glass opacity stays AA-safe, shipped weights 400/600/700, Sirati keeps its own tabs, no Apple branding or copy).

**Owns:** `lib/shared/theme/*`, `lib/shared/widgets/form_fields.dart`, `lib/shared/widgets/components/app_input.dart`, `app_button.dart`, `app_card.dart`, `lib/shared/widgets/auth_form_constraint.dart`.

**Blocked by:** none (round 1 merged)

**Status:** done (2026-11-20)

## Acceptance criteria

- [x] Scaffold background is `pageBackground`; screens that are forms or lists can ask for `groupedBackground` through one documented API
- [x] Text fields: filled with `cardFill`, no resting outline, focus ring ≥ 3:1 against the fill, error state still visible without colour alone; label, hint, helper and error text ≥ 4.5:1 on the fill
- [x] Outlined/secondary buttons are grey filled capsules; primary stays teal; 48dp targets kept
- [x] `AppCard` has no border or shadow; chips are filled capsules (selected = teal tint that keeps text ≥ 4.5:1)
- [x] AR/EN × light/dark widget tests on real pumped fields, buttons, cards and chips; strict contrast, no offsets
- [x] Full `flutter test` green; no schema change, no new dependency

**How to verify:** `flutter test test/shared`, then full `flutter test`.

## Outcome (2026-11-20)

- **Commits:** `75a2c1f` (code, tests, goldens, memory), `8b6018d` (ticket close), plus the follow-up commit that widened the handoff audit.
- **Files:**
  - `lib/shared/theme/sirati_colors.dart`: light `background` is now white (= `pageBackground`; owner approved 2026-11-20). Added `pressOverlay(fill)`, and `pressed()` now uses it.
  - `lib/shared/theme/page_surface.dart` (new): `PageSurfaceKind`, `PageSurface` (`of`, `fillOf`, `pageColor`, `fillColor`) and `GroupedSurface`, the one API for a grouped page: `GroupedSurface(child: Scaffold(...))`.
  - `lib/shared/theme/app_theme.dart`:
    - The scaffold and app bar sit on `pageBackground`.
    - `AppTheme.grouped(base)` switches the page, app bar, field, card, chip and secondary-button fills to `groupedBackground` / `groupedCard`.
    - New helpers `barColor`, `secondaryButtonStyle` and `chipLabelColor`.
    - Elevated buttons are capsules; outlined buttons are grey filled capsules with no side.
    - `cardTheme` fills with `cardFill`.
    - Chips are filled capsules: `cardFill` at rest, `primaryLight` with `primaryInk` and the checkmark when selected.
    - The legacy `AppCard` is a borderless, unshadowed page fill with a press overlay.
  - `lib/shared/widgets/form_fields.dart`:
    - `FilledFieldBorder` is not an outline border, so the label floats inside the fill.
    - The input theme has a page fill and no resting outline. The focus ring is primary ink at 2 px; the error ring is 1.5 px at rest and 2 px when focused.
    - Error label and error copy use `onErrorContainer`. Helper copy uses `textSecondary`.
    - `errorWash` / `successWash` sit over the real page fill. `labelledPadding` keeps labelled fields about 52 px tall (64.5 px without it).
  - `lib/shared/widgets/components/app_input.dart`: labelled fields use `labelledPadding`.
  - `lib/shared/widgets/components/app_button.dart`: secondary is the grey filled capsule on `PageSurface.fillOf`; primary and destructive are capsules.
  - `lib/shared/widgets/components/app_card.dart`: `AppSurfaceCard` is borderless and unshadowed, filled with the page fill, with a press overlay.
  - `test/shared/theme/theme_round2_test.dart` (new, 57 tests): AR/EN × light/dark × plain/grouped, on real pumped widgets.
    - Pages: the painted page and app bar colour.
    - Fields: pixel-sampled fill, no edge at rest, a focus ring ≥ 3:1, an error ring ≥ 3:1 on the wash, and the label inside the fill.
    - Errors show as text plus icon. All copy is ≥ 4.5:1.
    - Buttons: rendered Material colour, `StadiumBorder` without a side, ≥ 48 dp.
    - Cards: no border or shadow; fill and elevation 0.
    - Chips: rendered `Ink` fill and capsule, label ≥ 4.5:1, selected label is primary ink with the checkmark.
    - Grouped theme: changes fills only.
  - `test/shared/design_system_contrast_test.dart`, `test/shared/shared_components_contrast_test.dart`, `test/shared/contrast_probe_test.dart`, `test/ui_components_test.dart`: assertions that pinned the old spec now assert the new invariants, with no ratio loosened:
    - Resting field outline at 3:1 became "no resting side; the focus ring is ≥ 3:1".
    - Outlined-button side became "no side; the label carries state at AA".
    - Card `Container` shadow became "no painted box with a border or shadow".
    - The input fill expectation moved from `surface` to `cardFill`.
  - `test/golden/goldens/*.png`: 20 baselines regenerated on Windows (form fields, submit button, CV builder, ATS, dashboard, score booster, live preview).
  - `docs/agents/PROJECT_MEMORY.md`: the restyle line now describes the new scaffold, `GroupedSurface`, the fields, buttons, cards and chips.
- **Tests:** `flutter test` on the full suite: 3237 passed, 1 skipped (pre-existing), 0 failed. `flutter analyze`: no issues. No schema change, no new dependency.
- **Not covered by a test:** none of the criteria. Notes for the screen tickets (12-18):
  - A resting field is identified by its fill and label only. Its edge is below 3:1 against the page by design.
  - Unbordered `surface` boxes that now lose their edge on the white page. Found by a wide grep with every hit read. These need `cardFill` (bordered hits, dialogs and sheets are left out):
    - `lib/features/ats_scanner/presentation/cv_analysis/analysis_form_sections.dart:124`
    - `lib/features/auth/presentation/session_expired_screen.dart:329`
    - `lib/features/auth/presentation/session_expired_screen.dart:362`
    - `lib/features/dashboard/presentation/home/dashboard_home_header.dart:115`
    - `lib/features/jobs/presentation/widgets/job_news_card.dart:65`
    - `lib/shared/widgets/score_booster_card.dart:173`
    - `lib/shared/widgets/screen_header.dart:159`
    - `lib/shared/widgets/loading/ai_field_loading_overlay.dart:68`
    - `lib/shared/widgets/loading/ai_field_loading_overlay.dart:172`
  - Warm-grey fills (`surfaceLow` / `surfaceContainer` / `surfaceHigh`, #F2F1EC to #E7E5DE) now read beige on white. Unbordered ones:
    - `lib/features/cv_builder/presentation/cv_builder_screen.dart:376`
    - `lib/features/cv_builder/presentation/cv_builder_screen.dart:399`
    - `lib/features/cv_builder/presentation/cv_builder_screen.dart:446`
    - `lib/features/cv_builder/presentation/section_editor_framework.dart:165`
    - `lib/features/cv_builder/presentation/cv_generator/wizard_header.dart:150`
    - `lib/features/cv_builder/presentation/my_cvs/cv_document_card.dart:316`
    - `lib/shared/widgets/ai_cv_field.dart:106`
    - `lib/shared/widgets/ai_cv_field.dart:246`
    - `lib/shared/widgets/score_ring.dart:61`

    About 18 more are bordered (cv_builder editors, achievement sheet, skill chips, session_expired, motion, offline_view).
  - `bottomNavigationBarTheme` (white, flat) is not used by the app: the dashboard draws its own `DashboardNavigationBar`.
  - Fields that override the theme with their own outline or `surface` fill and stay old-style:
    - `lib/features/ats_scanner/presentation/cv_analysis_screen.dart:384`
    - `lib/features/cv_builder/presentation/widgets/skill_chips_selector.dart:345`
    - `lib/features/jobs/presentation/widgets/job_news_filters_bar.dart:266`
    - `lib/shared/widgets/job_title_picker_field.dart:86`
  - A plain `TextField` with a label (not `AppTextFormField` or `AppInput`) is 66.5 px tall unless the screen passes `AppFormStyles.labelledPadding`.
  - Sheet content (ticket 19) sits on `groupedBackground`. Wrap it in `GroupedSurface` so cards, fields and chips inside it use `groupedCard`.
