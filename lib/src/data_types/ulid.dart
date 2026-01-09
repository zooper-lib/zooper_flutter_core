import 'dart:math';
import 'dart:typed_data';

/// A ULID (Universally Unique Lexicographically Sortable Identifier).
///
/// ULIDs are 128-bit identifiers typically encoded as a 26-character Crockford
/// Base32 string.
class Ulid {
  /// The number of bytes in the ULID binary representation.
  static const int _byteLength = 16;

  /// The number of characters in the canonical ULID string representation.
  static const int _encodedLength = 26;

  /// Crockford Base32 alphabet used for ULID encoding.
  ///
  /// ULID intentionally omits easily-confused characters like `I`, `L`, and
  /// `O`.
  static const String _crockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Lookup table for decoding Crockford Base32 characters.
  ///
  /// This accepts both uppercase and lowercase characters.
  static final Map<int, int> _decodeTable = _buildDecodeTable();

  /// The canonical ULID string value.
  final String value;

  /// Creates a ULID from an existing ULID string.
  ///
  /// Throws a [FormatException] if [value] is invalid.
  Ulid(this.value) {
    if (!Ulid.isValid(value)) {
      throw FormatException('Invalid ULID: $value');
    }
  }

  /// Creates the "zero" ULID (all bits set to zero).
  Ulid.zero() : value = '00000000000000000000000000';

  /// Generates a new ULID using the current time.
  ///
  /// If [timestamp] is provided it is used (UTC) for deterministic generation.
  /// If [random] is provided it is used for the randomness portion.
  Ulid.newUlid({DateTime? timestamp, Random? random}) : value = Ulid.generate(timestamp: timestamp, random: random);

  /// Generates a new ULID string.
  static String generate({DateTime? timestamp, Random? random}) {
    final DateTime resolvedTimestamp = (timestamp ?? DateTime.now()).toUtc();
    final int milliseconds = resolvedTimestamp.millisecondsSinceEpoch;

    if (milliseconds < 0 || milliseconds > 0xFFFFFFFFFFFF) {
      throw RangeError('timestamp is out of range for ULID (48-bit ms).');
    }

    final Uint8List bytes = Uint8List(_byteLength);

    // First 48 bits = timestamp.
    bytes[0] = (milliseconds >> 40) & 0xFF;
    bytes[1] = (milliseconds >> 32) & 0xFF;
    bytes[2] = (milliseconds >> 24) & 0xFF;
    bytes[3] = (milliseconds >> 16) & 0xFF;
    bytes[4] = (milliseconds >> 8) & 0xFF;
    bytes[5] = milliseconds & 0xFF;

    // Remaining 80 bits = randomness.
    final Random resolvedRandom = random ?? _secureRandomOrThrow();
    for (int index = 6; index < _byteLength; index++) {
      // Byte-wise generation avoids modulo bias.
      bytes[index] = resolvedRandom.nextInt(256);
    }

    return encode(bytes);
  }

  /// Encodes 16 bytes into the canonical 26-character Crockford Base32 ULID.
  static String encode(Uint8List bytes) {
    if (bytes.length != _byteLength) {
      throw RangeError('ULID must be 16 bytes.');
    }

    // We convert 128 bits into 26 * 5 = 130 bits; the top 2 bits are zero.
    final StringBuffer stringBuffer = StringBuffer();

    int bitBuffer = 0;
    int bitBufferLength = 0;

    for (final int byteValue in bytes) {
      bitBuffer = (bitBuffer << 8) | (byteValue & 0xFF);
      bitBufferLength += 8;

      while (bitBufferLength >= 5) {
        final int shift = bitBufferLength - 5;
        final int index = (bitBuffer >> shift) & 0x1F;
        stringBuffer.write(_crockfordAlphabet[index]);
        bitBufferLength -= 5;
        bitBuffer = bitBuffer & ((1 << bitBufferLength) - 1);
      }
    }

    if (bitBufferLength > 0) {
      final int index = (bitBuffer << (5 - bitBufferLength)) & 0x1F;
      stringBuffer.write(_crockfordAlphabet[index]);
    }

    final String encoded = stringBuffer.toString();

    // ULID encoding must always produce exactly 26 characters.
    if (encoded.length != _encodedLength) {
      throw StateError(
        'ULID encoding produced unexpected length ${encoded.length}.',
      );
    }

    return encoded;
  }

