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
  String _busca = '';
  AlunosOrdenacao _ordenacao = AlunosOrdenacao.vencimento;
  int? _ultimoDiaVencimento;
  double? _ultimaMensalidade;
  DateTime? _lastSyncAt;

  @override
  void initState() {
    super.initState();
    _buscaController = TextEditingController();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void markSynced() {
    if (!mounted) return;
    setState(() => _lastSyncAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosHistoricoStreamProvider);
    if (_lastSyncAt == null && alunosAsync.hasValue) {
      markSynced();
    }

    final todosAlunos = alunosAsync.value ?? const <Aluno>[];
    final alunosBase = ref.watch(alunosFiltradosProvider);
    final alunos = _aplicarBuscaEOrdenacao(alunosBase);
    final filtro = ref.watch(alunosFiltroProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final defaultMensalidade = ref
        .watch(defaultMensalidadeStreamProvider)
        .value;

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AlunosHeaderSection(
                openingForm: _openingForm,
                onNovoAluno: () => _onNovoAluno(defaultMensalidade),
                onExportCsv: () => _exportarCsvAtual(context, alunos),
                onExportPdf: () => _exportarPdfAtual(context, alunos),
                buscaController: _buscaController,
                busca: _busca,
                onBuscaChanged: (value) => setState(() => _busca = value),
                onClearBusca: () {
                  _buscaController.clear();
                  setState(() => _busca = '');
                },
                ordenacao: _ordenacao,
                onOrdenacaoChanged: (value) =>
                    setState(() => _ordenacao = value),
                filtro: filtro,
                onFiltroChanged: (v) {
                  ref.read(alunosFiltroProvider.notifier).select(v);
                },
                stats: stats,
                isSyncing: alunosAsync.isLoading,
                lastSyncAt: _lastSyncAt,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              sliver: alunosAsync.when(
                data: (_) {
                  if (alunos.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: EmptyAlunosState(
                          hasData: todosAlunos.isNotEmpty,
                          hasBusca: _busca.trim().isNotEmpty,
                          onResetBusca: () {
                            _buscaController.clear();
                            setState(() {
                              _busca = '';
                              _ordenacao = AlunosOrdenacao.vencimento;
                            });
                            ref
                                .read(alunosFiltroProvider.notifier)
                                .select(AlunoFiltro.todos);
                          },
                          onAdd: _openingForm
                              ? null
                              : () => _onNovoAluno(defaultMensalidade),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                          milliseconds: 200 + (i > 8 ? 0 : i * 30),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingSm,
                          ),
                          child: AlunoCard(
                            key: ValueKey(alunos[i].id),
                            aluno: alunos[i],
                            defaultMensalidade: defaultMensalidade,
                            onSynced: markSynced,
                          ),
                        ),
                      );
                    }, childCount: alunos.length),
                  );
                },
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Erro ao carregar: $e',
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ),
                loading: () => SliverFillRemaining(
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
                ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Aluno salvo com sucesso.'),
          action: SnackBarAction(
            label: 'Cadastro rapido',
            onPressed: () => _onNovoAluno(defaultMensalidade),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatFirestoreError(e))),
      );
    }
  }

  Future<void> _exportarCsvAtual(
    BuildContext context,
    List<Aluno> alunos,
  ) async {
    if (alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao ha alunos na visao atual para exportar.'),
        ),
      );
      return;
    }
    try {
      await ReportExportService().exportarCsvMensal(alunos);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV da visao atual exportado com sucesso.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao exportar CSV: $e')));
    }
  }

  Future<void> _exportarPdfAtual(
    BuildContext context,
    List<Aluno> alunos,
  ) async {
    if (alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao ha alunos na visao atual para exportar.'),
        ),
      );
      return;
    }
    try {
      await ReportExportService().exportarPdfMensal(alunos);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF da visao atual exportado com sucesso.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao exportar PDF: $e')));
    }
  }

  List<Aluno> _aplicarBuscaEOrdenacao(List<Aluno> alunos) {
    final buscaNormalizada = _busca.trim().toLowerCase();
    final buscaDigitos = _somenteDigitos(buscaNormalizada);

    final filtrados = alunos.where((aluno) {
      if (buscaNormalizada.isEmpty) return true;
      final nome = aluno.nome.toLowerCase();
      final telefone = aluno.telefone.toLowerCase();
      final telefoneDigitos = _somenteDigitos(aluno.telefone);
      return nome.contains(buscaNormalizada) ||
          telefone.contains(buscaNormalizada) ||
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
}

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
