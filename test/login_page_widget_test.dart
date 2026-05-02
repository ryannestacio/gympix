import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/auth/providers/auth_providers.dart';
import 'package:gympix/features/auth/repository/auth_repository.dart';
import 'package:gympix/features/auth/ui/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:gympix/features/auth/models/auth_session.dart'
    show SessionLookupResult;

void main() {
  group('LoginPage widget', () {
    group('renderizacao', () {
      testWidgets('renderiza campos de email e senha', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_buildApp());
        await tester.pump();

        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Senha'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.text('Entre em contato para obter o app.'), findsOneWidget);
        expect(
          find.widgetWithText(OutlinedButton, 'Entrar em contato no WhatsApp'),
          findsOneWidget,
        );
        expect(
          find.text('Todos os direitos reservados a Ryan Estácio'),
          findsOneWidget,
        );
      });

      testWidgets('botao Entrar habilitado inicialmente', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_buildApp());
        await tester.pump();

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('renderiza logo do app', (WidgetTester tester) async {
        await tester.pumpWidget(_buildApp());
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
      });
    });

    group('interacoes', () {
      testWidgets('mostra erro de validacao com campos vazios', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_buildApp());
        await tester.pump();

        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Entrar'));
        await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
        await tester.pumpAndSettle();

        expect(find.text('Informe seu email.'), findsOneWidget);
        expect(find.text('Informe sua senha.'), findsOneWidget);
      });

      testWidgets('mostra erro para email com formato invalido', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_buildApp());
        await tester.pump();

        await tester.enterText(
          find.byType(TextFormField).first,
          'joao @mail.com',
        );
        await tester.enterText(find.byType(TextFormField).last, '123456');
        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Entrar'));
        await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
        await tester.pumpAndSettle();

        expect(find.text('Email invalido.'), findsOneWidget);
      });

      testWidgets('toggle visibilidade de senha funciona', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_buildApp());
        await tester.pump();

        // Inicialmente com icon visibility_outlined (senha oculta)
        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

        // Tap para mostrar
        await tester.ensureVisible(find.byIcon(Icons.visibility_outlined));
        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

        // Tap para ocultar novamente
        await tester.tap(find.byIcon(Icons.visibility_off_outlined));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      });
    });
  });
}

Widget _buildApp() {
  final fakeRepo = _FakeAuthRepository();

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWith((ref) => fakeRepo)],
    child: const MaterialApp(home: LoginPage()),
  );
}

class _FakeAuthRepository implements AuthRepository {
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