  /// Decodes a ULID string into 16 bytes.
  ///
  /// Throws a [FormatException] if [value] is invalid.
  static Uint8List decode(String value) {
    if (!isValid(value)) {
      throw FormatException('Invalid ULID: $value');
    }

    // ULID is 26 chars of 5 bits -> 130 bits. We discard the top 2 bits.
    final Uint8List bytes = Uint8List(_byteLength);

    int bitBuffer = 0;
    int bitBufferLength = 0;

    int byteIndex = 0;

    for (int index = 0; index < value.length; index++) {
      final int codeUnit = value.codeUnitAt(index);
      final int digitValue = _decodeTable[codeUnit] ?? -1;

      if (digitValue < 0) {
        throw FormatException('Invalid ULID character: ${value[index]}');
      }

      bitBuffer = (bitBuffer << 5) | digitValue;
      bitBufferLength += 5;

      while (bitBufferLength >= 8 && byteIndex < _byteLength) {
        final int shift = bitBufferLength - 8;
        bytes[byteIndex] = (bitBuffer >> shift) & 0xFF;
        byteIndex++;
        bitBufferLength -= 8;
        bitBuffer = bitBuffer & ((1 << bitBufferLength) - 1);
      }
    }

    return bytes;
  }

  /// Returns true if [value] is a canonical ULID string.
  static bool isValid(String? value) {
    if (value == null) {
      return false;
    }

    if (value.length != _encodedLength) {
      return false;
    }

    // The first character encodes the top 5 bits. For ULID, the top 2 bits must
    // be zero because we only have 128 bits of data.
    final int firstDigit = _decodeTable[value.codeUnitAt(0)] ?? -1;
    if (firstDigit < 0 || firstDigit > 7) {
      return false;
    }

    for (int index = 0; index < value.length; index++) {
      final int codeUnit = value.codeUnitAt(index);
      if (!_decodeTable.containsKey(codeUnit)) {
        return false;
      }
    }

    return true;
  }

  /// Returns the timestamp embedded in this ULID.
  DateTime get timestamp {
    final Uint8List bytes = Ulid.decode(value);

    // First 48 bits are milliseconds since Unix epoch.
    final int milliseconds = (bytes[0] << 40) | (bytes[1] << 32) | (bytes[2] << 24) | (bytes[3] << 16) | (bytes[4] << 8) | bytes[5];

    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  /// Returns the ULID string.
  @override
  String toString() {
    return value;
  }

  /// Compares ULIDs by their canonical string value.
  @override
  bool operator ==(Object other) {
    if (other is Ulid) {
      return value == other.value;
    }

    if (other is String) {
      return value == other;
    }

    return false;
  }

  /// Returns a hashCode consistent with [operator==].
  @override
  int get hashCode {
    return value.hashCode;
  }

  /// Builds the lookup table used by [decode] and [isValid].
  ///
  /// Crockford Base32 commonly treats `I`/`L` as `1` and `O` as `0`.
  static Map<int, int> _buildDecodeTable() {
    final Map<int, int> table = <int, int>{};

    for (int index = 0; index < _crockfordAlphabet.length; index++) {
      final int upper = _crockfordAlphabet.codeUnitAt(index);
      table[upper] = index;

      // Why: allow lowercase input without requiring callers to normalize.
      final int lower = String.fromCharCode(upper).toLowerCase().codeUnitAt(0);
      table[lower] = index;
    }

    // Crockford commonly allows I/L -> 1 and O -> 0.
    table['I'.codeUnitAt(0)] = 1;
    table['i'.codeUnitAt(0)] = 1;
    table['L'.codeUnitAt(0)] = 1;
    table['l'.codeUnitAt(0)] = 1;
    table['O'.codeUnitAt(0)] = 0;
    table['o'.codeUnitAt(0)] = 0;

    return table;
  }

  /// Returns a cryptographically secure random number generator.
  ///
  /// Throws a [StateError] on platforms that do not support [Random.secure].
  static Random _secureRandomOrThrow() {
    try {
      return Random.secure();
    } on Object catch (error) {
      throw StateError(
        'Secure random is unavailable on this platform. '
        'Pass a Random instance explicitly. Underlying error: $error',
      );
    }
  }
}
