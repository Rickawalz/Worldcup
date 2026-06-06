import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/username_validator.dart';

void main() {
  group('UsernameValidator', () {
    test('normalizes usernames case-insensitively', () {
      expect(UsernameValidator.normalize('  Ricky_Walz  '), 'ricky_walz');
    });

    test('accepts valid usernames', () {
      expect(UsernameValidator.validate('Bracket_2026'), isNull);
    });

    test('rejects invalid and reserved usernames', () {
      expect(UsernameValidator.validate('ab'), isNotNull);
      expect(UsernameValidator.validate('bad name'), isNotNull);
      expect(UsernameValidator.validate('admin'), isNotNull);
    });
  });
}
