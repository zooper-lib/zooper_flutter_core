/// A domain event that can be uniquely identified.
///
/// Most Zooper packages model domain events as immutable value objects.
/// This interface captures the common requirement that an event instance can be
/// correlated across logs, message buses, or storage using a stable identifier.
abstract interface class IdentifiedEvent<T> {
  /// The stable identifier for this event.
  ///
  /// The identifier type is intentionally generic so packages can use a `Uuid`,
  /// `Ulid`, database ID type, or other identifier primitive.
  T get id;
}

/// A domain event that carries a timestamp describing when it occurred.
///
/// Prefer representing `occurredOn` as an absolute point in time.
/// The producer of the event should define whether it uses UTC, local time, or
/// another convention.
abstract interface class TimestampedEvent {
  /// The point in time at which the event occurred.
  ///
  /// This value is used for ordering, auditing, and idempotency.
  DateTime get occurredOn;
}

/// A domain event that includes arbitrary metadata.
///
/// Metadata is intended for *cross-cutting* concerns like correlation IDs,
/// request context, environment info, or source identifiers.
abstract interface class MetadataEvent {
  /// Additional, non-domain data associated with this event.
  ///
  /// Use simple JSON-compatible values where possible.
  ///
  /// `Object?` is used instead of `dynamic` to keep typing explicit while still
  /// allowing `null` and heterogeneous values.
  Map<String, Object?> get metadata;
}

/// The standard Zooper domain event contract.
///
/// This combines identification, timestamping, and metadata into a single
/// interface to keep event handling code consistent across packages.
abstract interface class ZooperDomainEvent<T> implements IdentifiedEvent<T>, TimestampedEvent, MetadataEvent {}
