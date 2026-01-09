import 'package:flutter_test/flutter_test.dart';
import 'package:zooper_flutter_core/extensions/nullable_string_extensions.dart';

void main() {
  group('NullableStringExtensions', () {
    test('isNullOrEmpty returns true for null', () {
      // Arrange
      const String? value = null;

      // Act
      final bool result = value.isNullOrEmpty();

      // Assert
      expect(result, isTrue);
    });

    test('isNullOrEmpty returns true for empty string', () {
      // Arrange
      const String? value = '';

      // Act
      final bool result = value.isNullOrEmpty();

      // Assert
      expect(result, isTrue);
    });

    test('isNullOrEmpty returns false for non-empty string', () {
      // Arrange
      const String? value = 'x';

      // Act
      final bool result = value.isNullOrEmpty();

      // Assert
      expect(result, isFalse);
    });

    test('isNullOrWhitespace returns true for null', () {
      // Arrange
      const String? value = null;

      // Act
      final bool result = value.isNullOrWhitespace();

      // Assert
      expect(result, isTrue);
    });

    test('isNullOrWhitespace returns true for a single space', () {
      // Arrange
      const String? value = ' ';

      // Act
      final bool result = value.isNullOrWhitespace();

      // Assert
      expect(result, isTrue);
    });

    test('isNullOrWhitespace returns false for empty string', () {
      // Arrange
      const String? value = '';

      // Act
      final bool result = value.isNullOrWhitespace();

      // Assert
      // Why: current implementation treats only a single space as whitespace.
      expect(result, isFalse);
    });

    test('isNullOrWhitespace returns false for other whitespace', () {
      // Arrange
      const String? tab = '\t';

      // Act
      final bool result = tab.isNullOrWhitespace();

      // Assert
      // Why: documents the exact behavior so changes are intentional.
      expect(result, isFalse);
    });
  });
}
