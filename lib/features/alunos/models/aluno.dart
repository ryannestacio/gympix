import 'package:cloud_firestore/cloud_firestore.dart';

enum PagamentoStatus { pendente, atrasado, pago }

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
    switch (status) {
      case PagamentoStatus.pago:
        return 'Pago';
      case PagamentoStatus.atrasado:
        return 'Atrasado';
      case PagamentoStatus.pendente:
        return 'Pendente';
    }
  }

  Map<String, Object?> toFirestore() {
    return {
      'competencia': competencia,
      'valor': valor,
      'status': status.name,
      'diaVencimento': diaVencimento,
      'pagoEm': pagoEm == null ? null : Timestamp.fromDate(pagoEm!),
      'comprovanteUrl': comprovanteUrl,
      'observacao': observacao,
    };
  }

  static PagamentoMensal fromMap(
    String competencia,
    Map<String, dynamic> map, {
    required double fallbackValor,
    required int fallbackDiaVencimento,
  }) {
    final rawPagoEm = map['pagoEm'];
    return PagamentoMensal(
      competencia: competencia,
      valor: _parseDouble(map['valor'], fallbackValor),
      status: _parseStatus(map['status'], fallbackDiaVencimento),
      diaVencimento: _parseDia(map['diaVencimento'], fallbackDiaVencimento),
      pagoEm: rawPagoEm is Timestamp ? rawPagoEm.toDate() : null,
      comprovanteUrl: (map['comprovanteUrl'] as String?)?.trim(),
      observacao: (map['observacao'] as String?)?.trim(),
    );
  }

  static PagamentoStatus _parseStatus(dynamic value, int diaVencimento) {
    if (value is String) {
      for (final status in PagamentoStatus.values) {
        if (status.name == value) return status;
      }
    }
    return _isVencimentoEmAtraso(DateTime.now(), diaVencimento)
        ? PagamentoStatus.atrasado
        : PagamentoStatus.pendente;
  }
}

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

  // Compatibilidade com documentos antigos que tinham apenas o bool pago.
  final bool? pagoLegado;

  static String competenciaAtual([DateTime? now]) {
    final d = now ?? DateTime.now();
    final month = d.month.toString().padLeft(2, '0');
    return '${d.year}-$month';
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
    final competencia = competenciaAtual(ref);
    final existente = pagamentos[competencia];
    if (existente != null) return existente;

    if (pagoLegado == true) {
      return PagamentoMensal(
        competencia: competencia,
        valor: mensalidade,
        status: PagamentoStatus.pago,
        diaVencimento: diaVencimento,
      );
    }

    return PagamentoMensal(
      competencia: competencia,
      valor: mensalidade,
      status: _isVencimentoEmAtraso(ref, diaVencimento)
          ? PagamentoStatus.atrasado
          : PagamentoStatus.pendente,
      diaVencimento: diaVencimentoEfetivo(diaVencimento, ref),
    );
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

  /// Atualiza somente campos editáveis do cadastro do aluno.
  Map<String, Object?> toFirestoreUpdate() {
    return {
      'nome': nome,
      'telefone': telefone,
      'observacao': observacao,
      'diaVencimento': diaVencimento,
      'mensalidade': mensalidade,
    };
  }

  Map<String, Object?> toFirestoreCreate() {
    return {
      ...toFirestoreUpdate(),
      'criadoEm': FieldValue.serverTimestamp(),
      'ativo': ativo,
      'arquivadoEm': arquivadoEm == null
          ? null
          : Timestamp.fromDate(arquivadoEm!),
      'pagamentos': {
        for (final entry in pagamentos.entries)
          entry.key: entry.value.toFirestore(),
      },
    };
  }

  static Aluno fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final criado = data['criadoEm'];
    final arquivado = data['arquivadoEm'];
    final diaVencimento = _parseDia(data['diaVencimento'], 1);
    final mensalidade = _parseDouble(data['mensalidade'], 0);

    final pagamentos = <String, PagamentoMensal>{};
    final rawPagamentos = data['pagamentos'];
    if (rawPagamentos is Map) {
      for (final entry in rawPagamentos.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          pagamentos[key] = PagamentoMensal.fromMap(
            key,
            value,
            fallbackValor: mensalidade,
            fallbackDiaVencimento: diaVencimento,
          );
        } else if (value is Map) {
          pagamentos[key] = PagamentoMensal.fromMap(
            key,
            Map<String, dynamic>.from(value),
            fallbackValor: mensalidade,
            fallbackDiaVencimento: diaVencimento,
          );
        }
      }
    }

    return Aluno(
      id: doc.id,
      nome: (data['nome'] ?? '') as String,
      telefone: (data['telefone'] ?? '') as String,
      observacao: ((data['observacao'] ?? '') as String).trim(),
      diaVencimento: diaVencimento,
      mensalidade: mensalidade,
      criadoEm: (criado is Timestamp) ? criado.toDate() : DateTime.now(),
      pagamentos: pagamentos,
      ativo: data['ativo'] as bool? ?? true,
      arquivadoEm: arquivado is Timestamp ? arquivado.toDate() : null,
      pagoLegado: data['pago'] as bool?,
    );
  }
}

bool _isVencimentoEmAtraso(DateTime referenceDate, int diaVencimento) {
  final hoje = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );
  final vencimento = Aluno.dataVencimento(diaVencimento, referenceDate);
  return hoje.isAfter(vencimento);
}

int _parseDia(dynamic value, int fallback) {
  if (value is int) {
    return value.clamp(1, 31).toInt();
  }
  if (value is num) {
    return value.toInt().clamp(1, 31);
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed.clamp(1, 31).toInt();
  }
  return fallback;
}

double _parseDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized);
    if (parsed != null) return parsed;
  }
  return fallback;
}

