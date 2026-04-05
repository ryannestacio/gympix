import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/firestore_retry_policy.dart';
import '../../cobranca/models/cobranca_regua.dart';

class ConfigRepository {
  ConfigRepository(
    this._db,
    this._tenantId, {
    RetryPolicy? retryPolicy,
  }) : _retryPolicy = retryPolicy ?? RetryPolicy.standard;

  final FirebaseFirestore _db;
  final String _tenantId;
  final RetryPolicy _retryPolicy;

  DocumentReference<Map<String, dynamic>> get _tenantDoc =>
      _db.collection('tenants').doc(_tenantId);

  DocumentReference<Map<String, dynamic>> get _pixDoc =>
      _tenantDoc.collection('config').doc('pix');

  DocumentReference<Map<String, dynamic>> get _appDoc =>
      _tenantDoc.collection('config').doc('app');

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
    return _retryPolicy.execute(
      () => _pixDoc.set({'pixCode': pixCode.trim()}, SetOptions(merge: true)),
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
    return _retryPolicy.execute(
      () => _appDoc.set({'defaultMensalidade': value}, SetOptions(merge: true)),
    );
  }

  Stream<String?> watchCustomCobrancaMessage() {
    return _appDoc.snapshots().map((doc) {
      final data = doc.data();
      final message = data?['customCobrancaMessage'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      return null;
    });
  }

  Future<String?> getCustomCobrancaMessage() async {
    final doc = await _appDoc.get();
    final data = doc.data();
    final message = data?['customCobrancaMessage'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return null;
  }

  Future<void> setCustomCobrancaMessage(String value) {
    return _retryPolicy.execute(
      () => _appDoc.set(
        {'customCobrancaMessage': value.trim()},
        SetOptions(merge: true),
      ),
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
    return _retryPolicy.execute(
      () => _appDoc.set({
        'cobrancaRegua': config.toMap(),
      }, SetOptions(merge: true)),
    );
  }
}
