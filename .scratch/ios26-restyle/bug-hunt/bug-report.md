# Bug report: iOS 26 restyle (feat/ios26-restyle)

Scope: the 108 lib/ files changed by the restyle session (affc8ae..8794fb8), 37,323 lines in 20 slices. Each bug was proven by an independent prover from the claim alone, then re-checked by a separate verifier on a clean 8794fb8 copy with only its own fix applied.

**Confirmed: 50** (High 10, Medium 15, Low 25). Tests are in `tests/`, fixes in `fixes/` next to this file. No fix has been applied to the app.

## C05 [High] cv_generator_screen.dart, `_handleExitAttempt`, discard case (lines 319-325), together with `dispose` (lines 143-146)

- **Input:** create mode. Type anything so the form is dirty, press back, then choose Discard.
- **Should:** After Discard no draft is kept and no restore banner appears next time.
- **Actually:** dispose saves the discarded form after the clear (ops [clear, save]), so the discarded draft comes back as a restore banner.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C05_test.dart`
- **Fix:** Set _isDirty = false in the WizardExitAction.discard branch before awaiting _draftStore.clear(), as the save-draft branch already does.  The 3 hunt cases pass; cv_generator_restyle_test also passed with the fix in place (exit code 0). (`fixes/C05.diff`)
- **Verifier note:** Clean: 3/3 fail. A SavedCvDraft remains after Discard. The source confirms the discard branch never resets _isDirty, and dispose then saves when !_isEditMode && _isDirty. After the one-line single-file diff to cv_generator_screen.dart, 3/3 pass. The user's explicit Discard is silently undone and the draft comes back as a restore banner, with no error. High.

## C06 [High] lib/features/cv_builder/presentation/section_editor_framework.dart, ReorderableEntryList.build itemBuilder, line 371 (`key: ValueKey(item.hashCode ^ index)`).

- **Input:** typing into any field of an experience, education, certification or project row in the CV builder (production path: cv_builder_screen.dart lines 417-418). Each keystroke calls onChanged, which builds a new object with `entry.copyWith(...)`. ExperienceEntry, Certification and Project in shared/models/cv_document.dart do not override hashCode (only LocalizedText does), so the identity hashCode chang
- **Should:** Typing into an experience, education, certification or project row keeps the same field, its focus and the exact text typed, including spaces between words.
- **Actually:** Each keystroke disposes and rebuilds the tile: focus (and the keyboard) is lost after one character, and trailing spaces are trimmed away on rebuild.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C06_test.dart`
- **Fix:** Build the row body once and key the KeyedSubtree by the tile's own stable key (ValueKey<Object>(body.key ?? index)); every caller already keys its tile by ValueKey(item.id ?? index).  The C06 test and cv_builder_restyle_test (22) pass. (`fixes/C06.diff`)
- **Verifier note:** Clean: 1/1 fails. Focus or text is lost while typing 'Senior Engineer' keystroke by keystroke into Job Title in the real CvBuilderScreen. The source confirms KeyedSubtree key: ValueKey(item.hashCode ^ index), which changes with every copyWith. After the single-file diff to section_editor_framework.dart, 1/1 passes. Ordinary typing in experience, certification and project rows breaks (focus drops, spaces are trimmed). High.

## C08 [High] lib/features/cv_builder/presentation/skills_languages_editor.dart, `_CertificationEntryTileState._notify`, line 635, and the checkbox `onChanged` at lines 708-7

- **Input:** a certificate that already has an expiry year, for example "2027". The user ticks the no-expiry box.
- **Should:** Ticking no-expiry sets the certificate's expiryDate to null in the document and the export, and the box stays ticked after the tile is rebuilt.
- **Actually:** expiryDate keeps the old year (for example '2027'). After the tile is rebuilt the box shows unticked again with the year in the field.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C08_test.dart`
- **Fix:** _CertificationEntryTileState._notify builds a new Certification directly (keeping id and narrative) instead of calling copyWith, so a null date clears the field. The C08 and C09 tests, l10n_adoption_test and test/features/cv_builder (942 tests) all pass. The test needs cert_harness.dart, saved in the same folder. (`fixes/C08.diff`)
- **Verifier note:** Re-checked on a clean 8794fb8 worktree. All 3 cases fail with Expected null, Actual '2027'/'2030'/'1999', because Certification.copyWith(expiryDate: null) keeps the old year. With only C08.diff applied (it builds Certification directly in _notify; skills_languages_editor.dart only), 3 of 3 pass. Ticking no-expiry has no lasting effect and the old year reaches the export.

## C10 [High] skills_languages_editor.dart, `_ProjectEntryTileState._notify`, line 785 (`url: urlText.isEmpty ? null : urlText`). The root cause is in cv_document.dart, `Proj

