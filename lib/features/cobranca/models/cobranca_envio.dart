import 'package:cloud_firestore/cloud_firestore.dart';

import '../../alunos/models/aluno.dart';

enum CobrancaCanal {
  manualCopia,
  manualCompartilhamento,
  manualWhatsapp,
  automacaoLocal,
  automacaoPush,
}

class CobrancaEnvio {
  const CobrancaEnvio({
    required this.alunoId,
    required this.competencia,
    required this.status,
    required this.diasRelativos,
    required this.canal,
    required this.automatico,
    required this.mensagem,
    required this.enviadoEm,
    this.id,
    this.templateUsado,
    this.pixPayload,
    this.cobrancaLink,
  });

  final String? id;
  final String alunoId;
  final String competencia;
  final PagamentoStatus status;
  final int diasRelativos;
  final CobrancaCanal canal;
  final bool automatico;
  final String mensagem;
  final DateTime enviadoEm;
  final String? templateUsado;
  final String? pixPayload;
  final String? cobrancaLink;

  CobrancaEnvio copyWith({
    String? id,
    String? alunoId,
    String? competencia,
    PagamentoStatus? status,
    int? diasRelativos,
    CobrancaCanal? canal,
    bool? automatico,
    String? mensagem,
    DateTime? enviadoEm,
    String? templateUsado,
    String? pixPayload,
    String? cobrancaLink,
  }) {
    return CobrancaEnvio(
      id: id ?? this.id,
      alunoId: alunoId ?? this.alunoId,
      competencia: competencia ?? this.competencia,
      status: status ?? this.status,
      diasRelativos: diasRelativos ?? this.diasRelativos,
      canal: canal ?? this.canal,
      automatico: automatico ?? this.automatico,
      mensagem: mensagem ?? this.mensagem,
      enviadoEm: enviadoEm ?? this.enviadoEm,
      templateUsado: templateUsado ?? this.templateUsado,
      pixPayload: pixPayload ?? this.pixPayload,
      cobrancaLink: cobrancaLink ?? this.cobrancaLink,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'alunoId': alunoId,
      'competencia': competencia,
      'status': status.name,
      'diasRelativos': diasRelativos,
      'canal': canal.name,
      'automatico': automatico,
      'mensagem': mensagem,
      'templateUsado': templateUsado,
      'pixPayload': pixPayload,
      'cobrancaLink': cobrancaLink,
      'enviadoEm': Timestamp.fromDate(enviadoEm),
    };
  }

  static CobrancaEnvio fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String alunoId,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    return fromMap(
      data,
      id: doc.id,
      fallbackAlunoId: alunoId,
    );
  }

  static CobrancaEnvio fromMap(
    Map<String, dynamic> map, {
    String? id,
    String? fallbackAlunoId,
  }) {
    return CobrancaEnvio(
      id: id,
      alunoId: (map['alunoId'] as String?)?.trim().isNotEmpty == true
          ? (map['alunoId'] as String).trim()
          : (fallbackAlunoId ?? ''),
      competencia: (map['competencia'] as String?)?.trim() ?? '',
      status: _parsePagamentoStatus(map['status']),
      diasRelativos: _parseInt(map['diasRelativos'], 0),
      canal: _parseCanal(map['canal']),
      automatico: map['automatico'] as bool? ?? false,
      mensagem: (map['mensagem'] as String?)?.trim() ?? '',
      enviadoEm: _parseDateTime(map['enviadoEm']),
      templateUsado: (map['templateUsado'] as String?)?.trim(),
      pixPayload: (map['pixPayload'] as String?)?.trim(),
      cobrancaLink: (map['cobrancaLink'] as String?)?.trim(),
    );
  }
}

PagamentoStatus _parsePagamentoStatus(dynamic value) {
  if (value is String) {
    for (final status in PagamentoStatus.values) {
      if (status.name == value) return status;
    }
  }
  return PagamentoStatus.pendente;
}

CobrancaCanal _parseCanal(dynamic value) {
  if (value is String) {
    for (final canal in CobrancaCanal.values) {
      if (canal.name == value) return canal;
    }
  }
  return CobrancaCanal.manualCopia;
}

DateTime _parseDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
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
