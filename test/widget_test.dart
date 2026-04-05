import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gympix/features/alunos/models/aluno.dart';
import 'package:gympix/features/alunos/providers/alunos_providers.dart';
import 'package:gympix/features/auth/models/auth_access_state.dart';
import 'package:gympix/features/auth/models/auth_session.dart';
import 'package:gympix/features/auth/providers/auth_providers.dart';
import 'package:gympix/features/relatorios/models/competencia_report.dart';
import 'package:gympix/features/relatorios/providers/competencia_report_providers.dart';
import 'package:gympix/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('App inicializa com ProviderScope e renderiza Home', (
    WidgetTester tester,
  ) async {
    const session = AuthSession(
      uid: 'uid_teste',
      email: 'owner@gympix.com',
      displayName: 'Owner Teste',
      tenantId: 'tenant_a',
      role: TenantRole.owner,
    );

    const report = CompetenciaReportData(
      competencia: '2026-03',
      totais: const CompetenciaReportTotals(
        totalAlunos: 0,
        pendentes: 0,
        atrasados: 0,
        recebidoMes: 0,
        previstoMes: 0,
        inadimplenciaPercent: 0,
      ),
      alunosSnapshot: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authAccessStateProvider.overrideWith(
            (ref) => Stream.value(const AuthAccessState.authorized(session)),
          ),
          authSessionProvider.overrideWithValue(session),
          alunosStreamProvider.overrideWith((ref) => Stream.value(<Aluno>[])),
          competenciaReportProvider.overrideWith((ref) => report),
        ],
        child: const GymPixApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('GymPix'), findsWidgets);
    expect(find.textContaining('Resumo'), findsWidgets);
  });
}
