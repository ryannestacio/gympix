import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/utils/pix_key_validator.dart';

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
              title: 'Portal do Aluno',
              subtitle: 'Configurações de identidade e link do aluno',
              icon: Icons.launch_rounded,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _PortalSlugCard(
              slugAsync: ref.watch(tenantSlugStreamProvider),
              onTap: _openPortalSlugSheet,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _PortalGymNameCard(
              nameAsync: ref.watch(tenantNameStreamProvider),
              onTap: _openPortalGymNameSheet,
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
                          '1.2.0',
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
        var tipoChave = _detectarTipoChave(_pixController.text);

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chave Pix',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.content_paste_rounded, size: 16),
                        label: const Text('Colar'),
                        onPressed: () async {
                          final data = await Clipboard.getData(Clipboard.kTextPlain);
                          if (data != null && data.text != null) {
                            final text = data.text!;
                            _pixController.text = text;
                            setModalState(() {
                              tipoChave = _detectarTipoChave(text);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cadastre sua chave Pix estática ou o código Copia e Cola completo para gerar as cobranças dos alunos.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  TextField(
                    controller: _pixController,
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    onChanged: (text) {
                      setModalState(() {
                        tipoChave = _detectarTipoChave(text);
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cole a chave Pix ou código Copia e Cola...',
                    ),
                  ),
                  _buildFeedbackTipoChave(tipoChave, theme),
                  const SizedBox(height: AppTheme.spacingLg),
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

  String _detectarTipoChave(String key) {
    final cleaned = key.trim();
    if (cleaned.isEmpty) return '';

    if (cleaned.startsWith('000201')) {
      return 'copia_cola';
    }

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );
    if (emailRegex.hasMatch(cleaned)) return 'email';

    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 11) {
      return 'cpf_celular';
    }
    if (digitsOnly.length == 13) {
      return 'celular_ddi';
    }
    if (digitsOnly.length == 14) {
      return 'cnpj';
    }

    final evpRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (evpRegex.hasMatch(cleaned)) return 'aleatoria';

    return 'invalido';
  }

  Widget _buildFeedbackTipoChave(String tipo, ThemeData theme) {
    if (tipo.isEmpty) return const SizedBox.shrink();

    final scheme = theme.colorScheme;
    IconData icon;
    String label;
    Color color;

    switch (tipo) {
      case 'copia_cola':
        icon = Icons.qr_code_2_rounded;
        label = 'Código Pix Copia e Cola completo detectado.';
        color = const Color(0xFF16A34A); // Verde
        break;
      case 'email':
        icon = Icons.email_outlined;
        label = 'Tipo detectado: E-mail (Gerará QR Code estático).';
        color = scheme.primary;
        break;
      case 'cpf_celular':
        icon = Icons.badge_outlined;
        label = 'Tipo detectado: CPF ou Celular (Gerará QR Code estático).';
        color = scheme.primary;
        break;
      case 'celular_ddi':
        icon = Icons.phone_android_outlined;
        label = 'Tipo detectado: Celular com DDI (Gerará QR Code estático).';
        color = scheme.primary;
        break;
      case 'cnpj':
        icon = Icons.business_outlined;
        label = 'Tipo detectado: CNPJ (Gerará QR Code estático).';
        color = scheme.primary;
        break;
      case 'aleatoria':
        icon = Icons.vpn_key_outlined;
        label = 'Tipo detectado: Chave Aleatória EVP (Gerará QR Code estático).';
        color = scheme.primary;
        break;
      default:
        icon = Icons.warning_amber_rounded;
        label = 'Formato desconhecido ou chave inválida.';
        color = const Color(0xFFDC2626); // Vermelho
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
            final scheme = Theme.of(context).colorScheme;
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
                  const SizedBox(height: 6),
                  Text(
                    'Valor sugerido automaticamente ao cadastrar novos alunos para agilizar seu preenchimento.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  TextField(
                    controller: _mensalidadeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [BrlCurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Valor da Mensalidade',
                      hintText: 'Ex: R\$ 80,00',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Valores sugeridos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [60.0, 70.0, 80.0, 90.0, 100.0, 120.0, 150.0].map((val) {
                        final valText = formatBrl(val);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text('R\$ ${val.toStringAsFixed(0)}'),
                            onPressed: () {
                              _mensalidadeController.text = valText;
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
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
    final cleaned = pix.trim();
    if (cleaned.isEmpty) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe uma chave Pix.')),
      );
      return false;
    }

    if (!PixKeyValidator.isValid(cleaned)) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chave Pix inválida. Verifique o formato informado.')),
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

  Future<void> _openPortalSlugSheet() async {
    final currentSlug = ref.read(tenantSlugStreamProvider).value ?? '';
    final slugController = TextEditingController(text: currentSlug);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var saving = false;
        String? errorMessage;
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              if (saving) return;

              setModalState(() {
                saving = true;
                errorMessage = null;
              });

              try {
                final repo = ref.read(configRepositoryProvider);
                await repo.setTenantSlug(slugController.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código de acesso do portal atualizado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  setModalState(() {
                    errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
                    saving = false;
                  });
                }
              }
            }

            final slugText = slugController.text.trim();
            final generatedLink = slugText.isNotEmpty
                ? 'https://gympixapp.web.app/portal?tenant=$slugText'
                : '';

            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingSm,
                AppTheme.spacingLg,
                AppTheme.spacingLg + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portal do Aluno',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Defina um código curto e amigável (como o @ de uma rede social) para identificar sua academia no link do aluno.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    TextFormField(
                      controller: slugController,
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => submit(),
                      onChanged: (_) {
                        setModalState(() {});
                      },
                      decoration: const InputDecoration(
                        labelText: 'Código da Academia',
                        prefixText: '@ ',
                        hintText: 'ex: academiabemestar',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o código da academia.';
                        }
                        final clean = v.trim();
                        if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(clean)) {
                          return 'Use apenas letras, números, - e _.';
                        }
                        return null;
                      },
                    ),
                    if (generatedLink.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Link gerado:',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    generatedLink,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: 'Copiar link',
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: generatedLink));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copiado!')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: TextStyle(color: scheme.error, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingLg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saving ? null : submit,
                        icon: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(saving ? 'Salvando...' : 'Salvar Código'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openPortalGymNameSheet() async {
    final currentName = ref.read(tenantNameStreamProvider).value ?? '';
    final nameController = TextEditingController(text: currentName);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var saving = false;
        String? errorMessage;
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;

            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              if (saving) return;

              setModalState(() {
                saving = true;
                errorMessage = null;
              });

              try {
                final repo = ref.read(configRepositoryProvider);
                await repo.setTenantName(nameController.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nome da academia atualizado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  setModalState(() {
                    errorMessage = e.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
                    saving = false;
                  });
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacingLg,
                AppTheme.spacingSm,
                AppTheme.spacingLg,
                AppTheme.spacingLg + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nome da Academia',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Defina o nome de exibição oficial da sua academia no portal do aluno e nos documentos.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => submit(),
                      decoration: const InputDecoration(
                        labelText: 'Nome da Academia',
                        hintText: 'ex: Academia Bem Estar',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o nome da academia.';
                        }
                        return null;
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: saving ? null : submit,
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text('Salvar Nome'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Fundo do botão selecionado dependendo do tema escuro/claro para alto contraste
    final selectedBgColor = isDark
        ? scheme.surfaceContainerHigh
        : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerLow : const Color(0xFFF1F5F9), // Slate 100 claro
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outline.withOpacity(0.12)),
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
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? selectedBgColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
                                blurRadius: 6,
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
                          size: 15,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant.withOpacity(0.7),
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

class _PortalSlugCard extends StatelessWidget {
  const _PortalSlugCard({
    required this.slugAsync,
    required this.onTap,
  });

  final AsyncValue<String?> slugAsync;
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
                  child: Icon(Icons.link_rounded, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link do Portal do Aluno',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      slugAsync.when(
                        data: (slug) {
                          if (slug == null || slug.trim().isEmpty) {
                            return Text(
                              'Crie um código de acesso para gerar o link do portal.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            );
                          }
                          return Text(
                            'Código ativo: @$slug\nLink: gympixapp.web.app/portal?tenant=$slug',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        error: (err, _) => Text(
                          'Erro ao carregar link.',
                          style: textTheme.bodySmall?.copyWith(color: scheme.error),
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

class _PortalGymNameCard extends StatelessWidget {
  const _PortalGymNameCard({
    required this.nameAsync,
    required this.onTap,
  });

  final AsyncValue<String?> nameAsync;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
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
                  child: Icon(Icons.business_rounded, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nome da Academia',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      nameAsync.when(
                        data: (name) {
                          if (name == null || name.trim().isEmpty) {
                            return Text(
                              'Toque para configurar o nome da academia.',
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            );
                          }
                          return Text(
                            name,
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          );
                        },
                        loading: () => const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        error: (err, _) => Text(
                          'Erro ao carregar nome.',
                          style: textTheme.bodySmall?.copyWith(color: scheme.error),
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
