/// Extension methods on [DateTime] for Cryonix-specific date operations.
extension DateTimeExtensions on DateTime {
  /// Normalizes a date to midnight UTC, stripping any time component.
  /// Use this when storing session dates so that the same calendar day
  /// always resolves to the same SQLite value regardless of local timezone.
  ///
  /// Example:
  /// ```dart
  /// final sessionDate = DateTime.now().toMidnightUtc();
  /// ```
  DateTime toMidnightUtc() {
    return DateTime.utc(year, month, day);
  }

  /// Returns true if this date and [other] represent the same calendar day
  /// (in UTC), regardless of time component.
  bool isSameDayAs(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Formats this date as a compact display string, e.g. "17 May 2026".
  String toDisplayDate() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '$day ${months[month - 1]} $year';
  }
}
