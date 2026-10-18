# Job Match delivery

Production call chain: `MyCvsScreen` and `DashboardHomeTab` push
`AppRoutes.jobMatch`; `features/app/sirati_route_table.dart` composes
`JobMatchScreen`. Its entitlement provider fetches `/auth/me` and uses the
server subscription and Job Match quota. The feature repository consumes the
three Job Match methods in `CvApiService`.

The screen validates the full job description before creating `CvTargetJob`.
For users without a saved CV, the named generator route returns its
`GeneratedCv` through `handBackResult`, then the screen submits the match.
Pending advice keeps the deterministic score visible. Polling is bounded and
sparse because create, read, and apply share the backend AI throttle. A timeout
is still processing, with a manual refresh; reopening a result preserves its
selection and request identity.

Apply creates a copy, invalidates the CV and dashboard content caches and the
saved CV provider, then passes the returned CV (including its canonical
document) through the composition root to `GeneratedCvScreen`. Returning to
My CVs or the dashboard refreshes the mounted screen.

Acceptance: `test/features/job_match/job_match_acceptance_test.dart` pumps the
real entry points and route table with an HTTP mock. In both locales it checks
create/poll/apply request shapes, the canonical document in the real preview,
the text sent through the platform share channel, and cache/list refreshes.
The feature flow and domain tests cover entitlement, validation, handoff,
retry/resume, late refresh isolation, and safe selection. The RTL/contrast
tests inspect real widget/render trees and enforce text contrast >= 4.5.
`test/architecture/layering_invariants_test.dart` consumes the import graph.
The `Run tests` steps in `codemagic.yaml` (`android-preview`, `ios-preview`,
and `ios-testflight`) discover these untagged tests through
`flutter test --exclude-tags golden`.

All new UI copy lives in the Arabic and English ARB catalogs. User-entered
titles/descriptions and server advice remain content; no translated UI labels
are persisted, so this feature requires no string-data migration.

Backend integration limit: `SubscriptionGate::assertCanJobMatch` currently
checks today's create quota for show and apply as well. Creating the last
allowed match can therefore make later reads/apply return 429. The UI preserves
the immediate score and explains that response; changing that server policy is
outside this Flutter task.
