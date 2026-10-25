/// Bottom-navigation tabs of the authenticated shell, in display order
/// (Salem review: Home · My CVs · Jobs · Education).
enum DashboardTab {
  home('dashboard'),
  myCvs('my_cvs'),
  jobNews('job_news'),
  education('education');

  const DashboardTab(this.screenName);

  /// Analytics screen name; the shell is one route, so tabs log manually.
  final String screenName;

  /// Out-of-range indices (stale deep links, bad route args) land on home
  /// instead of crashing the tab stack.
  static DashboardTab fromIndex(int index) =>
      index >= 0 && index < values.length ? values[index] : home;
}
