import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// A minimal, dependency-free UUID implementation.
///
/// This implements RFC 9562 UUIDs and supports generating UUID versions 1–8.
/// It also provides parsing, formatting, and validation helpers.
class Uuid {
  /// The number of bytes in a UUID.
  static const int byteLength = 16;

  /// The canonical string length of a UUID (36 characters including hyphens).
  static const int canonicalStringLength = 36;

  /// Number of 100-nanosecond intervals between the UUID epoch
  /// (1582-10-15T00:00:00Z) and Unix epoch (1970-01-01T00:00:00Z).
  static const int _uuidEpochOffset100ns = 0x01B21DD213814000;

  /// Returns the nil UUID string.
  static String nil() {
    return '00000000-0000-0000-0000-000000000000';
  }

  /// Generates an RFC 9562 version 1 (time-based) UUID.
  ///
  /// If [timestamp] is omitted, the current UTC time is used.
  /// If [node] is omitted, a random 48-bit node id is generated.
  /// If [clockSequence] is omitted, a random 14-bit clock sequence is used.
  static String v1({
    DateTime? timestamp,
    List<int>? node,
    int? clockSequence,
    Random? random,
  }) {
    final DateTime resolvedTimestamp = (timestamp ?? DateTime.now()).toUtc();

    // UUID v1 uses 100ns ticks since 1582-10-15.
    final int uuidTimestamp100ns = (resolvedTimestamp.microsecondsSinceEpoch * 10) + _uuidEpochOffset100ns;

    final Uint8List nodeBytes = _resolveNodeBytes(node, random: random);
    final int resolvedClockSequence = _resolveClockSequence(clockSequence, random: random);

    final int timeLow = uuidTimestamp100ns & 0xFFFFFFFF;
    final int timeMid = (uuidTimestamp100ns >> 32) & 0xFFFF;
    final int timeHigh = (uuidTimestamp100ns >> 48) & 0x0FFF;

    final int clockSequenceLow = resolvedClockSequence & 0xFF;
    final int clockSequenceHigh = (resolvedClockSequence >> 8) & 0x3F;

    final Uint8List bytes = Uint8List(byteLength);

    _writeUint32BE(bytes, 0, timeLow);
    _writeUint16BE(bytes, 4, timeMid);

    // Set version to 1.
    _writeUint16BE(bytes, 6, (timeHigh | (1 << 12)));

    // Set variant to RFC 4122 (10xxxxxx).
    bytes[8] = (clockSequenceHigh | 0x80) & 0xFF;
    bytes[9] = clockSequenceLow;

    // Node.
    bytes.setRange(10, 16, nodeBytes);

    return formatCanonical(bytes);
  }

  /// Generates an RFC 9562 version 2 (DCE Security) UUID.
  ///
  /// Version 2 is rarely used. This implementation follows the traditional
  /// layout where the first 32 bits of [v1] are replaced with a local
  /// identifier and the clock sequence high byte encodes a domain.
  ///
  /// [localIdentifier] must fit into 32 bits.
  /// [domain] must be 0 (person), 1 (group), or 2 (org).
  static String v2({
    required int localIdentifier,
    required int domain,
    DateTime? timestamp,
    List<int>? node,
    int? clockSequence,
    Random? random,
  }) {
    if (localIdentifier < 0 || localIdentifier > 0xFFFFFFFF) {
      throw RangeError(
        'localIdentifier must fit into 32 bits (0..0xFFFFFFFF).',
      );
    }
    if (domain < 0 || domain > 2) {
      throw RangeError('domain must be 0, 1, or 2.');
    }

    final Uint8List bytes = parse(v1(timestamp: timestamp, node: node, clockSequence: clockSequence, random: random));

    // Replace time_low with the local identifier.
    _writeUint32BE(bytes, 0, localIdentifier);

    // Encode domain into the most significant 8 bits of the clock sequence.
    // This is the conventional DCE variant encoding.
    bytes[9] = domain & 0xFF;

    // Set version to 2 (keeping variant bits intact).
    bytes[6] = (bytes[6] & 0x0F) | 0x20;

    return formatCanonical(bytes);
  }

