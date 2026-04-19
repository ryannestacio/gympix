import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, StreamProvider;

import '../../../core/providers/firebase_providers.dart';
import '../../alunos/models/aluno.dart';
import '../../alunos/providers/alunos_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/competencia_report.dart';
import '../repository/competencia_fechamento_repository.dart';
import '../services/competencia_fechamento_service.dart';

final competenciaFechamentoRepositoryProvider =
    Provider.autoDispose<CompetenciaFechamentoRepository>((ref) {
      final session = ref.watch(authSessionProvider);
      if (session == null) {
        throw StateError('Sessao invalida para acessar fechamentos.');
      }
      return CompetenciaFechamentoRepository(
        ref.watch(firestoreProvider),
        session.tenantId,
      );
    });

final competenciaFechamentoServiceProvider =
    Provider.autoDispose<CompetenciaFechamentoService>((ref) {
      return CompetenciaFechamentoService(
        ref.watch(competenciaFechamentoRepositoryProvider),
      );
    });

final competenciaFechamentoStreamProvider = StreamProvider.autoDispose
    .family<CompetenciaReportData?, String>((ref, competencia) {
      return ref
          .watch(competenciaFechamentoRepositoryProvider)
          .watchFechamento(competencia);
    });

final competenciaReportLiveProvider =
    Provider.autoDispose<CompetenciaReportData>((ref) {
      final referencia = ref.watch(competenciaSelecionadaProvider);
      final alunosDashboard =
          ref.watch(alunosStreamProvider).value ?? const <Aluno>[];
      final alunosHistorico =
          ref.watch(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
      final competencia = Aluno.competenciaAtual(referencia);
      final alunosFechamento = alunosHistorico.where(
        (aluno) => aluno.ativo || aluno.pagamentos.containsKey(competencia),
      );

      return CompetenciaReportData.fromLive(
        referencia: referencia,
        alunosDashboard: alunosDashboard,
        alunosFechamento: alunosFechamento.toList()
          ..sort((a, b) => a.diaVencimento.compareTo(b.diaVencimento)),
      );
    });

final competenciaReportProvider = Provider.autoDispose<CompetenciaReportData>((
  ref,
) {
  return ref.watch(competenciaReportLiveProvider);
});
