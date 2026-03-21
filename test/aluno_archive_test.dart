import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';

void main() {
  test('aluno e ativo por padrao', () {
    final aluno = Aluno(
      id: '1',
      nome: 'Aluno Teste',
      telefone: '',
      observacao: '',
      diaVencimento: 10,
      mensalidade: 100,
      criadoEm: DateTime(2026, 1, 1),
      pagamentos: {},
    );

    expect(aluno.ativo, isTrue);
    expect(aluno.arquivadoEm, isNull);
  });

  test('copyWith permite marcar aluno como arquivado sem perder historico', () {
    final aluno = Aluno(
      id: '1',
      nome: 'Aluno Teste',
      telefone: '',
      observacao: '',
      diaVencimento: 10,
      mensalidade: 100,
      criadoEm: DateTime(2026, 1, 1),
      pagamentos: const {
        '2026-03': PagamentoMensal(
          competencia: '2026-03',
          valor: 100,
          status: PagamentoStatus.pago,
          diaVencimento: 10,
        ),
      },
    );

    final arquivadoEm = DateTime(2026, 3, 20);
    final arquivado = aluno.copyWith(
      ativo: false,
      arquivadoEm: arquivadoEm,
    );

    expect(arquivado.ativo, isFalse);
    expect(arquivado.arquivadoEm, arquivadoEm);
    expect(arquivado.pagamentos.length, 1);
    expect(arquivado.pagamentos['2026-03']?.status, PagamentoStatus.pago);
  });
}
