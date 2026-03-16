part of 'manual_restore_screen.dart';

extension on _ManualRestoreScreenState {
  String _processSecretKey(String key) {
    final cleaned = key.replaceAll(RegExp(r'[-\s]'), '');
    Logger.info('=== _processSecretKey START ===');
    Logger.info('Input key: "$key"');
    Logger.info('Cleaned key: "$cleaned"');
    final hasBase64Chars = cleaned.contains('_') || cleaned.contains('-');
    Logger.info('hasBase64Chars: $hasBase64Chars');
    Logger.info('_looksLikeBase64: ${_looksLikeBase64(cleaned)}');
    if (hasBase64Chars || _looksLikeBase64(cleaned)) {
      Logger.info('Detected Base64/Base64URL format');
      var padded = cleaned;
      if (cleaned.contains('_') || cleaned.contains('-')) {
        Logger.info('Converting Base64URL to Base64');
        padded = cleaned.replaceAll('_', '/').replaceAll('-', '+');
      }
      while (padded.length % 4 != 0) {
        padded += '=';
      }
      Logger.info('Standard Base64 (with padding): "$padded"');
      Logger.info('=== _processSecretKey END (Base64) ===');
      return padded;
    }
    Logger.info('Attempting Base32 decode');
    final decoded = _base32Decode(cleaned);
    if (decoded.length < 16 || decoded.length > 32) {
      throw Exception('Invalid decoded key length: ${decoded.length} bytes');
    }
    final base64 = base64Encode(decoded);
    Logger.info('Decoded Base32 and encoded to Base64: $base64');
    return base64;
  }

  List<int> _base32Decode(String input) {
    final cleaned = input.replaceAll(RegExp(r'[-\s]'), '');
    Logger.info('Base32 decoding: ${cleaned.length} characters: "$cleaned"');
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final charMap = <String, int>{};
    for (var index = 0; index < alphabet.length; index++) {
      charMap[alphabet[index]] = index;
    }
    final normalized = cleaned.toUpperCase();
    final mapped = StringBuffer();
    for (var index = 0; index < normalized.length; index++) {
      final char = normalized[index];
      final mappedChar = switch (char) {
        '0' => 'O',
        '1' => 'I',
        '8' => 'B',
        '9' => 'P',
        _ => char,
      };
      if (!charMap.containsKey(mappedChar) && !charMap.containsKey(char)) {
        Logger.error('Invalid Base32 character: $char');
        throw FormatException('Invalid Base32 character: $char');
      }
      mapped.write(charMap.containsKey(mappedChar) ? mappedChar : char);
    }

    final result = <int>[];
    var buffer = 0;
    var bits = 0;
    for (final char in mapped.toString().split('')) {
      final value = charMap[char];
      if (value == null) {
        Logger.error('Invalid Base32 character: $char');
        throw FormatException('Invalid Base32 character: $char');
      }
      buffer = (buffer << 5) | value;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        result.add((buffer >> bits) & 0xFF);
      }
    }
    Logger.info('Base32 decoded to ${result.length} bytes');
    return result;
  }
}
