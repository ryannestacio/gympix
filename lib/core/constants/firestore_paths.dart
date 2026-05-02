import 'package:cloud_firestore/cloud_firestore.dart';

/// Colecoes padrao do modelo multi-tenant.
class FirestoreCollections {
  static const String userTenants = 'user_tenants';
  static const String tenants = 'tenants';
  static const String alunos = 'alunos';
  static const String config = 'config';
  static const String fechamentosMensais = 'fechamentos_mensais';
  static const String cobrancaEnvios = 'cobranca_envios';
  static const String cobrancaPushQueue = 'cobranca_push_queue';
}

/// Documentos padrao dentro de `tenants/{tenantId}/config/{docId}`.
class FirestoreConfigDocs {
  static const String app = 'app';
  static const String pix = 'pix';
}

/// Paths canonicamente usados no Firestore.
class FirestorePaths {
  static String userTenantDoc(String uid) {
    return '${FirestoreCollections.userTenants}/$uid';
  }

  static String tenantDoc(String tenantId) {
    return '${FirestoreCollections.tenants}/$tenantId';
  }

  static String tenantAlunoDoc(String tenantId, String alunoId) {
    return '${tenantDoc(tenantId)}/${FirestoreCollections.alunos}/$alunoId';
  }

  static String tenantConfigDoc(String tenantId, String docId) {
    return '${tenantDoc(tenantId)}/${FirestoreCollections.config}/$docId';
  }

  static String tenantFechamentoDoc(String tenantId, String fechamentoId) {
    return '${tenantDoc(tenantId)}/${FirestoreCollections.fechamentosMensais}/$fechamentoId';
  }

  static String tenantAlunoCobrancaEnvioDoc(
    String tenantId,
    String alunoId,
    String envioId,
  ) {
    return '${tenantAlunoDoc(tenantId, alunoId)}/${FirestoreCollections.cobrancaEnvios}/$envioId';
  }

  static String tenantPushQueueDoc(String tenantId, String jobId) {
    return '${tenantDoc(tenantId)}/${FirestoreCollections.cobrancaPushQueue}/$jobId';
  }
}

/// Referencias tipadas para reduzir strings espalhadas pelo app.
class FirestoreRefs {
  static CollectionReference<Map<String, dynamic>> userTenants(
    FirebaseFirestore db,
  ) {
    return db.collection(FirestoreCollections.userTenants);
  }

  static DocumentReference<Map<String, dynamic>> userTenantDoc(
    FirebaseFirestore db,
    String uid,
  ) {
    return userTenants(db).doc(uid);
  }

  static CollectionReference<Map<String, dynamic>> tenants(
    FirebaseFirestore db,
  ) {
    return db.collection(FirestoreCollections.tenants);
  }

  static DocumentReference<Map<String, dynamic>> tenantDoc(
    FirebaseFirestore db,
    String tenantId,
  ) {
    return tenants(db).doc(tenantId);
  }

  static CollectionReference<Map<String, dynamic>> tenantAlunos(
    FirebaseFirestore db,
    String tenantId,
  ) {
    return tenantDoc(db, tenantId).collection(FirestoreCollections.alunos);
  }

  static DocumentReference<Map<String, dynamic>> tenantAlunoDoc(
    FirebaseFirestore db,
    String tenantId,
    String alunoId,
  ) {
    return tenantAlunos(db, tenantId).doc(alunoId);
  }

  static CollectionReference<Map<String, dynamic>> tenantAlunoCobrancaEnvios(
    FirebaseFirestore db,
    String tenantId,
    String alunoId,
  ) {
    return tenantAlunoDoc(
      db,
      tenantId,
      alunoId,
    ).collection(FirestoreCollections.cobrancaEnvios);
  }

  static CollectionReference<Map<String, dynamic>> tenantConfig(
    FirebaseFirestore db,
    String tenantId,
  ) {
    return tenantDoc(db, tenantId).collection(FirestoreCollections.config);
  }

  static DocumentReference<Map<String, dynamic>> tenantConfigDoc(
    FirebaseFirestore db,
    String tenantId,
    String docId,
  ) {
    return tenantConfig(db, tenantId).doc(docId);
  }

  static CollectionReference<Map<String, dynamic>> tenantFechamentosMensais(
    FirebaseFirestore db,
    String tenantId,
  ) {
    return tenantDoc(
      db,
      tenantId,
    ).collection(FirestoreCollections.fechamentosMensais);
  }

  static DocumentReference<Map<String, dynamic>> tenantFechamentoDoc(
    FirebaseFirestore db,
    String tenantId,
    String fechamentoId,
  ) {
    return tenantFechamentosMensais(db, tenantId).doc(fechamentoId);
  }

  static CollectionReference<Map<String, dynamic>> tenantCobrancaPushQueue(
    FirebaseFirestore db,
    String tenantId,
  ) {
    return tenantDoc(
      db,
      tenantId,
    ).collection(FirestoreCollections.cobrancaPushQueue);
  }
}
