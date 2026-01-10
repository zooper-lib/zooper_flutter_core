import 'dart:math';

import 'package:test/test.dart';
import 'package:zooper_flutter_core/src/strong_types/event_id.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

void main() {
  group('EventId', () {
    test('constructor preserves value, toString and equality', () {
      // Arrange
      const String raw = 'evt_123';

      // Act
      final EventId a = const EventId(raw);
      final EventId b = const EventId(raw);
      final EventId c = const EventId('evt_other');

      // Assert
      expect(a.value, raw);
      expect(a.toString(), raw);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('fromUlid generates a valid ULID', () {
      // Act
      final EventId id = EventId.fromUlid();

      // Assert
      expect(Ulid.isValid(id.value), isTrue);
      expect(id.value.length, 26);
    });

    test('fromUlid is deterministic with timestamp and random', () {
      // Arrange
      final DateTime ts = DateTime.utc(2021, 1, 1);
      final Random seedRandom = Random(123);

      // Act
      final EventId id = EventId.fromUlid(timestamp: ts, random: seedRandom);

      // Expected generated value using the same args
      final String expected = Ulid.generate(timestamp: ts, random: Random(123));

      // Assert
      expect(id.value, expected);
    });

    test('fromUuid generates a valid v4 UUID', () {
      // Act
      final EventId id = EventId.fromUuid();

      // Assert
      expect(Uuid.isValid(id.value), isTrue);
      expect(Uuid.version(id.value), equals(4));
    });

    test('fromUuid is deterministic with random', () {
      // Arrange
      final Random rnd = Random(99);

      // Act
      final EventId id = EventId.fromUuid(random: rnd);

      // Expected
      final String expected = Uuid.v4(random: Random(99));

      // Assert
      expect(id.value, expected);
    });
  });
}
