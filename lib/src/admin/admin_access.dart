import '../domain/models.dart';

class AdminAccess {
  static const adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'rgw1985@hotmail.com',
  );

  static bool get isConfigured => adminEmail.trim().isNotEmpty;

  static bool isAdmin(AppUser? user) {
    final configuredEmail = adminEmail.trim().toLowerCase();
    final userEmail = user?.email?.trim().toLowerCase();
    return configuredEmail.isNotEmpty && userEmail == configuredEmail;
  }
}
