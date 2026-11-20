# 20: Round 2 recapture and final check

**What to build:** recapture all 80 screens (AR/EN × light/dark), refresh the before/after board against the round 1 "before" captures, run the full suite and the dark-mode walk on the integrated branch, and list anything still in the old style.

**Blocked by:** 10, 11, 12, 13, 14, 15, 16, 17, 18, 19

**Status:** ready-for-agent

## Acceptance criteria

- [ ] All-screens capture rerun; board `D:\Sirati\docs\screenshots\ios26-before-after.html` refreshed
- [ ] Full `flutter test` green, `flutter analyze` clean
- [ ] Remaining gaps listed; the iOS back swipe on a real iPhone stays a ready-for-human note

**How to verify:** `flutter test`, `flutter test test_screens/all_screens_capture_test.dart`, open the board.
