import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_fields.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/firestore_retry_policy.dart';
import '../models/aluno.dart';
import 'aluno_mapper.dart';

/// Resultado de uma consulta paginada.
class AlunoPageResult {
  const AlunoPageResult({
    required this.alunos,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<Aluno> alunos;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;
}

class AlunosRepository {
  AlunosRepository(this._db, this._tenantId, {RetryPolicy? retryPolicy})
    : _retryPolicy = retryPolicy ?? RetryPolicy.critical;

  final FirebaseFirestore _db;
  final String _tenantId;
  final RetryPolicy _retryPolicy;
  Future<int>? _backfillInFlight;

  static const int defaultPageSize = 20;

  CollectionReference<Map<String, dynamic>> get _alunosCol =>
      FirestoreRefs.tenantAlunos(_db, _tenantId);

  // --- Real-time streams (sem paginação, para stats e UI reativa) ---

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
    return _alunosCol
        .orderBy('diaVencimento')
        .orderBy(FieldPath.documentId)
        .snapshots()
        .map((snap) {
          final alunos = snap.docs.map(AlunoMapper.fromDoc).toList();
          if (!onlyActive) return alunos;
          return alunos.where((aluno) => aluno.ativo).toList();
        });
  }

  // --- Paginação com startAfterDocument ---

  Future<AlunoPageResult> fetchAlunosPage({
    DocumentSnapshot? startAfter,
    int? limit,
    bool onlyActive = false,
  }) async {
    final pageSize = limit ?? defaultPageSize;

    Query<Map<String, dynamic>> query = _alunosCol
        .orderBy('diaVencimento')
        .orderBy(FieldPath.documentId)
        .limit(pageSize);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snap = await _retryPolicy.execute(() => query.get());

    final alunos = snap.docs.map(AlunoMapper.fromDoc).toList();

    if (onlyActive) {
      return _activeAlunosFromQueryResult(alunos, snap, pageSize);
    }

    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    final hasMore = snap.size >= pageSize;

    return AlunoPageResult(alunos: alunos, lastDoc: lastDoc, hasMore: hasMore);
  }

  /// Filtra alunos ativos pos-query e re-executa se paginacao reduzir demais.
  AlunoPageResult _activeAlunosFromQueryResult(
    List<Aluno> alunos,
    QuerySnapshot<Map<String, dynamic>> snap,
    int requestedPageSize,
  ) {
    final ativos = alunos.where((a) => a.ativo).toList();
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    // hasMore e estimado; com filtro somente-active pode haver mais paginas.
    final hasMore = snap.size >= requestedPageSize;
    return AlunoPageResult(alunos: ativos, lastDoc: lastDoc, hasMore: hasMore);
  }

  // --- Escritas ---

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

    final payload = {
      ...AlunoMapper.toFirestoreCreate(novo),
      FirestoreFields.tenantId: _tenantId,
      FirestoreFields.docType: FirestoreDocTypes.aluno,
    };

    return _retryPolicy.execute(() => _alunosCol.add(payload));
  }

  Future<void> updateAluno(Aluno aluno) {
    final data = {
      ...AlunoMapper.toFirestoreUpdate(aluno),
      FirestoreFields.status: aluno.ativo
          ? FirestoreStatus.ativo
          : FirestoreStatus.arquivado,
      FirestoreFields.tenantId: _tenantId,
    };
    return _retryPolicy.execute(() => _alunosCol.doc(aluno.id).update(data));
  }

