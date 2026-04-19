import '../../../core/domain/inadimplencia_calculator.dart';
import '../../../core/domain/inadimplencia_config.dart';

enum PagamentoStatus { pendente, atrasado, pago }

/// Representa o pagamento mensal de um aluno.
class PagamentoMensal {
  const PagamentoMensal({
    required this.competencia,
    required this.valor,
    required this.status,
    required this.diaVencimento,
    this.pagoEm,
    this.comprovanteUrl,
    this.observacao,
  });

  final String competencia;
  final double valor;
  final PagamentoStatus status;
  final int diaVencimento;
  final DateTime? pagoEm;
  final String? comprovanteUrl;
  final String? observacao;

  bool get pago => status == PagamentoStatus.pago;

  PagamentoMensal copyWith({
    String? competencia,
    double? valor,
    PagamentoStatus? status,
    int? diaVencimento,
    DateTime? pagoEm,
    String? comprovanteUrl,
    String? observacao,
    bool clearPagoEm = false,
    bool clearComprovanteUrl = false,
    bool clearObservacao = false,
  }) {
    return PagamentoMensal(
      competencia: competencia ?? this.competencia,
      valor: valor ?? this.valor,
      status: status ?? this.status,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      pagoEm: clearPagoEm ? null : (pagoEm ?? this.pagoEm),
      comprovanteUrl: clearComprovanteUrl
          ? null
          : (comprovanteUrl ?? this.comprovanteUrl),
      observacao: clearObservacao ? null : (observacao ?? this.observacao),
    );
  }

  String get statusLabel {
    return switch (status) {
      PagamentoStatus.pago => 'Pago',
      PagamentoStatus.atrasado => 'Atrasado',
      PagamentoStatus.pendente => 'Pendente',
    };
  }
}

/// Aluno da academia com dados de cadastro e pagamentos.
class Aluno {
  const Aluno({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.observacao,
    required this.diaVencimento,
    required this.mensalidade,
    required this.criadoEm,
    required this.pagamentos,
    this.ativo = true,
    this.arquivadoEm,
    this.pagoLegado,
  });

  final String id;
  final String nome;
  final String telefone;
  final String observacao;
  final int diaVencimento;
  final double mensalidade;
  final DateTime criadoEm;
  final Map<String, PagamentoMensal> pagamentos;
  final bool ativo;
  final DateTime? arquivadoEm;
  final bool? pagoLegado;

  static String competenciaAtual([DateTime? now]) {
    final d = now ?? DateTime.now();
    final month = d.month.toString().padLeft(2, '0');
    return '${d.year}-$month';
  }

