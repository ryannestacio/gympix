import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/firestore_error_formatter.dart';
import '../../configuracoes/providers/config_providers.dart';
import '../../relatorios/services/report_export_service.dart';
import '../controllers/alunos_actions_controller.dart';
import '../models/aluno.dart';
import '../providers/alunos_providers.dart';
import '../services/telefone_whatsapp_service.dart' as whatsapp_phone;
import '../usecases/aluno_cadastro_input.dart';
import 'aluno_form_sheet.dart';
import 'widgets/aluno_card.dart';
import 'widgets/alunos_header_section.dart';

class AlunosPage extends ConsumerStatefulWidget {
  const AlunosPage({super.key});

  @override
  ConsumerState<AlunosPage> createState() => _AlunosPageState();
}

class _AlunosPageState extends ConsumerState<AlunosPage> {
  bool _openingForm = false;
  late final TextEditingController _buscaController;

  // Busca com debounce
  String _buscaAtiva = '';
  Timer? _debounceTimer;

  // Ordenacao
  AlunosOrdenacao _ordenacao = AlunosOrdenacao.vencimento;

  // Seeds para formulario
  int? _ultimoDiaVencimento;
  double? _ultimaMensalidade;
  DateTime? _lastSyncAt;

  // Scroll controller para trigger de loadMore
  late final ScrollController _scrollController;
  bool _loadingMorePending = false;

