import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../alunos/models/aluno.dart';
import '../../alunos/providers/alunos_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../configuracoes/providers/config_providers.dart';
import '../models/cobranca_envio.dart';
import '../models/cobranca_regua.dart';
import '../repository/cobranca_regua_repository.dart';
import '../services/cobranca_notification_service.dart';
import '../services/cobranca_regua_automation_service.dart';
import '../services/cobranca_regua_planner.dart';
import '../services/cobranca_template_service.dart';
import '../services/pix_payload_service.dart';

final cobrancaReguaRepositoryProvider = Provider<CobrancaReguaRepository>((
  ref,
) {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    throw StateError('Sessao invalida para acessar regua de cobranca.');
  }
  return CobrancaReguaRepository(
    ref.watch(firestoreProvider),
    session.tenantId,
  );
});

final cobrancaReguaConfigStreamProvider = StreamProvider<CobrancaReguaConfig>((
  ref,
) {
  return ref.watch(cobrancaReguaRepositoryProvider).watchReguaConfig();
});

final cobrancaEnviosAlunoProvider = StreamProvider.autoDispose
    .family<List<CobrancaEnvio>, String>((ref, alunoId) {
      return ref
          .watch(cobrancaReguaRepositoryProvider)
          .watchEnviosAluno(alunoId);
    });

final cobrancaNotificationServiceProvider =
    Provider<CobrancaNotificationService>((ref) {
      return CobrancaNotificationService();
    });

final cobrancaReguaPlannerProvider = Provider<CobrancaReguaPlanner>((ref) {
  return CobrancaReguaPlanner();
});

final cobrancaTemplateServiceProvider = Provider<CobrancaTemplateService>((
  ref,
) {
  return CobrancaTemplateService();
});

final cobrancaReguaAutomationServiceProvider =
    Provider<CobrancaReguaAutomationService>((ref) {
      return CobrancaReguaAutomationService(
        reguaRepository: ref.watch(cobrancaReguaRepositoryProvider),
        configRepository: ref.watch(configRepositoryProvider),
        planner: ref.watch(cobrancaReguaPlannerProvider),
        templateService: ref.watch(cobrancaTemplateServiceProvider),
        notificationService: ref.watch(cobrancaNotificationServiceProvider),
        pixPayloadService: const PixPayloadService(),
      );
    });

final cobrancaReguaAutomationRunnerProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  if (Firebase.apps.isEmpty) return 0;
  final alunos =
      ref.watch(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
  if (alunos.isEmpty) return 0;
  return ref
      .watch(cobrancaReguaAutomationServiceProvider)
      .processarHoje(alunos);
});
