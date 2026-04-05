import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_retry_policy.dart';
import '../models/aluno.dart';

class AlunosRepository {
  AlunosRepository(
    this._db,
    this._tenantId, {
    RetryPolicy? retryPolicy,
  }) : _retryPolicy = retryPolicy ?? RetryPolicy.critical;

  final FirebaseFirestore _db;
  final String _tenantId;
  final RetryPolicy _retryPolicy;

  DocumentReference<Map<String, dynamic>> get _tenantDoc =>
      _db.collection('tenants').doc(_tenantId);

  CollectionReference<Map<String, dynamic>> get _col =>
      _tenantDoc.collection('alunos');

  Stream<List<Aluno>> watchAlunos() {
    return watchAlunosAtivos();
  }

  Stream<List<Aluno>> watchAlunosAtivos() {
    return _watchAlunos(onlyActive: true);
  }

  Stream<List<Aluno>> watchTodosAlunos() {
    return _watchAlunos();
  }

  Stream<List<Aluno>> _watchAlunos({bool onlyActive = false}) {
    return _col.orderBy('diaVencimento').snapshots().map((snap) {
      final alunos = snap.docs.map(Aluno.fromDoc).toList();
      if (!onlyActive) return alunos;
      return alunos.where((aluno) => aluno.ativo).toList();
    });
  }

  Future<void> createAluno({
    required String nome,
    required String telefone,
    required String observacao,
    required int diaVencimento,
    required double mensalidade,
    required bool pago,
  }) {
    final competencia = Aluno.competenciaAtual();
    final now = DateTime.now();
    final diaVencimentoEfetivo = Aluno.diaVencimentoEfetivo(diaVencimento, now);
    final status = pago
        ? PagamentoStatus.pago
        : (now.day > diaVencimentoEfetivo
              ? PagamentoStatus.atrasado
              : PagamentoStatus.pendente);

    final pagamentoInicial = PagamentoMensal(
      competencia: competencia,
      valor: mensalidade,
      status: status,
      diaVencimento: diaVencimentoEfetivo,
      pagoEm: pago ? now : null,
    );

    final novo = Aluno(
      id: '',
      nome: nome.trim(),
      telefone: telefone.trim(),
      observacao: observacao.trim(),
      diaVencimento: diaVencimento,
      mensalidade: mensalidade,
      criadoEm: DateTime.now(),
      pagamentos: {competencia: pagamentoInicial},
      pagoLegado: null,
    );

    return _retryPolicy.execute(() => _col.add(novo.toFirestoreCreate()));
  }

  Future<void> updateAluno(Aluno aluno) {
    final data = aluno.toFirestoreUpdate();
    return _retryPolicy.execute(() => _col.doc(aluno.id).update(data));
  }

  Future<void> syncPagamentoDoMesAtual(Aluno aluno) {
    final competencia = Aluno.competenciaAtual();
    final pagamento = aluno.pagamentoDoMesSincronizadoComCadastro();
    final data = {
      'pagamentos.$competencia': {
        ...pagamento.toFirestore(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      'pago': pagamento.pago,
    };
    return _retryPolicy.execute(() => _col.doc(aluno.id).update(data));
  }

  Future<void> archiveAluno(String id) {
    return _retryPolicy.execute(() => _col.doc(id).update({
      'ativo': false,
      'arquivadoEm': FieldValue.serverTimestamp(),
    }));
  }

  Future<void> unarchiveAluno(String id) {
    return _retryPolicy.execute(() => _col.doc(id).update({
      'ativo': true,
      'arquivadoEm': null,
    }));
  }

  Future<void> setPago({
    required Aluno aluno,
    required bool pago,
    double? valor,
    String? comprovanteUrl,
    String? observacao,
    DateTime? pagoEm,
  }) {
    final competencia = Aluno.competenciaAtual();
    final now = DateTime.now();
    final valorMensal =
        valor ?? aluno.pagamentos[competencia]?.valor ?? aluno.mensalidade;
    final diaVencimentoEfetivo = Aluno.diaVencimentoEfetivo(
      aluno.diaVencimento,
      now,
    );
    final status = pago
        ? PagamentoStatus.pago
        : (now.day > diaVencimentoEfetivo
              ? PagamentoStatus.atrasado
              : PagamentoStatus.pendente);

    final pagamento = PagamentoMensal(
      competencia: competencia,
      valor: valorMensal,
      status: status,
      diaVencimento: diaVencimentoEfetivo,
      pagoEm: pago ? (pagoEm ?? now) : null,
      comprovanteUrl: pago ? comprovanteUrl?.trim() : null,
      observacao: pago ? observacao?.trim() : null,
    );

    final data = {
      'pagamentos.$competencia': {
        ...pagamento.toFirestore(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      'pago': pago,
    };
    return _retryPolicy.execute(() => _col.doc(aluno.id).update(data));
  }
}
