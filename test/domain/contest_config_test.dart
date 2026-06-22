import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/domain/contest_submission_status.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/localization/app_strings.dart';

void main() {
  group('GlobalContestConfig submissions', () {
    test('areSubmissionsOpen requires accepting flag and future lock time', () {
      final futureLock = DateTime.now().add(const Duration(days: 1));
      final open = GlobalContestConfig(
        lockAt: futureLock,
        isAcceptingSubmissions: true,
      );
      expect(open.areSubmissionsOpen, isTrue);
      expect(open.isBracketEditingLocked, isFalse);

      final adminClosed = GlobalContestConfig(
        lockAt: futureLock,
        isAcceptingSubmissions: false,
      );
      expect(adminClosed.areSubmissionsOpen, isFalse);
      expect(adminClosed.isBracketEditingLocked, isTrue);

      final pastLock = GlobalContestConfig(
        lockAt: DateTime.now().subtract(const Duration(days: 1)),
        isAcceptingSubmissions: true,
      );
      expect(pastLock.areSubmissionsOpen, isFalse);
      expect(pastLock.isLocked, isTrue);
    expect(pastLock.isBracketEditingLocked, isTrue);
  });

  test('serializes lockAt as UTC ISO-8601 for Firestore rules', () {
    final config = GlobalContestConfig(
      lockAt: DateTime.utc(2026, 8, 11),
      isAcceptingSubmissions: true,
    );

    expect(config.toMap()['lockAt'], '2026-08-11T00:00:00.000Z');
  });
});

  group('submission status messages', () {
    test('prefers admin-closed message when toggle is off', () {
      const strings = AppStrings(Locale('en'));
      final config = GlobalContestConfig(
        lockAt: DateTime.now().subtract(const Duration(days: 1)),
        isAcceptingSubmissions: false,
      );

      expect(
        bracketEditingStatusMessage(strings, config, BracketStatus.draft),
        strings.submissionsClosedByAdmin,
      );
      expect(
        adminSubmissionStatusMessage(strings, config),
        strings.adminSubmissionsClosedByAdmin,
      );
    });

    test('shows lock-time message when only lock has passed', () {
      const strings = AppStrings(Locale('en'));
      final config = GlobalContestConfig(
        lockAt: DateTime.now().subtract(const Duration(days: 1)),
        isAcceptingSubmissions: true,
      );

      expect(
        bracketEditingStatusMessage(strings, config, BracketStatus.draft),
        strings.bracketReadOnly,
      );
    });
  });
}
