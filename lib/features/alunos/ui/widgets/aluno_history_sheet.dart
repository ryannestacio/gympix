import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../models/aluno.dart';

class HistoricoAlunoSheet extends StatefulWidget {
  const HistoricoAlunoSheet({super.key, required this.aluno});

  final Aluno aluno;

  @override
  State<HistoricoAlunoSheet> createState() => _HistoricoAlunoSheetState();
}

class _HistoricoAlunoSheetState extends State<HistoricoAlunoSheet> {
  String _competenciaSelecionada = 'todas';

  List<PagamentoMensal> get _itensOrdenados {
    final itens = widget.aluno.pagamentos.values.toList()
      ..sort((a, b) => b.competencia.compareTo(a.competencia));
    if (_competenciaSelecionada == 'todas') return itens;
    return itens
        .where((item) => item.competencia == _competenciaSelecionada)
        .toList();
  }

  List<String> get _competencias {
    final competencias = widget.aluno.pagamentos.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return ['todas', ...competencias];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final itens = _itensOrdenados;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingSm,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Historico mensal - ${widget.aluno.nome}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Filtre por competencia para revisar pagamentos anteriores.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            DropdownButtonFormField<String>(
              initialValue: _competenciaSelecionada,
              decoration: const InputDecoration(
                labelText: 'Competencia',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              items: _competencias
                  .map(
                    (competencia) => DropdownMenuItem<String>(
                      value: competencia,
                      child: Text(competenciaLabel(competencia)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _competenciaSelecionada = value);
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: scheme.outline.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exibindo ${itens.length} registro(s) em ${competenciaLabel(_competenciaSelecionada)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (itens.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingLg,
                ),
                child: Text(
                  'Sem registros para a competencia selecionada.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: itens.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spacingSm),
                  itemBuilder: (context, i) {
                    final p = itens[i];
                    final statusColor = statusColorFromPagamento(
                      context,
                      p.status,
                    );
                    return Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  competenciaLabel(p.competencia),
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  p.statusLabel.toUpperCase(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          HistoricoInfoRow(
                            label: 'Vencimento',
                            value: 'Dia ${p.diaVencimento}',
                          ),
                          HistoricoInfoRow(
                            label: 'Valor',
                            value: NumberFormat.currency(
                              locale: 'pt_BR',
                              symbol: 'R\$',
                            ).format(p.valor),
                          ),
                          HistoricoInfoRow(
                            label: 'Pago em',
                            value: p.pagoEm == null
                                ? '-'
                                : DateFormat('dd/MM/yyyy HH:mm').format(p.pagoEm!),
                          ),
                          if ((p.comprovanteUrl ?? '').isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingSm),
                            Text(
                              'Comprovante',
                              style: textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              p.comprovanteUrl!,
                              style: textTheme.bodySmall,
                            ),
                          ],
                          if ((p.observacao ?? '').isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingSm),
                            Text(
                              'Observacoes',
                              style: textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(p.observacao!, style: textTheme.bodySmall),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HistoricoInfoRow extends StatelessWidget {
  const HistoricoInfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodyMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color statusColorFromPagamento(BuildContext context, PagamentoStatus status) {
  final ext = AppThemeExtensions.of(context);
  return switch (status) {
    PagamentoStatus.pago => ext.success,
    PagamentoStatus.atrasado => Theme.of(context).colorScheme.error,
    PagamentoStatus.pendente => ext.warning,
  };
}

String competenciaLabel(String competencia) {
  if (competencia == 'todas') return 'Todas as competencias';
  final parts = competencia.split('-');
  if (parts.length != 2) return competencia;
  final ano = int.tryParse(parts[0]);
  final mes = int.tryParse(parts[1]);
  if (ano == null || mes == null) return competencia;

  const meses = [
    '',
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  if (mes < 1 || mes > 12) return competencia;
  return '${meses[mes]} $ano';
}

class RegistroPagamentoResult {
  const RegistroPagamentoResult({
    required this.pagoEm,
    required this.valor,
    this.comprovanteUrl,
    this.observacao,
  });

  final DateTime pagoEm;
  final double valor;
  final String? comprovanteUrl;
  final String? observacao;
}

class RegistroPagamentoSheet extends StatefulWidget {
  const RegistroPagamentoSheet({super.key, required this.aluno});

  final Aluno aluno;

  static Future<RegistroPagamentoResult?> show(
    BuildContext context, {
    required Aluno aluno,
  }) {
    return showModalBottomSheet<RegistroPagamentoResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingSm,
                AppTheme.spacingLg,
                AppTheme.spacingLg,
              ),
              child: RegistroPagamentoSheet(aluno: aluno),
            ),
          ),
        );
      },
    );
  }

  @override
  State<RegistroPagamentoSheet> createState() => _RegistroPagamentoSheetState();
}

class _RegistroPagamentoSheetState extends State<RegistroPagamentoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _valorController = TextEditingController(
    text: formatBrl(widget.aluno.pagamentoDoMes().valor),
  );
  late final _comprovanteController = TextEditingController();
  late final _obsController = TextEditingController();
  DateTime _pagoEm = DateTime.now();

  @override
  void dispose() {
    _valorController.dispose();
    _comprovanteController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registrar pagamento',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '${widget.aluno.nome} - ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(widget.aluno.mensalidade)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _pagoEm,
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime(DateTime.now().year + 1),
                );
                if (picked == null) return;
                setState(() {
                  _pagoEm = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    _pagoEm.hour,
                    _pagoEm.minute,
                  );
                });
              },
              icon: const Icon(Icons.event_outlined),
              label: Text('Data: ${DateFormat('dd/MM/yyyy').format(_pagoEm)}'),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              inputFormatters: const [BrlCurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Valor do mes',
                hintText: 'Ex: R\$ 200,00',
              ),
              validator: (v) {
                final valor = parseBrlCurrency((v ?? '').trim());
                if (valor == null || valor <= 0) return 'Valor invalido';
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _comprovanteController,
              decoration: const InputDecoration(
                labelText: 'Link do comprovante (opcional)',
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _obsController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Observacoes (opcional)',
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                final valor = parseBrlCurrency(_valorController.text.trim());
                if (valor == null || valor <= 0) return;
                Navigator.of(context).pop(
                  RegistroPagamentoResult(
                    pagoEm: _pagoEm,
                    valor: valor,
                    comprovanteUrl: _comprovanteController.text.trim().isEmpty
                        ? null
                        : _comprovanteController.text.trim(),
                    observacao: _obsController.text.trim().isEmpty
                        ? null
                        : _obsController.text.trim(),
                  ),
                );
              },
              child: const Text('Confirmar pagamento'),
            ),
          ],
        ),
      ),
    );
  }
}
