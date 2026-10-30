/// The app's one ATS grade scale, shared by every screen that shows a score
/// (ATS result, history, My CVs).
library;

/// ATS letter grade for a 0-100 score, mirroring the server's
/// `AtsScoringService::GRADE_THRESHOLDS`. The only grade scale in the app.
enum AtsGrade {
  aPlus('A+', 90),
  a('A', 80),
  b('B', 70),
  c('C', 60),
  d('D', 50),
  f('F', 0);

  const AtsGrade(this.label, this.floor);

  final String label;

  /// Lowest score that earns this grade.
  final int floor;

  static AtsGrade of(int score) =>
      values.firstWhere((g) => score >= g.floor, orElse: () => f);
}

/// Overall ATS score band (0-100): the grade scale grouped for copy and
/// colour, so a band never disagrees with the grade beside it.
enum ScoreBand {
  excellent,
  veryGood,
  fair,
  weak;

  static ScoreBand of(int score) => switch (AtsGrade.of(score)) {
        AtsGrade.aPlus || AtsGrade.a => excellent,
        AtsGrade.b => veryGood,
        AtsGrade.c => fair,
        AtsGrade.d || AtsGrade.f => weak,
      };
}
