import 'package:flutter_test/flutter_test.dart';
import 'package:zooper_flutter_core/zooper_flutter_core.dart';

class _TestDomainEvent implements ZooperDomainEvent<String> {
  _TestDomainEvent({
    required this.id,
    required this.occurredOn,
    required this.metadata,
  });

  @override
  final String id;

  @override
  final DateTime occurredOn;

  @override
  final Map<String, Object?> metadata;
}

void main() {
  group('ZooperDomainEvent', () {
    test('combines id, timestamp, and metadata contracts', () {
      // Arrange: A concrete implementation verifies the interface is usable.
      final DateTime occurredOn = DateTime.utc(2026, 1, 9);
      final Map<String, Object?> metadata = <String, Object?>{
        // This is intentionally heterogeneous to prove typing supports it.
        'correlationId': 'corr-123',
        'retryCount': 2,
        'nullableValue': null,
      };
      final _TestDomainEvent event = _TestDomainEvent(
        id: 'event-123',
        occurredOn: occurredOn,
        metadata: metadata,
      );

      // Act: Upcast to each interface to ensure the type relationships hold.
      final IdentifiedEvent<String> identifiedEvent = event;
      final TimestampedEvent timestampedEvent = event;
      final MetadataEvent metadataEvent = event;

      // Assert: The core contract is accessible through each interface.
      expect(identifiedEvent.id, 'event-123');
      expect(timestampedEvent.occurredOn, occurredOn);
      expect(metadataEvent.metadata, metadata);
    });
  });
}
