import '../../alunos/models/aluno.dart';

class CobrancaReguaStep {
  const CobrancaReguaStep({
    required this.diasRelativos,
    required this.ativo,
  });

  final int diasRelativos;
  final bool ativo;

  CobrancaReguaStep copyWith({
    int? diasRelativos,
    bool? ativo,
  }) {
    return CobrancaReguaStep(
      diasRelativos: diasRelativos ?? this.diasRelativos,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'diasRelativos': diasRelativos,
      'ativo': ativo,
    };
  }

  static CobrancaReguaStep fromMap(Map<String, dynamic> map) {
    return CobrancaReguaStep(
      diasRelativos: _parseInt(map['diasRelativos'], 0),
      ativo: map['ativo'] as bool? ?? true,
    );
  }
}

class CobrancaReguaConfig {
  const CobrancaReguaConfig({
    required this.automacaoAtiva,
    required this.notificacaoLocalAtiva,
    required this.notificacaoPushAtiva,
    required this.passos,
    required this.templatePendente,
    required this.templateAtrasado,
    required this.linkBaseUrl,
  });

  static const String defaultTemplatePendente =
      'Ola {nome}! Lembrete da mensalidade {competencia}. Valor: {valor}. '
      'Vencimento: dia {vencimento} ({dias_label}). Pix copia e cola: {pix}';

  static const String defaultTemplateAtrasado =
      'Ola {nome}! Consta pendencia da mensalidade {competencia}. '
      'Valor: {valor}. Venceu no dia {vencimento} ({dias_label}). '
      'Regularize pelo Pix: {pix}';

  static const CobrancaReguaConfig defaults = CobrancaReguaConfig(
    automacaoAtiva: true,
    notificacaoLocalAtiva: true,
    notificacaoPushAtiva: false,
    passos: <CobrancaReguaStep>[
      CobrancaReguaStep(diasRelativos: -3, ativo: true),
      CobrancaReguaStep(diasRelativos: 0, ativo: true),
      CobrancaReguaStep(diasRelativos: 3, ativo: true),
    ],
    templatePendente: defaultTemplatePendente,
    templateAtrasado: defaultTemplateAtrasado,
    linkBaseUrl: 'https://gympix.app',
  );

  final bool automacaoAtiva;
  final bool notificacaoLocalAtiva;
  final bool notificacaoPushAtiva;
  final List<CobrancaReguaStep> passos;
  final String templatePendente;
  final String templateAtrasado;
  final String linkBaseUrl;

  CobrancaReguaConfig copyWith({
    bool? automacaoAtiva,
    bool? notificacaoLocalAtiva,
    bool? notificacaoPushAtiva,
    List<CobrancaReguaStep>? passos,
    String? templatePendente,
    String? templateAtrasado,
    String? linkBaseUrl,
  }) {
    return CobrancaReguaConfig(
      automacaoAtiva: automacaoAtiva ?? this.automacaoAtiva,
      notificacaoLocalAtiva:
          notificacaoLocalAtiva ?? this.notificacaoLocalAtiva,
      notificacaoPushAtiva: notificacaoPushAtiva ?? this.notificacaoPushAtiva,
      passos: passos ?? this.passos,
      templatePendente: templatePendente ?? this.templatePendente,
      templateAtrasado: templateAtrasado ?? this.templateAtrasado,
      linkBaseUrl: linkBaseUrl ?? this.linkBaseUrl,
    );
  }

  bool isStepAtivo(int diasRelativos) {
    return passos.any((p) => p.diasRelativos == diasRelativos && p.ativo);
  }

  String templateByStatus(PagamentoStatus status) {
    return status == PagamentoStatus.atrasado
        ? templateAtrasado
        : templatePendente;
  }

  List<int> diasAtivosOrdenados() {
    final offsets = passos.where((p) => p.ativo).map((p) => p.diasRelativos);
    final unique = offsets.toSet().toList()..sort();
    return unique;
  }

  Map<String, Object?> toMap() {
    return {
      'automacaoAtiva': automacaoAtiva,
      'notificacaoLocalAtiva': notificacaoLocalAtiva,
      'notificacaoPushAtiva': notificacaoPushAtiva,
      'passos': passos.map((p) => p.toMap()).toList(),
      'templatePendente': templatePendente.trim(),
      'templateAtrasado': templateAtrasado.trim(),
      'linkBaseUrl': linkBaseUrl.trim(),
    };
  }

  static CobrancaReguaConfig fromMap(Map<String, dynamic> map) {
    final rawPassos = map['passos'];
    final passos = <CobrancaReguaStep>[];
    if (rawPassos is List) {
      for (final item in rawPassos) {
        if (item is Map<String, dynamic>) {
          passos.add(CobrancaReguaStep.fromMap(item));
          continue;
        }
        if (item is Map) {
          passos.add(CobrancaReguaStep.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return CobrancaReguaConfig(
      automacaoAtiva: map['automacaoAtiva'] as bool? ?? defaults.automacaoAtiva,
      notificacaoLocalAtiva:
          map['notificacaoLocalAtiva'] as bool? ?? defaults.notificacaoLocalAtiva,
      notificacaoPushAtiva:
          map['notificacaoPushAtiva'] as bool? ?? defaults.notificacaoPushAtiva,
      passos: passos.isEmpty ? defaults.passos : passos,
      templatePendente:
          (map['templatePendente'] as String?)?.trim().isNotEmpty == true
          ? (map['templatePendente'] as String).trim()
          : defaults.templatePendente,
      templateAtrasado:
          (map['templateAtrasado'] as String?)?.trim().isNotEmpty == true
          ? (map['templateAtrasado'] as String).trim()
          : defaults.templateAtrasado,
      linkBaseUrl: (map['linkBaseUrl'] as String?)?.trim().isNotEmpty == true
          ? (map['linkBaseUrl'] as String).trim()
          : defaults.linkBaseUrl,
    );
  }
}

int _parseInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}
