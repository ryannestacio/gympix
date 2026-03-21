import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';

void main() {
  group('vencimento efetivo por mes', () {
    test('ajusta dia 31 para o ultimo dia de fevereiro', () {
      final referencia = DateTime(2026, 2, 10);

      expect(Aluno.diaVencimentoEfetivo(31, referencia), 28);
      expect(
        Aluno.dataVencimento(31, referencia),
        DateTime(2026, 2, 28),
      );
    });

    test('ajusta dia 31 para 30 em abril', () {
      final referencia = DateTime(2026, 4, 10);

      expect(Aluno.diaVencimentoEfetivo(31, referencia), 30);
      expect(
        Aluno.dataVencimento(31, referencia),
        DateTime(2026, 4, 30),
      );
    });
  });

  group('status mensal', () {
    final aluno = Aluno(
      id: '1',
      nome: 'Aluno Teste',
      telefone: '',
      observacao: '',
      diaVencimento: 31,
      mensalidade: 100,
      criadoEm: DateTime(2026, 1, 1),
      pagamentos: {},
    );

    test('permanece pendente ate o ultimo dia valido do mes', () {
      final pagamento = aluno.pagamentoDoMes(DateTime(2026, 2, 28));

      expect(pagamento.status, PagamentoStatus.pendente);
      expect(pagamento.diaVencimento, 28);
    });

    test('fica atrasado apenas depois do ultimo dia valido do mes', () {
      final pagamento = aluno.pagamentoDoMes(DateTime(2026, 3, 1));

      expect(pagamento.status, PagamentoStatus.pendente);
      expect(pagamento.diaVencimento, 31);
    });
  });
}
