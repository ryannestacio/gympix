import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
import '../../providers/alunos_providers.dart';
import 'aluno_receipt_dialog.dart';
import 'aluno_id_card_dialog.dart';

class AlunoCard extends ConsumerStatefulWidget {
  const AlunoCard({
    super.key,
    required this.alunoId,
    required this.defaultMensalidade,
    required this.onSynced,
  });

  final String alunoId;
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

  Aluno get aluno {
    final a = ref.read(alunoProvider(widget.alunoId));
    if (a == null) {
      throw StateError('Aluno não disponível');
    }
    return a;
  }

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
      matricula: result.matricula,
      senha: result.senha,
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
    final aluno = ref.watch(alunoProvider(widget.alunoId));
    if (aluno == null) {
      return const SizedBox.shrink();
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (aluno.hasPendingWrites) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: 'Sincronização pendente',
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 16,
                              color: scheme.primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (aluno.matricula != null &&
                        aluno.matricula!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Matr\u00edcula: ${aluno.matricula}',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
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
                  if (v == 'carteirinha') _abrirCarteirinha();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'carteirinha',
                    child: Row(
                      children: [
                        Icon(Icons.badge_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Gerar carteirinha'),
                      ],
                    ),
                  ),
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
                            icon: const FaIcon(
                              FontAwesomeIcons.whatsapp,
                              size: 18,
                              color: Color(0xFF25D366),
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
                          icon: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            size: 18,
                            color: Color(0xFF25D366),
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

  String _calcularProximaMatricula(List<Aluno> alunos) {
    var maxMatriculaInt = 0;
    for (final a in alunos) {
      if (a.matricula != null && a.matricula!.trim().isNotEmpty) {
        final parsed = int.tryParse(a.matricula!.replaceAll(RegExp(r'\D'), ''));
        if (parsed != null && parsed > maxMatriculaInt) {
          maxMatriculaInt = parsed;
        }
      }
    }
    return (maxMatriculaInt + 1).toString().padLeft(4, '0');
  }

  Future<void> _onDuplicarCadastro() async {
    final alunos = ref.read(alunosHistoricoStreamProvider).value ?? const <Aluno>[];
    final seedMatricula = _calcularProximaMatricula(alunos);
    final matriculasExistentes = alunos
        .map((a) => a.matricula?.trim())
        .whereType<String>()
        .toList();

    final result = await AlunoFormSheet.show(
      context,
      title: 'Duplicar cadastro',
      initial: _draftFromAluno(),
      defaultMensalidade: widget.defaultMensalidade,
      seedMatricula: seedMatricula,
      matriculasExistentes: matriculasExistentes,
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
    await AlunoCobrarSheet.show(
      context: context,
      aluno: aluno,
      pixPayload: pixPayload,
      valorCobranca: valorCobranca,
      lembrete: lembrete,
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
    if (totalPendencias <= 0) return;

    final valorTotal = aluno.valorEmAbertoAte(
      referencia,
      referenciaStatus: referenciaStatus,
    );
    final competenciaLabel = totalPendencias == 1
        ? 'compet\u00eancia'
        : 'compet\u00eancias';
    final quitadaLabel = totalPendencias == 1
        ? 'quitada'
        : 'quitadas';
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
          '$totalPendencias $competenciaLabel $quitadaLabel com sucesso.',
      pendingMessage:
          'Quita\u00e7\u00e3o enviada. A sincroniza\u00e7\u00e3o pode levar alguns segundos.',
      cardMessage: '$totalPendencias $competenciaLabel $quitadaLabel',
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
    await _runGuarded(
      () async {
        await AlunoCobrarSheet.sharePixQr(
          aluno: aluno,
          pixPayload: pixPayload,
          valorCobranca: _formatCurrency(aluno.pagamentoDoMes().valor),
          message: mensagem,
        );
      },
      operationId: 'aluno:${aluno.id}:lembrete',
      successMessage: 'Lembrete compartilhado.',
      pendingMessage: 'Gerando recibo para compartilhamento...',
    );
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

  void _abrirCarteirinha() {
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (context) => AlunoIdCardDialog(alunoId: widget.alunoId),
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
}
