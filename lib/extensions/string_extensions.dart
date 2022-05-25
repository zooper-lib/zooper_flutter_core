extension StringExtensions on String {
  /// Helper to return an empty [String]
  static String get empty => '';

  Duration toDuration() {
    if (!RegExp(
            r"^(-|\+)?P(?:([-+]?[0-9,.]*)Y)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)W)?(?:([-+]?[0-9,.]*)D)?(?:T(?:([-+]?[0-9,.]*)H)?(?:([-+]?[0-9,.]*)M)?(?:([-+]?[0-9,.]*)S)?)?$")
        .hasMatch(this)) {
      throw ArgumentError("String does not follow correct format");
    }

    final weeks = _parseTime(this, "W");
    final days = _parseTime(this, "D");
    final hours = _parseTime(this, "H");
    final minutes = _parseTime(this, "M");
    final seconds = _parseTime(this, "S");

    return Duration(
      days: days + (weeks * 7),
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  /// Private helper method for extracting a time value from the ISO8601 string.
  int _parseTime(String duration, String timeUnit) {
    final timeMatch = RegExp(r"\d+" + timeUnit).firstMatch(duration);

    if (timeMatch == null) {
      return 0;
    }

    final timeString = timeMatch.group(0);

    return int.parse(timeString!.substring(0, timeString.length - 1));
  }
}
