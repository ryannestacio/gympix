import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/phone_input_formatter.dart';
import '../models/aluno.dart';

class AlunoFormResult {
  const AlunoFormResult({
    required this.nome,
    required this.telefone,
    required this.observacao,
    required this.diaVencimento,
    required this.mensalidade,
    required this.pago,
  });

  final String nome;
  final String telefone;
  final String observacao;
  final int diaVencimento;
  final double mensalidade;
  final bool pago;
}

class AlunoFormSheet extends StatefulWidget {
  const AlunoFormSheet({
    super.key,
    required this.title,
    this.initial,
    this.defaultMensalidade,
    this.seedDiaVencimento,
    this.seedMensalidade,
  });

  final String title;
  final Aluno? initial;
  final double? defaultMensalidade;
  final int? seedDiaVencimento;
  final double? seedMensalidade;

  static Future<AlunoFormResult?> show(
    BuildContext context, {
    required String title,
    Aluno? initial,
    double? defaultMensalidade,
    int? seedDiaVencimento,
    double? seedMensalidade,
  }) {
    return showModalBottomSheet<AlunoFormResult>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
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
                AppTheme.spacingXs,
                AppTheme.spacingLg,
                AppTheme.spacingMd,
              ),
              child: AlunoFormSheet(
                title: title,
                initial: initial,
                defaultMensalidade: defaultMensalidade,
                seedDiaVencimento: seedDiaVencimento,
                seedMensalidade: seedMensalidade,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<AlunoFormSheet> createState() => _AlunoFormSheetState();
}

class _AlunoFormSheetState extends State<AlunoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.initial?.nome ?? '');
  late final _telefone = TextEditingController(text: widget.initial?.telefone ?? '');
  late final _observacao = TextEditingController(
    text: widget.initial?.observacao ?? '',
  );
  late final _dia = TextEditingController(
    text: (widget.initial?.diaVencimento ?? widget.seedDiaVencimento ?? 10)
        .toString(),
  );
  late final _mensalidade = TextEditingController(
    text: _mensalidadeInitialText(),
  );

  bool _pago = false;

  @override
  void initState() {
    super.initState();
    _pago = widget.initial?.pago ?? false;
  }

  String _mensalidadeInitialText() {
    final v = widget.initial?.mensalidade ??
        widget.seedMensalidade ??
        widget.defaultMensalidade;
    if (v == null) return '';
    return formatBrl(v);
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _observacao.dispose();
    _dia.dispose();
    _mensalidade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.initial == null
                  ? 'Preencha os dados e toque em adicionar.'
                  : 'Atualize os dados e salve as alterações.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nome,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) {
                final nome = _normalizeName(v ?? '');
                if (nome.isEmpty) return 'Informe o nome';
                if (nome.length < 3) return 'Nome muito curto';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: const [BrPhoneInputFormatter()],
              decoration: const InputDecoration(labelText: 'Telefone'),
              validator: (v) {
                final digits = _onlyDigits(v ?? '');
                if (digits.isEmpty) return 'Informe o telefone';
                if (digits.length < 10 || digits.length > 11) {
                  return 'Telefone invalido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacao,
              textInputAction: TextInputAction.next,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observacao',
                hintText: 'Plano, restricao, desconto ou forma de pagamento',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dia,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Dia de vencimento'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 1 || n > 28) {
                        return '1 a 28';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _mensalidade,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: const [BrlCurrencyInputFormatter()],
                    decoration: const InputDecoration(labelText: 'Mensalidade'),
                    validator: (v) {
                      final n = parseBrlCurrency((v ?? '').trim());
                      if (n == null || n <= 0) return 'Valor inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pago no mês atual'),
              value: _pago,
              onChanged: (v) => setState(() => _pago = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                final dia = int.parse(_dia.text.trim());
                final mensalidade = parseBrlCurrency(_mensalidade.text.trim());
                if (mensalidade == null || mensalidade <= 0) return;
                Navigator.of(context).pop(
                  AlunoFormResult(
                    nome: _normalizeName(_nome.text),
                    telefone: _telefone.text.trim(),
                    observacao: _normalizeObservation(_observacao.text),
                    diaVencimento: dia,
                    mensalidade: mensalidade,
                    pago: _pago,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(
                widget.initial == null
                    ? Icons.person_add_alt_1_rounded
                    : Icons.check_rounded,
              ),
              label: Text(widget.initial == null ? 'Adicionar aluno' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeName(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _normalizeObservation(String value) {
  return value.trim().replaceAll(RegExp(r'[ \t]+'), ' ');
}

String _onlyDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}
