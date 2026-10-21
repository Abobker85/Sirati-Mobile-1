import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SIRATI-15: Continuous Integration Pipeline Invariants', () {
    // GitHub Actions lives at the monorepo root, one level above this project.
    // A standalone clone of the mobile repo (for example Codemagic's) has no
    // such file, so these checks only run where the file can exist.
    final workflowFile = File('../.github/workflows/ci.yml');

    test(
      'GitHub Actions workflow enforces format, fatal-infos analysis, and tests',
      () {
        final content = workflowFile.readAsStringSync();

        expect(content, contains('push:'));
        expect(content, contains('pull_request:'));

        expect(content,
            contains('dart format --output=none --set-exit-if-changed .'));

        expect(content,
            contains('flutter analyze --fatal-infos --fatal-warnings'));

        // Fast quality job stays OS-agnostic and skips goldens.
        expect(
            content, contains('flutter test --coverage --exclude-tags golden'));

        // SIRATI-29: a dedicated job must actually run goldens so mismatch fails CI.
        expect(content, contains('flutter test --tags golden'));
        expect(content, contains('runs-on: windows-latest'));
        expect(
          content,
          isNot(contains('echo "Flutter tests completed successfully."')),
        );

        expect(content, contains('timeout-minutes: 10'));
      },
      skip: workflowFile.existsSync()
          ? false
          : 'not a monorepo checkout: .github/workflows/ci.yml is absent',
    );

    test('Codemagic pipeline analyzes and tests in every workflow', () {
      final file = File('codemagic.yaml');
      expect(file.existsSync(), isTrue,
          reason: 'codemagic.yaml must exist at the project root');
      final content = file.readAsStringSync();

      final workflows = RegExp(r'^\s+instance_type:', multiLine: true)
          .allMatches(content)
          .length;
      final analyzeSteps =
          RegExp(r'^\s+script:\s*flutter analyze\s*$', multiLine: true)
              .allMatches(content)
              .length;
      final testSteps =
          RegExp(r'^\s+script:\s*flutter test\b.*$', multiLine: true)
              .allMatches(content)
              .length;

      expect(workflows, greaterThan(0));
      expect(analyzeSteps, workflows,
          reason: 'every workflow must run flutter analyze');
      expect(testSteps, workflows,
          reason: 'every workflow must run flutter test');
      expect(
        content,
        isNot(contains('echo "Flutter tests completed successfully."')),
      );
    });

    test('at least one CI definition exists in this checkout', () {
      expect(
        workflowFile.existsSync() || File('codemagic.yaml').existsSync(),
        isTrue,
      );
    });
  });
}
