import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../models/auth_access_state.dart';
import '../models/auth_session.dart';
import '../repository/auth_repository.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    db: ref.watch(firestoreProvider),
  );
}

@riverpod
Stream<User?> authUserChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

@riverpod
Stream<AuthAccessState> authAccessState(Ref ref) async* {
  final repository = ref.watch(authRepositoryProvider);
  yield const AuthAccessState.loading();
  await for (final user in repository.authStateChanges()) {
    if (user == null) {
      yield const AuthAccessState.unauthenticated();
      continue;
    }
    try {
      final result = await repository.resolveSession(user);
      if (result.isAuthorized) {
        yield AuthAccessState.authorized(result.session!);
      } else {
        yield AuthAccessState.unauthorized(reason: result.deniedReason);
      }
    } on FirebaseException catch (e) {
      final reason = switch (e.code) {
        'permission-denied' =>
          'Firestore bloqueou o acesso (permission-denied). Revise as regras de seguranca para user_tenants e tenants.',
        'unavailable' =>
          'Firestore indisponivel no momento. Verifique sua conexao e tente novamente.',
        _ =>
          'Falha ao validar permissao de acesso. [${e.code}] ${e.message ?? ''}',
      };
      yield AuthAccessState.unauthorized(reason: reason);
    } catch (e) {
      yield AuthAccessState.unauthorized(
        reason: 'Falha ao validar permissao de acesso. $e',
      );
    }
  }
}

@riverpod
AuthSession? authSession(Ref ref) {
  final access = ref.watch(authAccessStateProvider).asData?.value;
  if (access?.status != AuthAccessStatus.authorized) return null;
  return access?.session;
}

@riverpod
AuthAccessState authAccessSnapshot(Ref ref) {
  final accessAsync = ref.watch(authAccessStateProvider);
  return accessAsync.asData?.value ?? const AuthAccessState.loading();
}
