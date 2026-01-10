import 'dart:math';

import 'package:zooper_flutter_core/zooper_flutter_core.dart';

/// A strongly-typed identifier for domain events.
///
/// Wraps a string value to provide compile-time type safety and prevent
/// accidental interchange with other identifier types.
///
/// This is a zero-cost abstraction implemented using an extension type.
extension type const EventId(String value) {
  /// Creates a new `EventId` from a freshly generated ULID.
  ///
  /// Optional parameters allow deterministic generation for testing:
  /// - `timestamp`: UTC timestamp used for the ULID time component.
  /// - `random`: injectable randomness source.
  factory EventId.fromUlid({DateTime? timestamp, Random? random}) {
    final ulid = Ulid.generate(timestamp: timestamp, random: random);
    return EventId(ulid.toString());
  }

  /// Creates a new `EventId` from a version 4 UUID.
  ///
  /// Optional [random] can be injected for deterministic testing.
  factory EventId.fromUuid({Random? random}) {
    final uuid = Uuid.v4(random: random);
    return EventId(uuid);
  }

  /// JSON deserialization support.
  factory EventId.fromJson(String json) => EventId(json);

  /// JSON serialization support.
  String toJson() => value;
}
