import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/alunos_providers.dart';

enum AlunosOrdenacao { vencimento, nome, pagosPrimeiro, atrasadosPrimeiro }

class AlunosHeaderSection extends StatelessWidget {
  const AlunosHeaderSection({
    super.key,
    required this.openingForm,
    required this.onNovoAluno,
    required this.onExportCsv,
    required this.onExportPdf,
    required this.buscaController,
    required this.busca,
    required this.onBuscaChanged,
    required this.onClearBusca,
    required this.ordenacao,
    required this.onOrdenacaoChanged,
    required this.filtro,
    required this.onFiltroChanged,
    required this.stats,
    required this.isSyncing,
    required this.lastSyncAt,
  });

  final bool openingForm;
  final VoidCallback onNovoAluno;
  final VoidCallback onExportCsv;
  final VoidCallback onExportPdf;
  final TextEditingController buscaController;
  final String busca;
  final ValueChanged<String> onBuscaChanged;
  final VoidCallback onClearBusca;
  final AlunosOrdenacao ordenacao;
  final ValueChanged<AlunosOrdenacao> onOrdenacaoChanged;
  final AlunoFiltro filtro;
  final ValueChanged<AlunoFiltro> onFiltroChanged;
  final DashboardStats stats;
  final bool isSyncing;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
        AppTheme.spacingMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alunos',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Exportar visao atual',
                onSelected: (value) {
                  if (value == 'csv') onExportCsv();
                  if (value == 'pdf') onExportPdf();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Exportar CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Exportar PDF'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Icon(
                    Icons.ios_share_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: openingForm ? null : onNovoAluno,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cadastro, cobranca e status mensal em um so lugar.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SyncStatusChip(
            isSyncing: isSyncing,
            lastSyncAt: lastSyncAt,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          BuscaOrdenacaoBar(
            controller: buscaController,
            busca: busca,
            ordenacao: ordenacao,
            onBuscaChanged: onBuscaChanged,
            onClearBusca: onClearBusca,
            onOrdenacaoChanged: onOrdenacaoChanged,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          FiltroChips(
            value: filtro,
            onChanged: onFiltroChanged,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: InfoBadge(
                  icon: Icons.people_outline_rounded,
                  label: 'Ativos',
                  value: '${stats.totalAlunos}',
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: InfoBadge(
                  icon: Icons.schedule_rounded,
                  label: 'Pendentes',
                  value: '${stats.pendentes}',
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: InfoBadge(
                  icon: Icons.warning_amber_rounded,
                  label: 'Atrasados',
                  value: '${stats.atrasados}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BuscaOrdenacaoBar extends StatelessWidget {
  const BuscaOrdenacaoBar({
    super.key,
    required this.controller,
    required this.busca,
    required this.ordenacao,
    required this.onBuscaChanged,
    required this.onClearBusca,
    required this.onOrdenacaoChanged,
  });

  final TextEditingController controller;
  final String busca;
  final AlunosOrdenacao ordenacao;
  final ValueChanged<String> onBuscaChanged;
  final VoidCallback onClearBusca;
  final ValueChanged<AlunosOrdenacao> onOrdenacaoChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onBuscaChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou telefone',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: busca.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearBusca,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        PopupMenuButton<AlunosOrdenacao>(
          tooltip: 'Ordenar lista',
          onSelected: onOrdenacaoChanged,
          itemBuilder: (context) => AlunosOrdenacao.values
              .map(
                (item) => PopupMenuItem<AlunosOrdenacao>(
                  value: item,
                  child: Row(
                    children: [
                      Icon(
                        ordenacaoIcon(item),
                        size: 18,
                        color: item == ordenacao
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Text(ordenacaoLabel(item)),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: scheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_vert_rounded, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ordenar',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FiltroChips extends StatelessWidget {
  const FiltroChips({super.key, required this.value, required this.onChanged});

  final AlunoFiltro value;
  final ValueChanged<AlunoFiltro> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          label: 'Todos',
          selected: value == AlunoFiltro.todos,
          onTap: () => onChanged(AlunoFiltro.todos),
        ),
        _Chip(
          label: 'Pagos',
          selected: value == AlunoFiltro.pagos,
          onTap: () => onChanged(AlunoFiltro.pagos),
        ),
        _Chip(
          label: 'Pendentes',
          selected: value == AlunoFiltro.pendentes,
          onTap: () => onChanged(AlunoFiltro.pendentes),
        ),
        _Chip(
          label: 'Atrasados',
          selected: value == AlunoFiltro.atrasados,
          onTap: () => onChanged(AlunoFiltro.atrasados),
        ),
        _Chip(
          label: 'Inativos',
          selected: value == AlunoFiltro.inativos,
          onTap: () => onChanged(AlunoFiltro.inativos),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.6) : scheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class InfoBadge extends StatelessWidget {
  const InfoBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.isSyncing,
    required this.lastSyncAt,
  });

  final bool isSyncing;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = isSyncing
        ? 'Sincronizando...'
        : lastSyncAt == null
            ? 'Aguardando sincronizacao'
            : 'Atualizado as ${DateFormat('HH:mm').format(lastSyncAt!)}';
    final color = isSyncing ? scheme.primary : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: isSyncing
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  )
                : Icon(Icons.cloud_done_rounded, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class EmptyAlunosState extends StatelessWidget {
  const EmptyAlunosState({
    super.key,
    required this.hasData,
    required this.hasBusca,
    required this.onResetBusca,
    required this.onAdd,
  });

  final bool hasData;
  final bool hasBusca;
  final VoidCallback onResetBusca;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (hasData) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            hasBusca ? 'Nenhum aluno encontrado' : 'Nenhum aluno neste filtro',
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            hasBusca
                ? 'Tente buscar por outro nome ou telefone.'
                : 'Ajuste os filtros para ver outros alunos.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton.icon(
            onPressed: onResetBusca,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Limpar busca e filtros'),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.people_outline_rounded,
          size: 64,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Nenhum aluno cadastrado',
          style: textTheme.titleMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          'Toque em + Novo aluno para comecar',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar primeiro aluno'),
        ),
      ],
    );
  }
}

String ordenacaoLabel(AlunosOrdenacao value) {
  return switch (value) {
    AlunosOrdenacao.vencimento => 'Vencimento',
    AlunosOrdenacao.nome => 'Nome',
    AlunosOrdenacao.pagosPrimeiro => 'Pagos primeiro',
    AlunosOrdenacao.atrasadosPrimeiro => 'Atrasados primeiro',
  };
}

IconData ordenacaoIcon(AlunosOrdenacao value) {
  return switch (value) {
    AlunosOrdenacao.vencimento => Icons.event_outlined,
    AlunosOrdenacao.nome => Icons.sort_by_alpha_rounded,
    AlunosOrdenacao.pagosPrimeiro => Icons.check_circle_outline_rounded,
    AlunosOrdenacao.atrasadosPrimeiro => Icons.warning_amber_rounded,
  };
}
