import 'package:flutter_test/flutter_test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

void main() {
  group('StringExtensions', () {
    test('empty returns an empty string', () {
      // Arrange & Act
      final String value = StringExtensions.empty;

      // Assert
      expect(value, '');
    });

    test('toDuration parses weeks', () {
      // Arrange
      const String durationString = 'P2W';

      // Act
      final Duration duration = durationString.toDuration();

      // Assert
      // Why: weeks need correct conversion into days.
      expect(duration, const Duration(days: 14));
    });

    test('toDuration parses days, hours, minutes and seconds', () {
      // Arrange
      const String durationString = 'P1DT2H3M4S';

      // Act
      final Duration duration = durationString.toDuration();

      // Assert
      expect(duration, const Duration(days: 1, hours: 2, minutes: 3, seconds: 4));
    });

    test('toDuration parses time-only durations', () {
      // Arrange
      const String durationString = 'PT45M';

      // Act
      final Duration duration = durationString.toDuration();

      // Assert
      expect(duration, const Duration(minutes: 45));
    });

    test('toDuration throws ArgumentError for invalid format', () {
      // Arrange
      const String invalid = 'not-a-duration';

      // Act & Assert
      // Why: callers should get explicit failures instead of silent parsing.
      expect(() => invalid.toDuration(), throwsA(isA<ArgumentError>()));
    });

    test('toDuration returns zero for unsupported ISO-8601 units', () {
      // Arrange
      const String durationString = 'P1Y';

      // Act
      final Duration duration = durationString.toDuration();

      // Assert
      // Why: this documents the current limitation (years/months are not
      // representable as a fixed Duration).
      expect(duration, Duration.zero);
    });
  });
}
