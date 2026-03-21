String? normalizarTelefoneWhatsApp(String telefone) {
  final digitos = _somenteDigitos(telefone);
  if (digitos.isEmpty) return null;

  if (digitos.length == 12 || digitos.length == 13) {
    return digitos.startsWith('55') ? digitos : null;
  }

  if (digitos.length == 10 || digitos.length == 11) {
    return '55$digitos';
  }

  return null;
}

bool temTelefoneWhatsAppValido(String telefone) {
  return normalizarTelefoneWhatsApp(telefone) != null;
}

Uri? montarUriWhatsApp(String telefone) {
  final normalizado = normalizarTelefoneWhatsApp(telefone);
  if (normalizado == null) return null;
  return Uri.parse('https://wa.me/$normalizado');
}

String _somenteDigitos(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}
