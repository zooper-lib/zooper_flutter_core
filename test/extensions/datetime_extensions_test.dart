import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

void main() {
  group('DateTimeExtensions', () {
    test('firstDayOfWeek returns Monday of the same ISO week', () {
      // Arrange
      final DateTime wednesday = DateTime.utc(2026, 1, 7); // Wednesday.

      // Act
      final DateTime monday = wednesday.firstDayOfWeek();

      // Assert
      // Why: week-start calculations are easy to get wrong (Sunday vs Monday).
      expect(monday.weekday, DateTime.monday);
      expect(monday, DateTime.utc(2026, 1, 5));
    });

    test('firstDayOfMonth returns day 1 at midnight', () {
      // Arrange
      final DateTime dateTime = DateTime(2026, 1, 20, 13, 14, 15);

      // Act
      final DateTime firstDay = dateTime.firstDayOfMonth();

      // Assert
      expect(firstDay, DateTime(2026, 1, 1));
    });

    test('lastDayOfMonth returns correct day for leap-year February', () {
      // Arrange
      final DateTime februaryLeapYear = DateTime(2024, 2, 15);

      // Act
      final DateTime lastDay = februaryLeapYear.lastDayOfMonth();

      // Assert
      // Why: leap years are a common boundary condition.
      expect(lastDay, DateTime(2024, 2, 29));
    });

    test('lastSecond returns 23:59:59 of the same day', () {
      // Arrange
      final DateTime dateTime = DateTime(2026, 1, 1, 10, 30, 45);

      // Act
      final DateTime lastSecond = dateTime.lastSecond();

      // Assert
      expect(lastSecond, DateTime(2026, 1, 1, 23, 59, 59));
    });

    test('date getter returns midnight of the same date', () {
      // Arrange
      final DateTime dateTime = DateTime(2026, 1, 1, 10, 30, 45);

      // Act
      final DateTime dateOnly = dateTime.date;

      // Assert
      expect(dateOnly, DateTime(2026, 1, 1));
    });

    test('addMonth handles end-of-month dates', () {
      // Arrange
      final DateTime january31st = DateTime.utc(2024, 1, 31);

      // Act
      final DateTime plusOneMonth = january31st.addMonth();

      // Assert
      // Why: month arithmetic at month-end is tricky (Feb has fewer days).
      expect(plusOneMonth.year, 2024);
      expect(plusOneMonth.month, 2);
      expect(plusOneMonth.day, 29);
    });

    test('subtractMonth handles end-of-month dates', () {
      // Arrange
      final DateTime march31st = DateTime.utc(2024, 3, 31);

      // Act
      final DateTime minusOneMonth = march31st.subtractMonth();

      // Assert
      expect(minusOneMonth.year, 2024);
      expect(minusOneMonth.month, 2);
      expect(minusOneMonth.day, 29);
    });

    test('toIso8601 returns a parseable ISO-8601 string', () {
      // Arrange
      final DateTime dateTime = DateTime.utc(2026, 1, 1, 12, 0, 0);

      // Act
      final String isoString = dateTime.toIso8601();

      // Assert
      // Why: this string is commonly used for storage/serialization.
      expect(() => DateTime.parse(isoString), returnsNormally);
    });

    test('format uses the given DateFormat', () {
      // Arrange
      final DateTime dateTime = DateTime(2026, 1, 2);
      final DateFormat formatter = DateFormat('yyyy-MM-dd');

      // Act
      final String result = dateTime.format(formatter);

      // Assert
      expect(result, '2026-01-02');
    });
  });
}
