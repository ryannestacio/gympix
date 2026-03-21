import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/ui/alunos_page.dart';

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
}
