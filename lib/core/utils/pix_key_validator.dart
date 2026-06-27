class PixKeyValidator {
  const PixKeyValidator._();

  static bool isValid(String key) {
    final cleaned = key.trim();
    if (cleaned.isEmpty) return false;

    // 1. E-mail
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );
    if (emailRegex.hasMatch(cleaned)) return true;

    // 2. CPF (11) ou CNPJ (14) ou Telefone Celular (11 ou 13)
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 11 || digitsOnly.length == 14) {
      return true; // CPF, CNPJ ou Celular sem DDI
    }
    if (digitsOnly.length == 13) {
      return true; // Celular com DDI 55
    }

    // 3. Chave aleatória (UUID EVP Pix: 36 chars)
    final evpRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (evpRegex.hasMatch(cleaned)) return true;

    // 4. Pix copia e cola completo
    if (cleaned.startsWith('000201')) {
      return true;
    }

    return false;
  }
}
