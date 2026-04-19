import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/auth/models/auth_access_state.dart';
import 'package:gympix/features/auth/models/auth_session.dart';
import 'package:gympix/features/auth/providers/auth_providers.dart';
import 'package:gympix/features/auth/repository/auth_repository.dart';
import 'package:gympix/features/auth/ui/access_denied_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

void main() {
  group('AccessDeniedPage widget', () {
    testWidgets('renderiza titulo Acesso negado', (WidgetTester tester) async {
      await tester.pumpWidget(_buildApp(reason: 'Teste de acesso.'));
      await tester.pump();

      expect(find.text('Acesso negado'), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });

    testWidgets('exibe reason do estado nao autorizado', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp(reason: 'Sua conta foi desativada.'));
      await tester.pump();

      expect(find.textContaining('Sua conta foi desativada.'), findsOneWidget);
    });

    testWidgets('botao Sair da conta habilitado inicialmente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });
}

Widget _buildApp({String reason = 'Acesso negado.'}) {
  const session = AuthSession(
    uid: 'uid_test',
    email: 'user@test.com',
    displayName: 'User Test',
    tenantId: 'tenant_x',
    role: TenantRole.staff,
  );

  return ProviderScope(
    overrides: [
      authAccessStateProvider.overrideWith(
        (ref) => Stream.value(AuthAccessState.unauthorized(reason: reason)),
      ),
      authAccessSnapshotProvider.overrideWithValue(
        AuthAccessState.unauthorized(reason: reason),
      ),
      authSessionProvider.overrideWithValue(session),
      authRepositoryProvider.overrideWith((ref) => _FakeAuthRepo()),
    ],
    child: const MaterialApp(home: AccessDeniedPage()),
  );
}

class _FakeAuthRepo implements AuthRepository {
  @override
  Stream<fa.User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<SessionLookupResult> resolveSession(fa.User user) async {
    throw UnsupportedError('not implemented in test');
  }
}
