import 'package:cloud_firestore/cloud_firestore.dart';

import '../../alunos/models/aluno.dart';
import '../models/cobranca_envio.dart';
import '../models/cobranca_regua.dart';

class CobrancaReguaRepository {
  CobrancaReguaRepository(this._db, this._tenantId);
  final FirebaseFirestore _db;
  final String _tenantId;

  DocumentReference<Map<String, dynamic>> get _tenantDoc =>
      _db.collection('tenants').doc(_tenantId);

  DocumentReference<Map<String, dynamic>> get _appDoc =>
      _tenantDoc.collection('config').doc('app');

  CollectionReference<Map<String, dynamic>> _enviosCol(String alunoId) {
    return _tenantDoc
        .collection('alunos')
        .doc(alunoId)
        .collection('cobranca_envios');
  }

  CollectionReference<Map<String, dynamic>> get _pushQueueCol =>
      _tenantDoc.collection('cobranca_push_queue');

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

  Future<void> setReguaConfig(CobrancaReguaConfig config) async {
    await _appDoc.set({
      'cobrancaRegua': config.toMap(),
    }, SetOptions(merge: true));
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

  Future<void> registrarEnvio(CobrancaEnvio envio, {String? customId}) async {
    final docId = customId ?? _enviosCol(envio.alunoId).doc().id;
    await _enviosCol(envio.alunoId).doc(docId).set({
      ...envio.toMap(),
      'enviadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> hasAutomacaoRegistro({
    required String alunoId,
    required String competencia,
    required int diasRelativos,
    required PagamentoStatus status,
  }) async {
    final docId = buildAutomacaoDocId(
      competencia: competencia,
      diasRelativos: diasRelativos,
      status: status,
    );
    final doc = await _enviosCol(alunoId).doc(docId).get();
    return doc.exists;
  }

  Future<void> enqueuePush(CobrancaEnvio envio) async {
    await _pushQueueCol.add({
      ...envio.toMap(),
      'filaStatus': 'pendente',
      'criadoEm': FieldValue.serverTimestamp(),
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
}
