import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Notifier, NotifierProvider, Provider, StreamProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/aluno.dart';
import '../repository/alunos_repository.dart';

part 'alunos_providers.g.dart';

enum AlunoFiltro { todos, pagos, pendentes, atrasados, inativos }

class CompetenciaSelecionadaNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void select(DateTime value) {
    state = DateTime(value.year, value.month);
  }
}

final competenciaSelecionadaProvider =
    NotifierProvider.autoDispose<CompetenciaSelecionadaNotifier, DateTime>(
      CompetenciaSelecionadaNotifier.new,
    );

@riverpod
AlunosRepository alunosRepository(Ref ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    throw StateError('Sessao invalida para acessar dados de alunos.');
  }
  return AlunosRepository(ref.watch(firestoreProvider), session.tenantId);
}

@riverpod
Stream<List<Aluno>> alunosStream(Ref ref) {
  return ref.watch(alunosRepositoryProvider).watchAlunosAtivos();
}

final alunosHistoricoStreamProvider = StreamProvider.autoDispose<List<Aluno>>((
  ref,
) {
  return ref.watch(alunosRepositoryProvider).watchTodosAlunos();
});

@riverpod
class AlunosFiltro extends _$AlunosFiltro {
  @override
  AlunoFiltro build() => AlunoFiltro.todos;

  void select(AlunoFiltro value) {
    state = value;
  }
}

@riverpod
List<Aluno> alunosFiltrados(Ref ref) {
  final filtro = ref.watch(alunosFiltroProvider);
  final alunosAsync = ref.watch(alunosHistoricoStreamProvider);
  final alunos = alunosAsync.value ?? const <Aluno>[];
  final ativos = alunos.where((a) => a.ativo).toList();

  final filtrados = switch (filtro) {
    AlunoFiltro.todos => ativos,
    AlunoFiltro.pagos => ativos.where((a) => a.pago).toList(),
    AlunoFiltro.pendentes =>
      ativos.where((a) => !a.pago && !a.atrasado).toList(),
    AlunoFiltro.atrasados => ativos.where((a) => a.atrasado).toList(),
    AlunoFiltro.inativos => alunos.where((a) => !a.ativo).toList(),
  };

  filtrados.sort((a, b) => a.diaVencimento.compareTo(b.diaVencimento));
  return filtrados;
}

class DashboardStats {
  const DashboardStats({
    required this.totalAlunos,
    required this.pendentes,
    required this.atrasados,
    required this.recebidoMes,
    required this.previstoMes,
    required this.inadimplenciaPercent,
  });

  final int totalAlunos;
  final int pendentes;
  final int atrasados;
  final double recebidoMes;
  final double previstoMes;
  final double inadimplenciaPercent;
}

final alunosFechamentoMesProvider = Provider.autoDispose<List<Aluno>>((ref) {
  final alunos =
      ref.watch(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
  final referencia = ref.watch(competenciaSelecionadaProvider);
  final competencia = Aluno.competenciaAtual(referencia);
  final filtrados = alunos.where(
    (aluno) => aluno.ativo || aluno.pagamentos.containsKey(competencia),
  );

  return filtrados.toList()
    ..sort((a, b) => a.diaVencimento.compareTo(b.diaVencimento));
});

@riverpod
DashboardStats dashboardStats(Ref ref) {
  final alunos = ref.watch(alunosStreamProvider).value ?? const <Aluno>[];
  final referencia = ref.watch(competenciaSelecionadaProvider);
  return _buildDashboardStats(alunos, referencia);
}

final dashboardFechamentoStatsProvider = Provider.autoDispose<DashboardStats>((
  ref,
) {
  final alunos = ref.watch(alunosFechamentoMesProvider);
  final referencia = ref.watch(competenciaSelecionadaProvider);
  return _buildDashboardStats(alunos, referencia);
});

DashboardStats _buildDashboardStats(List<Aluno> alunos, DateTime referencia) {
  final pagamentosMes = alunos
      .map((a) => a.pagamentoDoMes(referencia))
      .toList();

  final pendentes = pagamentosMes
      .where((p) => p.status == PagamentoStatus.pendente)
      .length;
  final atrasados = pagamentosMes
      .where((p) => p.status == PagamentoStatus.atrasado)
      .length;
  final recebidos = pagamentosMes
      .where((p) => p.status == PagamentoStatus.pago)
      .toList();

  final recebidoMes = recebidos.fold<double>(0, (s, p) => s + p.valor);
  final previstoMes = pagamentosMes.fold<double>(0, (s, p) => s + p.valor);
  final totalNaoPago = pendentes + atrasados;
  final inadimplenciaPercent = alunos.isEmpty
      ? 0.0
      : (totalNaoPago / alunos.length) * 100.0;
  return DashboardStats(
    totalAlunos: alunos.length,
    pendentes: pendentes,
    atrasados: atrasados,
    recebidoMes: recebidoMes,
    previstoMes: previstoMes,
    inadimplenciaPercent: inadimplenciaPercent,
  );
}
