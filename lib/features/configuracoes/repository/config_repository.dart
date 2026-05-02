import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/firestore_fields.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/domain/inadimplencia_config.dart';
import '../../../core/utils/firestore_retry_policy.dart';
import '../../cobranca/models/cobranca_regua.dart';

class ConfigRepository {
  ConfigRepository(this._db, this._tenantId, {RetryPolicy? retryPolicy})
    : _retryPolicy = retryPolicy ?? RetryPolicy.standard;

  final FirebaseFirestore _db;
  final String _tenantId;
  final RetryPolicy _retryPolicy;

  DocumentReference<Map<String, dynamic>> get _pixDoc =>
      FirestoreRefs.tenantConfigDoc(_db, _tenantId, FirestoreConfigDocs.pix);

  DocumentReference<Map<String, dynamic>> get _appDoc =>
      FirestoreRefs.tenantConfigDoc(_db, _tenantId, FirestoreConfigDocs.app);

  Stream<String?> watchPixCode() {
    return _pixDoc.snapshots().map((doc) {
      final data = doc.data();
      final code = data?['pixCode'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
      return null;
    });
  }

  Future<String?> getPixCode() async {
    final doc = await _pixDoc.get();
    final data = doc.data();
    final code = data?['pixCode'];
    if (code is String && code.trim().isNotEmpty) return code.trim();
    return null;
  }

  Future<void> setPixCode(String pixCode) {
    return _upsertConfigDoc(
      docRef: _pixDoc,
      docType: FirestoreDocTypes.pixConfig,
      payload: {'pixCode': pixCode.trim()},
    );
  }

  Stream<double?> watchDefaultMensalidade() {
    return _appDoc.snapshots().map((doc) {
      final data = doc.data();
      final v = data?['defaultMensalidade'];
      if (v is num) return v.toDouble();
      return null;
    });
  }

  Future<void> setDefaultMensalidade(double value) {
    return _upsertConfigDoc(
      docRef: _appDoc,
      docType: FirestoreDocTypes.appConfig,
      payload: {'defaultMensalidade': value},
    );
  }

  Stream<CobrancaReguaConfig> watchCobrancaReguaConfig() {
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

  Future<CobrancaReguaConfig> getCobrancaReguaConfig() async {
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

  Future<void> setCobrancaReguaConfig(CobrancaReguaConfig config) {
    return _upsertConfigDoc(
      docRef: _appDoc,
      docType: FirestoreDocTypes.appConfig,
      payload: {'cobrancaRegua': config.toMap()},
    );
  }

  // --- Inadimplencia Config ---

  Stream<InadimplenciaConfig> watchInadimplenciaConfig() {
    return _appDoc.snapshots().map((doc) {
      final data = doc.data();
      final raw = data?['inadimplencia'];
      if (raw is Map<String, dynamic>) {
        return InadimplenciaConfig.fromMap(raw);
      }
      if (raw is Map) {
        return InadimplenciaConfig.fromMap(Map<String, dynamic>.from(raw));
      }
      return InadimplenciaConfig.defaults;
    });
  }

  Future<InadimplenciaConfig> getInadimplenciaConfig() async {
    final doc = await _appDoc.get();
    final data = doc.data();
    final raw = data?['inadimplencia'];
    if (raw is Map<String, dynamic>) {
      return InadimplenciaConfig.fromMap(raw);
    }
    if (raw is Map) {
      return InadimplenciaConfig.fromMap(Map<String, dynamic>.from(raw));
    }
    return InadimplenciaConfig.defaults;
  }

  Future<void> setInadimplenciaConfig(InadimplenciaConfig config) {
    return _upsertConfigDoc(
      docRef: _appDoc,
      docType: FirestoreDocTypes.appConfig,
      payload: {'inadimplencia': config.toMap()},
    );
  }

  Future<void> _upsertConfigDoc({
    required DocumentReference<Map<String, dynamic>> docRef,
    required String docType,
    required Map<String, Object?> payload,
  }) {
    return _retryPolicy.execute(() async {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final data = <String, Object?>{
          ...payload,
          FirestoreFields.tenantId: _tenantId,
          FirestoreFields.docType: docType,
          FirestoreFields.status: FirestoreStatus.ativo,
          FirestoreFields.ativo: true,
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
