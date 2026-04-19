import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authAction = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final message = next.error.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Falha no login: $message')));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Acessar conta',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      TextFormField(
                        controller: _emailController,
                        autofillHints: const [AutofillHints.username],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !authAction.isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'seu@email.com',
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Informe seu email.';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Email invalido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      TextFormField(
                        controller: _passwordController,
                        autofillHints: const [AutofillHints.password],
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !authAction.isLoading,
                        onFieldSubmitted: (_) => _onSubmit(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          hintText: 'Digite sua senha',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value?.trim() ?? '';
                          if (password.isEmpty) return 'Informe sua senha.';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                      FilledButton.icon(
                        onPressed: authAction.isLoading ? null : _onSubmit,
                        icon: authAction.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          authAction.isLoading ? 'Entrando...' : 'Entrar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
