import 'package:flutter_test/flutter_test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

void main() {
  group('DurationExtensions', () {
    test('totalDays returns fractional days', () {
      // Arrange
      const Duration duration = Duration(hours: 12);

      // Act
      final double days = duration.totalDays;

      // Assert
      // Why: callers often need fractional values for reporting.
      expect(days, 0.5);
    });

    test('totalHours returns fractional hours', () {
      // Arrange
      const Duration duration = Duration(minutes: 90);

      // Act
      final double hours = duration.totalHours;

      // Assert
      expect(hours, 1.5);
    });

    test('toHoursMinutes formats with zero-padding', () {
      // Arrange
      const Duration duration = Duration(hours: 5, minutes: 7);

      // Act
      final String formatted = duration.toHoursMinutes();

      // Assert
      // Why: formatting must stay stable for UI snapshots and exports.
      expect(formatted, '05:07');
    });

    test('toHoursMinutesSeconds formats with zero-padding', () {
      // Arrange
      const Duration duration = Duration(hours: 5, minutes: 7, seconds: 9);

      // Act
      final String formatted = duration.toHoursMinutesSeconds();

      // Assert
      expect(formatted, '05:07:09');
    });

    test('toHoursMinutesSeconds handles durations longer than 24 hours', () {
      // Arrange
      const Duration duration = Duration(hours: 27, minutes: 15, seconds: 0);

      // Act
      final String formatted = duration.toHoursMinutesSeconds();

      // Assert
      // Why: durations represent spans, not wall-clock times.
      expect(formatted, '27:15:00');
    });
  });
}
