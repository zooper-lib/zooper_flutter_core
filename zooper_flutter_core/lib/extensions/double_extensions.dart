import 'dart:math';

extension DoubleExtensions on double {
  /// Rounds the given number to x places
  double roundDouble(int places) {
    var mod = pow(10.0, places);
    return ((this * mod).round().toDouble() / mod);
  }
}
