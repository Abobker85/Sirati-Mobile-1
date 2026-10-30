import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/storage/guest_session.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/auth/presentation/sign_in_required_screen.dart';
import 'package:sirati/features/dashboard/presentation/home_screen.dart';
import 'package:sirati/features/settings/presentation/profile_screen.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';

/// Where the Jobs deep link and "Set job title" land.
void main() {
  setUpAll(registerSiratiRouteWidgets);
  tearDown(() => GuestSession.active.value = false);

  Future<Widget Function(String)> screens(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));
    return (name) => (AppRouter.onGenerateRoute(RouteSettings(name: name))
            as MaterialPageRoute<dynamic>)
        .builder(context);
  }

  for (final guest in [false, true]) {
    testWidgets('/job-news opens Home on the Jobs tab (guest: $guest)',
        (tester) async {
      GuestSession.active.value = guest;
      for (final path in [AppRoutes.jobNews, '${AppRoutes.jobNews}/']) {
        final screen = (await screens(tester))(path);
        expect(screen, isA<HomeScreen>(), reason: path);
        expect((screen as HomeScreen).initialIndex, DashboardTab.jobNews.index);
      }
    });
  }

  testWidgets('/profile edits the profile; a guest is invited to sign in',
      (tester) async {
    final screenFor = await screens(tester);
    GuestSession.active.value = false;
    expect(screenFor(AppRoutes.profile), isA<ProfileScreen>());
    GuestSession.active.value = true;
    expect(screenFor(AppRoutes.profile), isA<SignInRequiredScreen>());
  });
}
