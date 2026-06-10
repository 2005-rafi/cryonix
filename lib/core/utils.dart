/// Compatibility bridge — existing imports of `core/utils.dart` still work.
/// New code should import directly from `core/extensions/` instead.
library;
export 'extensions/date_time_extensions.dart';
export 'extensions/string_extensions.dart';

import 'package:uuid/uuid.dart';

/// Generates a RFC4122 v4 UUID string.
/// Prefer using `const Uuid().v4()` directly in new code.
String generateId() => const Uuid().v4();

/// Compatibility shim — use the [DateTimeExtensions] extension instead:
/// `myDate.toMidnightUtc()` replaces `DateNormalizer.normalizeToMidnightUtc(myDate)`.
@Deprecated('Use DateTime.toMidnightUtc() extension method instead.')
class DateNormalizer {
  static DateTime normalizeToMidnightUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
