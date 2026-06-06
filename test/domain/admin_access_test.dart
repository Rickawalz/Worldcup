import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/admin/admin_access.dart';
import 'package:world_cup_bracket/src/domain/models.dart';

void main() {
  test('admin access is enabled only for configured admin email', () {
    final admin = AppUser(
      id: 'user',
      username: 'Ricky',
      email: 'rgw1985@hotmail.com',
      createdAt: DateTime(2026),
    );
    final other = AppUser(
      id: 'other',
      username: 'Other',
      email: 'other@example.com',
      createdAt: DateTime(2026),
    );

    expect(AdminAccess.isConfigured, isTrue);
    expect(AdminAccess.isAdmin(admin), isTrue);
    expect(AdminAccess.isAdmin(other), isFalse);
  });
}
