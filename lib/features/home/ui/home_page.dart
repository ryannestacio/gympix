import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_theme_extensions.dart';
import '../../../core/utils/firestore_error_formatter.dart';
import '../../alunos/models/aluno.dart';
import '../../alunos/providers/alunos_providers.dart';
import '../../relatorios/models/competencia_report.dart';
import '../../relatorios/providers/competencia_report_providers.dart';
import '../../relatorios/services/report_export_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 0,
  );
  static final DateFormat _headerMonthFormatter = DateFormat('MM/yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(vencimentoHojeNotificationRunnerProvider);
    ref.watch(pagamentosAcumuladosBackfillRunnerProvider);
    final competenciaSelecionada = ref.watch(competenciaSelecionadaProvider);
    final report = ref.watch(competenciaReportProvider);
    final stats = ref.watch(dashboardStatsProvider);
    final alunosAtivos =
        ref.watch(alunosStreamProvider).value ?? const <Aluno>[];
    final proximos = _buildProximosVencimentos(alunosAtivos);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ext = AppThemeExtensions.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath = isDark
        ? 'assets/images/logo-gympix-pb.png'
        : 'assets/images/logo-gympix-colorida.png';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  AppTheme.spacingLg,
                  AppTheme.spacingMd,
                  AppTheme.spacingMd,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Center(
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              logoPath,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dashboard financeiro da academia',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: () => context.go('/config'),
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.primary,
                      ),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacingMd),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visão rápida',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          Row(
                            children: [
                              Expanded(
                                child: _FinanceMiniStat(
                                  label: 'Recebido',
                                  value: _formatMoney(stats.recebidoMes),
                                  color: ext.success,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: _FinanceMiniStat(
                                  label: 'Em aberto',
                                  value: _formatMoney(stats.emAbertoAcumulado),
                                  color: ext.warning,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: _FinanceMiniStat(
                                  label: 'Atrasados',
                                  value: '${stats.atrasados}',
                                  color: scheme.error,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Resumo do mês (${_headerMonthFormatter.format(competenciaSelecionada)})',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        _CompetenciaSelector(
                          competencia: competenciaSelecionada,
                          onChanged: (value) => ref
                              .read(competenciaSelecionadaProvider.notifier)
                              .select(value),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Alunos ativos',
                            value: '${stats.totalAlunos}',
                            icon: Icons.people_outline_rounded,
                            color: scheme.primary,
                            useGradient: true,
                            index: 0,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: _StatCard(
                            label: 'Pendentes',
                            value: '${stats.pendentes}',
                            icon: Icons.schedule_rounded,
                            color: ext.warning,
                            index: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Atrasados',
                            value: '${stats.atrasados}',
                            icon: Icons.warning_amber_rounded,
                            color: scheme.error,
                            index: 2,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: _StatCard(
                            label: 'Recebido',
                            value: _formatMoney(stats.recebidoMes),
                            icon: Icons.trending_up_rounded,
                            color: ext.success,
                            useGradient: true,
                            index: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Previsto',
                            value: _formatMoney(stats.previstoMes),
                            icon: Icons.assessment_outlined,
                            color: scheme.secondary,
                            index: 4,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: _StatCard(
                            label: 'Inadimplência',
                            value:
                                '${stats.inadimplenciaPercent.toStringAsFixed(0)}%',
                            icon: Icons.percent_rounded,
                            color: ext.warning,
                            index: 5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      'Vencimentos próximos',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _VencimentosSection(itens: proximos),
                    const SizedBox(height: AppTheme.spacingXl),
                    Text(
                      'Ações',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _ActionTile(
                      icon: Icons.people_alt_outlined,
                      title: 'Gerenciar alunos',
                      subtitle: 'Cadastrar, editar e cobrar alunos',
                      onTap: () => context.go('/alunos'),
                    ),
                    const SizedBox(height: AppTheme.spacingXs + 2),
                    _ActionTile(
                      icon: Icons.file_download_outlined,
                      title: 'Exportar CSV mensal',
                      subtitle: 'Baixar e compartilhar relatório financeiro',
                      onTap: () => _exportCsv(context, report),
                    ),
                    const SizedBox(height: AppTheme.spacingXs + 2),
                    _ActionTile(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Exportar PDF mensal',
                      subtitle: 'Resumo da competência selecionada',
                      onTap: () => _exportPdf(context, report),
                    ),
                    const SizedBox(height: AppTheme.spacingXs + 2),
                    _ActionTile(
                      icon: Icons.settings_outlined,
                      title: 'Configurações',
                      subtitle: 'Pix e mensalidade padrão',
                      onTap: () => context.go('/config'),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(
    BuildContext context,
    CompetenciaReportData report,
  ) async {
    try {
      await ReportExportService().exportarCsvCompetencia(report);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV exportado com sucesso.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    CompetenciaReportData report,
  ) async {
    try {
      await ReportExportService().exportarPdfCompetencia(report);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF exportado com sucesso.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
    }
  }

  String _formatMoney(double value) {
    return _currencyFormatter.format(value);
  }
}

class _CompetenciaSelector extends StatelessWidget {
  const _CompetenciaSelector({
    required this.competencia,
    required this.onChanged,
  });

  static final DateFormat _monthYearFormatter = DateFormat('MMM/yyyy', 'pt_BR');

  final DateTime competencia;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final atual = DateTime.now();
    final mesAtual = DateTime(atual.year, atual.month);
    final isMesAtual =
        competencia.year == mesAtual.year &&
        competencia.month == mesAtual.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                onChanged(DateTime(competencia.year, competencia.month - 1)),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 104),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _monthYearFormatter.format(competencia),
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: isMesAtual ? null : () => onChanged(mesAtual),
                  child: Text(
                    isMesAtual ? 'Mês atual' : 'Voltar ao mês atual',
                    style: textTheme.labelSmall?.copyWith(
                      color: isMesAtual
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                onChanged(DateTime(competencia.year, competencia.month + 1)),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _VencimentoItem {
  const _VencimentoItem({
    required this.aluno,
    required this.label,
    required this.daysUntil,
  });

  final Aluno aluno;
  final String label;
  final int daysUntil;
}

List<_VencimentoItem> _buildProximosVencimentos(List<Aluno> alunos) {
  final now = DateTime.now();
  final hoje = DateTime(now.year, now.month, now.day);
  final itens = <_VencimentoItem>[];

  for (final aluno in alunos) {
    if (aluno.pago) continue;
    final dueDate = Aluno.dataVencimento(aluno.diaVencimento, now);
    final normalizedDue = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntil = normalizedDue.difference(hoje).inDays;
    if (daysUntil < 0 || daysUntil > 7) continue;

    final label = switch (daysUntil) {
      0 => 'Vence hoje',
      1 => 'Vence amanhã',
      _ => 'Vence em $daysUntil dias',
    };

    itens.add(
      _VencimentoItem(aluno: aluno, label: label, daysUntil: daysUntil),
    );
  }

  itens.sort((a, b) {
    final byDays = a.daysUntil.compareTo(b.daysUntil);
    if (byDays != 0) return byDays;
    return a.aluno.nome.toLowerCase().compareTo(b.aluno.nome.toLowerCase());
  });

  return itens;
}

class _VencimentosSection extends StatelessWidget {
  const _VencimentosSection({required this.itens});

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  final List<_VencimentoItem> itens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (itens.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          'Nenhum aluno com vencimento para hoje ou para os próximos 7 dias.',
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: itens
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        '${item.aluno.diaVencimento}',
                        style: textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.aluno.nome,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.label} - ${_currencyFormatter.format(item.aluno.mensalidade)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
    this.useGradient = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.scale(
          scale: t,
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: useGradient ? null : scheme.surface,
          gradient: useGradient
              ? LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: isDark ? 0.85 : 0.92),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isDark ? 16 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXs),
              decoration: BoxDecoration(
                color: useGradient
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                icon,
                size: 22,
                color: useGradient ? Colors.white : color,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: useGradient ? Colors.white : scheme.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: useGradient
                    ? Colors.white.withValues(alpha: 0.9)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceMiniStat extends StatelessWidget {
  const _FinanceMiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: scheme.primary, size: 24),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
