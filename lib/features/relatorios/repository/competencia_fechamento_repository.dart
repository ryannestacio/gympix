import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_fields.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/firestore_retry_policy.dart';
import '../models/competencia_report.dart';

class CompetenciaFechamentoRepository {
  CompetenciaFechamentoRepository(
    this._db,
    this._tenantId, {
    RetryPolicy? retryPolicy,
  }) : _retryPolicy = retryPolicy ?? RetryPolicy.critical;

  final FirebaseFirestore _db;
  final String _tenantId;
  final RetryPolicy _retryPolicy;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirestoreRefs.tenantFechamentosMensais(_db, _tenantId);

  Stream<CompetenciaReportData?> watchFechamento(String competencia) {
    return _col.doc(competencia).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return CompetenciaReportData.fromFirestore(data);
    });
  }

  Future<CompetenciaReportData?> getFechamento(String competencia) async {
    final doc = await _col.doc(competencia).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return CompetenciaReportData.fromFirestore(data);
  }

  Future<void> salvarFechamento(CompetenciaReportData report) {
    return _retryPolicy.execute(() async {
      final docRef = _col.doc(report.competencia);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final data = <String, Object?>{
          ...report.toFirestore(),
          FirestoreFields.tenantId: _tenantId,
          FirestoreFields.docType: FirestoreDocTypes.fechamentoMensal,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        };
        if (!snap.exists) {
          data[FirestoreFields.createdAt] = FieldValue.serverTimestamp();
        }
        tx.set(docRef, data, SetOptions(merge: true));
      });
    });
  }
}