- **Input:** the user deletes the URL one key at a time, for example from "https://github.com/x" down to empty.
- **Should:** Clearing the URL field (one key at a time or select-all and delete) should store url null, so the URL is not autosaved or exported.
- **Actually:** The stored URL is never cleared. The last non-empty value ('h', or the whole URL if cleared in one step) stays in the document and the exported CV while the field shows empty.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C10_test.dart`
- **Fix:** In _ProjectEntryTileState._notify, build Project(id: widget.project.id, ...) directly instead of copyWith, so an empty field stores url null.  The test needs _harness.dart from the same folder. (`fixes/C10.diff`)
- **Verifier note:** Clean: 6 of 6 fail. Clearing key by key leaves url 'h'. Clearing in one step leaves the full URL, e.g. 'https://github.com/x'. Cause: Project.copyWith(url: null). With only C10.diff applied, 6 of 6 pass. A URL the user removed stays in the saved and exported CV.

## C11 [High] `experience_education_editor.dart` `itemBuilder`, lines 234-241 and 276-283. The cause is `section_editor_framework.dart:371`, `KeyedSubtree(key: ValueKey(item.

- **Input:** type one character in any field. `setExperience` triggers the `ListenableBuilder` rebuild, `copyWith` makes a new entry, and since entries have no `hashCode` override the identity hash gives a new outer key.
- **Should:** A tile keeps its State and focus while the user types, so every character typed is kept.
- **Actually:** After each character the row is rebuilt and focus moves away from the field (the keyboard closes on a device), so the characters typed next are lost.
- **Status:** demonstrated on clean code; fix not re-verified
- **Test:** `tests/C11_test.dart`
- **Fix:** Add an optional itemId callback to ReorderableEntryList and key rows by ValueKey(itemId?.call(item) ?? index). Pass itemId: (e) => e.id for experience and education. Diff (framework part): . The two itemId lines at the call sites are in C12.diff, because both fixes touch experience_education_editor.dart. (`fixes/C11.diff`)
- **Verifier note:** Clean: both tests (experience, education) fail with Expected true, Actual false. My filtered output did not show which expect failed (focus or State identity), but either matches the claim. The cause is confirmed in source: ValueKey(item.hashCode ^ index), with no hashCode override and copyWith on every keystroke. The fix run (C11.diff plus only the two itemId call-site hunks split from C12.diff) did not finish: the machine was very slow and I had to stop the run, so I did not verify the fix. On

## C12 [High] `_ExperienceEntryTileState._notifyChange` line 372, and `_EducationEntryTileState._notifyChange` lines 683-684. They build `LocalizedText(ar: ...)` only.

- **Input:** an entry with English values (for example imported with `defaultLanguage` en), then edit the title or the institution.
- **Should:** Editing any field of an experience or education entry keeps the English values of fields the tile cannot edit (location, degree, field of study).
- **Actually:** The first edit sets location.en, degree.en and fieldOfStudy.en to empty and the result is autosaved. The user cannot restore them from the tile.
- **Status:** confirmed by reading (clean re-run not done)
- **Test:** `tests/C12_test.dart`
- **Fix:** Use widget.entry.location.copyWith(ar: ...), widget.entry.degree.copyWith(ar: ...) and widget.entry.fieldOfStudy.copyWith(ar: ...) so the English values are kept.  That file also holds C11's itemId call-site lines; the combined patch is all-fixes.patch in the same folder. (`fixes/C12.diff`)
- **Verifier note:** Not re-run: the run was stopped before C12 because the machine was slow. I prepared a C12-only diff (C12.diff without the C11 itemId hunks) but did not apply it. Judged from the code: _notifyChange rebuilds location, degree and fieldOfStudy as LocalizedText(ar: ...) only, so any edit wipes the .en values and autosaves. The tile has no EN input to restore them. This is a silent data loss on entries that have English values, so it is a real bug even though my re-check did not run.

## C18 [High] skills_languages_editor.dart, `_CertificationEntryTile` (601-725) and `_ProjectEntryTile` (743-844). The root cause is in `ReorderableEntryList.itemBuilder`, se

- **Input:** type one character into any field of a certification or project row (name, issuer, year, title, role, URL or description).
- **Should:** Typing into a certification or project field keeps that field focused and keeps the same tile state, so the user can type a whole word.
- **Actually:** Each keystroke changes the row key, so the whole tile is rebuilt with new controllers. The field loses focus and the keyboard closes after every character.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C18_test.dart`
- **Fix:** Build the entry first and key the KeyedSubtree by the entry's own stable key (ValueKey(item.id ?? index)) when it has one, falling back to the old key otherwise. Existing motion and l10n editor tests still pass. (`fixes/C18.diff`)
- **Verifier note:** Clean: 6/6 fail with 'focus lost after typing' (certification and project rows, Latin and Arabic). With the single-file diff to section_editor_framework.dart, 6/6 pass. The row key is ValueKey(item.hashCode ^ index), and copyWith makes a new identity on every keystroke, so the tile remounts after each character. Even a value-based hashCode would still change with the content. Users cannot type normally in certification or project fields.

## C19 [High] lib/features/cv_builder/presentation/cv_generator_screen.dart, `initState` line 124 (`_fields.addListener(_onAnyFieldChanged)`), with `_onAnyFieldChanged` and `

- **Input:** the user only taps into a field, with no typing. A TextEditingController also notifies on selection changes: after `.text =` or on an empty field the caret goes from offset -1 to 0. Case (a): create mode while the draft restore banner is showing. Case (b): any mode with nothing typed, then Back.
- **Should:** Focusing a field without typing leaves the restore banner showing and the stored draft untouched. Only a real text edit counts as declining the offer.
- **Actually:** One tap on a field hides the restore banner, marks the form dirty and starts the autosave. Two seconds later the empty form is saved, which clears the stored draft for good.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C19_test.dart`
- **Fix:** In cv_generator_screen.dart, _onAnyFieldChanged keeps a snapshot of the field texts (_lastTexts, set before addListener). It marks the form dirty only when a text really changed, so caret or selection moves are ignored. (`fixes/C19.diff`)
- **Verifier note:** Clean: 6/6 fail with 'stored draft deleted by a focus alone' (clears=1, expected 0), in ar and en. With the single-file diff (text snapshot compare), 6/6 pass. A selection-only controller notification marks the form dirty, hides the restore banner, and the autosave of the empty form clears the stored draft. That is silent data loss from one tap.

## C28 [High] personal_details_editor.dart, _PersonalDetailsEditorState.initState (lines 153-170) and _onPersonalChanged/_onSummaryChanged (188-229). The trigger is in cv_bui

- **Input:** open a CV that has a newer local draft. The builder mounts first (setState at line 180), so PersonalDetailsEditor (the first tab) fills its 11 TextEditingControllers from the server document. Then tap Restore, which calls controller.updateDocument(draft).
- **Should:** After Restore, the personal and summary fields show the draft's values, and a later keystroke keeps the restored name, headline and other fields.
- **Actually:** The fields keep showing the server values. The first keystroke in any personal field overwrites the restored draft's name and headline with the server values (expected 'Draft Name', got 'Server Name').
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C28_test.dart`
- **Fix:** In cv_builder_screen.dart, add an int _documentGeneration and bump it with setState when Restore calls updateDocument(draft). Pass it as key: ValueKey(_documentGeneration) on the TabBarView so the editors rebuild from the restored document. (`fixes/C28.diff`)
- **Verifier note:** Confirmed. After Restore, the PersonalDetailsEditor fields keep the server values. One keystroke in LinkedIn writes the full name back to 'Server Name' (expected 'Draft Name'), and autosave then persists it. The restored draft is lost silently on an ordinary flow. prove-10/C28.diff (a ValueKey(_documentGeneration) on the TabBarView, bumped on restore) applied cleanly, touches only cv_builder_screen.dart, and the test passes with it.

## C34 [High] skills_languages_editor.dart, `_CertificationEntryTileState._notify` (630-631) and `initState` (611-612); `_ProjectEntryTileState._notify` (783-786) and `initSt

- **Input:** a certification or project whose text is stored in `en`, such as any English-language CV. `LocalizedText.fromJson` with `defaultLanguage` `'en'` fills `en` only.
- **Should:** The fields show the stored text in whichever language holds it, and editing one field changes only that field's edited variant. Other fields and the other language stay untouched.
- **Actually:** English-only entries show blank fields. The first edit writes ar-only LocalizedText for every field, which erases all English name, issuer, title, role and description text (and the en half of bilingual entries). The result is autosaved.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C34_test.dart`
- **Fix:** In skills_languages_editor.dart, add `_editableText` (show en when only en is stored, otherwise ar) and `_withEditedText` (copyWith into that same variant and keep the other one). Use both in the init and _notify of the certification and project tiles. (`fixes/C34.diff`)
- **Verifier note:** On clean, 3 of 5 cases fail. In an English CV, the certification and project tiles show empty fields (Found 0 widgets with text 'Name-en' / 'Title-en'). In a bilingual certification, editing the Arabic name blanks the English text (Expected 'Certificate', Actual ''). The controllers read .ar, and _notify writes LocalizedText(ar: text), which wipes en on the first keystroke. The result is autosaved. With C34.diff applied, all 5 pass. This loses data on ordinary input, so High.

## C07 [Medium] lib/features/auth/presentation/social_sign_in_section.dart, SocialSignInSection.build, the google()/apple() closures (lines 70-82). This section is used on Regi

- **Input:** on RegisterScreen, tap Google or Apple while the account picker or Apple sheet stays open for more than a frame (the normal case). loginControllerProvider is `NotifierProvider.autoDispose`, and SocialSignInSection only calls `ref.read` on it. RegisterScreen never watches it (only login_screen.dart:98 does). So the provider is disposed while `idToken()` / `apple.signIn()` is still pending.
- **Should:** Tapping Google or Apple on Register sends the provider token to the server after the picker closes, and a second tap while one sign-in is running is ignored.
- **Actually:** The controller is disposed while the picker is open. The server is never called, the user gets the 'unexpected error' snackbar, and the busy flag is lost, so another tap opens a second picker.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C07_test.dart`
- **Fix:** SocialSignInSection.build now calls ref.watch(loginControllerProvider), so the controller stays alive while the section is on screen. The C07 test and all 197 tests in test/features/auth pass. (`fixes/C07.diff`)
- **Verifier note:** Clean: 1/1 fails. The auth service calls are [] where ['google'] was expected, because the autoDispose loginControllerProvider is disposed while the picker is open on RegisterScreen. The source confirms SocialSignInSection only uses ref.read. After the single-file diff to social_sign_in_section.dart (ref.watch), 1/1 passes. The user sees an error snackbar rather than a silently wrong result, and social sign-in is gated by build flags. Medium.

## C09 [Medium] skills_languages_editor.dart, `_CertificationEntryTileState._notify`, lines 632-634 (issueDate). The root cause is in cv_document.dart, `Certification.copyWith`

- **Input:** the user deletes the issue year "2024" one key at a time.
- **Should:** When the issue-year field is emptied, the certificate's issueDate becomes null and nothing shows in the export.
- **Actually:** The document keeps the first character of the year (for example '2' from '2024'). The field shows empty, but the stored and exported CV still has that character.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C09_test.dart`
- **Fix:** Same fix as C08: _notify builds the Certification directly instead of calling copyWith, so an empty issue year saves as null. The C09 test passes. The test needs cert_harness.dart, saved in the same folder. (`fixes/C09.diff`)
- **Verifier note:** Clean: 3 of 3 fail. Deleting the year key by key leaves issueDate '2', '1' or '7' while the field shows empty. C09.diff is byte-identical to C08.diff. Applied alone, 3 of 3 pass. Medium because it needs the user to clear the field completely.

## C13 [Medium] `_notifyChange` lines 353-362 and 668-677. The error renders at lines 502-516 and 775-789. `initState` never validates.

- **Input:** start 2022, end 2023, then type 2019 into the end field.
- **Should:** When the end or graduation date precedes the start date, typed or loaded, the inline 'End date cannot precede start date' error is shown.
- **Actually:** No error is ever shown. Typing 2019 after start 2022 saves endDate=2019 silently, and entries that load invalid show nothing.
- **Status:** confirmed by reading (clean re-run not done)
- **Test:** `tests/C13_test.dart`
- **Fix:** In both entry tiles of experience_education_editor.dart, _dateError is now a getter computed from the current controller values and _isCurrent, so it survives tile rebuilds and also shows for entries loaded invalid. _notifyChange now calls setState(() {}). See (`fixes/C13.diff`)
- **Verifier note:** Not re-run (time ran out). From the code: _dateError is only set in _notifyChange and never in initState, so an entry loaded with an invalid date range shows no error. While typing, the error is lost because the tile State is rebuilt (the C11 bug). This is a missing validation message; the invalid range is saved silently. I rate it lower than the prover's High because the data saved is what the user typed. The C13.diff (a derived _dateError getter) looks correct but I did not test it.

## C16 [Medium] lib/shared/widgets/motion.dart, ErrorShakeState.build (the AnimatedBuilder builder), lines 319-326

- **Input:** any field wrapped in ErrorShake gets a new errorKey while the user is typing. Wrapped fields: app_input.dart:56, form_fields.dart:813, entry_list_field.dart:237, job_match_screen.dart:195 and :324. This happens with live validation after the first blur, or with autovalidate always after a submit, whenever the message changes.
- **Should:** When a new error appears, the field shakes and keeps its typed text, its focus and its EditableText state.
- **Actually:** The field's state is recreated twice per shake, at the start and at the end. Without a controller the typed text is wiped. Focus is lost in every case, so the keyboard closes while the user is typing.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C16_test.dart`
- **Fix:** Always return Transform.translate, with dx=0 when t is 0 or 1, so the child's element stays mounted. (`fixes/C16.diff`)
- **Verifier note:** Clean: 4/4 fail. In 3 cases EditableTextState is recreated and the text is lost when there is no controller. The external-controller case loses focus. With the single-file diff to motion.dart, 4/4 pass. ErrorShake switches between child and Transform.translate, which remounts the field at the start and end of each shake. The keyboard closes mid-typing whenever the error message changes. Most callers pass a controller, so in practice this is a focus loss and not usually data loss. I rated it Medi

## C17 [Medium] lib/shared/widgets/motion.dart, _MotionSegmentButton.build, lines 660-671

- **Input:** a VoiceOver or TalkBack user double-taps a segment.
- **Should:** Each segment's semantics node exposes a tap action, and a VoiceOver or TalkBack double-tap selects that segment.
- **Actually:** The segment nodes have a label and the button flag but no actions. Double-tapping does nothing and the selection cannot be changed with a screen reader.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C17_test.dart`
- **Fix:** Pass onTap: enabled ? onTap : null on the outer Semantics so the merged node exposes the tap action. (`fixes/C17.diff`)
- **Verifier note:** Clean: 2/2 fail with 'segment exposes no tap action' (Latin and Arabic). With the one-line diff (Semantics onTap), 2/2 pass. excludeSemantics drops the InkWell's tap, so screen-reader users cannot change the segmented control at all.

## C23 [Medium] lib/features/dashboard/presentation/premium_gate_screen.dart, _PremiumGateScreenState._refresh, lines 106-124 (catch at 114-117, and `_activated = active` at 12

- **Input:** informational mode (store unavailable). The offer says the account is subscribed (`access.is_subscribed: true`), so the active card and Continue button show. The user taps Refresh while offline, or `/auth/me` throws.
- **Should:** A refresh that cannot reach the server leaves known access unchanged: the active card and Continue stay.
- **Actually:** After a failed refresh the subscribed user is shown as locked: the active card and Continue disappear and the plans are shown, until a later refresh succeeds.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C23_test.dart`
- **Fix:** Make `active` a bool? and assign _activated only when the server actually answered (`if (active != null) _activated = active;`). A failed refresh then keeps the last known state and still sets the refreshFailed notice.  The hunt test passes. premium_gate_test passes, including 'refresh failure stays locked and can be retried' for an unsubscribed account (173 tests passed across the 4 files). (`fixes/C23.diff`)
- **Verifier note:** Confirmed. When /auth/me throws, `active` stays false and `_activated = false` locks a subscribed user: Continue disappears (the test finds 0 widgets with key premium-continue). C23.diff makes `active` nullable, touches only premium_gate_screen.dart, and the test passes with it. I rated it Medium, not High. It needs a failed refresh in informational mode. The refreshFailed notice is shown, so the user sees an error. A later successful refresh restores access.

## C25 [Medium] skill_chips_selector.dart, _computeSuggestions, lines 157-160

- **Input:** a taxonomy entry with an empty nameEn or nameAr (JobTitle.fromJson defaults a missing name_en or name_ar to ''), and any non-empty target title.
- **Should:** A taxonomy entry with an empty name matches only on its non-empty name, so its keywords appear only for related target titles.
- **Actually:** An entry with an empty nameEn or nameAr matches every non-empty target title, so its keywords are suggested for unrelated jobs.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C25_test.dart`
- **Fix:** In _computeSuggestions, trim and lowercase each name and match on it only when it is non-empty (both contains directions).  The hunt test and the existing skill_chips_selector_test pass after the fix (19/19). (`fixes/C25.diff`)
- **Verifier note:** Confirmed. A taxonomy entry with an empty nameEn or nameAr matches every title because title.contains('') is true, so 'LedgerOnlyKw' is suggested for unrelated titles. C25.diff guards against empty names, touches only skill_chips_selector.dart, and the test passes with it. It is a wrong result only on unusual data (a taxonomy row missing one name).

## C30 [Medium] personal_details_editor.dart, ContactValidators.validateGulfPhone (22-99).

- **Input:** a phone number typed with Arabic-Indic digits, e.g. "٠٥٠١٢٣٤٥٦٧" or "+٩٦٦٥٠١٢٣٤٥٦٧".
- **Should:** A valid Gulf or international number typed with Arabic-Indic digits validates and is stored in the CV with Latin digits.
- **Actually:** It shows 'Enter a valid Gulf or international phone number', and the Arabic-digit string is stored in personal.phone, which goes into the exported CV.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C30_test.dart`
- **Fix:** Import core/utils/latin_digits.dart. In validateGulfPhone use cleaned = latinDigits(value).replaceAll(...), and in _onPersonalChanged use phoneText = latinDigits(_phoneCtrl.text.trim()). (`fixes/C30.diff`)
- **Verifier note:** On clean, validateGulfPhone rejects an Arabic-Indic 0501234567 ('Enter a valid Gulf or international phone number'), and the editor stores the Arabic-digit string in personal.phone, which goes into the exported CV. The C30.diff fix adds latinDigits() in the validator and in _onPersonalChanged. Both tests then pass. The diff touches only personal_details_editor.dart. It is a wrong result only for Arabic-digit input, so Medium, although that input is common on Arabic keyboards.

## C31 [Medium] lib/features/dashboard/presentation/home/home_latest_cv_section.dart, `latestDashboardCvProvider`, lines 20-31.

- **Input:** - The backend list (D:/Sirati app/Http/Controllers/MobileContentController.php, `myCvs`, around line 139) sends no `updated_at` or `created_at`, only `updated_label`. The comment at line 181 of the same file says so too. - So `CvListItem.updatedAt` (cv_list.dart:33) is null for every row. Every key falls back to DateTime(1970) and the sort does nothing. - `items.first` is just the server order, `l
- **Should:** Home's 'My latest CV' shows the most recently updated CV, as the provider documents.
- **Actually:** Home shows the most recently created CV. Editing an older CV elsewhere never brings it to Home, because every updatedAt is null and the sort does nothing.
- **Status:** confirmed by reading (clean re-run not done)
- **Test:** `none saved`
- **Fix:** Backend change, written as a diff only (backend not edited): myCvs orders by latest('updated_at') and sends 'updated_at' => $cv->updated_at?->toIso8601String(), so the client sort works.   (not run: PHP tests not executed). (`fixes/C31.diff`)
- **Verifier note:** There was no test file, and no Flutter test can show this, so fails_on_clean and passes_with_own_fix are false: neither was run. I confirmed it by reading the code. MobileContentController::myCvs (line 124) orders by latest() (created_at) and sends only updated_label, with no updated_at or created_at. CvListItem.updatedAt (cv_list.dart:33) is therefore always null, and the sort in latestDashboardCvProvider is a no-op (Dart's sort is stable for 20 items). Home shows the newest-created CV. PUT /ge

## C33 [Medium] achievement_builder_sheet.dart, `_formattedSentence`, Arabic branch, lines 158-163, together with the method text of the "Project" preset at lines 331-333.

- **Input:** the Arabic sheet, tap the third preset (Project), then Insert. More generally, any method that starts with another preposition, such as بـ forms (بتطبيق، بالاعتماد، بواسطة).
- **Should:** A method that already starts with a means phrase is inserted as '، بتطبيق منهجية Agile ...' with no second preposition.
- **Actually:** The bullet written into the experience field (and the exported CV) reads '، عبر بتطبيق منهجية Agile ...' ('via by applying').
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C33_test.dart`
- **Fix:** Widen the Arabic list of phrases that already introduce the method (add بتطبيق, بواسطة, بالاعتماد, بالاستعانة, بفضل, بالتعاون), so no عبر is put before them. A bare word that only starts with ب, like بناء, still gets عبر. The new tests and the existing achievement_builder_sheet_test pass. (`fixes/C33.diff`)
- **Verifier note:** On clean, the built-in Arabic Project preset inserts a bullet with a doubled preposition ('عبر بتطبيق'). Typed methods led by بتطبيق or بواسطة also get عبر prefixed, for example the actual output '• خفضت زمن التسليم، عبر بتطبيق منهجية Scrum.'. The fix C33.diff widens the list of means phrases, and all tests then pass. Ungrammatical Arabic goes into the CV through a shipped preset. The user can still edit it afterwards, so I rated it the lower of High and Medium.

## C35 [Medium] skills_languages_editor.dart, `_buildSkillsCard` (176-178 and 229) and `_buildLanguagesCard` (282).

- **Input:** skills or languages stored in English only, e.g. `name.en="Python"` with `name.ar=""`.
- **Should:** Chips show the stored skill or language name in whichever language holds it, with its level label, and English categories group under their own localized heading.
- **Actually:** English-only skill chips are blank or show only ' (Advanced)'. Language chips show ' - <level>'. Every English skill is grouped under 'General skills'.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C35_test.dart`
- **Fix:** Chip names use `_editableText` (falls back to en). Add `_storedKey(t, englishMap)`: it returns ar, or maps an en-only value back to its storage key through SkillStorageKeys.english / LanguageLevelStorageKeys.english, so the level label and category grouping resolve correctly. This diff goes on top of C34.diff: (`fixes/C35.diff`)
- **Verifier note:** On clean, the English-only skill and language chips are blank or show only the level, and an English category is grouped under 'General skills'. The ar-only control case passes. C35.diff applies cleanly on its own but does not compile without C34.diff, because it calls _editableText, which C34.diff adds. With only C35.diff applied, the test fails to load. With C34.diff and C35.diff stacked, all 3 tests pass. The claim's own fix notes say it builds on C34. It is a display bug and loses no data, s

## C36 [Medium] lib/features/ats_scanner/presentation/analysis_result/score_tab.dart, `ScoreTab.build` lines 59-67 (`atsResultKeywordSummary(found.length, missing.length)`) and

- **Input:** A free (locked) analysis where the server cuts down the list. D:/Sirati/app/Http/Resources/CvAnalysisResource.php line 29 sends only `take($keywordsMissing, limit)` and puts the rest in `access.hidden.keywords_missing` (line 69). The model reads that into `analysis.hidden.keywordsMissing`.
- **Should:** The summary and the Missing heading report the true number of missing keywords: visible plus hidden.
- **Actually:** They report only the visible count. With the production free limit of 0 that is '0 missing keywords' and 'Missing (0)', directly above a note saying N keywords are hidden.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C36_test.dart`
- **Fix:** The summary uses `keywordsMissing.length + hidden.keywordsMissing`. _KeywordsCard gets an optional `missingTotal` that is used for the 'Missing (n)' heading. Existing ats_scanner and l10n tests still pass (148). (`fixes/C36.diff`)
- **Verifier note:** Clean run fails for the claimed reason: the summary reads '2 matched · 3 missing' or '· 0 missing' when 10 are missing and 1 is missing with 0 visible. The single-file diff passes 5/5. A locked free analysis states the wrong number of missing keywords, but the HiddenItemsNote right below shows the hidden count, so Medium.

## C38 [Medium] lib/shared/widgets/app_segmented_control.dart, AppSegmentedTabBar.preferredSize (lines 319-341), which calls SegmentLayout.heightWithoutContext (lines 510-532)

- **Input:** an AppSegmentedTabBar in AppBar.bottom. The AppBar's Material sets a DefaultTextStyle of textTheme.bodyMedium. Through Material's typography geometry (englishLike2021 or tall2021) that style carries letterSpacing 0.25, which the app's TextTheme never overrides. The painted Text in _Segment and SegmentLayout.compute (line 497, defaults.style.merge) both inherit that 0.25. heightWithoutContext measu
- **Should:** preferredSize reserves at least the height the track actually paints in the app bar, for any labels.
- **Actually:** For labels near the wrap boundary the track paints 68-74px but only 60px is reserved. The bar is cut off or overlaps the body, and no error is raised.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C38_test.dart`
- **Fix:** Set letterSpacing: 0 explicitly on the segment label style in SegmentLayout.compute, heightWithoutContext and _Segment.build. Measurement and paint then no longer depend on the inherited DefaultTextStyle. (`fixes/C38.diff`)
- **Verifier note:** Clean run fails with 'a=11 painted=74.0 reserved=60.0' (Arabic) and 'painted=68.0 reserved=60.0' (Latin): preferredSize under-reserves because the inherited letterSpacing 0.25 is not measured. With the letterSpacing: 0 diff both cases pass. Wrong layout (the bar is clipped or overlaps the body) only for labels near the wrap boundary, so Medium.

## C39 [Medium] lib/features/dashboard/presentation/home/dashboard_navigation_bar.dart, `_NavButton.build`, lines 201-213 (`Semantics(button: true, excludeSemantics: true, ...)

- **Input:** an assistive technology activates a tab through semantics. Examples: TalkBack double-tap, Switch Access, Voice Access, keyboard or semantics `tap` action.
- **Should:** Each tab's semantics node offers a tap action, and performing it switches to that tab.
- **Actually:** The tab node is a button with no tap action. Semantic activation (TalkBack, Switch Access, keyboard) does nothing and the tab never changes.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C39_test.dart`
- **Fix:** Pass onTap: onTap to the Semantics widget in _NavButton.build. (`fixes/C39.diff`)
- **Verifier note:** Clean run: hasAction(tap) is false for the nav tab semantics nodes in both ar and en. Adding onTap to Semantics passes 2/2. Screen-reader and switch-access users cannot switch dashboard tabs. That is a real accessibility break, but only on the assistive-tech path, so Medium.

## C41 [Medium] premium_gate_screen.dart, the ref.listen on sessionUserIdProvider in build() (lines 309-317), together with _refresh (99-125) and _refreshStillCurrent (127-136)

- **Input:** a refresh starts while SessionCache.user is null. AuthApiService.me() calls SessionCache.setUser, so the id goes from null to a value and sessionUserIdProvider is invalidated.
- **Should:** A refresh that first learns the signed-in account shows its own result: the active card when subscribed, the 'not found' notice when not.
- **Actually:** _resetFlow() runs as the session becomes known, so the refresh shows no result at all (no active card, no notice). The user has to tap Refresh again.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C41_test.dart`
- **Fix:** In the sessionUserIdProvider listener, reset only when previous != null, so null -> id (the session becoming known) is not treated as an account change. Both test cases pass. (`fixes/C41.diff`)
- **Verifier note:** Clean run: after Refresh with a null session, neither premium-continue nor premium-notice is found, because the null->id session change triggers _resetFlow and wipes the result. The diff (reset only when previous != null) passes 2/2, and logout (id->null) still resets. It needs the unusual cold-start-offline path, and a second tap recovers, so Medium.

## C01 [Low] skill_chips_selector.dart, build, the remove InkWell on each chip, lines 304-317

- **Input:** any selected skill chip.
- **Should:** A screen reader announces each chip's remove button with a label (for example 'Remove Flutter'), and the button and 'Clear all' are at least 48x48 dp targets.
- **Actually:** The remove button is an unlabelled 21x21 dp tap node, so TalkBack/VoiceOver reads only 'button'. 'Clear all' is shorter than 48 dp.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C01_test.dart`
- **Fix:** Replace the InkWell with an IconButton whose tooltip is '<cvEntryRemove> <skill>', with 48x48 minimum constraints and zero padding, and drop the chip's vertical padding. Give 'Clear all' minimumSize 48x48 and a padded tap target. (`fixes/C01.diff`)
- **Verifier note:** Clean worktree 8794fb8: 2/2 cases fail because the semantics node Rect(115.3,64,136.3,85) has [focus, tap] and no label (en and ar). After the single-file diff to skill_chips_selector.dart, 2/2 pass. This is a real accessibility defect: screen readers announce an unlabelled 21x21 button. Low.

## C02 [Low] lib/core/routing/expand_page_route.dart, ExpandPageRoute.buildTransitions, lines 124-133 (the CurvedAnimations are created inside buildTransitions).

- **Input:** - ModalRoute calls buildTransitions on every animation tick (routes.dart line 1205, a ListenableBuilder on `_listenable`). - So every frame builds a new `CurvedAnimation(curve, reverseCurve: curve.flipped)`. Each new one takes its curve direction from the parent's status at that moment. - Flutter's own CurvedAnimation keeps the forward curve when the direction changes mid-flight. A new one built w
- **Should:** An interrupted push (or a cancelled or released swipe) reverses smoothly from where the reveal is.
- **Actually:** In the first frame after the reverse starts, the reveal clip snaps by up to about 230 px with no time passing, because a fresh CurvedAnimation switches to the flipped curve.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C02_test.dart`
- **Fix:** Create the progress and opacity CurvedAnimations once per route (cached fields set with ??=) and dispose them in the route's dispose(). (`fixes/C02.diff`)
- **Verifier note:** Clean: 4/4 fail. The reveal rect jumps 21, 187 and 232 px in one 1 ms frame after the pop interrupts the push. The source confirms the CurvedAnimations are rebuilt in every buildTransitions call. After the single-file diff to expand_page_route.dart, 4/4 pass. It is a one-frame visual snap only on an interrupted or reversed transition, with a small listener leak. Low.

## C03 [Low] lib/shared/widgets/offline_view.dart, `_OfflinePingState.build`, lines 468-486. The ring Container is a non-positioned child of the Stack.

- **Input:** any reconnect attempt (auto-retry timer, coming back to the foreground, or tapping Retry) with motion not reduced. - The ring is sized `AppStateIcon.size + 44*ring`, so the Stack and the Center and Column around it grow by up to 44 px during the 900 ms ping.
- **Should:** The ping ring draws around the badge while the pill, title, body, tips and buttons stay still.
- **Actually:** On every reconnect attempt (auto retry, return to foreground, or tapping Retry), the content around the badge slides by up to about 21 px and back during the 900 ms ping.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C03_test.dart`
- **Fix:** Put the ring in Positioned.fill > IgnorePointer > OverflowBox (unbounded max) so it draws past the badge without resizing the Stack. (`fixes/C03.diff`)
- **Verifier note:** Clean: 1 of 2 cases fails. Content moves 21.5 px during the ping (tolerance 0.5). After the single-file diff to offline_view.dart, 2/2 pass. The source confirms the ring is a non-positioned Stack child whose size grows. This is a cosmetic layout jiggle during each reconnect, with no wrong data and no crash, so I rate it Low, below the prover's Medium.

## C04 [Low] lib/features/cv_builder/presentation/cv_generator/wizard_widgets.dart, AiEnhancedBeatFrame.build, lines 263-289

- **Input:** beat goes from 0 to 1 (the first enhancement), or from any N to N+1.
- **Should:** When the beat goes up, the framed field keeps its state and focus, and the frame resizes smoothly around the new result card.
- **Actually:** On every beat change the child subtree is rebuilt: the text field loses focus (keyboard drops) and the AnimatedSize starts fresh, so it jumps instead of animating.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C04_test.dart`
- **Fix:** Keep one stable tree for every beat: drop the key and the beat<=0 early return, and always use an unkeyed TweenAnimationBuilder tweening from beat-1 to beat, with glow = (beat - value).clamp(0,1).  The 3 hunt cases and the existing cv_builder enhance/restyle tests (45) pass. (`fixes/C04.diff`)
- **Verifier note:** Clean: 3/3 fail. The focused field loses focus on the 0->1, 1->2 and 5->6 beats. The source confirms the wrapper type or ValueKey('ai-beat-$beat') changes on each beat. After the single-file diff to wizard_widgets.dart, 3/3 pass. Text survives through the external controller. Only focus and keyboard are lost, and the AnimatedSize does not animate. Low.

## C14 [Low] 

- **Input:** 390pt-wide screen, `TextScaler` 2.0.
- **Should:** The experience/education editor lays out without overflow at every supported text scale (up to 2.0) on a 390pt screen, in English and Arabic.
- **Actually:** At 2.0, English overflows by 26 and 46 px and Arabic by 20 and 194 px. Arabic also overflows by 94 px at 1.5, so text is clipped.
- **Status:** confirmed by reading (clean re-run not done)
- **Test:** `tests/C14_test.dart`
- **Fix:** Wrapped both 'Sort chronologically' AppButton.text widgets in Flexible, and wrapped the 'Currently working' Text and both date-error Texts in Expanded. See (`fixes/C14.diff`)
- **Verifier note:** Not re-run (time ran out). The claim is RenderFlex overflow at the supported 2.0 text scale on a 390pt screen (Arabic also at 1.5). The fix wraps the sort buttons in Flexible and the labels and error texts in Expanded, which is plausible. Layout clipping only, so Low. Housekeeping: the worktree is unregistered from git (worktree remove, then prune), but the folder D:/Sirati/flutter_app/.claude/worktrees/verify-2 was left on disk because a file in it is locked (Permission denied). Delete it by ha

## C15 [Low] skill_chips_selector.dart, _SkillChipsSelectorState.build, "Clear all" TextButton onPressed, lines 221-234

- **Input:** enabled is false (AI enhancement running), some skills are selected, the user taps "Clear all".
- **Should:** While the selector is disabled during AI enhancement, 'Clear all' is disabled and the skills value is left unchanged.
- **Actually:** 'Clear all' stays active. It clears every skill, writes '' to the shared controller and calls onChanged during the enhancement.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C15_test.dart`
- **Fix:** The 'Clear all' TextButton's onPressed is now null when widget.enabled is false. See (`fixes/C15.diff`)
- **Verifier note:** Clean: 3 disabled cases fail because the controller becomes '' after a tap on Clear all. The enabled control case passes. With the single-file diff, 4/4 pass. Clear all ignores widget.enabled while AI enhancement runs. The impact is small: the enhancement result probably overwrites the skills anyway.

## C20 [Low] lib/features/cv_builder/presentation/generated_cv_screen.dart, _NextStepCard.build, lines 787-792

- **Input:** Arabic UI (Directionality rtl). The cards affected are Check ATS, Match job and Edit.
- **Should:** The trailing chevron on the Check ATS, Match job and Edit cards points to the trailing edge: right in LTR, left in RTL.
- **Actually:** In Arabic (RTL) all three chevrons are drawn pointing right, toward the leading edge, so they point backwards. LTR is correct.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C20_test.dart`
- **Fix:** Always use Icons.chevron_right_rounded in _NextStepCard. Icon mirrors it in RTL by itself. (`fixes/C20.diff`)
- **Verifier note:** Clean: ar fails (drawn 'right', expected 'left') and en passes. With the single-file diff, 2/2 pass. Icons.chevron_left_rounded has matchTextDirection, so picking it in RTL double-mirrors it. The result is a cosmetic backwards chevron in Arabic.

## C21 [Low] lib/shared/widgets/form_fields.dart, `_AppTextFormFieldState.didChange` (lines 687-705) and `_isShowingSuccess` (line 725); class doc at lines 463-466

- **Input:** The caller passes `AutovalidateMode.onUserInteraction`. The user submits while the field still has focus (on touch, tapping a button does not take focus from a TextField), so `_blurredOnce` is false. The submit's `Form.validate()` shows an error. The user then types a valid value without leaving the field. Example: on email_verification_screen (its Form has no autovalidateMode), type 3 digits, tap
- **Should:** Once the caller passes onUserInteraction after a failed submit, typing a valid value clears the error, red ring, fill and icon, and success chrome may show, even while the field keeps focus.
- **Actually:** The stale error text and red styling stay after the value is valid, until the field loses focus or the user submits again. Success chrome is held back the same way. Note: other provers used the git stash stack, which every worktree shares, so their stashes collided with mine and I popped another prover's stash by accident. I pushed it back and saved a copy at scratchpad/hunt/prove-7/foreign-stash-recovered.patch. stash@{2} ('prove-7 fix returned by prove-4') is my own C19 fix, no longer needed, and can be dropped. The worktree has been removed.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C21_test.dart`
- **Fix:** In form_fields.dart, both forceAlways checks (didChange and _isShowingSuccess) now also accept AutovalidateMode.onUserInteraction. A caller who opts in after a submit gets live validation without waiting for a blur, and 'forgive while editing' still applies. (`fixes/C21.diff`)
- **Verifier note:** Clean: 5/5 fail because the stale error text ('Please enter your email', its Arabic version, and 'required') stays after a valid value is typed with focus kept. With the single-file diff to form_fields.dart, 5/5 pass. The class doc says an explicit autovalidateMode overrides the blur-first gate after submit, but onUserInteraction is ignored until blur. The misleading error is temporary and does not block submit, so I rated it Low, not the claimed Medium.

## C22 [Low] lib/features/cv_builder/presentation/cv_builder_screen.dart, `_CvBuilderScreenState.build`, lines 463-467.

- **Input:** screen narrower than 900dp, motion not reduced, typing in any editor field.
- **Should:** One curved animation for the screen's whole life, disposed with the screen, so no status listeners pile up on the preview controller.
- **Actually:** Each rebuild (every keystroke) adds a new undisposed CurvedAnimation and status listener to _previewController. All of them are still alive after the screen closes.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C22_test.dart`
- **Fix:** Create the CurvedAnimation once in initState as a _previewCurve state field, use it in build, and dispose it before _previewController in dispose.  The hunt test passes, and cv_builder_screen_test, cv_builder_restyle_test and cv_builder_test pass. (`fixes/C22.diff`)
- **Verifier note:** Confirmed on a clean 8794fb8 worktree. After typing in the narrow builder, the test finds undisposed CurvedAnimations on _previewController after the screen closes. The prover-8 C22.diff applied cleanly, touches only cv_builder_screen.dart, and the test then passes. It is a listener and memory leak. Users see nothing wrong.

## C24 [Low] lib/shared/widgets/form_fields.dart, `_AppTextFormFieldState.didChange` (lines 679-706). The "forgive while editing" early return is at lines 691-697.

- **Input:** the field sits inside a `Form` whose `autovalidateMode` is `AutovalidateMode.onUserInteraction`. Callers switch to this after the first submit: login_screen.dart:119, the cv_generator wizard through wizard_widgets.dart:48, and register, forgot_password, change_password and profile screens. Example: the field is valid with "abc" and a submit validation passes. The user focuses the field and deletes
- **Should:** While the field has focus, typing never adds a new error or changes the message shown. New errors appear on blur or submit, even when the Form autovalidates onUserInteraction.
- **Actually:** After the first submit, the Form validates every field on each keystroke, so a new error appears mid-typing and an existing message changes (for example 'required' becomes 'too short') while the field still has focus.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C24_test.dart`
- **Fix:** In _AppTextFormFieldState, override validate(). When didChange sees that the focused field's new value fails the validator, it sets a _holdFormValidation flag (cleared in a post-frame callback). While that flag is set and the field still has focus, validate() returns !hasError without re-running the validator. Blur and submit still validate normally.  The hunt test passes, and all 21 test files that use AppTextFormField pass (536 tests), including calm_motion's forgive-while-editing tests and al (`fixes/C24.diff`)
- **Verifier note:** All 5 cases fail on clean. Once the Form is onUserInteraction, a new error ('too short' or 'required') appears while the field still has focus, and 'required' changes to 'too short'. This breaks the field's own documented forgive-while-editing rule. prove-8/C24.diff is EMPTY (0 bytes), so I wrote my own fix in form_fields.dart. It sets a _holdFormValidation flag when a focused edit fails the validator, clears it in a post-frame callback, and overrides validate() to return !hasError while the fla

## C26 [Low] job_title_picker_field.dart, _JobTitlePickerSheetState.build, lines 252-258

- **Input:** open the picker on a 390x844 phone with a 47 top inset, then focus the search field (keyboard 336).
- **Should:** With the keyboard open, the sheet's title row and Clear button stay below the status bar / Dynamic Island.
- **Actually:** The sheet is clamped to the full screen height, so the title and Clear button sit at y≈16–28, under the 47pt status-bar / Dynamic Island inset.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C26_test.dart`
- **Fix:** In _JobTitlePickerSheetState.build, cap the list height at screenH - keyboard - top inset - bottom padding. The top inset is read from View.of(context), because the route removes it from MediaQuery.  The hunt test and job_title_picker_manual_entry_test pass after the fix (15/15). (`fixes/C26.diff`)
- **Verifier note:** Confirmed. With the keyboard open, the picker header sits at y=27.5 and y=16, under the top insets of 47 and 20. C26.diff caps the height using View.of(context) padding, touches only job_title_picker_field.dart, and the test passes with it. The header and Clear button are partly hidden under the status bar, a layout problem only.

## C27 [Low] onboarding_screen.dart, _OnboardingHeroState.didUpdateWidget, lines 515-524 (together with _onPageChanged line 136 and `active: i == _index` line 279)

- **Input:** swipe from page 1 toward page 2 past the halfway point, with motion not reduced.
- **Should:** The incoming hero, already visible during the swipe, keeps its opacity and scale as it crosses the midpoint.
- **Actually:** At the halfway point the visible hero drops from opacity 1 and scale 1 to opacity 0 and scale 0.86, then fades back in, so it flashes on every swipe (and on the Next / dot animations).
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C27_test.dart`
- **Fix:** In _OnboardingHeroState.didUpdateWidget, do not replay the entrance when a page becomes active. Only make sure the hero is fully shown (value = 1 unless it is already animating); the page view's parallax/scale carries the swipe.  The hunt test, all of test/features/settings, splash_screen_test and contrast_reflow_and_tap_targets_test pass after the fix (391 tests). (`fixes/C27.diff`)
- **Verifier note:** Confirmed. At the swipe midpoint the incoming onboarding hero drops from opacity 1 to 0 (the test reports 'Actual: 0.0'). C27.diff stops replaying the entrance in didUpdateWidget, touches only onboarding_screen.dart, and the test passes with it. It is a visual flash only.

## C29 [Low] personal_details_editor.dart, the _includePhoto field (151), the Switch onChanged (408-412) and the atsPhotoEnabled banner (423-454).

- **Input:** turn the ATS photo switch on.
- **Should:** A toggle that says the photo option is enabled either changes the CV (and persists across tabs) or does not exist.
- **Actually:** Turning the switch on changes nothing in the CvDocument, and the switch resets to off after changing tabs.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C29_test.dart`
- **Fix:** There is no photo feature, so I removed the dead control at the root (AGENTS.md rule 3): deleted _includePhoto, the Switch and the atsPhotoEnabled banner, and kept the ATS photo advice card. The new test passes and test/cv_builder_test.dart still passes. The fixed test passes trivially, because no switch is left to check. The atsPhotoEnabled ARB key is now unused. (`fixes/C29.diff`)
- **Verifier note:** On clean 8794fb8 the test fails with 'switch changes nothing in the CV': the photo Switch flips on but CvDocument JSON is unchanged, and no photo field exists anywhere in the code. Fix C29.diff removes the switch and the atsPhotoEnabled banner, so the test then passes trivially (count=0, nothing to check). The UI confirms a setting that does nothing. No data is lost, so Low. The atsPhotoEnabled ARB key is left unused.

## C32 [Low] lib/shared/widgets/empty_state.dart, AppEmptyState.build, lines 72-75. A `Semantics(container: true, label: title)` wraps a `Text(title)` at line 92.

- **Input:** any AppEmptyState or AppErrorState (every empty and error screen) with a screen reader on.
- **Should:** A screen reader reads the empty/error state title once, then the subtitle.
- **Actually:** The container's label is 'TITLE\nTITLE[\nSUBTITLE]', so the title is announced twice.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C32_test.dart`
- **Fix:** Give the title Text semanticsLabel: '' so only the panel's label announces the title; the subtitle is still read. (`fixes/C32.diff`)
- **Verifier note:** On clean, the title appears twice in the semantics labels for all three inputs (Expected 1, Actual 2). Semantics(container:true, label: title) merges with the child Text(title). The fix C32.diff sets semanticsLabel '' on the title Text, and all 3 cases then pass. Screen readers read the title twice on every empty or error state. This is an accessibility nuisance, so Low.

## C37 [Low] lib/shared/widgets/motion.dart, MotionStepSwitcher.build, layoutBuilder, line 465 (`for (final old in previous) IgnorePointer(child: old)`)

- **Input:** Any change of `stepKey` while reduced motion is off, such as Next or Back in the CV wizard, or the send-code stage change on forgot password.
- **Should:** The outgoing step fades out with the same State: no new initState, and its text and scroll position stay.
- **Actually:** The outgoing step's State is disposed and a new one is created for the fade-out. Fields show blank or initial content, and initState side effects fire again.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C37_test.dart`
- **Fix:** Wrap both current and previous children in an IgnorePointer keyed with the child's own key (ignoring: false for current). A step that stops being current then updates in place and keeps its element. (`fixes/C37.diff`)
- **Verifier note:** Clean run gives log [init 0, init 1, dispose 0] in all 4 LTR/RTL forward/back cases: the outgoing step's State is rebuilt because its unkeyed IgnorePointer wrapper changes. The keyed IgnorePointer diff passes 4/4. Real users hit it, in the CV wizard steps and forgot-password, but the effect lasts only for the fade-out. The CV wizard ListView uses a PageStorageKey and the step content comes from the parent, so the visible harm is small: a re-init or flash plus any duplicated initState side effect

## C40 [Low] lib/shared/widgets/form_fields.dart, `_becameValid` and the tick branch of `buildField` (lines 583-592 and 789-803), plus `_ValidTickState.didChangeDependencies

- **Input:** `tickWhenValid: true`. The field becomes valid, so the tick starts and `_showTick` is true. Within the tick's 1.4 s an error takes over the suffix slot (for example a programmatic text change followed by a submit), which disposes `ValidTick` before its `onDone` runs. The value is then made valid again.
- **Should:** The tick plays at most once per field. An error that interrupts it does not make it replay when the field becomes valid again.
- **Actually:** After an error interrupts the tick and then clears, ValidTick mounts again and the tick plays a second time.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C40_test.dart`
- **Fix:** In buildField, set _showTick = false whenever showError or showSuccess takes the suffix slot, so an interrupted tick ends for good. The new test passes, and so do the existing valid-tick tests in alive_motion_test. (`fixes/C40.diff`)
- **Verifier note:** Clean run: ValidTick mounts again after an error interrupts the tick and then clears; it fails at all interrupt times. The diff passes 4/4. The tick animation replays, which is cosmetic only.

## C42 [Low] password_strength_meter.dart, evaluate (lines 27-30)

- **Input:** (a) Arabic-Indic digits such as "١٢٣٤٥٦٧٨"; (b) accented Latin letters (for example "éééééééé"), Cyrillic, or Persian/Urdu letters outside U+0600-06FF; (c) emoji
- **Should:** Arabic-Indic digits count as digits, letters of any script count as letters, and length counts characters, so strength follows the stated rules.
- **Actually:** Arabic-Indic digits count as letters, accented/Cyrillic/Persian letters count as symbols, and emoji count double toward length, so the meter shows the wrong strength.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C42_test.dart`
- **Fix:** Count length with password.runes.length. Use unicode regexes: letter [/p{L}/p{M}], digit /p{Nd}, symbol [^/p{L}/p{M}/p{Nd}]. The new test passes, and so do the existing meter, contrast and ui_components tests. (`fixes/C42.diff`)
- **Verifier note:** Clean run fails all 3 cases: Arabic-Indic digits are not counted as digits, accented letters count as symbols, and emoji are counted by UTF-16 length. The unicode-regex/runes diff passes 3/3. The meter is display-only and gates nothing, so Low.

## C43 [Low] `_calendarMode` at lines 60 and 199-200. It is passed to the tiles at lines 238 and 280, but `widget.calendarMode` is never read.

- **Input:** tap Hijri.
- **Should:** Choosing Hijri on the 'Calendar for dates' control should change the date fields the user sees, at least so the example dates are Hijri (e.g. 1442-05). If not, the control should not be offered.
- **Actually:** Tapping Hijri only changes the control's own state. The tiles ignore calendarMode, so the start, end and graduation hints stay Gregorian ('e.g. 2021-01', 'e.g. 2024-05', 'e.g. 2022'). Nothing in display, hints or storage changes.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C43_test.dart`
- **Fix:** The tiles now read widget.calendarMode. A new helper, _calendarHint(hint, mode), rewrites the Gregorian YYYY[-MM] example in the start, end and graduation hints as its Hijri equivalent (via ArabicDateFormat.gregorianToHijri) when Hijri is selected.  With the fix, the C43 test passes in ar and en, and all 926 tests in test/features/cv_builder still pass. Another valid fix would be to remove the dead control. (`fixes/C43.diff`)
- **Verifier note:** On a clean worktree the test fails for the claimed reason in both ar and en: after tapping Hijri, the date hints are still Gregorian. With the diff applied (it touches only experience_education_editor.dart), the test passes. The Hijri/Gregorian control is dead: calendarMode is passed to the tiles but never read. Stored data and sorting are correct because the parser detects the calendar on its own, so this is a no-op control (AGENTS.md rule 6), not wrong data.

## C44 [Low] lines 46-48, through `compareCvDates`. A plain year counts as January, and an end date that does not parse compares as +1.

- **Input:** - Start `2020-05` or `May 2020` with end `2020`. - End `Present`. - Partial typing such as `2`, or `202`, which is read as a Hijri year.
- **Should:** No error for a year-only end in the same year as a month start (e.g. 2020-05 to 2020), or for partial or non-date end text. A truly earlier end (2020-05 to 2019 or 2020-04) is still flagged.
- **Actually:** validateDateRange returns 'End date cannot precede start date' for 2020-05 / May 2020 to 2020, for end 'Present', and for partial input such as '2', '20' or '202'.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C44_test.dart`
- **Fix:** validateDateRange returns null unless both sides have a four-digit year and parse. A year-only end is compared at its last month: December, or Dhu al-Hijjah converted for Hijri years. test/cv_builder_test.dart still passes. (`fixes/C44.diff`)
- **Verifier note:** Clean run fails for the claimed reason. A month start with a year-only end in the same year (e.g. 1990-02 to 1990) is flagged as endDateBeforeStart. So is partial typing ('1', '19', '199') and 'Present'. With the fix the test passes. validateDateRange runs on every change, so the user sees a false error while typing. The 'Present' case is less likely in real use because there is a separate 'current' toggle. Only the message is wrong; nothing is lost.

## C45 [Low] history_cards.dart, GeneratedCvHistoryCard.build, lines 233-250

- **Input:** the initial is drawn in AppTypography.titleLg (18pt, Arabic line height 1.52) inside a fixed 40x40 box. In the Arabic UI (the default) at text scale 1.5x or more, the line box is 18*1.52*1.5 = 41px, which is taller than 40px. At 2x to 3x the letter is 36 to 54px.
- **Should:** The avatar initial is fully visible at every text scale and in both UI languages.
- **Actually:** From 1.5x up in the Arabic UI (and at larger scales in English), the initial's line box is bigger than the 40x40 box and the letter is clipped.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C45_test.dart`
- **Fix:** Wrapped the initial Text in FittedBox(fit: BoxFit.scaleDown) inside the fixed box. The new test, history_test and contrast_reflow_and_tap_targets_test all pass (162 tests). (`fixes/C45.diff`)
- **Verifier note:** Clean run fails: the avatar box stays 40px while the initial's line box needs 41px at 1.5x (Arabic) and 55px at 2x. With the FittedBox fix the test passes. The test measures line box against box size, which only approximates clipping. At 1.5x the glyph may still fit; at 2x to 3x it really is clipped. Cosmetic only, and only at large accessibility text sizes.

## C46 [Low] email_verification_screen.dart, `_verify`, lines 108-113 (`onRetry => _verify`) and line 86

- **Input:** - Verification fails with a retryable `ApiException`, so a snackbar with Retry appears. Snackbars live on the root ScaffoldMessenger and stay up after navigation. - The user taps Back: `_leave` calls `replaceRoot(Login)` and this screen's state is disposed. - The user taps Retry on the Login screen while the snackbar is still showing.
- **Should:** Tapping a stale Retry after leaving the screen is a harmless no-op, or the snackbar is gone.
- **Actually:** _verify reads State.context after dispose. It throws 'This widget has been unmounted, so the State no longer has a context' (email_verification_screen.dart:86) as an uncaught async error.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C46_test.dart`
- **Fix:** Return early in _verify when the State is unmounted: `if (_isLoading || !mounted) return;`. (`fixes/C46.diff`)
- **Verifier note:** Clean run fails with 'This widget has been unmounted, so the State no longer has a context' when a stale snackbar Retry fires after the user leaves for Login. The one-line mounted guard makes the test pass. Real lifecycle bug, but it needs an unusual sequence (Retry tapped after navigating away). The only effects are an uncaught async error and a Retry that does nothing.

## C47 [Low] cv_analysis_screen.dart, `_submit`, lines 284-288 (`onAction => _submit`) and lines 165-166

- **Input:** the AI status is failed, so a snackbar with Retry appears and the result screen is pushed on top of the form. - (a) The user pops the result screen and the form (back to home) while the snackbar is still up, then taps Retry. - (b) The user stays on the result screen and taps Retry. The form is still mounted underneath.
- **Should:** A stale Retry tapped after the analysis form is gone does nothing and raises no error.
- **Actually:** _submit runs on the disposed form state. AppLocale.isEnglish(context) (cv_analysis_screen.dart:166) throws 'This widget has been unmounted' as an uncaught async error.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C47_test.dart`
- **Fix:** Return early in _submit when the State is unmounted: `if (_isLoading || !mounted) return;`. (`fixes/C47.diff`)
- **Verifier note:** Clean run fails with the unmounted-context error in _submit, via AppLocale.isEnglish(context), when a stale Retry fires after the form is popped. The mounted guard makes the test pass. Same class as C46. Case (b) of the claim, a duplicate result screen, is not covered by this test or the fix.

## C48 [Low] my_cvs_screen.dart, `_MyCvsScreenState._edit`, lines 75-79

- **Input:** tap Edit, then leave the My CVs screen (it gets disposed) while `getGeneratedCv` is still running, and the request then fails (offline or timeout).
- **Should:** A CV load that fails after the user left My CVs is dropped quietly, as _reportError intends with its mounted check.
- **Actually:** The catch reads State.context after dispose (my_cvs_screen.dart:78). It throws 'This widget has been unmounted' as an uncaught async error from the unawaited _edit.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C48_test.dart`
- **Fix:** Add `if (!mounted) return;` at the top of _edit's catch block, before context is read. (`fixes/C48.diff`)
- **Verifier note:** Clean run fails in both cases (offline and a generic error). The catch in _edit reads AppLocalizations.of(context) after dispose, before _reportError's own mounted check runs. The added `if (!mounted) return;` makes both pass. It is an uncaught async error with nothing visible to the user, and it needs the user to leave mid-load and the load then to fail.

## C49 [Low] my_cvs_screen.dart, `_slim` ValueNotifier, `_onListScroll` and `_slimHeader`, lines 320-369

- **Input:** scroll past `MyCvsSlimHeader.showAfter` so `_slim` becomes true. Then cause the list to be rebuilt at offset 0. Two ways to do that: - Switch the app language. `myCvsProvider(english)` is a new family member, so the page shows the loading skeleton and then a fresh ListView. - Have a reload fail (error state), then tap Retry.
- **Should:** When a rebuilt list appears at offset 0 (after a language switch or Retry), only the large MyCvsHeader shows.
- **Actually:** The slim header stays visible over the large header at offset 0, so the page shows two titles and two notification bells until the user scrolls.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C49_test.dart`
- **Fix:** Listen for Notification instead of only ScrollNotification, and in _onListScroll also handle ScrollMetricsNotification (depth 0, vertical). A fresh list sends that after its first layout, so _slim follows its real offset. C49_test and the existing my_cvs_header_restyle_test (20 tests) pass.   (note: the Python edit also rewrote line endings, so check the diff's whitespace when applying) (`fixes/C49.diff`)
- **Verifier note:** Clean run fails: after a language switch, MyCvsSlimHeader is still shown over the large header on a fresh list at offset 0. With the fix (handle ScrollMetricsNotification) the test passes. The diff touched only my_cvs_screen.dart and applied with --ignore-whitespace, because the earlier prover's edit rewrote line endings. Visual only: two titles and two bells until the user scrolls.

## C50 [Low] change_password_screen.dart, `build`: the current-password field's `onChanged` (lines 151-155) against the new-password validator (lines 186-188)

- **Input:** enter current = X and new = X, press Update. The new field shows `settingsNewPasswordSameAsCurrent`. Then fix the current-password field instead of the new one.
- **Should:** Once the current password is changed so it no longer equals the new password, the 'same as current' error on the new-password field clears.
- **Actually:** The stale 'New password must differ from current' error stays under the new-password field until the user edits that field or submits again.
- **Status:** demonstrated on clean code; its own fix passes
- **Test:** `tests/C50_test.dart`
- **Fix:** Add _newKey = GlobalKey<FormFieldState<String>>() on the new-password AppTextFormField. In the current field's onChanged, call _newKey.currentState?.validate() when _submitted. C50_test, settings_forms_restyle_test and account_security_test pass (41 tests). (`fixes/C50.diff`)
- **Verifier note:** Clean worktree at 8794fb8: both cases fail at line 42 for the reason in the claim. After the user submits with current == new, then edits only the current-password field, the 'New password must differ from current' error stays under the new-password field. The 4-line diff touches only change_password_screen.dart. It adds a key to the new-password field and revalidates that field from the current field's onChanged once the form has been submitted. With the diff applied, both cases pass. This is a

## Coverage

- **Read:** every line of 108 lib/ files (37,323 lines), twice: Phase 1 readers, then fresh Phase 2 reviewers.
- **Suspicions:** 176 recorded, 72 rated 3 or higher; the top 50 were proven. The 22 other rated-3+ ones are in `unchecked.md`; the 104 rated below 3 were not checked.
- **Rejected:** none of the 50 (one first-pass rejection was overturned on recheck).
- **Not fully re-checked:** C12, C13, C14 and C31 are confirmed by reading only in the clean pass (the machine was slow); C11 is demonstrated on clean code but its fix did not finish its clean re-run.
- **Process problem:** provers shared one git stash across worktrees and popped each other's changes, so every result was re-run on a clean copy. Leftover prover stashes remain in `git stash list` (stash@{0}-{2}); the user backup is stash@{3}, also pinned as branch backup/notification-fix-stash.
