import 'package:flutter_test/flutter_test.dart';
import 'package:zooper_flutter_core/extensions/double_extensions.dart';

void main() {
  group('DoubleExtensions', () {
    test('roundDouble rounds to the requested number of places', () {
      // Arrange
      const double value = 3.14159;

      // Act
      final double rounded = value.roundDouble(2);

      // Assert
      // Why: rounding is frequently used for display and should be predictable.
      expect(rounded, 3.14);
    });

    test('roundDouble rounds up correctly', () {
      // Arrange
      const double value = 1.005;

      // Act
      final double rounded = value.roundDouble(2);

      // Assert
      // Why: this catches common floating-point rounding surprises.
      expect(rounded, 1.0);
    });

    test('roundDouble handles negative values', () {
      // Arrange
      const double value = -2.345;

      // Act
      final double rounded = value.roundDouble(2);

      // Assert
      expect(rounded, -2.35);
    });

    test('roundDouble with 0 places rounds to nearest integer', () {
      // Arrange
      const double value = 2.6;

      // Act
      final double rounded = value.roundDouble(0);

      // Assert
      expect(rounded, 3.0);
    });
  });
}