  static DateTime? tryParseCompetencia(String competencia) {
    final parts = competencia.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }
    return DateTime(year, month);
  }

  /// Referencia usada para avaliar status (pendente/atrasado) de uma competencia.
  /// No mes atual usa o dia de hoje; em meses passados usa o ultimo dia do mes.
  static DateTime referenciaStatusDaCompetencia(
    DateTime competencia, {
    DateTime? agora,
  }) {
    final now = agora ?? DateTime.now();
    final competenciaMes = DateTime(competencia.year, competencia.month);
    final mesAtual = DateTime(now.year, now.month);
    if (competenciaMes.year == mesAtual.year &&
        competenciaMes.month == mesAtual.month) {
      return now;
    }
    return DateTime(competencia.year, competencia.month + 1, 0);
  }

  static int diaVencimentoEfetivo(int diaVencimento, DateTime referenceDate) {
    final ultimoDiaDoMes = DateTime(
      referenceDate.year,
      referenceDate.month + 1,
      0,
    ).day;
    return diaVencimento.clamp(1, ultimoDiaDoMes).toInt();
  }

  static DateTime dataVencimento(int diaVencimento, DateTime referenceDate) {
    final diaEfetivo = diaVencimentoEfetivo(diaVencimento, referenceDate);
    return DateTime(referenceDate.year, referenceDate.month, diaEfetivo);
  }

  PagamentoMensal pagamentoDoMes([DateTime? now]) {
    final ref = now ?? DateTime.now();
    return pagamentoDaCompetencia(competenciaAtual(ref), referenciaStatus: ref);
  }

  PagamentoMensal pagamentoDaCompetencia(
    String competencia, {
    DateTime? referenciaStatus,
  }) {
    final existente = pagamentos[competencia];
    if (existente != null) {
      if (existente.pago) return existente;
      final referenciaCompetencia =
          tryParseCompetencia(competencia) ?? DateTime.now();
      final statusRef = referenciaStatus ?? DateTime.now();
      final diaVencimentoComp = diaVencimentoEfetivo(
        existente.diaVencimento,
        referenciaCompetencia,
      );
      final hoje = DateTime(statusRef.year, statusRef.month, statusRef.day);
      final vencimento = DateTime(
        referenciaCompetencia.year,
        referenciaCompetencia.month,
        diaVencimentoComp,
      );
      final statusAtual = hoje.isAfter(vencimento)
          ? PagamentoStatus.atrasado
          : PagamentoStatus.pendente;
      return existente.copyWith(
        status: statusAtual,
        diaVencimento: diaVencimentoComp,
      );
    }

    final referenciaCompetencia =
        tryParseCompetencia(competencia) ?? DateTime.now();
    final statusRef = referenciaStatus ?? DateTime.now();
    final competenciaAtualRef = competenciaAtual(statusRef);
    final diaVencimentoComp = diaVencimentoEfetivo(
      diaVencimento,
      referenciaCompetencia,
    );

    if (pagoLegado == true && competencia == competenciaAtualRef) {
      return PagamentoMensal(
        competencia: competencia,
        valor: mensalidade,
        status: PagamentoStatus.pago,
        diaVencimento: diaVencimentoComp,
      );
    }

    final hoje = DateTime(statusRef.year, statusRef.month, statusRef.day);
    final vencimento = DateTime(
      referenciaCompetencia.year,
      referenciaCompetencia.month,
      diaVencimentoComp,
    );

    return PagamentoMensal(
      competencia: competencia,
      valor: mensalidade,
      status: hoje.isAfter(vencimento)
          ? PagamentoStatus.atrasado
          : PagamentoStatus.pendente,
      diaVencimento: diaVencimentoComp,
    );
  }

  List<String> competenciasCobraveisAte(DateTime referencia) {
    final limiteReferencia = DateTime(referencia.year, referencia.month);
    final inicioCadastro = DateTime(criadoEm.year, criadoEm.month);
    final inicioPagamentos = _menorCompetenciaRegistrada() ?? inicioCadastro;
    final inicio = inicioPagamentos.isBefore(inicioCadastro)
        ? inicioPagamentos
        : inicioCadastro;
    final fim = _ultimaCompetenciaCobravel(limiteReferencia);

    if (fim.isBefore(inicio)) return const <String>[];

    final competencias = <String>[];
    var cursor = DateTime(inicio.year, inicio.month);
    while (!cursor.isAfter(fim)) {
      competencias.add(competenciaAtual(cursor));
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return competencias;
  }

  List<PagamentoMensal> pagamentosAte(
    DateTime referencia, {
    DateTime? referenciaStatus,
  }) {
    final statusRef =
        referenciaStatus ?? referenciaStatusDaCompetencia(referencia);
    return competenciasCobraveisAte(referencia).map((competencia) {
      return pagamentoDaCompetencia(competencia, referenciaStatus: statusRef);
    }).toList()..sort((a, b) => a.competencia.compareTo(b.competencia));
  }

  double valorEmAbertoAte(DateTime referencia, {DateTime? referenciaStatus}) {
    return pagamentosAte(
      referencia,
      referenciaStatus: referenciaStatus,
    ).where((p) => !p.pago).fold<double>(0, (sum, p) => sum + p.valor);
  }

  int totalCompetenciasEmAbertoAte(
    DateTime referencia, {
    DateTime? referenciaStatus,
  }) {
    return pagamentosAte(
      referencia,
      referenciaStatus: referenciaStatus,
    ).where((p) => !p.pago).length;
  }

  bool temEmAbertoAte(DateTime referencia, {DateTime? referenciaStatus}) {
    return totalCompetenciasEmAbertoAte(
          referencia,
          referenciaStatus: referenciaStatus,
        ) >
        0;
  }

  PagamentoMensal pagamentoDoMesSincronizadoComCadastro([DateTime? now]) {
    final ref = now ?? DateTime.now();
    final competencia = competenciaAtual(ref);
    final pagamentoAtual = pagamentoDoMes(ref);
    final diaEfetivo = diaVencimentoEfetivo(diaVencimento, ref);

    return pagamentoAtual.copyWith(
      competencia: competencia,
      valor: mensalidade,
      diaVencimento: diaEfetivo,
    );
  }

  bool get pago => pagamentoDoMes().pago;

  bool get atrasado => pagamentoDoMes().status == PagamentoStatus.atrasado;

  String get statusLabel => pagamentoDoMes().statusLabel;

  Aluno copyWith({
    String? id,
    String? nome,
    String? telefone,
    String? observacao,
    int? diaVencimento,
    double? mensalidade,
    DateTime? criadoEm,
    Map<String, PagamentoMensal>? pagamentos,
    bool? ativo,
    DateTime? arquivadoEm,
    bool? pagoLegado,
  }) {
    return Aluno(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      observacao: observacao ?? this.observacao,
      diaVencimento: diaVencimento ?? this.diaVencimento,
      mensalidade: mensalidade ?? this.mensalidade,
      criadoEm: criadoEm ?? this.criadoEm,
      pagamentos: pagamentos ?? this.pagamentos,
      ativo: ativo ?? this.ativo,
      arquivadoEm: arquivadoEm ?? this.arquivadoEm,
      pagoLegado: pagoLegado ?? this.pagoLegado,
    );
  }

  /// Calcula o status de inadimplencia deste aluno usando as configuracoes padrao.
  /// Para usar config customizada, chame [InadimplenciaCalculator.calcular] diretamente.
  InadimplenciaResultado inadimplencia({
    InadimplenciaConfig? config,
    DateTime? agora,
  }) {
    return InadimplenciaCalculator.calcular(
      aluno: this,
      config: config ?? InadimplenciaConfig.defaults,
      agora: agora ?? DateTime.now(),
    );
  }

  DateTime _ultimaCompetenciaCobravel(DateTime referencia) {
    if (ativo) return referencia;

    if (arquivadoEm != null) {
      final arquivado = DateTime(arquivadoEm!.year, arquivadoEm!.month);
      return arquivado.isBefore(referencia) ? arquivado : referencia;
    }

    final maiorCompetencia = _maiorCompetenciaRegistrada();
    if (maiorCompetencia != null) {
      return maiorCompetencia.isBefore(referencia)
          ? maiorCompetencia
          : referencia;
    }

    return DateTime(criadoEm.year, criadoEm.month);
  }

  DateTime? _menorCompetenciaRegistrada() {
    DateTime? menor;
    for (final competencia in pagamentos.keys) {
      final parsed = tryParseCompetencia(competencia);
      if (parsed == null) continue;
      if (menor == null || parsed.isBefore(menor)) {
        menor = parsed;
      }
    }
    return menor;
  }

  DateTime? _maiorCompetenciaRegistrada() {
    DateTime? maior;
    for (final competencia in pagamentos.keys) {
      final parsed = tryParseCompetencia(competencia);
      if (parsed == null) continue;
      if (maior == null || parsed.isAfter(maior)) {
        maior = parsed;
      }
    }
    return maior;
  }
}
