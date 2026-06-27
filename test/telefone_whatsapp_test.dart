import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/services/telefone_whatsapp_service.dart';

void main() {
  group('normalizacao de telefone para WhatsApp', () {
    test('adiciona DDI 55 quando numero esta sem codigo do pais', () {
      expect(normalizarTelefoneWhatsApp('11987654321'), '5511987654321');
      expect(normalizarTelefoneWhatsApp('(11) 98765-4321'), '5511987654321');
    });

    test('preserva numero quando DDI 55 ja foi informado', () {
      expect(normalizarTelefoneWhatsApp('5511987654321'), '5511987654321');
      expect(
        normalizarTelefoneWhatsApp('+55 (11) 98765-4321'),
        '5511987654321',
      );
    });

    test('rejeita formatos invalidos', () {
      expect(normalizarTelefoneWhatsApp('12345'), isNull);
      expect(normalizarTelefoneWhatsApp('4411987654321'), isNull);
    });
  });

  group('montarUriWhatsApp', () {
    test('retorna URI simples do WhatsApp', () {
      expect(
        montarUriWhatsApp('11987654321')?.toString(),
        'https://wa.me/5511987654321',
      );
    });

    test('retorna URI com mensagem formatada', () {
      expect(
        montarUriWhatsApp('11987654321', mensagem: 'Olá, tudo bem?')
            ?.toString(),
        'https://wa.me/5511987654321?text=Ol%C3%A1%2C%20tudo%20bem%3F',
      );
    });
  });
}