  /// Generates an RFC 9562 version 3 (name-based, MD5) UUID.
  static String v3({required String namespace, required String name}) {
    final Uint8List namespaceBytes = parse(namespace);
    final Uint8List nameBytes = Uint8List.fromList(utf8.encode(name));

    final Uint8List toHash = Uint8List(namespaceBytes.length + nameBytes.length);
    toHash.setRange(0, namespaceBytes.length, namespaceBytes);
    toHash.setRange(namespaceBytes.length, toHash.length, nameBytes);

    final Uint8List digest = _Md5().hash(toHash);

    _applyVersionAndVariant(digest, version: 3);
    return formatCanonical(digest);
  }

  /// Generates an RFC 9562 version 4 (random) UUID.
  static String v4({Random? random}) {
    final Uint8List bytes = _randomBytes(byteLength, random: random);

    _applyVersionAndVariant(bytes, version: 4);
    return formatCanonical(bytes);
  }

  /// Generates an RFC 9562 version 5 (name-based, SHA-1) UUID.
  static String v5({required String namespace, required String name}) {
    final Uint8List namespaceBytes = parse(namespace);
    final Uint8List nameBytes = Uint8List.fromList(utf8.encode(name));

    final Uint8List toHash = Uint8List(namespaceBytes.length + nameBytes.length);
    toHash.setRange(0, namespaceBytes.length, namespaceBytes);
    toHash.setRange(namespaceBytes.length, toHash.length, nameBytes);

    final Uint8List digest20 = _Sha1().hash(toHash);
    final Uint8List digest16 = Uint8List.fromList(digest20.sublist(0, 16));

    _applyVersionAndVariant(digest16, version: 5);
    return formatCanonical(digest16);
  }

  /// Generates an RFC 9562 version 6 (reordered time) UUID.
  ///
  /// v6 is time-ordered like v1 but rearranges the timestamp bits to improve
  /// database index locality.
  static String v6({
    DateTime? timestamp,
    List<int>? node,
    int? clockSequence,
    Random? random,
  }) {
    final DateTime resolvedTimestamp = (timestamp ?? DateTime.now()).toUtc();

    final int uuidTimestamp100ns = (resolvedTimestamp.microsecondsSinceEpoch * 10) + _uuidEpochOffset100ns;

    final Uint8List nodeBytes = _resolveNodeBytes(node, random: random);
    final int resolvedClockSequence = _resolveClockSequence(clockSequence, random: random);

    // In v6, the 60-bit timestamp is laid out as:
    // time_high (32 bits), time_mid (16 bits), time_low (12 bits)
    final int timestamp60 = uuidTimestamp100ns & 0x0FFFFFFFFFFFFFFF;

    final int timeHigh32 = (timestamp60 >> 28) & 0xFFFFFFFF;
    final int timeMid16 = (timestamp60 >> 12) & 0xFFFF;
    final int timeLow12 = timestamp60 & 0x0FFF;

    final int clockSequenceLow = resolvedClockSequence & 0xFF;
    final int clockSequenceHigh = (resolvedClockSequence >> 8) & 0x3F;

    final Uint8List bytes = Uint8List(byteLength);

    _writeUint32BE(bytes, 0, timeHigh32);
    _writeUint16BE(bytes, 4, timeMid16);

    // Set version to 6.
    _writeUint16BE(bytes, 6, (timeLow12 | (6 << 12)));

    // Variant.
    bytes[8] = (clockSequenceHigh | 0x80) & 0xFF;
    bytes[9] = clockSequenceLow;

    // Node.
    bytes.setRange(10, 16, nodeBytes);

    return formatCanonical(bytes);
  }

  /// Generates an RFC 9562 version 7 (Unix epoch time-ordered) UUID.
  ///
  /// v7 encodes a 48-bit millisecond Unix timestamp followed by random bits.
  static String v7({DateTime? timestamp, Random? random}) {
    final DateTime resolvedTimestamp = (timestamp ?? DateTime.now()).toUtc();

    final int milliseconds = resolvedTimestamp.millisecondsSinceEpoch;
    if (milliseconds < 0 || milliseconds > 0xFFFFFFFFFFFF) {
      throw RangeError('timestamp is out of range for UUID v7 (48-bit ms).');
    }

    final Uint8List bytes = _randomBytes(byteLength, random: random);

    // Write 48-bit timestamp big-endian.
    bytes[0] = (milliseconds >> 40) & 0xFF;
    bytes[1] = (milliseconds >> 32) & 0xFF;
    bytes[2] = (milliseconds >> 24) & 0xFF;
    bytes[3] = (milliseconds >> 16) & 0xFF;
    bytes[4] = (milliseconds >> 8) & 0xFF;
    bytes[5] = milliseconds & 0xFF;

    // Set version to 7.
    bytes[6] = (bytes[6] & 0x0F) | 0x70;

    // Set variant.
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    return formatCanonical(bytes);
  }

