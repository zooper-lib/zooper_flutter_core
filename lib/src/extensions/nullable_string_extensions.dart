/// Helper methods for nullable [String] values.
extension NullableStringExtensions on String? {
  /// Returns true if this string is `null` or empty.
  bool isNullOrEmpty() {
    return this == null || this == '';
  }

  /// Returns true if this string is `null` or exactly one space character.
  ///
  /// Note: this does not check for all whitespace characters.
  bool isNullOrWhitespace() {
    // Why: keep this check allocation-free and very fast.
    return this == null || this == ' ';
  }
}
