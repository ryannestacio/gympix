import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';

void main() {
  group('Acumulacao de mensalidades', () {
    test(
      'aluno ativo gera competencias cobraveis do cadastro ate a referencia',
      () {
        final aluno = _alunoBase();
        final competencias = aluno.competenciasCobraveisAte(
          DateTime(2026, 4, 1),
        );

        expect(competencias, ['2026-01', '2026-02', '2026-03', '2026-04']);
      },
    );

    test('valor em aberto acumula competencias nao pagas', () {
      final aluno = _alunoBase(
        pagamentos: {
          '2026-02': _pagamento(
            competencia: '2026-02',
            status: PagamentoStatus.pago,
          ),
        },
      );

      final total = aluno.valorEmAbertoAte(
        DateTime(2026, 4, 1),
        referenciaStatus: DateTime(2026, 4, 20),
      );

      expect(total, 300);
    });

    test('aluno inativo nao acumula apos o mes de arquivamento', () {
      final aluno = _alunoBase(
        ativo: false,
        arquivadoEm: DateTime(2026, 3, 15),
      );

      final competencias = aluno.competenciasCobraveisAte(DateTime(2026, 5, 1));
      final total = aluno.valorEmAbertoAte(
        DateTime(2026, 5, 1),
        referenciaStatus: DateTime(2026, 5, 20),
      );

      expect(competencias, ['2026-01', '2026-02', '2026-03']);
      expect(total, 300);
    });
  });
}

Aluno _alunoBase({
  bool ativo = true,
  DateTime? arquivadoEm,
  Map<String, PagamentoMensal> pagamentos = const {},
}) {
  return Aluno(
    id: '1',
    nome: 'Aluno Teste',
    telefone: '',
    observacao: '',
    diaVencimento: 10,
    mensalidade: 100,
    criadoEm: DateTime(2026, 1, 1),
    pagamentos: pagamentos,
    ativo: ativo,
    arquivadoEm: arquivadoEm,
  );
}

PagamentoMensal _pagamento({
  required String competencia,
  required PagamentoStatus status,
}) {
  return PagamentoMensal(
    competencia: competencia,
    valor: 100,
    status: status,
    diaVencimento: 10,
    pagoEm: status == PagamentoStatus.pago ? DateTime(2026, 2, 5) : null,
  );
}
