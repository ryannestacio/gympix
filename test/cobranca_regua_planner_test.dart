import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';
import 'package:gympix/features/cobranca/models/cobranca_regua.dart';
import 'package:gympix/features/cobranca/services/cobranca_regua_planner.dart';

void main() {
  group('CobrancaReguaPlanner', () {
    test('dispara no D-3 para aluno pendente', () {
      final planner = CobrancaReguaPlanner();
      final aluno = _alunoBase(diaVencimento: 13);
      final now = DateTime(2026, 3, 10);

      final acoes = planner.planejarHoje(
        alunos: [aluno],
        config: CobrancaReguaConfig.defaults,
        now: now,
      );

      expect(acoes.length, 1);
      expect(acoes.first.diasRelativos, -3);
      expect(acoes.first.pagamento.status, PagamentoStatus.pendente);
    });

    test('dispara no D+3 para aluno atrasado', () {
      final planner = CobrancaReguaPlanner();
      final aluno = _alunoBase(diaVencimento: 13);
      final now = DateTime(2026, 3, 16);

      final acoes = planner.planejarHoje(
        alunos: [aluno],
        config: CobrancaReguaConfig.defaults,
        now: now,
      );

      expect(acoes.length, 1);
      expect(acoes.first.diasRelativos, 3);
      expect(acoes.first.pagamento.status, PagamentoStatus.atrasado);
    });

    test('nao dispara quando passo correspondente esta inativo', () {
      final planner = CobrancaReguaPlanner();
      final aluno = _alunoBase(diaVencimento: 13);
      final now = DateTime(2026, 3, 10);
      final config = CobrancaReguaConfig.defaults.copyWith(
        passos: const [
          CobrancaReguaStep(diasRelativos: -3, ativo: false),
          CobrancaReguaStep(diasRelativos: 0, ativo: true),
          CobrancaReguaStep(diasRelativos: 3, ativo: true),
        ],
      );

      final acoes = planner.planejarHoje(
        alunos: [aluno],
        config: config,
        now: now,
      );

      expect(acoes, isEmpty);
    });
  });
}

Aluno _alunoBase({required int diaVencimento}) {
  return Aluno(
    id: '1',
    nome: 'Aluno Regua',
    telefone: '(11) 99999-9999',
    observacao: '',
    diaVencimento: diaVencimento,
    mensalidade: 150,
    criadoEm: DateTime(2026, 1, 1),
    pagamentos: const {},
  );
}
