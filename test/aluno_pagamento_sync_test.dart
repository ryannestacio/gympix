import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';

void main() {
  test('sincroniza pagamento atual com mensalidade e vencimento editados', () {
    final aluno = Aluno(
      id: '1',
      nome: 'Aluno Teste',
      telefone: '',
      observacao: '',
      diaVencimento: 25,
      mensalidade: 120,
      criadoEm: DateTime(2026, 1, 1),
      pagamentos: const {
        '2026-03': PagamentoMensal(
          competencia: '2026-03',
          valor: 100,
          status: PagamentoStatus.pendente,
          diaVencimento: 20,
        ),
      },
    );

    final editado = aluno.copyWith(
      diaVencimento: 31,
      mensalidade: 150,
    );

    final sincronizado = editado.pagamentoDoMesSincronizadoComCadastro(
      DateTime(2026, 3, 10),
    );

    expect(sincronizado.valor, 150);
    expect(sincronizado.diaVencimento, 31);
    expect(sincronizado.status, PagamentoStatus.pendente);
  });

  test('preserva dados de pagamento ja registrado ao sincronizar cadastro', () {
    final pagoEm = DateTime(2026, 4, 5, 8, 30);
    final aluno = Aluno(
      id: '1',
      nome: 'Aluno Teste',
      telefone: '',
      observacao: '',
      diaVencimento: 10,
      mensalidade: 100,
      criadoEm: DateTime(2026, 1, 1),
      pagamentos: {
        '2026-04': PagamentoMensal(
          competencia: '2026-04',
          valor: 100,
          status: PagamentoStatus.pago,
          diaVencimento: 10,
          pagoEm: pagoEm,
          comprovanteUrl: 'https://comprovante',
          observacao: 'Pago no caixa',
        ),
      },
    );

    final editado = aluno.copyWith(
      diaVencimento: 31,
      mensalidade: 180,
    );

    final sincronizado = editado.pagamentoDoMesSincronizadoComCadastro(
      DateTime(2026, 4, 20),
    );

    expect(sincronizado.valor, 180);
    expect(sincronizado.diaVencimento, 30);
    expect(sincronizado.status, PagamentoStatus.pago);
    expect(sincronizado.pagoEm, pagoEm);
    expect(sincronizado.comprovanteUrl, 'https://comprovante');
    expect(sincronizado.observacao, 'Pago no caixa');
  });
}
