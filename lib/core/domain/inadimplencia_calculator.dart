import '../domain/inadimplencia_config.dart';
import '../domain/inadimplencia_status.dart';
import '../../features/alunos/models/aluno.dart';

/// Resultado detalhado do calculo de inadimplencia.
class InadimplenciaResultado {
  const InadimplenciaResultado({
    required this.status,
    required this.competenciaAtual,
    this.pagamentoEncontrado,
    this.diasAtraso,
    this.diasRestantes,
  });

  /// Status calculado
  final InadimplenciaStatus status;

  /// Mes de competencia sendo avaliado ("2026-04")
  final String competenciaAtual;

  /// Pagamento encontrado para esta competencia, se existir
  final PagamentoMensal? pagamentoEncontrado;

  /// Dias de atraso apos o vencimento (somente se emAtraso/inadimplente)
  final int? diasAtraso;

  /// Dias restantes ate o vencimento (somente se aVencer)
  final int? diasRestantes;

  bool get isPago => status == InadimplenciaStatus.emDia;
  bool get semPagamentoCompetencia => pagamentoEncontrado == null;
}

/// Servico stateless que calcula inadimplencia por competencia mensal.
/// Nao depende de UI ou banco — apenas configuracoes e dados do pagamento.
class InadimplenciaCalculator {
  /// Calcula o status de inadimplencia de um aluno para o mes atual.
  ///
  /// Regras:
  /// 1. Se o pagamento do mes ja foi feito -> emDia
  /// 2. Se ha competencias anteriores SEM pagamento -> inadimplente (acumulada)
  /// 3. Se estamos ANTES do dia de vencimento -> aVencer
  /// 4. Se e exatamente o dia de vencimento -> venceHoje (se habilitado)
  /// 5. Se passou do vencimento mas dentro da tolerancia -> emAtraso
  /// 6. Se ultrapassou a tolerancia -> inadimplente
  ///
  /// Flexibilidade futura: O dia de vencimento vem do `Aluno.diaVencimento`,
  /// facilitando migrar para vencimento personalizado por cliente.
  static InadimplenciaResultado calcular({
    required Aluno aluno,
    required InadimplenciaConfig config,
    DateTime? agora,
  }) {
    final now = agora ?? DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final competencia = Aluno.competenciaAtual(now);
    final pagamentoCorrente = aluno.pagamentoDaCompetencia(
      competencia,
      referenciaStatus: now,
    );

    // 1. Ja pagou a competencia vigente?
    if (pagamentoCorrente.pago) {
      return InadimplenciaResultado(
        status: InadimplenciaStatus.emDia,
        competenciaAtual: competencia,
        pagamentoEncontrado: pagamentoCorrente,
      );
    }

    // 2. Competencias anteriores SEM pagamento -> inadimplencia acumulada
    // Ordernar competencias para verificar as mais antigas primeiro
    final competenciasOrdenadas = aluno.competenciasCobraveisAte(now)..sort();
    for (final comp in competenciasOrdenadas) {
      if (_isCompetenciaAnterior(comp, competencia)) {
        final pag = aluno.pagamentoDaCompetencia(comp, referenciaStatus: now);
        if (!pag.pago) {
          // Inadimplencia acumulada: nao pagou mes anterior
          final diff = hoje.difference(_ultimoDiaDaCompetencia(comp)).inDays;
          return InadimplenciaResultado(
            status: InadimplenciaStatus.inadimplente,
            competenciaAtual: competencia,
            pagamentoEncontrado: pag,
            diasAtraso: diff > 0 ? diff : 1,
          );
        }
      }
    }

    // 3-6. Competencia corrente sem pagamento -> calcular com base em dias
    final diaVencimentoEfetivo = Aluno.diaVencimentoEfetivo(
      aluno.diaVencimento,
      now,
    );
    final vencimento = DateTime(now.year, now.month, diaVencimentoEfetivo);
    final limiteTolerancia = vencimento.add(
      Duration(days: config.diasTolerancia),
    );

    if (hoje.isBefore(vencimento)) {
      final diasRestantes = vencimento.difference(hoje).inDays;
      return InadimplenciaResultado(
        status: InadimplenciaStatus.aVencer,
        competenciaAtual: competencia,
        pagamentoEncontrado: pagamentoCorrente,
        diasRestantes: diasRestantes,
      );
    }

    if (config.habilitarVenceHoje && hoje.day == vencimento.day) {
      return InadimplenciaResultado(
        status: InadimplenciaStatus.venceHoje,
        competenciaAtual: competencia,
        pagamentoEncontrado: pagamentoCorrente,
        diasAtraso: 0,
      );
    }

    if (hoje.isBefore(limiteTolerancia) || hoje.day == limiteTolerancia.day) {
      final diasAtraso = hoje.difference(vencimento).inDays;
      return InadimplenciaResultado(
        status: InadimplenciaStatus.emAtraso,
        competenciaAtual: competencia,
        pagamentoEncontrado: pagamentoCorrente,
        diasAtraso: diasAtraso > 0 ? diasAtraso : 0,
      );
    }

    // Ultrapassou tolerancia
    final diasAtraso = hoje.difference(vencimento).inDays;
    return InadimplenciaResultado(
      status: InadimplenciaStatus.inadimplente,
      competenciaAtual: competencia,
      pagamentoEncontrado: pagamentoCorrente,
      diasAtraso: diasAtraso > 0 ? diasAtraso : 0,
    );
  }

  static bool _isCompetenciaAnterior(String a, String b) {
    return a.compareTo(b) < 0;
  }

  static DateTime _ultimoDiaDaCompetencia(String competencia) {
    final parts = competencia.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }
}
