import '../localization/app_strings.dart';
import 'models.dart';

String bracketEditingStatusMessage(
  AppStrings strings,
  GlobalContestConfig config,
  BracketStatus status,
) {
  if (!config.areSubmissionsOpen) {
    if (!config.isAcceptingSubmissions) {
      return strings.submissionsClosedByAdmin;
    }
    return strings.bracketReadOnly;
  }
  if (status == BracketStatus.submitted) {
    return strings.bracketSubmitted;
  }
  return strings.autosaveEnabled;
}

String adminSubmissionStatusMessage(AppStrings strings, GlobalContestConfig config) {
  if (config.areSubmissionsOpen) {
    return strings.adminSubmissionsOpen(config.lockAt.toLocal().toString());
  }
  if (!config.isAcceptingSubmissions) {
    return strings.adminSubmissionsClosedByAdmin;
  }
  return strings.adminSubmissionsClosedByLock(config.lockAt.toLocal().toString());
}

String adminSubmissionStatusHint(AppStrings strings, GlobalContestConfig config) {
  if (config.areSubmissionsOpen) {
    return strings.adminSubmissionsOpenHint;
  }
  if (!config.isAcceptingSubmissions) {
    return strings.adminSubmissionsClosedByAdminHint;
  }
  return strings.adminSubmissionsClosedByLockHint;
}
