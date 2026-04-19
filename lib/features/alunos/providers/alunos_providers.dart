import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show FutureProvider, Notifier, NotifierProvider, Provider, StreamProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/aluno.dart';
import '../repository/alunos_repository.dart';
import '../services/vencimento_hoje_notification_service.dart';

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

// --- Streams em tempo real (mantidos para stats e reportes) ---

@riverpod
Stream<List<Aluno>> alunosStream(Ref ref) {
  return ref.watch(alunosRepositoryProvider).watchAlunosAtivos();
}

final alunosHistoricoStreamProvider = StreamProvider.autoDispose<List<Aluno>>((
  ref,
) {
  return ref.watch(alunosRepositoryProvider).watchTodosAlunos();
});

final vencimentoHojeNotificationServiceProvider =
    Provider<VencimentoHojeNotificationService>((ref) {
      return VencimentoHojeNotificationService();
    });

final vencimentoHojeNotificationRunnerProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final alunos =
          ref.watch(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
      if (alunos.isEmpty) return 0;

      final now = DateTime.now();
      final hoje = DateTime(now.year, now.month, now.day);
      final totalVencimentosHoje = alunos.where((aluno) {
        if (!aluno.ativo) return false;
        final pagamento = aluno.pagamentoDoMes(now);
        if (pagamento.status == PagamentoStatus.pago) return false;
        final vencimento = Aluno.dataVencimento(aluno.diaVencimento, now);
        return vencimento.year == hoje.year &&
            vencimento.month == hoje.month &&
            vencimento.day == hoje.day;
      }).length;

      if (totalVencimentosHoje <= 0) return 0;
      await ref
          .read(vencimentoHojeNotificationServiceProvider)
          .notifyDueToday(totalAlunos: totalVencimentosHoje, now: now);
      return totalVencimentosHoje;
    });

final pagamentosAcumuladosBackfillRunnerProvider =
    FutureProvider.autoDispose<int>((ref) async {
      final alunos =
          ref.watch(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
      if (alunos.isEmpty) return 0;

      try {
        return await ref
            .read(alunosRepositoryProvider)
            .backfillPagamentosAcumulados(alunos: alunos);
      } catch (_) {
        return 0;
      }
    });

// --- Lista paginada com startAfterDocument ---

@riverpod
class AlunosPaginados extends _$AlunosPaginados {
  final List<Aluno> _alunos = [];
  final Set<String> _ids = {};
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  AsyncValue<List<Aluno>> build({bool onlyActive = true}) {
    // Reset quando muda o parametro
    _alunos.clear();
    _ids.clear();
    _lastDoc = null;
    _hasMore = true;
    _loadingMore = false;

    ref.keepAlive();

    // Primeira pagina carrega no build
    _loadNextPage();
    return const AsyncLoading();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || state.isLoading) return;
    _loadingMore = true;
    await _loadNextPage();
    _loadingMore = false;
  }

  /// True se existem mais paginas para carregar.
  bool get hasMore => _hasMore && !_loadingMore;

  /// Forca recarregamento completo (limpa cache).
  void refresh() {
    _alunos.clear();
    _ids.clear();
    _lastDoc = null;
    _hasMore = true;
    _loadingMore = false;
    _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    final repo = ref.read(alunosRepositoryProvider);
    try {
      var keepPaging = true;
      var hopCount = 0;
      while (keepPaging) {
        final page = await repo.fetchAlunosPage(
          startAfter: _lastDoc,
          onlyActive: onlyActive,
        );

        var addedAny = false;
        for (final aluno in page.alunos) {
          if (_ids.contains(aluno.id)) continue;
          _ids.add(aluno.id);
          _alunos.add(aluno);
          addedAny = true;
        }

        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
        hopCount++;

        // Quando onlyActive=true, uma pagina pode vir vazia apos filtro.
        // Avanca automaticamente ate achar ativos ou acabar as paginas.
        keepPaging = onlyActive && !addedAny && _hasMore && hopCount < 40;
      }

      state = AsyncData(_alunos.toList());
    } catch (e, st) {
      if (_alunos.isEmpty) {
        state = AsyncError(e, st);
      } else {
        // Mantem dados anteriores como fallback
        state = AsyncData(_alunos.toList());
      }
    }
  }
}

// --- Filtro e stats mantidos ---

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
  final referencia = DateTime.now();
  final competenciaAtual = Aluno.competenciaAtual(referencia);
  final referenciaStatus = Aluno.referenciaStatusDaCompetencia(referencia);

  final filtrados = switch (filtro) {
    AlunoFiltro.todos => ativos,
    AlunoFiltro.pagos =>
      ativos
          .where(
            (a) => !a.temEmAbertoAte(
              referencia,
              referenciaStatus: referenciaStatus,
            ),
          )
          .toList(),
    AlunoFiltro.pendentes => ativos.where((a) {
      final pagamentoAtual = a.pagamentoDaCompetencia(
        competenciaAtual,
        referenciaStatus: referenciaStatus,
      );
      final emAbertoTotal = a.totalCompetenciasEmAbertoAte(
        referencia,
        referenciaStatus: referenciaStatus,
      );
      final soCompetenciaAtual = !pagamentoAtual.pago && emAbertoTotal == 1;
      return pagamentoAtual.status == PagamentoStatus.pendente &&
          soCompetenciaAtual;
    }).toList(),
    AlunoFiltro.atrasados => ativos.where((a) {
      final pagamentoAtual = a.pagamentoDaCompetencia(
        competenciaAtual,
        referenciaStatus: referenciaStatus,
      );
      final emAbertoTotal = a.totalCompetenciasEmAbertoAte(
        referencia,
        referenciaStatus: referenciaStatus,
      );
      final possuiPendenciaAnterior =
          emAbertoTotal > (pagamentoAtual.pago ? 0 : 1);
      return pagamentoAtual.status == PagamentoStatus.atrasado ||
          possuiPendenciaAnterior;
    }).toList(),
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
    required this.emAbertoAcumulado,
    required this.inadimplenciaPercent,
  });

  final int totalAlunos;
  final int pendentes;
  final int atrasados;
  final double recebidoMes;
  final double previstoMes;
  final double emAbertoAcumulado;
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
  final ativos = alunos.where((a) => a.ativo).toList();
  final competencia = Aluno.competenciaAtual(referencia);
  final referenciaStatus = Aluno.referenciaStatusDaCompetencia(referencia);
  final pagamentosMes = ativos
      .map(
        (a) => a.pagamentoDaCompetencia(
          competencia,
          referenciaStatus: referenciaStatus,
        ),
      )
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
  final emAbertoAcumulado = ativos.fold<double>(
    0,
    (total, aluno) =>
        total +
        aluno.valorEmAbertoAte(referencia, referenciaStatus: referenciaStatus),
  );
  final inadimplentesAcumulados = ativos
      .where(
        (aluno) => aluno.temEmAbertoAte(
          referencia,
          referenciaStatus: referenciaStatus,
        ),
      )
      .length;
  final inadimplenciaPercent = ativos.isEmpty
      ? 0.0
      : (inadimplentesAcumulados / ativos.length) * 100.0;
  return DashboardStats(
    totalAlunos: ativos.length,
    pendentes: pendentes,
    atrasados: atrasados,
    recebidoMes: recebidoMes,
    previstoMes: previstoMes,
    emAbertoAcumulado: emAbertoAcumulado,
    inadimplenciaPercent: inadimplenciaPercent,
  );
}
