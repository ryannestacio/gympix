import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/inadimplencia_config.dart';
import '../../../../core/domain/inadimplencia_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/utils/firestore_error_formatter.dart';
import '../../../configuracoes/providers/config_providers.dart';
import '../../controllers/alunos_actions_controller.dart';
import '../../models/aluno.dart';
import '../../services/telefone_whatsapp_service.dart';
import '../../usecases/aluno_cadastro_input.dart';
import '../aluno_form_sheet.dart';
import 'aluno_history_sheet.dart';

class AlunoCard extends ConsumerStatefulWidget {
  const AlunoCard({
    super.key,
    required this.aluno,
    required this.defaultMensalidade,
    required this.onSynced,
  });

  final Aluno aluno;
  final double? defaultMensalidade;
  final VoidCallback onSynced;

  @override
  ConsumerState<AlunoCard> createState() => _AlunoCardState();
}

class _AlunoCardState extends ConsumerState<AlunoCard> {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  bool _busy = false;
  final Set<String> _runningOperations = <String>{};
  String? _feedbackLabel;
  Color? _feedbackColor;
  Timer? _feedbackTimer;

  Aluno get aluno => widget.aluno;

  Aluno _draftFromAluno() {
    return Aluno(
      id: '',
      nome: '',
      telefone: '',
      observacao: aluno.observacao,
      diaVencimento: aluno.diaVencimento,
      mensalidade: aluno.mensalidade,
      criadoEm: DateTime.now(),
      pagamentos: const {},
      pagoLegado: false,
    );
  }

  AlunoCadastroInput _toCadastroInput(AlunoFormResult result) {
    return AlunoCadastroInput(
      nome: result.nome,
      telefone: result.telefone,
      observacao: result.observacao,
      diaVencimento: result.diaVencimento,
      mensalidade: result.mensalidade,
      pago: result.pago,
    );
  }

  static String _formatCurrency(double value) {
    return _currencyFormatter.format(value);
  }

