# Sirati tests

## Unit / widget tests

```bash
flutter test
```

## Golden tests (theme × direction)

Goldens live under `test/golden/goldens/` and cover:

- Dashboard stat + action card cluster
- `SubmitButton` enabled / loading / disabled
- `AppTextFormField` idle / error / success
- `ScoreBoosterCard`

Each subject is rendered in a **4-way matrix**: light+LTR, light+RTL, dark+LTR, dark+RTL — with a fixed `MediaQuery` (390×844, `textScaler` 1.0, `disableAnimations: true`).

### Update baselines

After intentional visual changes (theme tokens, spacing, component chrome):

```bash
flutter test test/golden --update-goldens
```

Or all tests with golden updates:

```bash
flutter test --update-goldens
```

Commit the updated PNGs under `test/golden/goldens/`.

### CI note

Golden pixel comparison can be sensitive to OS font rasterization. Prefer running update-goldens on the same OS the CI uses, or pin a Linux runner for goldens.