  /// Generates an RFC 9562 version 8 (custom) UUID.
  ///
  /// [customBytes] must be 16 bytes. Version and variant bits are overwritten
  /// to guarantee a valid RFC UUID encoding.
  static String v8({required List<int> customBytes}) {
    if (customBytes.length != byteLength) {
      throw RangeError('customBytes must be exactly 16 bytes.');
    }

    final Uint8List bytes = Uint8List.fromList(customBytes);
    _applyVersionAndVariant(bytes, version: 8);
    return formatCanonical(bytes);
  }

  /// Parses a canonical UUID string into 16 bytes.
  ///
  /// Accepts lower/upper case hex and requires the canonical hyphen positions.
  static Uint8List parse(String value) {
    if (!isValid(value)) {
      throw FormatException('Invalid UUID: $value');
    }

    // Special-case nil to avoid variant/version constraints.
    if (value == nil()) {
      return Uint8List(byteLength);
    }

    final String normalized = value.toLowerCase();
    final Uint8List bytes = Uint8List(byteLength);

    int byteIndex = 0;
    int i = 0;
    while (i < normalized.length) {
      final int codeUnit = normalized.codeUnitAt(i);
      if (codeUnit == 45 /* '-' */ ) {
        i++;
        continue;
      }

      final int high = _hexDigitToInt(codeUnit);
      final int low = _hexDigitToInt(normalized.codeUnitAt(i + 1));
      bytes[byteIndex] = (high << 4) | low;
      byteIndex++;
      i += 2;
    }

    return bytes;
  }

  /// Formats 16 UUID bytes into the canonical hyphenated representation.
  static String formatCanonical(List<int> bytes) {
    if (bytes.length != byteLength) {
      throw RangeError('UUID must be 16 bytes.');
    }

    final StringBuffer stringBuffer = StringBuffer();

    for (int index = 0; index < bytes.length; index++) {
      // Hyphen placement (8-4-4-4-12).
      if (index == 4 || index == 6 || index == 8 || index == 10) {
        stringBuffer.write('-');
      }

      final int value = bytes[index] & 0xFF;
      final String hex = value.toRadixString(16).padLeft(2, '0');
      stringBuffer.write(hex);
    }

    return stringBuffer.toString();
  }

  /// Returns true if [value] is a canonical UUID string (or nil).
  static bool isValid(String? value) {
    if (value == null) {
      return false;
    }
    if (value.length != canonicalStringLength) {
      return false;
    }

    // Fast path: nil is always considered valid.
    if (value == nil()) {
      return true;
    }

    // Validate hyphen positions first.
    if (value.codeUnitAt(8) != 45 || value.codeUnitAt(13) != 45 || value.codeUnitAt(18) != 45 || value.codeUnitAt(23) != 45) {
      return false;
    }

    // Validate hex digits and collect version/variant.
    for (int index = 0; index < value.length; index++) {
      if (index == 8 || index == 13 || index == 18 || index == 23) {
        continue;
      }

      final int codeUnit = value.codeUnitAt(index);
      final bool isHex = (codeUnit >= 48 && codeUnit <= 57) || (codeUnit >= 65 && codeUnit <= 70) || (codeUnit >= 97 && codeUnit <= 102);
      if (!isHex) {
        return false;
      }
    }

    final int versionNibble = _hexDigitToInt(value.codeUnitAt(14));
    if (versionNibble < 1 || versionNibble > 8) {
      return false;
    }

    // Variant is the high bits of the 17th byte (string position 19).
    final int variantNibble = _hexDigitToInt(value.codeUnitAt(19));
    final bool isRfc4122Variant = (variantNibble & 0x8) == 0x8 && (variantNibble & 0x4) == 0x0;
    if (!isRfc4122Variant) {
      return false;
    }

    return true;
  }

  /// Extracts the UUID version number from [value].
  ///
  /// Throws if [value] is not a valid UUID string.
  static int version(String value) {
    if (!isValid(value)) {
      throw FormatException('Invalid UUID: $value');
    }

    if (value == nil()) {
      return 0;
    }

    return _hexDigitToInt(value.codeUnitAt(14));
  }

