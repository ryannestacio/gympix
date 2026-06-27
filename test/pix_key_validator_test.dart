import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/core/utils/pix_key_validator.dart';

void main() {
  group('PixKeyValidator', () {
    test('rejeita chaves vazias', () {
      expect(PixKeyValidator.isValid(''), isFalse);
      expect(PixKeyValidator.isValid('   '), isFalse);
    });

    test('valida e-mails corretos e rejeita incorretos', () {
      expect(PixKeyValidator.isValid('usuario@exemplo.com'), isTrue);
      expect(PixKeyValidator.isValid('usuario.sobrenome@exemplo.com.br'), isTrue);
      expect(PixKeyValidator.isValid('usuario@'), isFalse);
      expect(PixKeyValidator.isValid('usuario@exemplo'), isFalse);
      expect(PixKeyValidator.isValid('usuario@.com'), isFalse);
    });

    test('valida CPF e CNPJ (apenas dígitos ou formatados)', () {
      // CPF
      expect(PixKeyValidator.isValid('12345678909'), isTrue);
      expect(PixKeyValidator.isValid('123.456.789-09'), isTrue);
      // CNPJ
      expect(PixKeyValidator.isValid('12345678000199'), isTrue);
      expect(PixKeyValidator.isValid('12/345.678/0001-99'), isTrue);
      // Tamanho incorreto
      expect(PixKeyValidator.isValid('1234567890'), isFalse);
      expect(PixKeyValidator.isValid('123456789099'), isFalse);
    });

    test('valida telefones celulares', () {
      expect(PixKeyValidator.isValid('82982199052'), isTrue); // 11 dígitos
      expect(PixKeyValidator.isValid('+5582982199052'), isTrue); // 13 dígitos
      expect(PixKeyValidator.isValid('5582982199052'), isTrue); // 13 dígitos
      expect(PixKeyValidator.isValid('123456789'), isFalse); // Curto demais
      expect(PixKeyValidator.isValid('123456789012345'), isFalse); // Longo demais
    });

    test('valida chave aleatória EVP (UUID v4)', () {
      expect(PixKeyValidator.isValid('123e4567-e89b-12d3-a456-426614174000'), isTrue);
      expect(PixKeyValidator.isValid('123E4567-E89B-12D3-A456-426614174000'), isTrue); // Hex case-insensitive
      expect(PixKeyValidator.isValid('123e4567-e89b-12d3-a456-42661417400'), isFalse); // Curto
      expect(PixKeyValidator.isValid('123e4567e89b12d3a456426614174000'), isFalse); // Sem hifens
    });

    test('valida código Pix Copia e Cola', () {
      expect(PixKeyValidator.isValid('00020101021226870014br.gov.bcb.pix2565...'), isTrue);
      expect(PixKeyValidator.isValid('000201...'), isTrue);
      expect(PixKeyValidator.isValid('100201...'), isFalse); // Início incorreto
    });
  });
}
