import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/currency_input_formatter.dart';
import '../../../core/utils/firestore_error_formatter.dart';
import '../../../core/utils/firestore_sync_status.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/ui/sign_out_confirmation_dialog.dart';
import '../providers/config_providers.dart';

class ConfigPage extends ConsumerStatefulWidget {
  const ConfigPage({super.key});

  @override
  ConsumerState<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends ConsumerState<ConfigPage> {
  final _pixController = TextEditingController();
  final _mensalidadeController = TextEditingController();

  @override
  void dispose() {
    _pixController.dispose();
    _mensalidadeController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSignOut() async {
    final shouldSignOut = await showSignOutConfirmationDialog(context);
    if (!mounted || !shouldSignOut) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pixAsync = ref.watch(pixCodeStreamProvider);
    final mensalidadeAsync = ref.watch(defaultMensalidadeStreamProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authAction = ref.watch(authControllerProvider);

    final pixValue = _pixController.text.trim();
    final mensalidadeValue = _mensalidadeController.text.trim();

    ref.listen(pixCodeStreamProvider, (_, next) {
      final pix = next.value;
      if (pix != null && _pixController.text.trim() != pix) {
        _pixController.text = pix;
      }
    });

    ref.listen(defaultMensalidadeStreamProvider, (_, next) {
      final value = next.value;
      if (value != null) {
        final asText = formatBrl(value);
        if (_mensalidadeController.text.trim() != asText) {
          _mensalidadeController.text = asText;
        }
      }
    });

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError) {
        final error = next.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error == null
                  ? 'Nao foi possivel sair da conta. Tente novamente.'
                  : formatFirestoreError(error),
            ),
          ),
        );
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
            const _SettingsHeroCard(title: 'Configura\u00e7\u00f5es'),
            const SizedBox(height: AppTheme.spacingLg),
            const _SectionHeader(
              title: 'Apar\u00eancia',
              subtitle: 'Personaliza\u00e7\u00e3o de tema',
              icon: Icons.palette_outlined,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              accentColor: scheme.primary,
              child: _ThemeModeSwitch(
                selectedMode: themeMode,
                onChanged: (mode) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            const _SectionHeader(
              title: 'Pagamentos',
              subtitle: 'Pix e valores padr\u00e3o',
              icon: Icons.payment_outlined,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _PaymentOptionCard(
              icon: Icons.qr_code_2_outlined,
              title: 'Chave Pix',
              subtitle: pixValue.isEmpty
                  ? 'Defina a chave usada nas cobran\u00e7as.'
                  : 'Chave cadastrada e pronta para uso.',
              onTap: () => _openPixSheet(isLoading: pixAsync.isLoading),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _PaymentOptionCard(
              icon: Icons.attach_money_rounded,
              title: 'Mensalidade padr\u00e3o',
              subtitle: mensalidadeValue.isEmpty
                  ? 'Defina o valor sugerido no cadastro de alunos.'
                  : 'Valor atual: $mensalidadeValue',
              onTap: () =>
                  _openMensalidadeSheet(isLoading: mensalidadeAsync.isLoading),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            const _SectionHeader(
              title: 'Sistema',
              subtitle: 'Sess\u00e3o e informa\u00e7\u00f5es do app',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _SectionCard(
              accentColor: scheme.secondary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vers\u00e3o do app',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '1.0.0',
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
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
                          : _confirmAndSignOut,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(
                          color: scheme.error.withValues(alpha: 0.3),
                        ),
                      ),
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

  Future<void> _openPixSheet({required bool isLoading}) async {
    if (isLoading) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (saving) return;
              setModalState(() => saving = true);
              final ok = await _savePix(_pixController.text.trim());
              if (context.mounted) setModalState(() => saving = false);
              if (ok && context.mounted) Navigator.of(context).pop();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingSm,
                AppTheme.spacingLg,
                AppTheme.spacingLg +
                    MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chave Pix',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : submit,
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(saving ? 'Salvando...' : 'Salvar chave Pix'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openMensalidadeSheet({required bool isLoading}) async {
    if (isLoading) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (saving) return;
              setModalState(() => saving = true);
              final ok = await _saveMensalidade(
                _mensalidadeController.text.trim(),
              );
              if (context.mounted) setModalState(() => saving = false);
              if (ok && context.mounted) Navigator.of(context).pop();
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingSm,
                AppTheme.spacingLg,
                AppTheme.spacingLg +
                    MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mensalidade padr\u00e3o',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  TextField(
                    controller: _mensalidadeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [BrlCurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      hintText: 'Ex: R\$ 80,00',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving ? null : submit,
                      icon: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        saving
                            ? 'Salvando...'
                            : 'Salvar mensalidade padr\u00e3o',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _savePix(String pix) async {
    if (pix.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma chave Pix v\u00e1lida.')),
      );
      return false;
    }

    try {
      await ref.read(configRepositoryProvider).setPixCode(pix);
      final syncState = await waitForFirestoreSync(ref.read(firestoreProvider));
      if (!mounted) return false;
      final message = syncState == FirestoreSyncState.synced
          ? 'Chave Pix salva e sincronizada.'
          : 'Chave Pix salva localmente. Sincronizaremos quando a internet voltar.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
      return false;
    }
  }

  Future<bool> _saveMensalidade(String valueAsText) async {
    final value = parseBrlCurrency(valueAsText);
    if (value == null || value <= 0) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor de mensalidade inv\u00e1lido.')),
      );
      return false;
    }

    try {
      await ref.read(configRepositoryProvider).setDefaultMensalidade(value);
      final syncState = await waitForFirestoreSync(ref.read(firestoreProvider));
      if (!mounted) return false;
      final message = syncState == FirestoreSyncState.synced
          ? 'Mensalidade padr\u00e3o salva e sincronizada.'
          : 'Mensalidade salva localmente. Sincronizaremos quando a internet voltar.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatFirestoreError(e))));
      return false;
    }
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.95),
            scheme.primaryContainer.withValues(alpha: 0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              Icons.settings_outlined,
              size: 22,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              title,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, size: 18, color: scheme.primary),
        ),
        const SizedBox(width: AppTheme.spacingXs),
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
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.accentColor});

  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedAccent = accentColor ?? scheme.primary;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.06),
            blurRadius: isDark ? 16 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 4,
            color: resolvedAccent.withValues(alpha: 0.85),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg - 4),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSwitch extends StatelessWidget {
  const _ThemeModeSwitch({required this.selectedMode, required this.onChanged});

  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;

  static const _items = <_ThemeModeItem>[
    _ThemeModeItem(
      mode: ThemeMode.light,
      label: 'Claro',
      icon: Icons.light_mode_outlined,
    ),
    _ThemeModeItem(
      mode: ThemeMode.dark,
      label: 'Escuro',
      icon: Icons.dark_mode_outlined,
    ),
    _ThemeModeItem(
      mode: ThemeMode.system,
      label: 'Sistema',
      icon: Icons.brightness_auto_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: _items.map((item) {
          final selected = item.mode == selectedMode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  onTap: () => onChanged(item.mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.20 : 0.05,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : const [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 16,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeModeItem {
  const _ThemeModeItem({
    required this.mode,
    required this.label,
    required this.icon,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.06),
            blurRadius: isDark ? 14 : 10,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXs),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: AppTheme.spacingSm),
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
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
