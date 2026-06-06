class UsernameValidator {
  static final _validPattern = RegExp(r'^[A-Za-z0-9_]{3,20}$');

  static const _reserved = {
    'admin',
    'administrator',
    'api',
    'firebase',
    'fifa',
    'moderator',
    'support',
    'worldcup',
  };

  static String normalize(String username) {
    return username.trim().toLowerCase();
  }

  static String? validate(String username) {
    final normalized = normalize(username);
    if (!_validPattern.hasMatch(username.trim())) {
      return 'Use 3-20 letters, numbers, or underscores.';
    }
    if (_reserved.contains(normalized)) {
      return 'That username is reserved.';
    }
    return null;
  }
}
