import 'package:flutter_test/flutter_test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

void main() {
  group('Uuid', () {
    test('v4 generates a valid UUID', () {
      // Arrange & Act
      final String id = Uuid.v4();

      // Assert
      expect(Uuid.isValid(id), isTrue);
      expect(Uuid.version(id), 4);
    });

    test('v7 generates a valid UUID with version 7', () {
      // Arrange & Act
      final String id = Uuid.v7();

      // Assert
      expect(Uuid.isValid(id), isTrue);
      expect(Uuid.version(id), 7);
    });

    test('v1 generates a valid UUID with version 1', () {
      // Arrange & Act
      final String id = Uuid.v1();

      // Assert
      expect(Uuid.isValid(id), isTrue);
      expect(Uuid.version(id), 1);
    });

    test('v3 is deterministic for same namespace and name', () {
      // Arrange
      const String namespaceDns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

      // Act
      final String a = Uuid.v3(namespace: namespaceDns, name: 'example.com');
      final String b = Uuid.v3(namespace: namespaceDns, name: 'example.com');

      // Assert
      // Why: name-based UUIDs must be stable.
      expect(a, b);
      expect(Uuid.version(a), 3);
    });

    test('v5 is deterministic for same namespace and name', () {
      // Arrange
      const String namespaceDns = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

      // Act
      final String a = Uuid.v5(namespace: namespaceDns, name: 'example.com');
      final String b = Uuid.v5(namespace: namespaceDns, name: 'example.com');

      // Assert
      expect(a, b);
      expect(Uuid.version(a), 5);
    });

    test('parse/formatCanonical round-trips', () {
      // Arrange
      final String id = Uuid.v4();

      // Act
      final String formatted = Uuid.formatCanonical(Uuid.parse(id));

      // Assert
      // Why: canonical formatter should be stable.
      expect(formatted, id);
    });

    test('nil is valid and has version 0', () {
      // Arrange
      final String id = Uuid.nil();

      // Act & Assert
      expect(Uuid.isValid(id), isTrue);
      expect(Uuid.version(id), 0);
    });

    test('isValid rejects non-canonical strings', () {
      // Arrange
      const String missingHyphens = 'f81d4fae7dec11d0a76500a0c91e6bf6';

      // Act & Assert
      // Why: canonical representation prevents ambiguity across packages.
      expect(Uuid.isValid(missingHyphens), isFalse);
    });
  });
}
