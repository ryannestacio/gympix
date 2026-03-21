import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/competencia_report.dart';

class CompetenciaFechamentoRepository {
  CompetenciaFechamentoRepository(this._db, this._tenantId);

  final FirebaseFirestore _db;
  final String _tenantId;

  DocumentReference<Map<String, dynamic>> get _tenantDoc =>
      _db.collection('tenants').doc(_tenantId);

  CollectionReference<Map<String, dynamic>> get _col =>
      _tenantDoc.collection('fechamentos_mensais');

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

  Future<void> salvarFechamento(CompetenciaReportData report) async {
    await _col.doc(report.competencia).set(report.toFirestore());
  }
}
