import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../cobranca/models/cobranca_regua.dart';
import '../../cobranca/providers/cobranca_regua_providers.dart';
import '../providers/config_providers.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _pixController = TextEditingController();
  final _mensalidadeController = TextEditingController();
  final _customCobrancaController = TextEditingController();
  final _templatePendenteController = TextEditingController();
  final _templateAtrasadoController = TextEditingController();
  bool _savingPix = false;
  bool _savingMensalidade = false;
  bool _savingCustomCobranca = false;
  bool _savingRegua = false;
  bool _showPixValue = false;
  bool _editingPix = false;
  bool _showMensalidadeValue = false;
  bool _editingMensalidade = false;
  bool _reguaAutomacaoAtiva = CobrancaReguaConfig.defaults.automacaoAtiva;
  bool _reguaNotificacaoLocalAtiva =
      CobrancaReguaConfig.defaults.notificacaoLocalAtiva;
  bool _reguaNotificacaoPushAtiva =
      CobrancaReguaConfig.defaults.notificacaoPushAtiva;
  bool _stepDm3 = true;
  bool _stepD0 = true;
  bool _stepDp3 = true;
  StreamSubscription<String?>? _customCobrancaSubscription;
  StreamSubscription<CobrancaReguaConfig>? _reguaSubscription;

  @override
  void initState() {
    super.initState();
    _customCobrancaSubscription = ref
        .read(configRepositoryProvider)
        .watchCustomCobrancaMessage()
        .listen((message) {
          final nextValue = message ?? '';
          if (_customCobrancaController.text.trim() != nextValue) {
            _customCobrancaController.text = nextValue;
          }
        });
    _reguaSubscription = ref
        .read(cobrancaReguaRepositoryProvider)
        .watchReguaConfig()
        .listen(_applyReguaConfig);
  }

  @override
  void dispose() {
    _customCobrancaSubscription?.cancel();
    _reguaSubscription?.cancel();
    _pixController.dispose();
    _mensalidadeController.dispose();
    _customCobrancaController.dispose();
    _templatePendenteController.dispose();
    _templateAtrasadoController.dispose();
    super.dispose();
  }

  void _applyReguaConfig(CobrancaReguaConfig config) {
    if (!mounted || _savingRegua) return;
    final passos = {
      for (final passo in config.passos) passo.diasRelativos: passo.ativo,
    };
    setState(() {
      _reguaAutomacaoAtiva = config.automacaoAtiva;
      _reguaNotificacaoLocalAtiva = config.notificacaoLocalAtiva;
      _reguaNotificacaoPushAtiva = config.notificacaoPushAtiva;
      _stepDm3 = passos[-3] ?? true;
      _stepD0 = passos[0] ?? true;
      _stepDp3 = passos[3] ?? true;
      if (_templatePendenteController.text.trim() != config.templatePendente) {
        _templatePendenteController.text = config.templatePendente;
      }
      if (_templateAtrasadoController.text.trim() != config.templateAtrasado) {
        _templateAtrasadoController.text = config.templateAtrasado;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pixAsync = ref.watch(pixCodeStreamProvider);
    final defaultMensalidadeAsync = ref.watch(defaultMensalidadeStreamProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authAction = ref.watch(authControllerProvider);

    ref.listen(pixCodeStreamProvider, (_, next) {
      final pix = next.value;
      if (!_editingPix && pix != null && _pixController.text.trim() != pix) {
        _pixController.text = pix;
      }
    });

    ref.listen(defaultMensalidadeStreamProvider, (_, next) {
      final v = next.value;
      if (!_editingMensalidade && v != null) {
        final asText = formatBrl(v);
        if (_mensalidadeController.text.trim() != asText) {
          _mensalidadeController.text = asText;
        }
      }
    });

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao sair: ${next.error}')));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
            AppTheme.spacingXl,
          ),
          children: [
            Text(
              'Configurações',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Ajuste aparência, pagamentos e padrões do app.',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _SectionHeader(title: 'Aparência', icon: Icons.palette_outlined),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema visual',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha claro, escuro ou siga o sistema.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined, size: 18),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined, size: 18),
                        label: Text('Escuro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded, size: 18),
                        label: Text('Sistema'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (Set<ThemeMode> selected) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setThemeMode(selected.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _SectionHeader(title: 'Pagamentos', icon: Icons.payment_outlined),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chave Pix (copia e cola)',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Esta chave será usada nas mensagens de cobrança.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _SecureValueCard(
                    title: 'Chave Pix salva',
                    value: _maskPixValue(_pixController.text.trim()),
                    hasValue: _pixController.text.trim().isNotEmpty,
                    revealed: _showPixValue,
                    revealedValue: _pixController.text.trim(),
                    onToggleReveal: () {
                      setState(() => _showPixValue = !_showPixValue);
                    },
                    onEdit: () {
                      setState(() {
                        _editingPix = !_editingPix;
                        if (!_editingPix) {
                          _showPixValue = false;
                        }
                      });
                    },
                    editLabel: _editingPix ? 'Fechar edição' : 'Editar chave',
                  ),
                  if (_editingPix) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      controller: _pixController,
                      minLines: 5,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Cole a chave Pix aqui...',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: pixAsync.isLoading || _savingPix
                          ? null
                          : _onSalvarPix,
                      child: Text(
                        _savingPix ? 'Salvando...' : 'Salvar chave Pix',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd + 4),
            _SectionHeader(title: 'Valores', icon: Icons.attach_money_rounded),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensalidade padrão',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Valor sugerido ao cadastrar novo aluno.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _SecureValueCard(
                    title: 'Valor salvo',
                    value: _mensalidadeController.text.trim().isEmpty
                        ? '--'
                        : _maskedMoneyLabel(_mensalidadeController.text.trim()),
                    hasValue: _mensalidadeController.text.trim().isNotEmpty,
                    revealed: _showMensalidadeValue,
                    revealedValue: _mensalidadeController.text.trim(),
                    onToggleReveal: () {
                      setState(() {
                        _showMensalidadeValue = !_showMensalidadeValue;
                      });
                    },
                    onEdit: () {
                      setState(() {
                        _editingMensalidade = !_editingMensalidade;
                        if (!_editingMensalidade) {
                          _showMensalidadeValue = false;
                        }
                      });
                    },
                    editLabel: _editingMensalidade
                        ? 'Fechar edição'
                        : 'Editar valor',
                  ),
                  if (_editingMensalidade) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      controller: _mensalidadeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [BrlCurrencyInputFormatter()],
                      decoration: const InputDecoration(
                        hintText: 'Ex: R\$ 80,00',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          defaultMensalidadeAsync.isLoading ||
                              _savingMensalidade
                          ? null
                          : _onSalvarMensalidade,
                      child: Text(
                        _savingMensalidade
                            ? 'Salvando...'
                            : 'Salvar mensalidade padrão',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd + 4),
            _SectionHeader(title: 'Mensagens', icon: Icons.message_outlined),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frase personalizada de cobrança',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Esse texto será incluído nas mensagens de cobrança, depois do resumo da mensalidade.',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _customCobrancaController,
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText:
                          'Ex: Em caso de dúvida, entre em contato para regularização.',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _savingCustomCobranca
                          ? null
                          : _onSalvarMensagemCobranca,
                      child: Text(
                        _savingCustomCobranca
                            ? 'Salvando...'
                            : 'Salvar frase personalizada',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd + 4),
            _SectionHeader(
              title: 'Regua de cobranca',
              icon: Icons.schedule_send_outlined,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _reguaAutomacaoAtiva,
                    onChanged: (v) => setState(() => _reguaAutomacaoAtiva = v),
                    title: const Text('Automacao ativa'),
                    subtitle: const Text(
                      'Dispara lembretes automaticamente por D-3, D0 e D+3.',
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _reguaNotificacaoLocalAtiva,
                    onChanged: (v) {
                      setState(() => _reguaNotificacaoLocalAtiva = v);
                    },
                    title: const Text('Notificacao local'),
                    subtitle: const Text(
                      'Gera alerta local no aparelho quando a regra dispara.',
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _reguaNotificacaoPushAtiva,
                    onChanged: (v) =>
                        setState(() => _reguaNotificacaoPushAtiva = v),
                    title: const Text('Fila para push'),
                    subtitle: const Text(
                      'Registra o disparo para processamento externo de push.',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Passos ativos',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('D-3'),
                        selected: _stepDm3,
                        onSelected: (v) => setState(() => _stepDm3 = v),
                      ),
                      FilterChip(
                        label: const Text('D0'),
                        selected: _stepD0,
                        onSelected: (v) => setState(() => _stepD0 = v),
                      ),
                      FilterChip(
                        label: const Text('D+3'),
                        selected: _stepDp3,
                        onSelected: (v) => setState(() => _stepDp3 = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _templatePendenteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Template pendente',
                      hintText:
                          'Use {nome}, {competencia}, {valor}, {vencimento}, {dias_label}, {pix}, {link}',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _templateAtrasadoController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Template atrasado',
                      hintText:
                          'Use {nome}, {competencia}, {valor}, {vencimento}, {dias_label}, {pix}, {link}',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _savingRegua ? null : _onSalvarRegua,
                      child: Text(
                        _savingRegua ? 'Salvando...' : 'Salvar regua',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            _SectionHeader(title: 'Sistema', icon: Icons.info_outline_rounded),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Versão do app',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '1.0.0',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: authAction.isLoading
                          ? null
                          : () => ref
                                .read(authControllerProvider.notifier)
                                .signOut(),
                      icon: authAction.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.logout_rounded, size: 18),
                      label: Text(authAction.isLoading ? 'Saindo...' : 'Sair'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSalvarPix() async {
    final pix = _pixController.text.trim();
    if (pix.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um código Pix válido.')),
      );
      return;
    }

    setState(() => _savingPix = true);
    final pendingTimer = _schedulePendingSyncFeedback(
      'Chave Pix salva localmente. A sincronizacao pode levar alguns segundos.',
    );
    try {
      await ref.read(configRepositoryProvider).setPixCode(pix);
      if (!mounted) return;
      setState(() {
        _editingPix = false;
        _showPixValue = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chave Pix salva.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar Pix: $e')));
    } finally {
      pendingTimer.cancel();
      if (mounted) setState(() => _savingPix = false);
    }
  }

  Future<void> _onSalvarMensalidade() async {
    final value = parseBrlCurrency(_mensalidadeController.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor de mensalidade inválido.')),
      );
      return;
    }

    setState(() => _savingMensalidade = true);
    final pendingTimer = _schedulePendingSyncFeedback(
      'Mensalidade salva localmente. A sincronizacao pode levar alguns segundos.',
    );
    try {
      await ref.read(configRepositoryProvider).setDefaultMensalidade(value);
      if (!mounted) return;
      setState(() {
        _editingMensalidade = false;
        _showMensalidadeValue = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensalidade padrão salva.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar mensalidade: $e')));
    } finally {
      pendingTimer.cancel();
      if (mounted) setState(() => _savingMensalidade = false);
    }
  }

  Future<void> _onSalvarMensagemCobranca() async {
    final value = _customCobrancaController.text.trim();

    setState(() => _savingCustomCobranca = true);
    final pendingTimer = _schedulePendingSyncFeedback(
      'Frase salva localmente. A sincronizacao pode levar alguns segundos.',
    );
    try {
      await ref.read(configRepositoryProvider).setCustomCobrancaMessage(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Frase personalizada salva.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar frase: $e')));
    } finally {
      pendingTimer.cancel();
      if (mounted) setState(() => _savingCustomCobranca = false);
    }
  }

  Future<void> _onSalvarRegua() async {
    if (!_stepDm3 && !_stepD0 && !_stepDp3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ative pelo menos um passo da regua (D-3, D0 ou D+3).'),
        ),
      );
      return;
    }

    setState(() => _savingRegua = true);
    final pendingTimer = _schedulePendingSyncFeedback(
      'Regua salva localmente. A sincronizacao pode levar alguns segundos.',
    );
    try {
      final atual = await ref
          .read(cobrancaReguaRepositoryProvider)
          .getReguaConfig();
      final novaRegua = atual.copyWith(
        automacaoAtiva: _reguaAutomacaoAtiva,
        notificacaoLocalAtiva: _reguaNotificacaoLocalAtiva,
        notificacaoPushAtiva: _reguaNotificacaoPushAtiva,
        passos: [
          CobrancaReguaStep(diasRelativos: -3, ativo: _stepDm3),
          CobrancaReguaStep(diasRelativos: 0, ativo: _stepD0),
          CobrancaReguaStep(diasRelativos: 3, ativo: _stepDp3),
        ],
        templatePendente: _templatePendenteController.text.trim(),
        templateAtrasado: _templateAtrasadoController.text.trim(),
      );
      await ref.read(cobrancaReguaRepositoryProvider).setReguaConfig(novaRegua);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Regua de cobranca salva com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar regua: $e')));
    } finally {
      pendingTimer.cancel();
      if (mounted) setState(() => _savingRegua = false);
    }
  }

  Timer _schedulePendingSyncFeedback(String message) {
    return Timer(const Duration(seconds: 6), () {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  String _maskPixValue(String value) {
    if (value.isEmpty) return 'Nenhuma chave Pix configurada';
    if (value.length <= 12) return '••••••••';
    final start = value.substring(0, 8);
    final end = value.substring(value.length - 6);
    return '$start••••••••••••$end';
  }

  String _maskedMoneyLabel(String value) {
    if (value.isEmpty) return '--';
    return '••••••';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: AppTheme.spacingXs),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}

class _SecureValueCard extends StatelessWidget {
  const _SecureValueCard({
    required this.title,
    required this.value,
    required this.hasValue,
    required this.revealed,
    required this.revealedValue,
    required this.onToggleReveal,
    required this.onEdit,
    required this.editLabel,
  });

  final String title;
  final String value;
  final bool hasValue;
  final bool revealed;
  final String revealedValue;
  final VoidCallback onToggleReveal;
  final VoidCallback onEdit;
  final String editLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (hasValue)
                IconButton(
                  tooltip: revealed ? 'Ocultar' : 'Mostrar',
                  onPressed: onToggleReveal,
                  icon: Icon(
                    revealed
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
            ],
          ),
          Text(
            hasValue ? (revealed ? revealedValue : value) : value,
            style: textTheme.bodyMedium?.copyWith(
              color: hasValue ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(editLabel),
            ),
          ),
        ],
      ),
    );
  }
}