  @override
  void initState() {
    super.initState();
    _buscaController = TextEditingController();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _buscaController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMorePending || _openingForm) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final atEnd = currentScroll >= maxScroll - 200;
    final notifier = ref.read(_alunosPaginados.notifier);
    if (atEnd && notifier.hasMore) {
      _loadingMorePending = true;
      notifier.loadMore();
      _loadingMorePending = false;
    }
  }

  void markSynced() {
    if (!mounted) return;
    setState(() => _lastSyncAt = DateTime.now());
  }

  void _onBuscaChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _buscaAtiva = value);
    });
  }

  List<Aluno> _getAlunosOrdenados(List<Aluno> alunos) {
    final busca = _buscaAtiva.trim().toLowerCase();
    final buscaDigitos = _somenteDigitos(busca);

    final filtrados = alunos.where((aluno) {
      if (busca.isEmpty) return true;
      final nome = aluno.nome.toLowerCase();
      final telefone = aluno.telefone.toLowerCase();
      final telefoneDigitos = _somenteDigitos(aluno.telefone);
      return nome.contains(busca) ||
          telefone.contains(busca) ||
          (buscaDigitos.isNotEmpty && telefoneDigitos.contains(buscaDigitos));
    }).toList();

    filtrados.sort((a, b) {
      final byNome = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
      final byVencimento = a.diaVencimento.compareTo(b.diaVencimento);

      return switch (_ordenacao) {
        AlunosOrdenacao.vencimento => byVencimento != 0 ? byVencimento : byNome,
        AlunosOrdenacao.nome => byNome,
        AlunosOrdenacao.pagosPrimeiro => _compararPeso(
          _pesoPago(a),
          _pesoPago(b),
          byNome,
        ),
        AlunosOrdenacao.atrasadosPrimeiro => _compararPeso(
          _pesoAtraso(a),
          _pesoAtraso(b),
          byNome,
        ),
      };
    });
    return filtrados;
  }

  List<Aluno> _aplicarFiltro(
    AlunoFiltro filtro,
    List<Aluno> ativosPaginados,
    List<Aluno> historico,
  ) {
    final referencia = DateTime.now();
    final competenciaAtual = Aluno.competenciaAtual(referencia);
    final referenciaStatus = Aluno.referenciaStatusDaCompetencia(referencia);
    final historicoById = <String, Aluno>{
      for (final aluno in historico) aluno.id: aluno,
    };
    final ativos = ativosPaginados
        .map((aluno) => historicoById[aluno.id] ?? aluno)
        .where((aluno) => aluno.ativo)
        .toList();

    return switch (filtro) {
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
      AlunoFiltro.inativos => historico.where((a) => !a.ativo).toList(),
    };
  }

  /// Provider instance reutilizado na pagina (somente ativos).
  AlunosPaginadosProvider get _alunosPaginados =>
      alunosPaginadosProvider(onlyActive: true);

  @override
  Widget build(BuildContext context) {
    ref.watch(pagamentosAcumuladosBackfillRunnerProvider);
    final paginationState = ref.watch(_alunosPaginados);
    final ativosPaginados = paginationState.value ?? const <Aluno>[];
    final historicoAsync = ref.watch(alunosHistoricoStreamProvider);
    final historico = historicoAsync.value ?? const <Aluno>[];
    final filtro = ref.watch(alunosFiltroProvider);
    final todosAlunos = historico;
    final alunosBase = _aplicarFiltro(filtro, ativosPaginados, historico);
    final alunos = _getAlunosOrdenados(alunosBase);
    final stats = ref.watch(dashboardStatsProvider);
    final defaultMensalidade = ref
        .watch(defaultMensalidadeStreamProvider)
        .value;

    final scheme = Theme.of(context).colorScheme;
    final isLoading = filtro == AlunoFiltro.inativos
        ? historicoAsync.isLoading
        : paginationState.isLoading;
    final notifier = ref.read(_alunosPaginados.notifier);
    final hasMore = filtro == AlunoFiltro.inativos ? false : notifier.hasMore;
    final baseAsync = filtro == AlunoFiltro.inativos
        ? historicoAsync
        : paginationState;
    final hasBaseData = filtro == AlunoFiltro.inativos
        ? historico.isNotEmpty
        : ativosPaginados.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: AlunosHeaderSection(
                openingForm: _openingForm,
                onNovoAluno: () => _onNovoAluno(defaultMensalidade),
                onExportCsv: () => _exportarCsvAtual(context, alunos),
                onExportPdf: () => _exportarPdfAtual(context, alunos),
                buscaController: _buscaController,
                busca: _buscaAtiva,
                onBuscaChanged: _onBuscaChanged,
                onClearBusca: () {
                  _buscaController.clear();
                  setState(() => _buscaAtiva = '');
                },
                ordenacao: _ordenacao,
                onOrdenacaoChanged: (value) =>
                    setState(() => _ordenacao = value),
                filtro: filtro,
                onFiltroChanged: (v) {
                  ref.read(alunosFiltroProvider.notifier).select(v);
                },
                stats: stats,
                isSyncing: isLoading,
                lastSyncAt: _lastSyncAt,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              sliver: baseAsync.hasError && !hasBaseData
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'Erro ao carregar: ${formatFirestoreError(baseAsync.asError!.error)}',
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    )
                  : isLoading && !hasBaseData
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    )
                  : alunos.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: EmptyAlunosState(
                          hasData: todosAlunos.isNotEmpty,
                          hasBusca: _buscaAtiva.trim().isNotEmpty,
                          onResetBusca: () {
                            _buscaController.clear();
                            setState(() {
                              _buscaAtiva = '';
                              _ordenacao = AlunosOrdenacao.vencimento;
                            });
                            ref
                                .read(alunosFiltroProvider.notifier)
                                .select(AlunoFiltro.todos);
                            notifier.refresh();
                          },
                          onAdd: _openingForm
                              ? null
                              : () => _onNovoAluno(defaultMensalidade),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        if (i >= alunos.length && hasMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingSm,
                          ),
                          child: RepaintBoundary(
                            child: _AnimatedCard(
                              key: ValueKey(alunos[i].id),
                              delay: i > 8 ? 0 : i * 30,
                              child: AlunoCard(
                                aluno: alunos[i],
                                defaultMensalidade: defaultMensalidade,
                                onSynced: markSynced,
                              ),
                            ),
                          ),
                        );
                      }, childCount: alunos.length + (hasMore ? 1 : 0)),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: _openingForm
              ? null
              : () => _onNovoAluno(defaultMensalidade),
          backgroundColor: scheme.primary,
          icon: _openingForm
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_rounded, size: 24),
          label: Text(_openingForm ? 'Abrindo...' : 'Novo aluno'),
        ),
      ),
    );
  }

  Future<void> _onNovoAluno(double? defaultMensalidade) async {
    if (_openingForm) return;

    setState(() => _openingForm = true);
    final result = await AlunoFormSheet.show(
      context,
      title: 'Novo aluno',
      defaultMensalidade: defaultMensalidade,
      seedDiaVencimento: _ultimoDiaVencimento,
      seedMensalidade: _ultimaMensalidade,
    );
    if (mounted) setState(() => _openingForm = false);
    if (result == null) return;

    try {
      await ref
          .read(alunosActionsControllerProvider)
          .criarAluno(
            AlunoCadastroInput(
              nome: result.nome,
              telefone: result.telefone,
              observacao: result.observacao,
              diaVencimento: result.diaVencimento,
              mensalidade: result.mensalidade,
              pago: result.pago,
            ),
          );
      _ultimoDiaVencimento = result.diaVencimento;
      _ultimaMensalidade = result.mensalidade;
      markSynced();
      ref.read(_alunosPaginados.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aluno salvo com sucesso.'),
          action: SnackBarAction(
            label: 'Cadastro r\u00e1pido',
            onPressed: () => _onNovoAluno(defaultMensalidade),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
    }
  }

  Future<void> _exportarCsvAtual(
    BuildContext context,
    List<Aluno> alunos,
  ) async {
    if (alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'N\u00e3o h\u00e1 alunos na vis\u00e3o atual para exportar.',
          ),
        ),
      );
      return;
    }
    try {
      await ReportExportService().exportarCsvMensal(alunos);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV da vis\u00e3o atual exportado com sucesso.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
    }
  }

  Future<void> _exportarPdfAtual(
    BuildContext context,
    List<Aluno> alunos,
  ) async {
    if (alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'N\u00e3o h\u00e1 alunos na vis\u00e3o atual para exportar.',
          ),
        ),
      );
      return;
    }
    try {
      await ReportExportService().exportarPdfMensal(alunos);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF da vis\u00e3o atual exportado com sucesso.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
    }
  }
}

/// Wrapper de animacao reutilizavel para cards da lista.
class _AnimatedCard extends StatefulWidget {
  const _AnimatedCard({
    required super.key,
    required this.child,
    this.delay = 0,
  });

  final Widget child;
  final int delay;

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _startAnimation();
  }

  void _startAnimation() {
    widget.delay == 0
        ? _controller.forward()
        : Future.delayed(Duration(milliseconds: widget.delay), () {
            if (mounted) _controller.forward();
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// --- Helper functions (fora da classe para reuso) ---

int _compararPeso(int pesoA, int pesoB, int fallback) {
  final compare = pesoB.compareTo(pesoA);
  return compare != 0 ? compare : fallback;
}

int _pesoPago(Aluno aluno) {
  if (aluno.pago) return 2;
  if (aluno.atrasado) return 0;
  return 1;
}

int _pesoAtraso(Aluno aluno) {
  if (aluno.atrasado) return 2;
  if (!aluno.pago) return 1;
  return 0;
}

String _somenteDigitos(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

String? normalizarTelefoneWhatsApp(String telefone) {
  return whatsapp_phone.normalizarTelefoneWhatsApp(telefone);
}
