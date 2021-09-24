extension NullableStringExtensions on String? {
  /// Indicates if the Stirng is null or ""
  bool isNullOrEmpty() {
    return this == null || this == "";
  }

  /// Indicates if the Stirng is null or " "
  bool isNullOrWhitespace() {
    return this == null || this == ' ';
  }
}
