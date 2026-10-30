# CV export

Sharing a generated CV hands the employer the real PDF. The generated-CV hub's Share button downloads the CV's PDF in the CV's own language and opens the device share sheet with it. Download keeps opening the server's PDF link in the browser. The old `cv_export` feature (`CvExportDialog`) had no caller: its dialog was removed and its controller moved into `cv_builder` (issue #19).

## User flow

- Generated CV hub (`AppRoutes.cv(id)`): Download and Share follow one readiness rule (`isCvReadyToSend`: the server's `export.ready`, else the AI status). When the CV is not ready, both show the server's reason (or `cvNotReadyToSend`) and nothing leaves the app. Both buttons are enabled together and disabled only while their own action runs.
- Share downloads `GET /generated-cvs/<id>/download?language=<cv language>` with the server's default design, checks the `%PDF-` header, and shares the bytes as `application/pdf` named by `ExportFileNamer`. A 402 shows `cvShareSubscriptionRequired`; any other failure, including a body that is not a PDF, shows `cvShareFailed`.
- Download (hub and My CVs) may first offer a design picker. The design list is requested in the CV's language (`listCvTemplates(language:)`), not the app's. My CVs reads the row's `language` when the server sends it, else fetches the CV; when the language can't be learned it uses the default design.
- The hub preview's reading direction is `AppLocale.directionOf(cv.language)`; it is never guessed from the text.

## Code map

| Path | Responsibility |
| --- | --- |
| `lib/features/cv_builder/application/pdf_export_controller.dart` | Downloads the PDF, rejects non-PDF bytes, maps 402 to `premiumLocked`, shares through `pdfShareProvider`. |
| `lib/features/cv_builder/domain/export_file_namer.dart` | Safe Arabic or Latin PDF filenames. |
| `lib/features/cv_builder/presentation/generated_cv_screen.dart` | Hub Download/Share, design picker, preview direction. |
| `lib/features/cv_builder/presentation/my_cvs_screen.dart` | My CVs download with the CV-language design list. |

## Tests

- `test/features/cv_builder/pdf_export_controller_test.dart`: the shared file equals the served PDF for arbitrary PDF bodies; arbitrary non-PDF bodies are never shared; only 402 is a premium lock, whatever the body says.
- `test/features/cv_builder/generated_cv_hub_test.dart`: Share parity with Download across languages, AI statuses and server export reasons; design list and direction follow the CV language for any app language.
- `test/features/cv_builder/my_cvs_export_gate_test.dart`: My CVs design list in the CV language, from the row or from the CV.

## Known gaps

- The server's premium-template lock in `CvTemplateRenderer::downloadResponse` answers 403 (also used for "not yours"), so the app reports it as a general failure; it should answer 402 like `SubscriptionRequiredException`.
- `/mobile/my-cvs` rows do not include `language` yet, so My CVs fetches the CV before offering designs.
- The share sheet always uses the default design; a design choice for Share is not offered.
