DateTime? parseStoredDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }

  try {
    final dynamic raw = value;
    final seconds = raw.seconds;
    if (seconds is int) {
      final nanoseconds = raw.nanoseconds;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + (nanoseconds is int ? nanoseconds ~/ 1000000 : 0),
        isUtc: true,
      );
    }
  } catch (_) {}

  return null;
}

String? parseStoredString(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}
