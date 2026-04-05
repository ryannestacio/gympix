import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/aluno.dart';

/// Converte [Aluno] e [PagamentoMensal] para/de documentos do Firestore.
/// Separa as dependências de persistência do model de domínio.
class AlunoMapper {
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
          entry.key: pagamentoToFirestore(entry.value),
      },
    };
  }

  /// Converte os campos editáveis de um [Aluno] em mapa para update.
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

  /// Converte [PagamentoMensal] em mapa para Firestore.
  static Map<String, Object?> pagamentoToFirestore(PagamentoMensal p) {
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
}