  /// Applies the UUID [version] and RFC 4122 variant bits to [bytes].
  static void _applyVersionAndVariant(Uint8List bytes, {required int version}) {
    // Version nibble is the high 4 bits of byte 6.
    bytes[6] = (bytes[6] & 0x0F) | ((version & 0x0F) << 4);

    // Variant is the high 2 bits of byte 8, RFC 4122 = 10.
    bytes[8] = (bytes[8] & 0x3F) | 0x80;
  }

  /// Resolves a 48-bit node identifier.
  static Uint8List _resolveNodeBytes(List<int>? node, {Random? random}) {
    if (node != null) {
      if (node.length != 6) {
        throw RangeError('node must be exactly 6 bytes.');
      }
      return Uint8List.fromList(node);
    }

    final Uint8List generated = _randomBytes(6, random: random);

    // Set multicast bit to indicate this is not a real MAC address.
    generated[0] = generated[0] | 0x01;

    return generated;
  }

  /// Resolves a 14-bit clock sequence.
  static int _resolveClockSequence(int? clockSequence, {Random? random}) {
    if (clockSequence != null) {
      if (clockSequence < 0 || clockSequence > 0x3FFF) {
        throw RangeError('clockSequence must be 0..0x3FFF (14 bits).');
      }
      return clockSequence;
    }

    final Uint8List bytes = _randomBytes(2, random: random);
    return ((bytes[0] << 8) | bytes[1]) & 0x3FFF;
  }

  /// Creates random bytes.
  static Uint8List _randomBytes(int length, {Random? random}) {
    final Random resolvedRandom = random ?? _secureRandomOrThrow();

    final Uint8List bytes = Uint8List(length);
    for (int index = 0; index < length; index++) {
      // We generate bytes directly to avoid bias from larger ranges.
      bytes[index] = resolvedRandom.nextInt(256);
    }

    return bytes;
  }

  /// Returns a secure random instance or throws with actionable guidance.
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

/// Writes a 16-bit unsigned integer in big-endian to [bytes] at [offset].
void _writeUint16BE(Uint8List bytes, int offset, int value) {
  bytes[offset] = (value >> 8) & 0xFF;
  bytes[offset + 1] = value & 0xFF;
}

/// Writes a 32-bit unsigned integer in big-endian to [bytes] at [offset].
void _writeUint32BE(Uint8List bytes, int offset, int value) {
  bytes[offset] = (value >> 24) & 0xFF;
  bytes[offset + 1] = (value >> 16) & 0xFF;
  bytes[offset + 2] = (value >> 8) & 0xFF;
  bytes[offset + 3] = value & 0xFF;
}

/// Converts a single ASCII hex digit code unit into its integer value.
int _hexDigitToInt(int codeUnit) {
  if (codeUnit >= 48 && codeUnit <= 57) {
    return codeUnit - 48;
  }
  if (codeUnit >= 65 && codeUnit <= 70) {
    return codeUnit - 55;
  }
  if (codeUnit >= 97 && codeUnit <= 102) {
    return codeUnit - 87;
  }

  throw FormatException('Invalid hex digit: ${String.fromCharCode(codeUnit)}');
}

/// A minimal MD5 implementation used only for UUID v3.
class _Md5 {
  /// Per-round left-rotation amounts used by the MD5 compression function.
  static const List<int> _shiftAmounts = <int>[
    7,
    12,
    17,
    22,
    7,
    12,
    17,
    22,
    7,
    12,
    17,
    22,
    7,
    12,
    17,
    22,
    5,
    9,
    14,
    20,
    5,
    9,
    14,
    20,
    5,
    9,
    14,
    20,
    5,
    9,
    14,
    20,
    4,
    11,
    16,
    23,
    4,
    11,
    16,
    23,
    4,
    11,
    16,
    23,
    4,
    11,
    16,
    23,
    6,
    10,
    15,
    21,
    6,
    10,
    15,
    21,
    6,
    10,
    15,
    21,
    6,
    10,
    15,
    21,
  ];