  Future<void> syncPagamentoDoMesAtual(Aluno aluno) {
    final competencia = Aluno.competenciaAtual();
    final pagamento = aluno.pagamentoDoMesSincronizadoComCadastro();
    final data = {
      'pagamentos.$competencia': {
        ...AlunoMapper.pagamentoToFirestore(pagamento),
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      'pago': pagamento.pago,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
    return _retryPolicy.execute(() => _alunosCol.doc(aluno.id).update(data));
  }

  Future<void> archiveAluno(String id) {
    return _retryPolicy.execute(
      () => _alunosCol.doc(id).update({
        FirestoreFields.ativo: false,
        FirestoreFields.status: FirestoreStatus.arquivado,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        'arquivadoEm': FieldValue.serverTimestamp(),
      }),
    );
  }

  Future<void> unarchiveAluno(String id) {
    return _retryPolicy.execute(
      () => _alunosCol.doc(id).update({
        FirestoreFields.ativo: true,
        FirestoreFields.status: FirestoreStatus.ativo,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        'arquivadoEm': null,
      }),
    );
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
        ...AlunoMapper.pagamentoToFirestore(pagamento),
        'atualizadoEm': FieldValue.serverTimestamp(),
      },
      'pago': pago,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
    return _retryPolicy.execute(() => _alunosCol.doc(aluno.id).update(data));
  }

  Future<void> quitarPendenciasAcumuladas({
    required Aluno aluno,
    DateTime? referencia,
    DateTime? pagoEm,
    String? comprovanteUrl,
    String? observacao,
  }) async {
    final now = pagoEm ?? DateTime.now();
    final referenciaBase = referencia ?? now;
    final pendencias = aluno
        .pagamentosAte(referenciaBase, referenciaStatus: now)
        .where((pagamento) => !pagamento.pago)
        .toList();
    if (pendencias.isEmpty) return;

    final data = <String, Object?>{};
    for (final pendencia in pendencias) {
      final pagamentoQuitado = pendencia.copyWith(
        status: PagamentoStatus.pago,
        pagoEm: now,
        comprovanteUrl: comprovanteUrl?.trim(),
        observacao: observacao?.trim(),
      );
      data['pagamentos.${pendencia.competencia}'] = {
        ...AlunoMapper.pagamentoToFirestore(pagamentoQuitado),
        'atualizadoEm': FieldValue.serverTimestamp(),
      };
    }

    final competenciaAtual = Aluno.competenciaAtual(referenciaBase);
    final competenciaAtualCobravel = aluno
        .competenciasCobraveisAte(referenciaBase)
        .contains(competenciaAtual);
    if (competenciaAtualCobravel) {
      final quitouMesAtual = pendencias.any(
        (pagamento) => pagamento.competencia == competenciaAtual,
      );
      final pagoMesAtual = quitouMesAtual
          ? true
          : aluno
                .pagamentoDaCompetencia(competenciaAtual, referenciaStatus: now)
                .pago;
      data['pago'] = pagoMesAtual;
    }
    data[FirestoreFields.updatedAt] = FieldValue.serverTimestamp();

    await _retryPolicy.execute(() => _alunosCol.doc(aluno.id).update(data));
  }

  Future<int> backfillPagamentosAcumulados({
    required Iterable<Aluno> alunos,
    DateTime? referencia,
    DateTime? agora,
  }) {
    final running = _backfillInFlight;
    if (running != null) return running;

    late final Future<int> future;
    future =
        _executarBackfillPagamentosAcumulados(
          alunos: alunos,
          referencia: referencia,
          agora: agora,
        ).whenComplete(() {
          if (identical(_backfillInFlight, future)) {
            _backfillInFlight = null;
          }
        });
    _backfillInFlight = future;
    return future;
  }

  Future<int> _executarBackfillPagamentosAcumulados({
    required Iterable<Aluno> alunos,
    DateTime? referencia,
    DateTime? agora,
  }) async {
    final referenciaBase = referencia ?? DateTime.now();
    final now = agora ?? DateTime.now();
    var totalCompetenciasPersistidas = 0;

    for (final aluno in alunos) {
      final pagamentosFaltantes = _pagamentosFaltantesAte(
        aluno,
        referencia: referenciaBase,
        agora: now,
      );
      if (pagamentosFaltantes.isEmpty) continue;

      final data = <String, Object?>{};
      for (final entry in pagamentosFaltantes.entries) {
        data['pagamentos.${entry.key}'] = {
          ...AlunoMapper.pagamentoToFirestore(entry.value),
          'atualizadoEm': FieldValue.serverTimestamp(),
        };
      }

      final competenciaAtual = Aluno.competenciaAtual(referenciaBase);
      if (pagamentosFaltantes.containsKey(competenciaAtual)) {
        data['pago'] = pagamentosFaltantes[competenciaAtual]!.pago;
      }
      data[FirestoreFields.updatedAt] = FieldValue.serverTimestamp();

      await _retryPolicy.execute(() => _alunosCol.doc(aluno.id).update(data));
      totalCompetenciasPersistidas += pagamentosFaltantes.length;
    }

    return totalCompetenciasPersistidas;
  }

  Map<String, PagamentoMensal> _pagamentosFaltantesAte(
    Aluno aluno, {
    required DateTime referencia,
    required DateTime agora,
  }) {
    final faltantes = <String, PagamentoMensal>{};
    final competencias = aluno.competenciasCobraveisAte(referencia);

    for (final competencia in competencias) {
      if (aluno.pagamentos.containsKey(competencia)) continue;
      final referenciaCompetencia =
          Aluno.tryParseCompetencia(competencia) ?? referencia;
      final referenciaStatus = Aluno.referenciaStatusDaCompetencia(
        referenciaCompetencia,
        agora: agora,
      );
      faltantes[competencia] = aluno.pagamentoDaCompetencia(
        competencia,
        referenciaStatus: referenciaStatus,
      );
    }

    return faltantes;
  }
}
