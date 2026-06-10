/// Extension methods on [String] for Cryonix-specific text operations.
extension StringExtensions on String {
  /// Returns the string truncated to [maxLength] characters, with [suffix]
  /// appended if truncation occurred. Useful for displaying long classroom
  /// names or student names in constrained UI spaces.
  ///
  /// Example:
  /// ```dart
  /// 'Advanced Mathematics Class'.truncate(20); // 'Advanced Mathematics...'
  /// ```
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Returns this string with the first character uppercased and the rest
  /// unchanged. Handles empty strings gracefully.
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns true if this string is not null and contains at least one
  /// non-whitespace character. Use instead of `!str.isEmpty` checks.
  bool get hasContent => trim().isNotEmpty;
}
