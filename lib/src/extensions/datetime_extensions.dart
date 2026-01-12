import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

/// Date and time helpers used across Zooper packages.
///
/// These helpers focus on common calendar operations that are easy to
/// accidentally get wrong (like month math).
extension DateTimeExtensions on DateTime {
  /// Returns the first day of the week containing this date.
  ///
  /// This follows the ISO-8601 convention where weeks start on Monday.
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

  /// Adds [months] months to this date.
  ///
  /// This delegates to Jiffy to handle edge cases (like adding one month to
  /// the 31st of a month).
  DateTime addMonth([int months = 1]) {
    return Jiffy.parseFromDateTime(this).add(months: months).dateTime;
  }

  /// Subtracts [months] months from this date.
  ///
  /// This delegates to Jiffy to handle edge cases (like subtracting one month
  /// from the 31st of a month).
  DateTime subtractMonth([int months = 1]) {
    return Jiffy.parseFromDateTime(this).subtract(months: months).dateTime;
  }

  /// Gets the date with hour:0, minute:0, ...
  DateTime get date => DateTime(year, month, day);

  /// Converts the [DateTime] into an ISO8601 [String]
  ///
  /// This uses Jiffy's default ISO-8601 formatting.
  String toIso8601() => Jiffy.parseFromDateTime(this).format();

  /// Formats the [DateTime] to a readable [String]
  String format(DateFormat dateFormat) => dateFormat.format(this);
}