  /// Table of constants derived from the sine function.
  ///
  /// This is part of the MD5 specification.
  static const List<int> _table = <int>[
    0xd76aa478,
    0xe8c7b756,
    0x242070db,
    0xc1bdceee,
    0xf57c0faf,
    0x4787c62a,
    0xa8304613,
    0xfd469501,
    0x698098d8,
    0x8b44f7af,
    0xffff5bb1,
    0x895cd7be,
    0x6b901122,
    0xfd987193,
    0xa679438e,
    0x49b40821,
    0xf61e2562,
    0xc040b340,
    0x265e5a51,
    0xe9b6c7aa,
    0xd62f105d,
    0x02441453,
    0xd8a1e681,
    0xe7d3fbc8,
    0x21e1cde6,
    0xc33707d6,
    0xf4d50d87,
    0x455a14ed,
    0xa9e3e905,
    0xfcefa3f8,
    0x676f02d9,
    0x8d2a4c8a,
    0xfffa3942,
    0x8771f681,
    0x6d9d6122,
    0xfde5380c,
    0xa4beea44,
    0x4bdecfa9,
    0xf6bb4b60,
    0xbebfbc70,
    0x289b7ec6,
    0xeaa127fa,
    0xd4ef3085,
    0x04881d05,
    0xd9d4d039,
    0xe6db99e5,
    0x1fa27cf8,
    0xc4ac5665,
    0xf4292244,
    0x432aff97,
    0xab9423a7,
    0xfc93a039,
    0x655b59c3,
    0x8f0ccc92,
    0xffeff47d,
    0x85845dd1,
    0x6fa87e4f,
    0xfe2ce6e0,
    0xa3014314,
    0x4e0811a1,
    0xf7537e82,
    0xbd3af235,
    0x2ad7d2bb,
    0xeb86d391,
  ];

  /// Hashes [input] and returns a 16-byte digest.
  Uint8List hash(Uint8List input) {
    // We implement MD5 directly to avoid pulling a dependency into core.

    int a = 0x67452301;
    int b = 0xefcdab89;
    int c = 0x98badcfe;
    int d = 0x10325476;

    final Uint8List padded = _pad(input);

    for (int offset = 0; offset < padded.length; offset += 64) {
      final List<int> m = _decodeLittleEndianWords(padded, offset);

      int aa = a;
      int bb = b;
      int cc = c;
      int dd = d;

      for (int i = 0; i < 64; i++) {
        int f;
        int g;

        if (i < 16) {
          f = (bb & cc) | ((~bb) & dd);
          g = i;
        } else if (i < 32) {
          f = (dd & bb) | ((~dd) & cc);
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = bb ^ cc ^ dd;
          g = (3 * i + 5) % 16;
        } else {
          f = cc ^ (bb | (~dd));
          g = (7 * i) % 16;
        }

        final int temp = dd;
        dd = cc;
        cc = bb;

        final int sum = (aa + f + _table[i] + m[g]) & 0xFFFFFFFF;
        bb = (bb + _leftRotate32(sum, _shiftAmounts[i])) & 0xFFFFFFFF;
        aa = temp;
      }

      a = (a + aa) & 0xFFFFFFFF;
      b = (b + bb) & 0xFFFFFFFF;
      c = (c + cc) & 0xFFFFFFFF;
      d = (d + dd) & 0xFFFFFFFF;
    }

    final Uint8List digest = Uint8List(16);
    _writeUint32LE(digest, 0, a);
    _writeUint32LE(digest, 4, b);
    _writeUint32LE(digest, 8, c);
    _writeUint32LE(digest, 12, d);
    return digest;
  }

  /// Pads [input] to the 512-bit block boundary required by MD5.
  ///
  /// This appends a `1` bit, then zero bits, then the original message length
  /// in bits as a 64-bit little-endian integer.
  Uint8List _pad(Uint8List input) {
    final int bitLength = input.length * 8;

    // Padding: 0x80 then zeros until length ≡ 56 (mod 64), then 64-bit length.
    int paddedLength = input.length + 1;
    while ((paddedLength % 64) != 56) {
      paddedLength++;
    }
    paddedLength += 8;

    final Uint8List padded = Uint8List(paddedLength);
    padded.setRange(0, input.length, input);
    padded[input.length] = 0x80;

    // Append original length in bits as little-endian 64-bit.
    _writeUint32LE(padded, paddedLength - 8, bitLength & 0xFFFFFFFF);
    _writeUint32LE(padded, paddedLength - 4, (bitLength >> 32) & 0xFFFFFFFF);

    return padded;
  }

