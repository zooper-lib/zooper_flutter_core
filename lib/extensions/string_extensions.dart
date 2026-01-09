/// Helper methods for non-nullable [String] values.
extension StringExtensions on String {
  /// Helper to return an empty [String]
  static String get empty => '';

  /// Parses an ISO-8601 duration string into a [Duration].
  ///
  /// Throws an [ArgumentError] when this string is not a valid ISO-8601
  /// duration representation.
  Duration toDuration() {
    // Why: validate the entire string up-front so parsing logic can stay
    // simple and predictable.
    if (!RegExp(
            r'^(-|\+)?P(?:([-+]?[0-9,.]*)Y)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)W)?(?:([-+]?[0-9,.]*)D)?(?:T(?:([-+]?[0-9,.]*)H)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)S)?)?$')
        .hasMatch(this)) {
      throw ArgumentError('String does not follow correct format');
    }

    // Why: ISO-8601 durations can specify weeks and/or date/time components.
    // We parse each supported unit independently for clarity.
    final weeks = _parseTime(this, 'W');
    final days = _parseTime(this, 'D');
    final hours = _parseTime(this, 'H');
    final minutes = _parseTime(this, 'M');
    final seconds = _parseTime(this, 'S');

    return Duration(
      days: days + (weeks * 7),
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  /// Extracts the integer value for a given ISO-8601 duration [timeUnit].
  ///
  /// Returns 0 if the unit is not present.
  int _parseTime(String duration, String timeUnit) {
    final timeMatch = RegExp(r'\d+' + timeUnit).firstMatch(duration);

    if (timeMatch == null) {
      return 0;
    }

    final timeString = timeMatch.group(0);

    return int.parse(timeString!.substring(0, timeString.length - 1));
  }
}
