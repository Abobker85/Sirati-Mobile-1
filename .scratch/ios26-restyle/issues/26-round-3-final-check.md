# 26: Round 3 recapture and final check

**What to build:** from the main checkout, recapture all 80 screens (AR/EN x light/dark), add a fourth column (round 3) to the board, run the full suite and analyze, confirm no gradient is still visible in the captures, and update the remaining-gaps list.

**Blocked by:** 23, 24, 25

**Status:** ready-for-agent

## Acceptance criteria

- [ ] Round 2 captures kept as `after-round2/`; all-screens recaptured; board shows before / round 1 / round 2 / round 3
- [ ] Full `flutter test` green, `flutter analyze` clean
- [ ] Remaining gaps listed

**How to verify:** `flutter test`, `flutter test test_screens/all_screens_capture_test.dart`, open the board.
