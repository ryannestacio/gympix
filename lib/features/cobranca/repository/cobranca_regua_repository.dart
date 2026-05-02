import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_fields.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/firestore_retry_policy.dart';
import '../../alunos/models/aluno.dart';
import '../models/cobranca_envio.dart';
import '../models/cobranca_regua.dart';

class CobrancaReguaRepository {
  CobrancaReguaRepository(this._db, this._tenantId, {RetryPolicy? retryPolicy})
    : _retryPolicy = retryPolicy ?? RetryPolicy.critical;

  final FirebaseFirestore _db;
  final String _tenantId;
  final RetryPolicy _retryPolicy;

  DocumentReference<Map<String, dynamic>> get _appDoc =>
      FirestoreRefs.tenantConfigDoc(_db, _tenantId, FirestoreConfigDocs.app);

  CollectionReference<Map<String, dynamic>> _enviosCol(String alunoId) {
    return FirestoreRefs.tenantAlunoCobrancaEnvios(_db, _tenantId, alunoId);
  }

  CollectionReference<Map<String, dynamic>> get _pushQueueCol =>
      FirestoreRefs.tenantCobrancaPushQueue(_db, _tenantId);

  Stream<CobrancaReguaConfig> watchReguaConfig() {
    return _appDoc.snapshots().map((doc) {
      final data = doc.data();
      final raw = data?['cobrancaRegua'];
      if (raw is Map<String, dynamic>) {
        return CobrancaReguaConfig.fromMap(raw);
      }
      if (raw is Map) {
        return CobrancaReguaConfig.fromMap(Map<String, dynamic>.from(raw));
      }
      return CobrancaReguaConfig.defaults;
    });
  }

  Future<CobrancaReguaConfig> getReguaConfig() async {
    final doc = await _appDoc.get();
    final data = doc.data();
    final raw = data?['cobrancaRegua'];
    if (raw is Map<String, dynamic>) {
      return CobrancaReguaConfig.fromMap(raw);
    }
    if (raw is Map) {
      return CobrancaReguaConfig.fromMap(Map<String, dynamic>.from(raw));
    }
    return CobrancaReguaConfig.defaults;
  }

  Future<void> setReguaConfig(CobrancaReguaConfig config) {
    return _upsertTenantAppConfig({'cobrancaRegua': config.toMap()});
  }

  Stream<List<CobrancaEnvio>> watchEnviosAluno(
    String alunoId, {
    int limit = 40,
  }) {
    return _enviosCol(alunoId)
        .orderBy('enviadoEm', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => CobrancaEnvio.fromDoc(doc, alunoId: alunoId))
              .toList();
        });
  }

  Future<void> registrarEnvio(CobrancaEnvio envio, {String? customId}) {
    final docId = customId ?? _enviosCol(envio.alunoId).doc().id;
    return _retryPolicy.execute(
      () => _enviosCol(envio.alunoId).doc(docId).set({
        ...envio.toMap(),
        'enviadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

  Future<bool> registrarAutomacaoEnvioComIntegridade({
    required CobrancaEnvio envio,
    required String docId,
    required bool enqueuePush,
  }) {
    return _retryPolicy.execute(() async {
      final envioRef = _enviosCol(envio.alunoId).doc(docId);
      final pushJobId = buildPushQueueJobId(
        alunoId: envio.alunoId,
        envioId: docId,
      );
      final pushRef = _pushQueueCol.doc(pushJobId);

      return _db.runTransaction<bool>((tx) async {
        final envioSnap = await tx.get(envioRef);
        if (envioSnap.exists) return false;

        tx.set(envioRef, {
          ...envio.toMap(),
          'enviadoEm': FieldValue.serverTimestamp(),
        });

        if (enqueuePush) {
          final pushSnap = await tx.get(pushRef);
          if (!pushSnap.exists) {
            tx.set(pushRef, {
              ...envio.toMap(),
              'idempotencyKey': pushJobId,
              'filaStatus': 'pendente',
              'criadoEm': FieldValue.serverTimestamp(),
            });
          }
        }

        return true;
      });
    });
  }

  Future<void> _upsertTenantAppConfig(Map<String, Object?> payload) {
    return _retryPolicy.execute(() async {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(_appDoc);
        final data = <String, Object?>{
          ...payload,
          FirestoreFields.tenantId: _tenantId,
          FirestoreFields.docType: FirestoreDocTypes.appConfig,
          FirestoreFields.status: FirestoreStatus.ativo,
          FirestoreFields.ativo: true,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        };
        if (!snap.exists) {
          data[FirestoreFields.createdAt] = FieldValue.serverTimestamp();
        }
        tx.set(_appDoc, data, SetOptions(merge: true));
      });
    });
  }

  static String buildAutomacaoDocId({
    required String competencia,
    required int diasRelativos,
    required PagamentoStatus status,
  }) {
    final offsetLabel = diasRelativos < 0
        ? 'm${-diasRelativos}'
        : diasRelativos == 0
        ? 'd0'
        : 'p$diasRelativos';
    return 'auto_${competencia}_${offsetLabel}_${status.name}';
  }

  static String buildPushQueueJobId({
    required String alunoId,
    required String envioId,
  }) {
    final normalizedAluno = alunoId.replaceAll('/', '_');
    final normalizedEnvio = envioId.replaceAll('/', '_');
    return 'push_${normalizedAluno}_$normalizedEnvio';
  }
}
