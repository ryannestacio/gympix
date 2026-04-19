import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/aluno.dart';

/// Converte [Aluno] e [PagamentoMensal] para/de documentos do Firestore.
/// Toda a logica de mapeamento de persistencia fica aqui,
/// mantendo os models de dominio livres de dependencia de banco.
class AlunoMapper {
  // --- Aluno: Firestore ---

  /// Converte um [Aluno] em mapa para criação no Firestore.
  static Map<String, Object?> toFirestoreCreate(Aluno aluno) {
    return {
      ...toFirestoreUpdate(aluno),
      'criadoEm': FieldValue.serverTimestamp(),
      'ativo': aluno.ativo,
      'arquivadoEm': aluno.arquivadoEm == null
          ? null
          : Timestamp.fromDate(aluno.arquivadoEm!),
      'pagamentos': {
        for (final entry in aluno.pagamentos.entries)
          entry.key: _pagamentoToMap(entry.value),
      },
    };
  }

  /// Converte os campos editaveis de um [Aluno] em mapa para update.
  static Map<String, Object?> toFirestoreUpdate(Aluno aluno) {
    return {
      'nome': aluno.nome,
      'telefone': aluno.telefone,
      'observacao': aluno.observacao,
      'diaVencimento': aluno.diaVencimento,
      'mensalidade': aluno.mensalidade,
    };
  }

  /// Converte [DocumentSnapshot] em [Aluno].
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
          pagamentos[key] = _pagamentoFromMap(
            key,
            value,
            fallbackValor: mensalidade,
            fallbackDiaVencimento: diaVencimento,
          );
        } else if (value is Map) {
          pagamentos[key] = _pagamentoFromMap(
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

  // --- PagamentoMensal: mapas internos ---

  /// Converte [PagamentoMensal] em mapa para Firestore.
  static Map<String, Object?> pagamentoToFirestore(PagamentoMensal p) {
    return _pagamentoToMap(p);
  }

  static Map<String, Object?> _pagamentoToMap(PagamentoMensal p) {
    return {
      'competencia': p.competencia,
      'valor': p.valor,
      'status': p.status.name,
      'diaVencimento': p.diaVencimento,
      'pagoEm': p.pagoEm == null ? null : Timestamp.fromDate(p.pagoEm!),
      'comprovanteUrl': p.comprovanteUrl,
      'observacao': p.observacao,
    };
  }

  static PagamentoMensal _pagamentoFromMap(
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

  // --- Helpers ---

  static int _parseDia(dynamic value, int fallback) {
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

  static double _parseDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed;
    }
    return fallback;
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

  static bool _isVencimentoEmAtraso(
    DateTime referenceDate,
    int diaVencimento,
  ) {
    final hoje = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final vencimento = Aluno.dataVencimento(diaVencimento, referenceDate);
    return hoje.isAfter(vencimento);
  }
}
