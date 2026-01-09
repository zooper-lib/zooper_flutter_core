/// Core primitives and extensions shared across Zooper Flutter packages.
///
/// This package intentionally keeps dependencies minimal and provides small,
/// stable building blocks that other Zooper packages can rely on.
library zooper_flutter_core;

// Data types
export 'src/data_types/ulid.dart';
export 'src/data_types/uuid.dart';

// Extensions
export 'src/extensions/datetime_extensions.dart';
export 'src/extensions/double_extensions.dart';
export 'src/extensions/duration_extensions.dart';
export 'src/extensions/nullable_string_extensions.dart';
export 'src/extensions/string_extensions.dart';

// Interfaces
export 'src/interfaces/events/domain_events.dart';
