/// Configuracoes de inadimplencia por academia (tenant).
/// Permite que cada academia defina seus proprios prazos e tolerancias.
class InadimplenciaConfig {
  const InadimplenciaConfig({
    required this.diaLimitePagamento,
    required this.diasTolerancia,
    required this.permitirAcessoMesmoInadimplente,
    this.habilitarVenceHoje = true,
  });

  static const InadimplenciaConfig defaults = InadimplenciaConfig(
    diaLimitePagamento: 5,
    diasTolerancia: 5,
    permitirAcessoMesmoInadimplente: true,
    habilitarVenceHoje: true,
  );

  /// Dia do mes limite para pagamento sem atraso (ex: dia 5)
  final int diaLimitePagamento;

  /// Dias adicionais de tolerancia apos o dia limite (ex: +5 dias -> dia 10)
  final int diasTolerancia;

  /// Se permite operar o app mesmo quando inadimplente
  final bool permitirAcessoMesmoInadimplente;

  /// Se habilita o status intermediario "Vence Hoje"
  final bool habilitarVenceHoje;

  int get diaToleranciaMax => diaLimitePagamento + diasTolerancia;

  InadimplenciaConfig copyWith({
    int? diaLimitePagamento,
    int? diasTolerancia,
    bool? permitirAcessoMesmoInadimplente,
    bool? habilitarVenceHoje,
  }) {
    return InadimplenciaConfig(
      diaLimitePagamento: diaLimitePagamento ?? this.diaLimitePagamento,
      diasTolerancia: diasTolerancia ?? this.diasTolerancia,
      permitirAcessoMesmoInadimplente:
          permitirAcessoMesmoInadimplente ?? this.permitirAcessoMesmoInadimplente,
      habilitarVenceHoje: habilitarVenceHoje ?? this.habilitarVenceHoje,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'diaLimitePagamento': diaLimitePagamento,
      'diasTolerancia': diasTolerancia,
      'permitirAcessoMesmoInadimplente': permitirAcessoMesmoInadimplente,
      'habilitarVenceHoje': habilitarVenceHoje,
    };
  }

  static InadimplenciaConfig fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return defaults;
    return InadimplenciaConfig(
      diaLimitePagamento:
          (map['diaLimitePagamento'] as num?)?.toInt() ?? defaults.diaLimitePagamento,
      diasTolerancia:
          (map['diasTolerancia'] as num?)?.toInt() ?? defaults.diasTolerancia,
      permitirAcessoMesmoInadimplente:
          map['permitirAcessoMesmoInadimplente'] as bool? ??
              defaults.permitirAcessoMesmoInadimplente,
      habilitarVenceHoje:
          map['habilitarVenceHoje'] as bool? ?? defaults.habilitarVenceHoje,
    );
  }
}
