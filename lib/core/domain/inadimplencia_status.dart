/// Status de inadimplencia baseado em competencia mensal
/// com granularidade empresarial:
///   emDia       -> pagou o mes vigente
///   aVencer     -> dentro do prazo inicial de pagamento
///   venceHoje   -> ultimo dia do prazo inicial
///   emAtraso    -> passou do prazo, mas dentro da tolerancia
///   inadimplente -> ultrapassou a tolerancia
enum InadimplenciaStatus {
  emDia,
  aVencer,
  venceHoje,
  emAtraso,
  inadimplente,
}

extension InadimplenciaStatusX on InadimplenciaStatus {
  /// Cor semantic consistente com o Design System existente
  String get label => switch (this) {
    InadimplenciaStatus.emDia => 'Em dia',
    InadimplenciaStatus.aVencer => 'A vencer',
    InadimplenciaStatus.venceHoje => 'Vence hoje',
    InadimplenciaStatus.emAtraso => 'Em atraso',
    InadimplenciaStatus.inadimplente => 'Inadimplente',
  };

  String get shortLabel => switch (this) {
    InadimplenciaStatus.emDia => 'PAGO',
    InadimplenciaStatus.aVencer => 'A VENCER',
    InadimplenciaStatus.venceHoje => 'VENCE HOJE',
    InadimplenciaStatus.emAtraso => 'ATRASADO',
    InadimplenciaStatus.inadimplente => 'INADIMPLENTE',
  };

  /// Label detalhado com contagem de dias (ex: "Atrasado ha 3 dias")
  String detailedLabel({int? diasRestantes, int? diasAtraso}) {
    if (diasRestantes != null && diasRestantes > 0) {
      return 'Vence em $diasRestantes ${diasRestantes == 1 ? 'dia' : 'dias'}';
    }
    if (diasAtraso != null && diasAtraso > 0) {
      return 'Atrasado ha $diasAtraso ${diasAtraso == 1 ? 'dia' : 'dias'}';
    }
    return label;
  }

  bool get isPago => this == InadimplenciaStatus.emDia;
  bool get isVencendo =>
      this == InadimplenciaStatus.aVencer ||
      this == InadimplenciaStatus.venceHoje;
  bool get isAtrasado => this == InadimplenciaStatus.inadimplente;
  bool get isAlerta => this == InadimplenciaStatus.emAtraso;
}