  static Color _inadimplenciaColor(
    InadimplenciaStatus status,
    BuildContext context,
  ) {
    final ext = AppThemeExtensions.of(context);
    return switch (status) {
      InadimplenciaStatus.emDia => ext.success,
      InadimplenciaStatus.aVencer => ext.info,
      InadimplenciaStatus.venceHoje => ext.warning,
      InadimplenciaStatus.emAtraso => ext.warning,
      InadimplenciaStatus.inadimplente => Theme.of(context).colorScheme.error,
    };
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final configAsync = ref.watch(inadimplenciaConfigStreamProvider);
    final config = configAsync.value ?? InadimplenciaConfig.defaults;
    final resultado = aluno.inadimplencia(config: config);
    final mensalidadeLabel = _formatCurrency(
      resultado.pagamentoEncontrado?.valor ?? aluno.mensalidade,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final referencia = DateTime.now();
    final referenciaStatus = Aluno.referenciaStatusDaCompetencia(referencia);
    final competenciaAtual = Aluno.competenciaAtual(referencia);
    final pagamentoAtual = aluno.pagamentoDaCompetencia(
      competenciaAtual,
      referenciaStatus: referenciaStatus,
    );
    final competenciasEmAberto = aluno.totalCompetenciasEmAbertoAte(
      referencia,
      referenciaStatus: referenciaStatus,
    );
    final valorEmAberto = aluno.valorEmAbertoAte(
      referencia,
      referenciaStatus: referenciaStatus,
    );
    final possuiDebitoRetroativo =
        pagamentoAtual.pago && competenciasEmAberto > 0;
    final pendenciasLabel = competenciasEmAberto == 1
        ? 'pendência'
        : 'pendências';
    final statusColor = possuiDebitoRetroativo
        ? scheme.error
        : _inadimplenciaColor(resultado.status, context);
    final statusLabelText = possuiDebitoRetroativo
        ? (competenciasEmAberto == 1
              ? 'Débito retroativo'
              : 'Débitos retroativos')
        : resultado.status.detailedLabel(
            diasRestantes: resultado.diasRestantes,
            diasAtraso: resultado.diasAtraso,
          );
    final mostrarQuitarPendencias =
        possuiDebitoRetroativo || competenciasEmAberto > 1;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg - 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  aluno.nome,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                enabled: !_busy,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                onSelected: (v) async {
                  if (v == 'duplicar') await _onDuplicarCadastro();
                  if (v == 'copiar_cobranca') await _onCopiarCobranca();
                  if (v == 'inativar') await _onInativar();
                  if (v == 'ativar') await _onAtivar();
                  if (v == 'historico') _abrirHistorico();
                  if (v == 'lembrete') await _enviarLembrete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicar',
                    child: Row(
                      children: [
                        Icon(Icons.content_copy_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Duplicar cadastro'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'copiar_cobranca',
                    child: Row(
                      children: [
                        Icon(Icons.copy_all_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Copiar cobran\u00e7a'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'historico',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Hist\u00f3rico mensal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'lembrete',
                    child: Row(
                      children: [
                        Icon(Icons.message_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Enviar lembrete'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: aluno.ativo ? 'inativar' : 'ativar',
                    child: Row(
                      children: [
                        Icon(
                          aluno.ativo
                              ? Icons.archive_outlined
                              : Icons.unarchive_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(aluno.ativo ? 'Inativar' : 'Ativar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            'Vencimento: dia ${aluno.diaVencimento}',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Mensalidade: $mensalidadeLabel',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (aluno.observacao.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              aluno.observacao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              statusLabelText.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (!aluno.ativo) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'INATIVO',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _feedbackLabel == null
                ? const SizedBox.shrink()
                : Padding(
                    key: ValueKey(_feedbackLabel),
                    padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (_feedbackColor ?? scheme.primary).withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: _feedbackColor ?? scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _feedbackLabel!,
                              style: textTheme.bodySmall?.copyWith(
                                color: _feedbackColor ?? scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              if (compact) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _onCobrar,
                            icon: const Icon(
                              Icons.qr_code_2_outlined,
                              size: 18,
                            ),
                            label: const Text('Cobrar'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                _busy ||
                                    !temTelefoneWhatsAppValido(aluno.telefone)
                                ? null
                                : _onWhatsApp,
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _onEditar,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Editar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _busy ? null : _onTogglePago,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(aluno.pago ? 'Desfazer' : 'Marcar pago'),
                      ),
                    ),
                    if (mostrarQuitarPendencias) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : _onQuitarPendenciasAcumuladas,
                          icon: const Icon(Icons.done_all_rounded, size: 18),
                          label: Text(
                            'Quitar ${_formatCurrency(valorEmAberto)}',
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _onCobrar,
                          icon: const Icon(Icons.qr_code_2_outlined, size: 18),
                          label: const Text('Cobrar'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _busy ||
                                  !temTelefoneWhatsAppValido(aluno.telefone)
                              ? null
                              : _onWhatsApp,
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _onEditar,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _busy ? null : _onTogglePago,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(aluno.pago ? 'Desfazer' : 'Marcar pago'),
                        ),
                      ),
                    ],
                  ),
                  if (mostrarQuitarPendencias) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _onQuitarPendenciasAcumuladas,
                        icon: const Icon(Icons.done_all_rounded, size: 18),
                        label: Text(
                          'Quitar $competenciasEmAberto $pendenciasLabel (${_formatCurrency(valorEmAberto)})',
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _runGuarded(
    Future<void> Function() action, {
    required String operationId,
    required String successMessage,
    required String pendingMessage,
    String? cardMessage,
  }) async {
    if (_busy || _runningOperations.contains(operationId)) return;

    setState(() {
      _runningOperations.add(operationId);
      _busy = true;
    });
    Timer? pendingTimer;
    var showedPendingFeedback = false;

    pendingTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted || !_runningOperations.contains(operationId)) return;
      showedPendingFeedback = true;
      _showCardFeedback(
        'Sincronizando altera\u00e7\u00e3o...',
        color: Theme.of(context).colorScheme.primary,
        markSynced: false,
        autoHideAfter: null,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pendingMessage)));
    });

    try {
      await action();
      if (!mounted) return;
      _showCardFeedback(
        cardMessage ?? successMessage,
        color: AppThemeExtensions.of(context).success,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      if (showedPendingFeedback) {
        _clearCardFeedback();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
    } finally {
      pendingTimer.cancel();
      if (mounted) {
        setState(() {
          _runningOperations.remove(operationId);
          _busy = _runningOperations.isNotEmpty;
        });
      }
    }
  }

  void _showCardFeedback(
    String message, {
    required Color color,
    bool markSynced = true,
    Duration? autoHideAfter = const Duration(seconds: 2),
  }) {
    _feedbackTimer?.cancel();
    if (markSynced) {
      widget.onSynced();
    }
    setState(() {
      _feedbackLabel = message;
      _feedbackColor = color;
    });
    if (autoHideAfter != null) {
      _feedbackTimer = Timer(autoHideAfter, () {
        if (!mounted) return;
        setState(() {
          _feedbackLabel = null;
          _feedbackColor = null;
        });
      });
    }
  }

  void _clearCardFeedback() {
    _feedbackTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _feedbackLabel = null;
      _feedbackColor = null;
    });
  }

  Future<void> _onEditar() async {
    final result = await AlunoFormSheet.show(
      context,
      title: 'Editar aluno',
      initial: aluno,
      defaultMensalidade: widget.defaultMensalidade,
    );
    if (result == null) return;

    await _runGuarded(
      () async {
        await ref
            .read(alunosActionsControllerProvider)
            .atualizarAluno(
              original: aluno,
              input: _toCadastroInput(result),
              operationId: 'aluno:${aluno.id}:atualizar',
            );
      },
      operationId: 'aluno:${aluno.id}:atualizar',
      successMessage: 'Aluno atualizado.',
      pendingMessage:
          'Aluno atualizado localmente. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
      cardMessage: 'Aluno atualizado',
    );
  }

  Future<void> _onDuplicarCadastro() async {
    final result = await AlunoFormSheet.show(
      context,
      title: 'Duplicar cadastro',
      initial: _draftFromAluno(),
      defaultMensalidade: widget.defaultMensalidade,
    );
    if (result == null) return;

    await _runGuarded(
      () async {
        await ref
            .read(alunosActionsControllerProvider)
            .criarAluno(
              _toCadastroInput(result),
              operationId: 'aluno:${aluno.id}:duplicar',
            );
      },
      operationId: 'aluno:${aluno.id}:duplicar',
      successMessage: 'Cadastro duplicado.',
      pendingMessage:
          'Cadastro criado localmente. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
      cardMessage: 'Cadastro duplicado',
    );
  }

  Future<void> _onCobrar() async {
    final pixPayload = await _buildPixPayloadOrShowError(
      emptyMessage:
          'Configure o Pix em Configura\u00e7\u00f5es antes de cobrar.',
      unavailableMessage:
          'N\u00e3o foi poss\u00edvel carregar o Pix agora. Tente novamente em alguns segundos.',
    );
    if (pixPayload == null) return;

    final valorCobranca = _formatCurrency(aluno.pagamentoDoMes().valor);
    final lembrete = await _buildMensagemCobranca(pixPayload);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              12,
              AppTheme.spacingLg,
              0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cobrar com Pix',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                        ),
                        child: QrImageView(
                          data: pixPayload,
                          size: 208,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        aluno.nome,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        valorCobranca,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pix c\u00f3pia e cola',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  pixPayload,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _copyPixPayload(
                          pixPayload,
                          successMessage: 'C\u00f3digo Pix copiado.',
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => _sharePixQrPng(
                          pixPayload: pixPayload,
                          message:
                              'QR Code Pix - ${aluno.nome} - $valorCobranca',
                        ),
                        child: const Text('Compartilhar QR'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _sharePixQrPng(pixPayload: pixPayload, message: lembrete),
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Enviar mensagem pronta'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: lembrete));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cobran\u00e7a copiada.')),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Copiar cobran\u00e7a'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCopiarCobranca() async {
    final pixPayload = await _buildPixPayloadOrShowError(
      emptyMessage:
          'Configure o Pix em Configura\u00e7\u00f5es antes de copiar a cobran\u00e7a.',
      unavailableMessage:
          'N\u00e3o foi poss\u00edvel carregar o Pix agora. Tente novamente em alguns segundos.',
    );
    if (pixPayload == null) return;

    final mensagem = await _buildMensagemCobranca(pixPayload);
    await Clipboard.setData(ClipboardData(text: mensagem));
    if (!mounted) return;
    _showCardFeedback(
      'Cobran\u00e7a copiada',
      color: Theme.of(context).colorScheme.primary,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mensagem de cobran\u00e7a copiada.')),
    );
  }

  Future<void> _onTogglePago() async {
    if (aluno.pago) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desfazer pagamento'),
          content: const Text(
            'Deseja marcar o m\u00eas atual como n\u00e3o pago?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Desfazer'),
            ),
          ],
        ),
      );
      if (ok != true) return;

      await _runGuarded(
        () async {
          await ref
              .read(alunosActionsControllerProvider)
              .desfazerPagamento(
                aluno,
                operationId:
                    'aluno:${aluno.id}:pagamento:desfazer:${Aluno.competenciaAtual()}',
              );
        },
        operationId:
            'aluno:${aluno.id}:pagamento:desfazer:${Aluno.competenciaAtual()}',
        successMessage: 'Pagamento desfeito para o m\u00eas atual.',
        pendingMessage:
            'Pagamento desfeito localmente. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
        cardMessage: 'Pagamento desfeito',
      );
      return;
    }

    final registro = await RegistroPagamentoSheet.show(context, aluno: aluno);
    if (registro == null) return;

    await _runGuarded(
      () async {
        await ref
            .read(alunosActionsControllerProvider)
            .registrarPagamento(
              aluno: aluno,
              valor: registro.valor,
              pagoEm: registro.pagoEm,
              comprovanteUrl: registro.comprovanteUrl,
              observacao: registro.observacao,
              operationId:
                  'aluno:${aluno.id}:pagamento:registrar:${Aluno.competenciaAtual()}',
            );
      },
      operationId:
          'aluno:${aluno.id}:pagamento:registrar:${Aluno.competenciaAtual()}',
      successMessage: 'Pagamento registrado.',
      pendingMessage:
          'Pagamento registrado localmente. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
      cardMessage: 'Pagamento registrado',
    );
  }

  Future<void> _onQuitarPendenciasAcumuladas() async {
    final referencia = DateTime.now();
    final referenciaStatus = Aluno.referenciaStatusDaCompetencia(referencia);
    final totalPendencias = aluno.totalCompetenciasEmAbertoAte(
      referencia,
      referenciaStatus: referenciaStatus,
    );
    if (totalPendencias <= 1) return;

    final valorTotal = aluno.valorEmAbertoAte(
      referencia,
      referenciaStatus: referenciaStatus,
    );
    final competenciaLabel = totalPendencias == 1
        ? 'compet\u00eancia'
        : 'compet\u00eancias';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar pend\u00eancias acumuladas'),
        content: Text(
          'Quitar $totalPendencias $competenciaLabel em aberto de ${aluno.nome} (${_formatCurrency(valorTotal)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final operationId =
        'aluno:${aluno.id}:pagamento:quitar-acumulado:${Aluno.competenciaAtual(referencia)}';
    await _runGuarded(
      () async {
        await ref
            .read(alunosActionsControllerProvider)
            .quitarPendenciasAcumuladas(aluno, operationId: operationId);
      },
      operationId: operationId,
      successMessage:
          '$totalPendencias $competenciaLabel quitadas com sucesso.',
      pendingMessage:
          'Quita\u00e7\u00e3o enviada. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
      cardMessage: '$totalPendencias $competenciaLabel quitadas',
    );
  }

  Future<void> _onInativar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inativar aluno'),
        content: Text(
          'Inativar ${aluno.nome}? O hist\u00f3rico financeiro ser\u00e1 preservado, mas ele sair\u00e1 da lista principal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Inativar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _runGuarded(
      () async {
        await ref
            .read(alunosActionsControllerProvider)
            .inativarAluno(aluno.id, operationId: 'aluno:${aluno.id}:inativar');
      },
      operationId: 'aluno:${aluno.id}:inativar',
      successMessage: 'Aluno inativado.',
      pendingMessage:
          'Aluno inativado localmente. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
      cardMessage: 'Aluno inativado',
    );
  }

  Future<void> _onAtivar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ativar aluno'),
        content: Text(
          'Ativar ${aluno.nome}? Ele voltar\u00e1 a aparecer na lista principal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _runGuarded(
      () async {
        await ref
            .read(alunosActionsControllerProvider)
            .ativarAluno(aluno.id, operationId: 'aluno:${aluno.id}:ativar');
      },
      operationId: 'aluno:${aluno.id}:ativar',
      successMessage: 'Aluno ativado.',
      pendingMessage:
          'Aluno ativado localmente. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
      cardMessage: 'Aluno ativado',
    );
  }

  Future<void> _enviarLembrete() async {
    final pixPayload = await _buildPixPayloadOrShowError(
      emptyMessage: 'Configure o Pix antes de enviar lembrete.',
      unavailableMessage:
          'N\u00e3o foi poss\u00edvel carregar o Pix agora. Tente novamente em alguns segundos.',
    );
    if (pixPayload == null) return;

    final mensagem = await _buildMensagemCobranca(pixPayload);
    await _sharePixQrPng(pixPayload: pixPayload, message: mensagem);
  }

  Future<void> _onWhatsApp() async {
    final uri = montarUriWhatsApp(aluno.telefone);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre um telefone v\u00e1lido para usar o WhatsApp.',
          ),
        ),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        await SharePlus.instance.share(ShareParams(text: uri.toString()));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'N\u00e3o foi poss\u00edvel abrir o WhatsApp. Link compartilhado como alternativa.',
            ),
          ),
        );
      }
    } on PlatformException {
      await SharePlus.instance.share(ShareParams(text: uri.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp indispon\u00edvel no momento. Link compartilhado como alternativa.',
          ),
        ),
      );
    }
  }

  void _abrirHistorico() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => HistoricoAlunoSheet(aluno: aluno),
    );
  }

  Future<String?> _buildPixPayloadOrShowError({
    required String emptyMessage,
    required String unavailableMessage,
  }) async {
    try {
      final payload = await ref
          .read(alunosActionsControllerProvider)
          .gerarPixPayload(aluno);
      if ((payload ?? '').trim().isEmpty) {
        if (!mounted) return null;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(emptyMessage)));
        return null;
      }
      return payload;
    } catch (_) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(unavailableMessage)));
      return null;
    }
  }

  Future<String> _buildMensagemCobranca(String pixPayload) {
    return ref
        .read(alunosActionsControllerProvider)
        .montarMensagemCobranca(aluno: aluno, pixPayload: pixPayload);
  }

  Future<void> _copyPixPayload(
    String payload, {
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  Future<Uint8List?> _buildPixQrPngBytes(String pixPayload) async {
    final valorCobranca = _formatCurrency(aluno.pagamentoDoMes().valor);
    final painter = QrPainter(
      data: pixPayload,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
    );
    final imageData = await painter.toImageData(
      920,
      format: ui.ImageByteFormat.png,
    );
    if (imageData == null) return null;

    final codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    final qrImage = frame.image;

    const canvasWidth = 1280.0;
    const canvasHeight = 1580.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      Paint()..color = Colors.white,
    );

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(64, 64, 1152, 1452),
      const Radius.circular(40),
    );
    canvas.drawRRect(cardRect, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final qrContainer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(150, 140, 980, 980),
      const Radius.circular(28),
    );
    canvas.drawRRect(qrContainer, Paint()..color = Colors.white);
    canvas.drawRRect(
      qrContainer,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    const qrRect = Rect.fromLTWH(180, 170, 920, 920);
    canvas.drawImageRect(
      qrImage,
      Rect.fromLTWH(0, 0, qrImage.width.toDouble(), qrImage.height.toDouble()),
      qrRect,
      Paint(),
    );

    _paintCenteredText(
      canvas,
      text: aluno.nome,
      top: 1150,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 52,
        fontWeight: FontWeight.w700,
      ),
    );

    _paintCenteredText(
      canvas,
      text: valorCobranca,
      top: 1220,
      style: const TextStyle(
        color: Color(0xFF2563EB),
        fontSize: 62,
        fontWeight: FontWeight.w800,
      ),
    );

    canvas.drawLine(
      const Offset(180, 1328),
      const Offset(1100, 1328),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 3,
    );

    _paintCenteredText(
      canvas,
      text: AppConstants.appName,
      top: 1370,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 54,
        fontWeight: FontWeight.w800,
      ),
    );

    _paintCenteredText(
      canvas,
      text: 'QR Code Pix para pagamento',
      top: 1444,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 34,
        fontWeight: FontWeight.w500,
      ),
    );

    final picture = recorder.endRecording();
    final composedImage = await picture.toImage(
      canvasWidth.toInt(),
      canvasHeight.toInt(),
    );
    final composedData = await composedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return composedData?.buffer.asUint8List();
  }

  void _paintCenteredText(
    Canvas canvas, {
    required String text,
    required double top,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 980);

    painter.paint(canvas, Offset((1280 - painter.width) / 2, top));
  }

  Future<void> _sharePixQrPng({
    required String pixPayload,
    required String message,
  }) async {
    try {
      final pngBytes = await _buildPixQrPngBytes(pixPayload);
      if (pngBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'N\u00e3o foi poss\u00edvel gerar a imagem do QR Code.',
            ),
          ),
        );
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name: 'gympix-cobranca-${aluno.nome}.png',
            ),
          ],
          text: message,
          subject: 'Cobran\u00e7a Pix - ${aluno.nome}',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'N\u00e3o foi poss\u00edvel compartilhar o QR Code Pix.',
          ),
        ),
      );
    }
  }
}
