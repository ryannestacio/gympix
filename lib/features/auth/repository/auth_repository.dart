import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final normalizedPassword = password.trim();
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

  Future<SessionLookupResult> resolveSession(User user) async {
    final membershipDoc = await _db
        .collection('user_tenants')
        .doc(user.uid)
        .get();
    if (!membershipDoc.exists) {
      return const SessionLookupResult.denied(
        'Sua conta nao possui acesso autorizado.',
      );
    }

    final membership = membershipDoc.data() ?? <String, dynamic>{};
    final memberAtivo = membership['ativo'] as bool? ?? false;
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

    final tenantDoc = await _db.collection('tenants').doc(tenantId).get();
    if (!tenantDoc.exists) {
      return const SessionLookupResult.denied(
        'Tenant nao encontrado ou removido.',
      );
    }

    final tenantData = tenantDoc.data() ?? <String, dynamic>{};
    if (!_isTenantAtivo(tenantData['status'])) {
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

  bool _isTenantAtivo(dynamic status) {
    if (status is bool) return status;
    if (status is String) {
      final value = status.trim().toLowerCase();
      return value == 'ativo' || value == 'active' || value == 'enabled';
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
}
