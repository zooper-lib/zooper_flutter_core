/// Convenience helpers for working with [Duration] values.
extension DurationExtensions on Duration {
  /// Returns the days as double
  double get totalDays => inMicroseconds / Duration.microsecondsPerDay;

  /// Returns the hours as double
  double get totalHours => inMicroseconds / Duration.microsecondsPerHour;

  /// Returns the minutes as double
  double get totalMinutes => inMicroseconds / Duration.microsecondsPerMinute;

  /// Returns the seconds as double
  double get totalSeconds => inMicroseconds / Duration.microsecondsPerSecond;

  /// Formats this duration as a zero-padded `HH:mm` string.
  String toHoursMinutes() {
    final String twoDigitMinutes = _toTwoDigits(inMinutes.remainder(60));
    return '${_toTwoDigits(inHours)}:$twoDigitMinutes';
  }

  /// Formats this duration as a zero-padded `HH:mm:ss` string.
  String toHoursMinutesSeconds() {
    final String twoDigitMinutes = _toTwoDigits(inMinutes.remainder(60));
    final String twoDigitSeconds = _toTwoDigits(inSeconds.remainder(60));
    return '${_toTwoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  /// Returns [n] as a zero-padded 2-digit string.
  String _toTwoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
}
