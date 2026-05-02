import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/firestore_fields.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/auth_session.dart';

class AuthLoginException implements Exception {
  const AuthLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository({required FirebaseAuth auth, required FirebaseFirestore db})
    : _auth = auth,
      _db = db;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password;
    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      throw const AuthLoginException('Informe email e senha para entrar.');
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthLoginException(_firebaseErrorMessage(e.code));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const AuthLoginException('Informe o email para redefinir a senha.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthLoginException(_resetPasswordErrorMessage(e.code));
    }
  }

  Future<SessionLookupResult> resolveSession(User user) async {
    try {
      await _seedInitialTenantIfMissing(user);
    } on FirebaseException catch (e) {
      // O seed usa transacao (exige online). Em offline, seguimos com cache.
      if (!_isNetworkOrSyncTransientCode(e.code)) rethrow;
    }

    final membershipDoc = await _getWithOfflineFallback(
      FirestoreRefs.userTenantDoc(_db, user.uid),
    );
    if (!membershipDoc.exists) {
      return const SessionLookupResult.denied(
        'Sua conta nao possui acesso autorizado.',
      );
    }

    final membership = membershipDoc.data() ?? <String, dynamic>{};
    final memberAtivo = _isMembershipAtivo(membership);
    if (!memberAtivo) {
      return const SessionLookupResult.denied(
        'Seu acesso foi desativado. Contate o administrador.',
      );
    }

    final tenantId = _resolveTenantId(membership);
    if (tenantId == null || tenantId.isEmpty) {
      return const SessionLookupResult.denied(
        'Tenant nao encontrado para esta conta.',
      );
    }

    final tenantDoc = await _getWithOfflineFallback(
      FirestoreRefs.tenantDoc(_db, tenantId),
    );
    if (!tenantDoc.exists) {
      return const SessionLookupResult.denied(
        'Tenant nao encontrado ou removido.',
      );
    }

    final tenantData = tenantDoc.data() ?? <String, dynamic>{};
    if (!_isTenantAtivo(tenantData)) {
      return const SessionLookupResult.denied(
        'Tenant inativo. Acesso bloqueado.',
      );
    }

    final fallbackEmail = (membership['email'] as String?)?.trim() ?? '';
    final email = (user.email ?? fallbackEmail).trim();
    if (email.isEmpty) {
      return const SessionLookupResult.denied('Conta sem email valido.');
    }

    final fallbackName = (membership['nome'] as String?)?.trim() ?? '';
    final displayName = (user.displayName ?? fallbackName).trim().isEmpty
        ? email
        : (user.displayName ?? fallbackName).trim();

    return SessionLookupResult.authorized(
      AuthSession(
        uid: user.uid,
        email: email,
        displayName: displayName,
        tenantId: tenantId,
        role: parseTenantRole(membership['role']),
      ),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getWithOfflineFallback(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      return await docRef.get();
    } on FirebaseException catch (e) {
      if (!_isNetworkOrSyncTransientCode(e.code)) rethrow;
      try {
        return await docRef.get(const GetOptions(source: Source.cache));
      } on FirebaseException {
        rethrow;
      }
    }
  }

  bool _isNetworkOrSyncTransientCode(String code) {
    return code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        code == 'aborted' ||
        code == 'cancelled' ||
        code == 'failed-precondition';
  }

  Future<void> _seedInitialTenantIfMissing(User user) async {
    final membershipRef = FirestoreRefs.userTenantDoc(_db, user.uid);
    final existingMembership = await membershipRef.get();
    if (existingMembership.exists) return;

    final tenantId = user.uid;
    final tenantRef = FirestoreRefs.tenantDoc(_db, tenantId);
    final appConfigRef = FirestoreRefs.tenantConfigDoc(
      _db,
      tenantId,
      FirestoreConfigDocs.app,
    );
    final pixConfigRef = FirestoreRefs.tenantConfigDoc(
      _db,
      tenantId,
      FirestoreConfigDocs.pix,
    );

    await _db.runTransaction((tx) async {
      final membershipSnap = await tx.get(membershipRef);
      if (membershipSnap.exists) return;

      final tenantSnap = await tx.get(tenantRef);
      final appConfigSnap = await tx.get(appConfigRef);
      final pixConfigSnap = await tx.get(pixConfigRef);

      final now = FieldValue.serverTimestamp();
      final displayName = _resolveDisplayName(user);

      if (!tenantSnap.exists) {
        tx.set(tenantRef, {
          FirestoreFields.tenantId: tenantId,
          'nome': _resolveTenantName(displayName, user.email),
          FirestoreFields.status: FirestoreStatus.ativo,
          FirestoreFields.ativo: true,
          FirestoreFields.createdAt: now,
          FirestoreFields.updatedAt: now,
        });
      }

      tx.set(membershipRef, {
        FirestoreFields.tenantId: tenantId,
        FirestoreFields.role: TenantRole.owner.name,
        FirestoreFields.status: FirestoreStatus.ativo,
        FirestoreFields.ativo: true,
        FirestoreFields.createdAt: now,
        FirestoreFields.updatedAt: now,
        'email': (user.email ?? '').trim().toLowerCase(),
        'nome': displayName,
      });

      if (!appConfigSnap.exists) {
        tx.set(appConfigRef, {
          FirestoreFields.tenantId: tenantId,
          FirestoreFields.docType: FirestoreDocTypes.appConfig,
          FirestoreFields.status: FirestoreStatus.ativo,
          FirestoreFields.ativo: true,
          FirestoreFields.createdAt: now,
          FirestoreFields.updatedAt: now,
        });
      }

      if (!pixConfigSnap.exists) {
        tx.set(pixConfigRef, {
          FirestoreFields.tenantId: tenantId,
          FirestoreFields.docType: FirestoreDocTypes.pixConfig,
          FirestoreFields.status: FirestoreStatus.ativo,
          FirestoreFields.ativo: true,
          FirestoreFields.createdAt: now,
          FirestoreFields.updatedAt: now,
        });
      }
    });
  }

  String _resolveDisplayName(User user) {
    final fromProfile = (user.displayName ?? '').trim();
    if (fromProfile.isNotEmpty) return fromProfile;

    final email = (user.email ?? '').trim();
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Usuario';
  }

  String _resolveTenantName(String displayName, String? email) {
    final normalized = displayName.trim();
    if (normalized.isNotEmpty) return 'Academia $normalized';

    final fallbackEmail = (email ?? '').trim();
    if (fallbackEmail.contains('@')) {
      return 'Academia ${fallbackEmail.split('@').first}';
    }

    return 'Minha academia';
  }

  String? _resolveTenantId(Map<String, dynamic> membership) {
    final tenantId = (membership['tenantId'] as String?)?.trim();
    if (tenantId != null && tenantId.isNotEmpty) return tenantId;

    // Preparado para o futuro: permitir varios tenants por usuario.
    final tenantIds = membership['tenantIds'];
    if (tenantIds is List) {
      for (final item in tenantIds) {
        if (item is String && item.trim().isNotEmpty) return item.trim();
      }
    }
    return null;
  }

  bool _isMembershipAtivo(Map<String, dynamic> membership) {
    final ativo = membership[FirestoreFields.ativo];
    if (ativo is bool) return ativo;

    final status = membership[FirestoreFields.status];
    if (status is String) {
      final value = status.trim().toLowerCase();
      return value == FirestoreStatus.ativo ||
          value == 'active' ||
          value == 'enabled';
    }

    return false;
  }

  bool _isTenantAtivo(Map<String, dynamic> tenantData) {
    final ativo = tenantData[FirestoreFields.ativo];
    if (ativo is bool) return ativo;

    final status = tenantData[FirestoreFields.status];
    if (status is String) {
      final value = status.trim().toLowerCase();
      return value == FirestoreStatus.ativo ||
          value == 'active' ||
          value == 'enabled';
    }

    // Compatibilidade com tenant antigo sem status explicito.
    return true;
  }

  String _firebaseErrorMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Email invalido.',
      'user-disabled' => 'Usuario desativado.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email ou senha invalidos.',
      'too-many-requests' => 'Muitas tentativas. Tente novamente mais tarde.',
      'network-request-failed' =>
        'Falha de rede. Verifique sua conexao e tente novamente.',
      _ => 'Nao foi possivel autenticar. Tente novamente.',
    };
  }

  String _resetPasswordErrorMessage(String code) {
    return switch (code) {
      'invalid-email' => 'Email invalido.',
      'user-not-found' => 'Nenhuma conta encontrada com este email.',
      'too-many-requests' =>
        'Muitas tentativas de redefinicao. Tente novamente mais tarde.',
      _ => 'Nao foi possivel enviar o email de redefinicao. Tente novamente.',
    };
  }
}
