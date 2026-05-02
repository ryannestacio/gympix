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
                tooltip: 'Exportar vis\u00e3o atual',
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
            'Cadastro, cobran\u00e7a e status mensal em um s\u00f3 lugar.',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SyncStatusChip(isSyncing: isSyncing, lastSyncAt: lastSyncAt),
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
          FiltroChips(value: filtro, onChanged: onFiltroChanged),
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
    const items = <_FiltroChipItem>[
      _FiltroChipItem(label: 'Ativos', value: AlunoFiltro.todos),
      _FiltroChipItem(label: 'Pagos', value: AlunoFiltro.pagos),
      _FiltroChipItem(label: 'Pendentes', value: AlunoFiltro.pendentes),
      _FiltroChipItem(label: 'Atrasados', value: AlunoFiltro.atrasados),
      _FiltroChipItem(label: 'Inativos', value: AlunoFiltro.inativos),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(items.length, (index) {
        final item = items[index];
        return _Chip(
          label: item.label,
          selected: value == item.value,
          index: index,
          onTap: () => onChanged(item.value),
        );
      }),
    );
  }
}

class _FiltroChipItem {
  const _FiltroChipItem({required this.label, required this.value});

  final String label;
  final AlunoFiltro value;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.index,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = _chipRadius(index);
    final padding = _chipPadding(index);
    final yOffset = switch (index) {
      0 => 0.0,
      1 => -1.5,
      2 => 1.0,
      3 => -2.0,
      _ => 0.5,
    };

    return Transform.translate(
      offset: Offset(0, yOffset),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.62)
            : scheme.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _chipRadius(int index) {
    return switch (index) {
      0 => const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(14),
        bottomLeft: Radius.circular(14),
        bottomRight: Radius.circular(22),
      ),
      1 => const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(22),
        bottomLeft: Radius.circular(22),
        bottomRight: Radius.circular(12),
      ),
      2 => const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(24),
      ),
      3 => const BorderRadius.only(
        topLeft: Radius.circular(14),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(14),
      ),
      _ => const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(14),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(20),
      ),
    };
  }

  EdgeInsets _chipPadding(int index) {
    return switch (index) {
      0 => const EdgeInsets.fromLTRB(17, 9, 14, 8),
      1 => const EdgeInsets.fromLTRB(15, 8, 17, 10),
      2 => const EdgeInsets.fromLTRB(16, 10, 16, 8),
      3 => const EdgeInsets.fromLTRB(15, 8, 18, 9),
      _ => const EdgeInsets.fromLTRB(16, 9, 15, 9),
    };
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
        ? 'Aguardando sincroniza\u00e7\u00e3o'
        : 'Atualizado \u00e0s ${DateFormat('HH:mm').format(lastSyncAt!)}';
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
          'Toque em + Novo aluno para come\u00e7ar',
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
