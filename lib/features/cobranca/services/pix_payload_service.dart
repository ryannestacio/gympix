class PixPayloadService {
  const PixPayloadService();

  static const String _pixGui = 'br.gov.bcb.pix';
  static const String _countryCode = 'BR';
  static const String _merchantCategoryCode = '0000';
  static const String _transactionCurrency = '986';

  String resolvePayload({
    required String pixCodeOrKey,
    required double amount,
    required String merchantName,
    required String merchantCity,
    String txid = 'GYMPIX',
  }) {
    final normalized = pixCodeOrKey.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('O codigo Pix nao pode estar vazio.');
    }

    if (looksLikePayload(normalized)) {
      return normalized;
    }

    return buildStaticPayload(
      pixKey: normalized,
      amount: amount,
      merchantName: merchantName,
      merchantCity: merchantCity,
      txid: txid,
    );
  }

  bool looksLikePayload(String value) {
    final normalized = value.trim();
    return normalized.startsWith('000201') &&
        normalized.contains(_pixGui) &&
        normalized.contains('6304');
  }

  String buildStaticPayload({
    required String pixKey,
    required double amount,
    required String merchantName,
    required String merchantCity,
    String txid = 'GYMPIX',
  }) {
    final sanitizedKey = _normalizePixKey(pixKey);
    if (sanitizedKey.isEmpty) {
      throw ArgumentError('A chave Pix nao pode estar vazia.');
    }

    final sanitizedName = _sanitizeText(merchantName, maxLength: 25);
    final sanitizedCity = _sanitizeText(merchantCity, maxLength: 15);
    final sanitizedTxid = _sanitizeTxid(txid);
    final normalizedAmount = amount <= 0 ? null : amount.toStringAsFixed(2);

    final merchantAccountInfo = _field(
      '26',
      '${_field('00', _pixGui)}${_field('01', sanitizedKey)}',
    );

    final additionalData = _field('62', _field('05', sanitizedTxid));
    final amountField = normalizedAmount == null
        ? ''
        : _field('54', normalizedAmount);

    final payloadWithoutCrc =
        '${_field('00', '01')}'
        '$merchantAccountInfo'
        '${_field('52', _merchantCategoryCode)}'
        '${_field('53', _transactionCurrency)}'
        '$amountField'
        '${_field('58', _countryCode)}'
        '${_field('59', sanitizedName)}'
        '${_field('60', sanitizedCity)}'
        '$additionalData'
        '6304';

    final crc = _crc16Ccitt(payloadWithoutCrc);
    return '$payloadWithoutCrc$crc';
  }

  String _field(String id, String value) {
    final length = value.length.toString().padLeft(2, '0');
    return '$id$length$value';
  }

  String _sanitizeText(String input, {required int maxLength}) {
    final normalized = _stripAccents(input)
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 /.-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return 'GYMPIX';
    }

    return normalized.length <= maxLength
        ? normalized
        : normalized.substring(0, maxLength);
  }

  String _sanitizeTxid(String input) {
    final cleaned = _stripAccents(
      input,
    ).toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.isEmpty) return 'GYMPIX';
    return cleaned.length <= 25 ? cleaned : cleaned.substring(0, 25);
  }

  String _stripAccents(String value) {
    return value
        .replaceAll(RegExp('[\\u00C0-\\u00C5\\u00E0-\\u00E5]'), 'A')
        .replaceAll(RegExp('[\\u00C8-\\u00CB\\u00E8-\\u00EB]'), 'E')
        .replaceAll(RegExp('[\\u00CC-\\u00CF\\u00EC-\\u00EF]'), 'I')
        .replaceAll(RegExp('[\\u00D2-\\u00D6\\u00F2-\\u00F6]'), 'O')
        .replaceAll(RegExp('[\\u00D9-\\u00DC\\u00F9-\\u00FC]'), 'U')
        .replaceAll(RegExp('[\\u00C7\\u00E7]'), 'C')
        .replaceAll(RegExp('[\\u00D1\\u00F1]'), 'N');
  }

  String _normalizePixKey(String pixKey) {
    final trimmed = pixKey.trim();

    if (trimmed.startsWith('000201')) {
      return trimmed;
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');

    // 1. CPF (11 dígitos) ou CNPJ (14 dígitos)
    if (digitsOnly.length == 11 && !trimmed.contains('@')) {
      final hasPhoneIndicators = trimmed.contains('(') || trimmed.contains(')') || trimmed.contains('+') || trimmed.startsWith('55');
      final isProbablyPhone = hasPhoneIndicators || (digitsOnly[2] == '9' && !trimmed.contains('.'));

      if (isProbablyPhone) {
        return '+55$digitsOnly';
      } else {
        return digitsOnly; // CPF apenas números
      }
    }

    if (digitsOnly.length == 14) {
      return digitsOnly; // CNPJ apenas números
    }

    // 2. Celular com DDI (13 dígitos)
    if (digitsOnly.length == 13 && digitsOnly.startsWith('55')) {
      return '+$digitsOnly';
    }

    // Celular já com sinal de +
    if (trimmed.startsWith('+55') && digitsOnly.length == 13) {
      return trimmed;
    }

    // 3. Outros formatos (E-mail, EVP/Aleatória)
    return trimmed;
  }

  String _crc16Ccitt(String payload) {
    var crc = 0xFFFF;
    for (final codeUnit in payload.codeUnits) {
      crc ^= codeUnit << 8;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
}
