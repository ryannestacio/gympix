import '../../alunos/models/aluno.dart';
import '../models/cobranca_regua.dart';

class CobrancaReguaAcao {
  const CobrancaReguaAcao({
    required this.aluno,
    required this.pagamento,
    required this.diasRelativos,
    required this.dataVencimento,
    required this.competencia,
  });

  final Aluno aluno;
  final PagamentoMensal pagamento;
  final int diasRelativos;
  final DateTime dataVencimento;
  final String competencia;
}

class CobrancaReguaPlanner {
  List<CobrancaReguaAcao> planejarHoje({
    required List<Aluno> alunos,
    required CobrancaReguaConfig config,
    DateTime? now,
  }) {
    if (!config.automacaoAtiva) return const <CobrancaReguaAcao>[];

    final referencia = _dateOnly(now ?? DateTime.now());
    final result = <CobrancaReguaAcao>[];

    for (final aluno in alunos) {
      if (!aluno.ativo) continue;
      final pagamento = aluno.pagamentoDoMes(referencia);
      if (pagamento.pago) continue;

      final vencimento = _dateOnly(
        Aluno.dataVencimento(aluno.diaVencimento, referencia),
      );
      final diasRelativos = referencia.difference(vencimento).inDays;
      if (!config.isStepAtivo(diasRelativos)) continue;

      result.add(
        CobrancaReguaAcao(
          aluno: aluno,
          pagamento: pagamento,
          diasRelativos: diasRelativos,
          dataVencimento: vencimento,
          competencia: Aluno.competenciaAtual(referencia),
        ),
      );
    }

    return result;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
