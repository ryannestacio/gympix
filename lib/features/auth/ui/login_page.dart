import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _logoDarkPath = 'assets/images/logo-gympix-pb.png';
  static const _logoLightPath = 'assets/images/logo-gympix-colorida.png';
  static const _contactPhoneDigits = '5582982199052';
  static const _contactMessage =
      'Olá, Ryan! Tenho interesse em obter o app GymPix.';
  static final _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );

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

  Future<void> _openWhatsAppContact() async {
    final encodedMessage = Uri.encodeComponent(_contactMessage);
    final uri = Uri.parse(
      'https://wa.me/$_contactPhoneDigits?text=$encodedMessage',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel abrir o WhatsApp no momento.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel abrir o WhatsApp no momento.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAction = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = theme.brightness == Brightness.dark;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final message = next.error.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Falha no login: $message')));
      }
    });

    final logoPath = isDark ? _logoDarkPath : _logoLightPath;
    const headerBackground = Color(0xFF0A0C10);
    final contentBackground = theme.colorScheme.surface;
    final credentialsGroupBackground = isDark
        ? const Color(0xFF10151E)
        : const Color(0xFFF7F9FD);
    final credentialsGroupBorder = isDark
        ? const Color(0xFF2B3341)
        : const Color(0xFFE1E7F0);
    final inputFill = isDark ? const Color(0xFF171D27) : Colors.white;
    final inputBorder = isDark
        ? const Color(0xFF353E4D)
        : const Color(0xFFD9E0EB);
    final inputLabelColor = isDark
        ? const Color(0xFFD4DAE6)
        : const Color(0xFF2F3642);
    final inputHintColor = isDark
        ? const Color(0xFF7E8797)
        : const Color(0xFFA6ADB9);
    final buttonBackground = isDark
        ? const Color(0xFFE8EDF7)
        : const Color(0xFF090B10);
    final buttonForeground = isDark ? const Color(0xFF0D1016) : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: headerBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(color: Color(0xFF0A0C10)),
                  ),
                  const _HeaderPattern(),
                  Center(
                    child: Container(
                      width: 82,
                      height: 82,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Image.asset(
                        logoPath,
                        fit: BoxFit.contain,
                        semanticLabel: 'Logo GymPix',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: contentBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(46),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    30,
                    24,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(
                                bottom: keyboardInset + AppTheme.spacingLg,
                              ),
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: AutofillGroup(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Entrar',
                                        textAlign: TextAlign.center,
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingXs,
                                      ),
                                      Text(
                                        'Use seu email e senha para acessar o GymPix',
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodySmall?.copyWith(
                                          fontSize: 13,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingLg,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: credentialsGroupBackground,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: credentialsGroupBorder,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            TextFormField(
                                              controller: _emailController,
                                              autofillHints: const [
                                                AutofillHints.username,
                                              ],
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              enabled: !authAction.isLoading,
                                              decoration: InputDecoration(
                                                labelText: 'Email',
                                                hintText:
                                                    'seuemail@exemplo.com',
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior
                                                        .always,
                                                labelStyle: TextStyle(
                                                  color: inputLabelColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                floatingLabelStyle: TextStyle(
                                                  color: inputLabelColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                hintStyle: TextStyle(
                                                  color: inputHintColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                                filled: true,
                                                fillColor: inputFill,
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                      14,
                                                      19,
                                                      14,
                                                      12,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: inputBorder,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                        width: 1.2,
                                                      ),
                                                    ),
                                              ),
                                              validator: (value) {
                                                final email =
                                                    value?.trim() ?? '';
                                                if (email.isEmpty) {
                                                  return 'Informe seu email.';
                                                }
                                                if (!_emailRegex.hasMatch(
                                                  email,
                                                )) {
                                                  return 'Email invalido.';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(
                                              height: AppTheme.spacingSm,
                                            ),
                                            TextFormField(
                                              controller: _passwordController,
                                              autofillHints: const [
                                                AutofillHints.password,
                                              ],
                                              obscureText: _obscurePassword,
                                              textInputAction:
                                                  TextInputAction.done,
                                              enabled: !authAction.isLoading,
                                              onFieldSubmitted: (_) =>
                                                  _onSubmit(),
                                              decoration: InputDecoration(
                                                labelText: 'Senha',
                                                hintText:
                                                    '\u2022 \u2022 \u2022 \u2022 \u2022 \u2022 \u2022',
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior
                                                        .always,
                                                labelStyle: TextStyle(
                                                  color: inputLabelColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                floatingLabelStyle: TextStyle(
                                                  color: inputLabelColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                                hintStyle: TextStyle(
                                                  color: inputHintColor,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                                filled: true,
                                                fillColor: inputFill,
                                                contentPadding:
                                                    const EdgeInsets.fromLTRB(
                                                      14,
                                                      19,
                                                      14,
                                                      12,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: inputBorder,
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color: theme
                                                            .colorScheme
                                                            .primary,
                                                        width: 1.2,
                                                      ),
                                                    ),
                                                suffixIcon: IconButton(
                                                  tooltip: _obscurePassword
                                                      ? 'Mostrar senha'
                                                      : 'Ocultar senha',
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscurePassword =
                                                          !_obscurePassword;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    _obscurePassword
                                                        ? Icons
                                                              .visibility_outlined
                                                        : Icons
                                                              .visibility_off_outlined,
                                                  ),
                                                ),
                                              ),
                                              validator: (value) {
                                                final password = value ?? '';
                                                if (password.isEmpty) {
                                                  return 'Informe sua senha.';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingLg,
                                      ),
                                      SizedBox(
                                        height: 48,
                                        child: FilledButton(
                                          onPressed: authAction.isLoading
                                              ? null
                                              : _onSubmit,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: buttonBackground,
                                            foregroundColor: buttonForeground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: authAction.isLoading
                                              ? SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(buttonForeground),
                                                  ),
                                                )
                                              : const Text('Entrar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Quer levar o GymPix para sua academia?',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Entre em contato para obter o app.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _openWhatsAppContact,
                              icon: const Icon(Icons.chat_outlined),
                              label: const Text(
                                'Entrar em contato no WhatsApp',
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Todos os direitos reservados a Ryan Estácio',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPattern extends StatelessWidget {
  const _HeaderPattern();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        children: [
          _PatternShape(
            left: -48,
            top: -12,
            width: 108,
            height: 108,
            radius: 54,
            opacity: 0.18,
          ),
          _PatternShape(
            left: 54,
            top: -8,
            width: 82,
            height: 82,
            radius: 16,
            rotateDegrees: 45,
            opacity: 0.14,
          ),
          _PatternShape(
            right: -28,
            top: 10,
            width: 92,
            height: 92,
            radius: 18,
            opacity: 0.15,
          ),
          _PatternShape(
            left: 10,
            top: 68,
            width: 84,
            height: 84,
            radius: 42,
            opacity: 0.17,
          ),
          _PatternShape(
            left: 102,
            top: 74,
            width: 98,
            height: 98,
            radius: 18,
            rotateDegrees: 45,
            opacity: 0.12,
          ),
          _PatternShape(
            right: 32,
            top: 64,
            width: 110,
            height: 110,
            radius: 55,
            opacity: 0.17,
          ),
          _PatternShape(
            left: -30,
            bottom: -38,
            width: 120,
            height: 120,
            radius: 60,
            opacity: 0.16,
          ),
          _PatternShape(
            left: 98,
            bottom: -32,
            width: 92,
            height: 92,
            radius: 46,
            opacity: 0.14,
          ),
          _PatternShape(
            right: -18,
            bottom: -42,
            width: 124,
            height: 124,
            radius: 18,
            rotateDegrees: 45,
            opacity: 0.14,
          ),
        ],
      ),
    );
  }
}

class _PatternShape extends StatelessWidget {
  const _PatternShape({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
    required this.radius,
    required this.opacity,
    this.rotateDegrees,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double height;
  final double radius;
  final double opacity;
  final double? rotateDegrees;

  @override
  Widget build(BuildContext context) {
    Widget child = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const SizedBox.expand(),
    );

    if (rotateDegrees != null) {
      child = Transform.rotate(
        angle: (rotateDegrees! * 3.141592653589793) / 180,
        child: child,
      );
    }

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}
