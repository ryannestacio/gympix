import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/portal_auth_provider.dart';

class PortalLoginPage extends ConsumerStatefulWidget {
  const PortalLoginPage({super.key, this.initialMatricula, this.tenantId});

  final String? initialMatricula;
  final String? tenantId;

  @override
  ConsumerState<PortalLoginPage> createState() => _PortalLoginPageState();
}

class _PortalLoginPageState extends ConsumerState<PortalLoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final _matriculaController = TextEditingController(
    text: widget.initialMatricula ?? '',
  );
  final _senhaController = TextEditingController();
  late final _tenantController = TextEditingController(
    text: widget.tenantId ?? '',
  );
  bool _senhaVisivel = false;
  String? _gymName;
  String? _resolvedTenantId;
  bool _isLoadingGym = false;

  @override
  void initState() {
    super.initState();
    if (widget.tenantId != null) {
      _loadGymName();
    }
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _senhaController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  Future<void> _loadGymName() async {
    if (!mounted) return;
    setState(() => _isLoadingGym = true);
    try {
      final db = ref.read(firestoreProvider);
      final input = widget.tenantId!.trim();

      // 1. Tenta buscar direto por UID
      final doc = await db.collection('tenants').doc(input).get();
      if (doc.exists && mounted) {
        setState(() {
          _gymName = doc.data()?['nome'] as String?;
          _resolvedTenantId = doc.id;
        });
        return;
      }

      // 2. Tenta buscar por slug
      final query = await db
          .collection('tenants')
          .where('slug', isEqualTo: input.toLowerCase())
          .limit(1)
          .get();
      if (query.docs.isNotEmpty && mounted) {
        setState(() {
          _gymName = query.docs.first.data()['nome'] as String?;
          _resolvedTenantId = query.docs.first.id;
        });
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isLoadingGym = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final matricula = _matriculaController.text.trim();
    final senha = _senhaController.text.trim();
    final inputTenant = widget.tenantId ?? _tenantController.text.trim();

    String? tenantId = _resolvedTenantId;

    if (tenantId == null) {
      if (mounted) setState(() => _isLoadingGym = true);
      try {
        final db = ref.read(firestoreProvider);
        // 1. Tenta UID
        final doc = await db.collection('tenants').doc(inputTenant).get();
        if (doc.exists) {
          tenantId = doc.id;
        } else {
          // 2. Tenta slug
          final query = await db
              .collection('tenants')
              .where('slug', isEqualTo: inputTenant.toLowerCase())
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            tenantId = query.docs.first.id;
          }
        }
      } catch (_) {
        // ignore
      } finally {
        if (mounted) setState(() => _isLoadingGym = false);
      }
    }

    if (tenantId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código da academia inválido ou não encontrado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final ok = await ref.read(portalAuthProvider.notifier).login(matricula, senha, tenantId);
    if (!mounted) return;

    if (ok) {
      context.go('/portal/painel');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(portalAuthProvider);

    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo / Cabeçalho
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Image.asset(
                          'assets/images/logo-gympix-pb.png',
                          fit: BoxFit.contain,
                          semanticLabel: 'Logo GymPix',
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'GymPix Aluno',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF0F1F5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_isLoadingGym)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      Text(
                        _gymName != null
                            ? 'Acesse seu painel na $_gymName'
                            : 'Acesse seu painel com sua matrícula e senha',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF8F9BB3),
                        ),
                      ),
                    const SizedBox(height: 32),

                    // Mensagem de Erro
                    if (state.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: scheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Campo Código da Academia (caso não fornecido na URL)
                    if (widget.tenantId == null) ...[
                      TextFormField(
                        controller: _tenantController,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Código da Academia',
                          prefixIcon: Icon(Icons.business_rounded),
                          hintText: 'Digite o código da academia',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o código da academia';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Campo Matrícula
                    TextFormField(
                      controller: _matriculaController,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Matrícula',
                        prefixIcon: Icon(Icons.badge_outlined),
                        hintText: 'Ex: 0001',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe sua matrícula';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo Senha
                    TextFormField(
                      controller: _senhaController,
                      obscureText: !_senhaVisivel,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _senhaVisivel
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() => _senhaVisivel = !_senhaVisivel);
                          },
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe sua senha';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botão Login
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      icon: state.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.login_rounded),
                      label: Text(
                        state.isLoading ? 'Autenticando...' : 'Acessar Painel',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: Text(
              'Desenvolvido com carinho por Ryan Estácio ❤︎',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF8F9BB3).withValues(alpha: 0.35),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
