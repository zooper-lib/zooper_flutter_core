import 'package:jiffy/jiffy.dart';
import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  DateTime firstDayOfWeek() {
    // The week starts with monday, not sunday!
    return subtract(Duration(days: weekday - 1));
  }

  /// Gets the first day of this month
  DateTime firstDayOfMonth() {
    return DateTime(year, month, 1);
  }

  /// Gets the last day of this month
  DateTime lastDayOfMonth() {
    return DateTime(year, month + 1, 0);
  }

  /// Gets the last second of this day
  DateTime lastSecond() {
    return DateTime(year, month, day, 23, 59, 59);
  }

  DateTime addMonth([int months = 1]) {
    return Jiffy(this).add(months: months).dateTime;
  }

  DateTime subtractMonth([int months = 1]) {
    return Jiffy(this).subtract(months: months).dateTime;
  }

  /// Gets the date with hour:0, minute:0, ...
  DateTime get date => DateTime(year, month, day);

  /// Converts the [DateTime] into an ISO8601 [String]
  ///
  /// e.g. 2021-5-25T12:00:00.000Z
  String toIso8601() => Jiffy(this).format();

  /// Formats the [DateTime] to a readable [String]
  String format(DateFormat dateFormat) => dateFormat.format(this);
}
