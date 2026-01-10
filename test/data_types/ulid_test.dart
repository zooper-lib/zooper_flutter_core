import 'package:test/test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

void main() {
  group('Ulid', () {
    test('newUlid generates a valid ULID', () {
      // Arrange & Act
      final Ulid ulid = Ulid.newUlid();

      // Assert
      expect(Ulid.isValid(ulid.value), isTrue);
      expect(ulid.value.length, 26);
    });

    test('constructor throws for invalid ULID', () {
      // Arrange
      const String invalid = 'not-a-ulid';

      // Act & Assert
      expect(() => Ulid(invalid), throwsA(isA<FormatException>()));
    });

    test('encode/decode round-trips', () {
      // Arrange
      final Ulid original = Ulid.newUlid();

      // Act
      final String encoded = Ulid.encode(Ulid.decode(original.value));

      // Assert
      // Why: stable encoding/decoding protects persistence.
      expect(encoded, original.value);
    });

    test('timestamp matches provided timestamp', () {
      // Arrange
      final DateTime timestamp = DateTime.utc(2025, 1, 1, 0, 0, 0);

      // Act
      final Ulid ulid = Ulid.newUlid(timestamp: timestamp);

      // Assert
      // Why: being able to inject timestamps makes tests deterministic.
      expect(ulid.timestamp, timestamp);
    });

    test('zero creates canonical zero ULID', () {
      // Arrange & Act
      final Ulid ulid = Ulid.zero();

      // Assert
      expect(ulid.value, '00000000000000000000000000');
      expect(Ulid.isValid(ulid.value), isTrue);
    });
  });
}