  /// Decodes 16 little-endian 32-bit words from [bytes] starting at [offset].
  List<int> _decodeLittleEndianWords(Uint8List bytes, int offset) {
    final List<int> words = List<int>.filled(16, 0);
    for (int i = 0; i < 16; i++) {
      final int wordOffset = offset + (i * 4);
      // Why: MD5 operates on little-endian 32-bit words.
      words[i] = (bytes[wordOffset]) | (bytes[wordOffset + 1] << 8) | (bytes[wordOffset + 2] << 16) | (bytes[wordOffset + 3] << 24);
    }
    return words;
  }
}

/// A minimal SHA-1 implementation used only for UUID v5.
class _Sha1 {
  /// Hashes [input] and returns a 20-byte digest.
  Uint8List hash(Uint8List input) {
    // We implement SHA-1 directly to avoid pulling a dependency into core.

    int h0 = 0x67452301;
    int h1 = 0xEFCDAB89;
    int h2 = 0x98BADCFE;
    int h3 = 0x10325476;
    int h4 = 0xC3D2E1F0;

    final Uint8List padded = _pad(input);

    final List<int> w = List<int>.filled(80, 0);

    for (int offset = 0; offset < padded.length; offset += 64) {
      for (int i = 0; i < 16; i++) {
        final int base = offset + (i * 4);
        w[i] = ((padded[base] << 24) | (padded[base + 1] << 16) | (padded[base + 2] << 8) | (padded[base + 3])) & 0xFFFFFFFF;
      }

      for (int i = 16; i < 80; i++) {
        w[i] = _leftRotate32(
          (w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16]) & 0xFFFFFFFF,
          1,
        );
      }

      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;

      for (int i = 0; i < 80; i++) {
        int f;
        int k;

        if (i < 20) {
          f = (b & c) | ((~b) & d);
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = (b & c) | (b & d) | (c & d);
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        final int temp = (_leftRotate32(a, 5) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = _leftRotate32(b, 30);
        b = a;
        a = temp;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    final Uint8List digest = Uint8List(20);
    _writeUint32BE(digest, 0, h0);
    _writeUint32BE(digest, 4, h1);
    _writeUint32BE(digest, 8, h2);
    _writeUint32BE(digest, 12, h3);
    _writeUint32BE(digest, 16, h4);

    return digest;
  }

  /// Pads [input] to the 512-bit block boundary required by SHA-1.
  ///
  /// This appends a `1` bit, then zero bits, then the original message length
  /// in bits as a 64-bit big-endian integer.
  Uint8List _pad(Uint8List input) {
    final int bitLength = input.length * 8;

    // Padding: 0x80 then zeros until length ≡ 56 (mod 64), then 64-bit length.
    int paddedLength = input.length + 1;
    while ((paddedLength % 64) != 56) {
      paddedLength++;
    }
    paddedLength += 8;

    final Uint8List padded = Uint8List(paddedLength);
    padded.setRange(0, input.length, input);
    padded[input.length] = 0x80;

    // Append original length in bits as big-endian 64-bit.
    final int lengthOffset = paddedLength - 8;
    padded[lengthOffset] = (bitLength >> 56) & 0xFF;
    padded[lengthOffset + 1] = (bitLength >> 48) & 0xFF;
    padded[lengthOffset + 2] = (bitLength >> 40) & 0xFF;
    padded[lengthOffset + 3] = (bitLength >> 32) & 0xFF;
    padded[lengthOffset + 4] = (bitLength >> 24) & 0xFF;
    padded[lengthOffset + 5] = (bitLength >> 16) & 0xFF;
    padded[lengthOffset + 6] = (bitLength >> 8) & 0xFF;
    padded[lengthOffset + 7] = bitLength & 0xFF;

    return padded;
  }
}

/// Rotates a 32-bit integer [value] left by [shift] bits.
int _leftRotate32(int value, int shift) {
  return ((value << shift) | (value >> (32 - shift))) & 0xFFFFFFFF;
}

/// Writes a 32-bit unsigned integer in little-endian to [bytes] at [offset].
void _writeUint32LE(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xFF;
  bytes[offset + 1] = (value >> 8) & 0xFF;
  bytes[offset + 2] = (value >> 16) & 0xFF;
  bytes[offset + 3] = (value >> 24) & 0xFF;
}
