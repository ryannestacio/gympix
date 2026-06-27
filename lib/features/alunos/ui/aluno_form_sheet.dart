import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/first_letter_uppercase_formatter.dart';
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
    this.matricula,
    this.senha,
  });

  final String nome;
  final String telefone;
  final String observacao;
  final int diaVencimento;
  final double mensalidade;
  final bool pago;
  final String? matricula;
  final String? senha;
}

class AlunoFormSheet extends StatefulWidget {
  const AlunoFormSheet({
    super.key,
    required this.title,
    this.initial,
    this.defaultMensalidade,
    this.seedDiaVencimento,
    this.seedMensalidade,
    this.seedMatricula,
    this.matriculasExistentes = const [],
  });

  final String title;
  final Aluno? initial;
  final double? defaultMensalidade;
  final int? seedDiaVencimento;
  final double? seedMensalidade;
  final String? seedMatricula;
  final List<String> matriculasExistentes;

  static Future<AlunoFormResult?> show(
    BuildContext context, {
    required String title,
    Aluno? initial,
    double? defaultMensalidade,
    int? seedDiaVencimento,
    double? seedMensalidade,
    String? seedMatricula,
    List<String> matriculasExistentes = const [],
  }) {
    return showModalBottomSheet<AlunoFormResult>(
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
                seedMatricula: seedMatricula,
                matriculasExistentes: matriculasExistentes,
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
  late final _telefone = TextEditingController(
    text: widget.initial?.telefone ?? '',
  );
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
  late final _matricula = TextEditingController(
    text: widget.initial?.matricula ?? widget.seedMatricula ?? '',
  );
  late final _senha = TextEditingController(
    text: widget.initial?.senha ?? '',
  );

  bool _pago = false;

  @override
  void initState() {
    super.initState();
    _pago = widget.initial?.pago ?? false;
  }

  String _mensalidadeInitialText() {
    final v =
        widget.initial?.mensalidade ??
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
    _matricula.dispose();
    _senha.dispose();
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
              controller: _matricula,
              enabled: widget.initial == null || widget.initial!.id.isEmpty,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Matr\u00edcula',
                hintText: 'Ex: 0001',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe a matr\u00edcula';
                final clean = v.trim();
                final isNew = widget.initial == null || widget.initial!.id.isEmpty;
                if (isNew && widget.matriculasExistentes.contains(clean)) {
                  return 'Matr\u00edcula j\u00e1 est\u00e1 em uso';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nome,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              inputFormatters: const [FirstLetterUppercaseFormatter()],
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
                  return 'Telefone inv\u00e1lido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _senha,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Senha do Aluno (Portal)',
                hintText: 'Deixe vazio para usar a matrícula',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _observacao,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: const [FirstLetterUppercaseFormatter()],
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observa\u00e7\u00e3o',
                hintText:
                    'Plano, restri\u00e7\u00e3o, desconto ou forma de pagamento',
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
                    decoration: const InputDecoration(
                      labelText: 'Dia de vencimento',
                    ),
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
                final matriculaVal = _matricula.text.trim().isEmpty ? null : _matricula.text.trim();
                final senhaVal = _senha.text.trim().isEmpty ? matriculaVal : _senha.text.trim();

                Navigator.of(context).pop(
                  AlunoFormResult(
                    nome: _normalizeName(_nome.text),
                    telefone: _telefone.text.trim(),
                    observacao: _normalizeObservation(_observacao.text),
                    diaVencimento: dia,
                    mensalidade: mensalidade,
                    pago: _pago,
                    matricula: matriculaVal,
                    senha: senhaVal,
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
              label: Text(
                widget.initial == null ? 'Adicionar aluno' : 'Salvar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _normalizeName(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  return forceFirstLetterUppercase(normalized);
}

String _normalizeObservation(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[ \t]+'), ' ');
  return forceFirstLetterUppercase(normalized);
}

String _onlyDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}
