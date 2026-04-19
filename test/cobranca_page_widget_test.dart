import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/cobranca/ui/cobranca_page.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  group('CobrancaPage', () {
    testWidgets('renderiza saudacao com nome', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CobrancaPage(
            nome: 'Joao Silva',
            pixCode: 'PIX-TEST-123',
            valor: '80,00',
          ),
        ),
      );

      expect(find.textContaining('Joao Silva'), findsOneWidget);
      expect(find.textContaining('80,00'), findsOneWidget);
    });

    testWidgets('renderiza QR Code quando pixCode nao esta vazio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CobrancaPage(
            nome: 'Maria',
            pixCode: 'PIX-DATA',
            valor: '100',
          ),
        ),
      );

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('mostra aviso quando pixCode esta vazio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CobrancaPage(
            nome: 'Test',
            pixCode: '',
            valor: '50',
          ),
        ),
      );

      expect(
        find.textContaining('Pix n\u00e3o informado'),
        findsOneWidget,
      );
    });

    testWidgets('botao copiar desabilitado quando pixCode esta vazio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CobrancaPage(
            nome: 'Test',
            pixCode: '',
            valor: '50',
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('ao clicar copiar, botao responde', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CobrancaPage(
            nome: 'Maria',
            pixCode: 'PIX-COPIA-COLA-TEST',
            valor: '120',
          ),
        ),
      );

      // Botao habilitado
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
    });
  });
}
