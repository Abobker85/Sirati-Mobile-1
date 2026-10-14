# Sirati: KSA launch plan (review of the external evaluation)

Checked against `main` on 2026-10-14. Every claim was verified in code (file:line in the
fact-check log). Verdicts: 17 true, 6 partly true, 1 false.

## 1. Corrections to the evaluation

| # | Evaluation said | Actually |
|---|---|---|
| 9 | Google/Apple buttons visible and show "coming soon" (high rejection risk) | **False.** With `socialSignInEnabled = false` the buttons and separator are not rendered (`login_screen.dart:327`). Not a blocker. |
| 13 | Structured builder losing work is a "critical UX bug" | **Overstated.** `/builder` has routes but no UI entry point, so users never reach it. Real issue: an unfinished, memory-only feature is registered in production. |
| 14 | Screens "only share plain text" | **Partly.** GeneratedCv shares plain text; My CVs has no share action at all. `CvExportDialog` has no callers. |
| 22 | English mode shows Arabic input-method labels | **Not user-visible.** `CvAnalysis.inputMethodLabel` is Arabic-only but unused; the classification warning is localized. Drop. |
| 5 | AppLog redacts all PII | **Partly.** Messages/data are redacted; debug stack traces bypass it, and pattern matching is best effort. |
| 6 | Phone/location can't be edited | **Partly.** UI is read-only and the client sends only name/job title; backend support for changing them is unverified. |
| 19 | Guest boundaries unclear | **Partly.** "Continue without account" works but nothing explains what guests can't do. |

The evaluation missed two Guideline 2.1 items:
- `education_screen.dart:281`: "Notify me on launch" only stores a local flag; no notification is ever sent.
- `premium_gate_screen.dart:17`: `/premium` is a placeholder with no purchase flow.

## 2. Plan

### Phase 0: before App Store submission (blockers)

| Task | Change | Size |
|---|---|---|
| P0-1 Education tab | **Decision needed**: wire to `GET /mobile/education` (backend has content), or hide the tab until ready. Either way remove the local-only "Notify me". | M / S |
| P0-2 Job card bookmark | Hide the icon until saved jobs exist (saved jobs move to v1.1). | S |
| P0-3 ATS upgrade card | Make "Ready to upgrade your CV?" tap the same generate action as the bottom bar. | S |
| P0-4 Production routes | Register `/gallery` and `/builder*` only in non-prod flavors; unknown builder id -> not-found. Make sure nothing in prod links to `/premium`. | S |
| P0-5 Telemetry | **Decision needed**: Firebase Analytics on/off. Set release Sentry DSN/environment via `--dart-define` in the build config (Codemagic). | S |
| P0-6 Guest mode | One line under "Continue without account" saying what needs an account. | S |
| P0-7 Store items (not code) | Terms & Conditions text/URL, privacy policy URL, review notes + demo account for Apple. | owner |

### Phase 1: v1.0.1 quick wins (data already parsed, small UI work)

| Task | Change |
|---|---|
| P1-1 ATS weaknesses | Render `weaknesses` (priority, issue, fix) in RecommendationsTab, sorted by priority. |
| P1-2 Job skill gaps | Show `missing_skills` and `experience_level` on JobNewsDetailScreen next to matched skills; link to "Tailor my CV". |
| P1-3 Analysis notifications | `analysis/{id}` opens `/analysis/{id}` instead of History (`notification_target.dart:109`). |
| P1-4 Duplicate AI generations | Pass an idempotency key from ImprovedCvController (`improved_cv_controller.dart:76`). |
| P1-5 Job feed edge cases | One-item feed must not show "No job news"; `isNew` from `published_at`, not index 0. |
| P1-6 Colour tokens | "New", "Details" and highlighted MetaChip use `primaryInk`, not the fill `primary`. |

### Phase 2: v1.1 for the KSA market

| Task | Change | Depends on |
|---|---|---|
| P2-1 Profile editing | Editable phone + city in ProfileScreen; refresh `profile_context` and the Match filter. | Backend `PUT /auth/profile` accepting phone/city (verify in Laravel). |
| P2-2 Server-driven filters | Categories and cities from an API (new sectors/regions without an app update). | New backend endpoint. |
| P2-3 Job deep links | `/job-news/{id}` route using the unused `jobNewsItem` (`GET /mobile/job-news/{id}`). | — |
| P2-4 PDF export | Fix stale `pdfBytes` and the overlapping-preview race in PdfExportController, then wire CvExportDialog into GeneratedCv and My CVs with native file sharing. | — |
| P2-5 Saved jobs | Real bookmark (local first, server later); re-show the icon. | P0-2 |
| P2-6 Premium | RevenueCat entitlements, paywall on `/premium`, premium templates / limits. | Pricing decision, store products. |
| P2-7 Structured builder | Finish (persistent storage, entry point) or delete it. | Product decision. |

## 3. Decisions needed from the owner

1. Education tab: wire live content now, or hide it for launch?
2. Analytics: enable Firebase Analytics at launch?
3. Structured builder: finish later or remove?
4. Premium: launch free, add RevenueCat in v1.1?

## 4. How it will be built

Phase 0 and Phase 1 split into independent tasks (different files) run in parallel by the coders,
each with tests, a cross-vendor review, and one full test run after merging. Backend-dependent
items (P2-1, P2-2) start with a check of the Laravel API in `D:\Sirati`.
