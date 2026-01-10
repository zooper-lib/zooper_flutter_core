import 'dart:math';

/// Numeric helpers for `double` values.
extension DoubleExtensions on double {
  /// Rounds this value to [places] decimal places.
  ///
  /// This uses a base-10 scaling factor to avoid string conversions.
  double roundDouble(int places) {
    final mod = pow(10.0, places);
    return ((this * mod).round().toDouble() / mod);
  }
}
