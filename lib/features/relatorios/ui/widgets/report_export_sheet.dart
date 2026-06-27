import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../alunos/models/aluno.dart';
import '../../../alunos/providers/alunos_providers.dart';
import '../../providers/competencia_report_providers.dart';
import '../../services/report_export_service.dart';

class ReportExportSheet extends ConsumerStatefulWidget {
  const ReportExportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => const ReportExportSheet(),
    );
  }

  @override
  ConsumerState<ReportExportSheet> createState() => _ReportExportSheetState();
}

class _ReportExportSheetState extends ConsumerState<ReportExportSheet> {
  bool _exporting = false;

  Future<void> _exportPdf1(WidgetRef ref) async {
    setState(() => _exporting = true);
    try {
      final report = ref.read(competenciaReportProvider);
      await ReportExportService().exportarPdfCompetencia(report);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf2(WidgetRef ref) async {
    setState(() => _exporting = true);
    try {
      final alunos = ref.read(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
      if (alunos.isEmpty) {
        throw 'Nenhum aluno encontrado para exportar cadastro.';
      }
      await ReportExportService().exportarPdfCadastroGeral(alunos);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf3(WidgetRef ref) async {
    final selecionado = await showDialog<DateTime>(
      context: context,
      builder: (context) => const MesAnoPickerDialog(),
    );
    if (selecionado == null) return;

    setState(() => _exporting = true);
    try {
      final alunos = ref.read(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
      if (alunos.isEmpty) {
        throw 'Nenhum aluno encontrado para exportar relatório.';
      }
      await ReportExportService().exportarPdfMensal(alunos, referencia: selecionado);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final competenciaSelecionada = ref.watch(competenciaSelecionadaProvider);
    final competenciaLabel = DateFormat('MM/yyyy').format(competenciaSelecionada);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingXs,
          AppTheme.spacingLg,
          AppTheme.spacingMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Exportar Relatórios PDF',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Escolha o tipo de relatório financeiro ou cadastral que deseja gerar.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            if (_exporting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _ReportOptionCard(
                icon: Icons.analytics_outlined,
                title: 'Competência Selecionada ($competenciaLabel)',
                subtitle: 'Gera o balanço financeiro com faturamentos, inadimplência e a lista de alunos deste mês específico.',
                onTap: () => _exportPdf1(ref),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _ReportOptionCard(
                icon: Icons.contact_mail_outlined,
                title: 'Cadastro Geral (Ficha de Contatos)',
                subtitle: 'Gera uma ficha cadastral completa com todos os alunos (ativos e inativos), contendo contatos, vencimentos e mensalidades.',
                onTap: () => _exportPdf2(ref),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _ReportOptionCard(
                icon: Icons.date_range_outlined,
                title: 'Escolher Competência Passada',
                subtitle: 'Selecione qualquer mês e ano do histórico para gerar o balanço financeiro fechado daquele período.',
                onTap: () => _exportPdf3(ref),
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}

class _ReportOptionCard extends StatelessWidget {
  const _ReportOptionCard({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: scheme.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: scheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class MesAnoPickerDialog extends StatefulWidget {
  const MesAnoPickerDialog({super.key});

  @override
  State<MesAnoPickerDialog> createState() => _MesAnoPickerDialogState();
}

class _MesAnoPickerDialogState extends State<MesAnoPickerDialog> {
  late int _mesSelecionado;
  late int _anoSelecionado;

  final List<String> _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  late List<int> _anos;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesSelecionado = now.month;
    _anoSelecionado = now.year;
    _anos = List.generate(11, (index) => now.year - 5 + index);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: scheme.surface,
      title: Text(
        'Selecionar Competência',
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _mesSelecionado,
              decoration: const InputDecoration(
                labelText: 'Mês',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(_meses[index]),
                );
              }),
              onChanged: (val) {
                if (val != null) setState(() => _mesSelecionado = val);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _anoSelecionado,
              decoration: const InputDecoration(
                labelText: 'Ano',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _anos.map((ano) {
                return DropdownMenuItem(
                  value: ano,
                  child: Text('$ano'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _anoSelecionado = val);
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(DateTime(_anoSelecionado, _mesSelecionado));
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
