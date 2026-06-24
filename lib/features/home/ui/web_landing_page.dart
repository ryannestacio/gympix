import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class WebLandingPage extends StatefulWidget {
  const WebLandingPage({super.key});

  @override
  State<WebLandingPage> createState() => _WebLandingPageState();
}

class _WebLandingPageState extends State<WebLandingPage> {
  static const _logoPath = 'assets/images/logo-gympix-colorida.png';
  static const _contactPhoneDigits = '5582982199052';
  static const _contactMessage =
      'Olá, Ryan! Quero conhecer o GymPix para minha academia.';

  Future<void> _openWhatsAppContact() async {
    final encodedMessage = Uri.encodeComponent(_contactMessage);
    final uri = Uri.parse(
      'https://wa.me/$_contactPhoneDigits?text=$encodedMessage',
    );

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (opened || !mounted) return;
    } catch (_) {
      // Fallback abaixo evita fricção em navegadores mais restritivos.
    }

    if (!mounted) return;
    final copied = await _copyTextSafely(uri.toString());
    if (!mounted) return;
    final message = copied
        ? 'Não foi possível abrir o WhatsApp. Link copiado para a área de transferência.'
        : 'Não foi possível abrir o WhatsApp no momento.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _copyTextSafely(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }

  void _goToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1040;
    final isTablet = width >= 720;
    final horizontalPadding = isDesktop ? 56.0 : (isTablet ? 32.0 : 20.0);

    return Scaffold(
      backgroundColor: _LandingColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(onLoginTap: _goToLogin),
                    SizedBox(height: isDesktop ? 58 : 40),
                    _HeroSection(
                      isDesktop: isDesktop,
                      onLoginTap: _goToLogin,
                      onContactTap: _openWhatsAppContact,
                    ),
                    SizedBox(height: isDesktop ? 50 : 34),
                    const _DashboardPreview(),
                    SizedBox(height: isDesktop ? 58 : 42),
                    const _BenefitsSection(),
                    SizedBox(height: isDesktop ? 54 : 38),
                    _BottomCta(
                      onLoginTap: _goToLogin,
                      onContactTap: _openWhatsAppContact,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'GymPix © ${DateTime.now().year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _LandingColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandingColors {
  const _LandingColors._();

  static const background = Color(0xFF080B10);
  static const surface = Color(0xFF0E141E);
  static const surfaceAlt = Color(0xFF121A26);
  static const border = Color(0xFF243044);
  static const primary = Color(0xFF72A0FF);
  static const primaryStrong = Color(0xFF2F74FF);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);
  static const text = Color(0xFFF7FAFF);
  static const softText = Color(0xFFC9D5E8);
  static const mutedText = Color(0xFF8B98AD);
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Image.asset(
            _WebLandingPageState._logoPath,
            fit: BoxFit.contain,
            semanticLabel: 'Logo GymPix',
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'GymPix',
          style: TextStyle(
            color: _LandingColors.text,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: onLoginTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: _LandingColors.text,
            side: const BorderSide(color: _LandingColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
          child: const Text('Entrar'),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.isDesktop,
    required this.onLoginTap,
    required this.onContactTap,
  });

  final bool isDesktop;
  final VoidCallback onLoginTap;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Eyebrow(text: 'Cobrança Pix para academias'),
        const SizedBox(height: 18),
        Text(
          'GymPix',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _LandingColors.text,
            fontSize: isDesktop ? 68 : 48,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Controle mensalidades, atrasos e cobranças em um painel simples, com Pix pronto para enviar pelo WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _LandingColors.softText,
              fontSize: isDesktop ? 20 : 17,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 28),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: onLoginTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _LandingColors.background,
                        ),
                        child: const Text('Acessar plataforma'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onContactTap,
                        icon: const Icon(Icons.chat_outlined, size: 19),
                        label: const Text('Falar no WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _LandingColors.text,
                          side: const BorderSide(color: _LandingColors.border),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: onLoginTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _LandingColors.background,
                        ),
                        child: const Text('Acessar plataforma'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onContactTap,
                        icon: const Icon(Icons.chat_outlined, size: 19),
                        label: const Text('Falar no WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _LandingColors.text,
                          side: const BorderSide(color: _LandingColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 30),
        const _TrustBar(),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _LandingColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _LandingColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _LandingColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrustBar extends StatelessWidget {
  const _TrustBar();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        const children = [
          _TrustMetric(value: 'Pix', label: 'código e QR Code'),
          _TrustMetric(value: 'Mensal', label: 'controle por competência'),
          _TrustMetric(value: 'Relatórios', label: 'CSV e PDF para gestão'),
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: _LandingColors.border),
            ),
          ),
          child: isWide
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: children,
                )
              : const Column(
                  children: [
                    _TrustMetric(value: 'Pix', label: 'código e QR Code'),
                    SizedBox(height: 14),
                    _TrustMetric(
                      value: 'Mensal',
                      label: 'controle por competência',
                    ),
                    SizedBox(height: 14),
                    _TrustMetric(
                      value: 'Relatórios',
                      label: 'CSV e PDF para gestão',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: _LandingColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _LandingColors.mutedText, fontSize: 12),
        ),
      ],
    );
  }
}

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LandingColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: _LandingColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewHeader(),
          SizedBox(height: 20),
          _PreviewStats(),
          SizedBox(height: 18),
          _PreviewActivityList(),
        ],
      ),
    );
  }
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 460;
        final title = Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _LandingColors.primaryStrong.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.dashboard_outlined,
                color: _LandingColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel financeiro',
                    style: TextStyle(
                      color: _LandingColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Visão rápida da rotina da academia',
                    style: TextStyle(
                      color: _LandingColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 12), const _StatusPill()],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            const _StatusPill(),
          ],
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _LandingColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: _LandingColors.success),
          SizedBox(width: 7),
          Text(
            'Online',
            style: TextStyle(
              color: _LandingColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStats extends StatelessWidget {
  const _PreviewStats();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        const stats = [
          _PreviewStat(
            label: 'Recebido',
            value: 'R\$ 8.420',
            accent: _LandingColors.success,
          ),
          _PreviewStat(
            label: 'Em aberto',
            value: 'R\$ 1.980',
            accent: _LandingColors.warning,
          ),
          _PreviewStat(
            label: 'Atrasados',
            value: '7 alunos',
            accent: _LandingColors.primary,
          ),
        ];

        if (!isWide) {
          return const Column(
            children: [
              _PreviewStat(
                label: 'Recebido',
                value: 'R\$ 8.420',
                accent: _LandingColors.success,
              ),
              SizedBox(height: 10),
              _PreviewStat(
                label: 'Em aberto',
                value: 'R\$ 1.980',
                accent: _LandingColors.warning,
              ),
              SizedBox(height: 10),
              _PreviewStat(
                label: 'Atrasados',
                value: '7 alunos',
                accent: _LandingColors.primary,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: stats[0]),
            const SizedBox(width: 10),
            Expanded(child: stats[1]),
            const SizedBox(width: 10),
            Expanded(child: stats[2]),
          ],
        );
      },
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _LandingColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: _LandingColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _LandingColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewActivityList extends StatelessWidget {
  const _PreviewActivityList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PreviewActivityItem(
          icon: Icons.qr_code_2_rounded,
          title: 'Pix gerado para Lucas Almeida',
          subtitle: 'Mensagem pronta para envio no WhatsApp',
        ),
        SizedBox(height: 10),
        _PreviewActivityItem(
          icon: Icons.check_circle_outline_rounded,
          title: 'Pagamento confirmado',
          subtitle: 'Histórico atualizado na competência atual',
        ),
      ],
    );
  }
}

class _PreviewActivityItem extends StatelessWidget {
  const _PreviewActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(icon, color: _LandingColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _LandingColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _LandingColors.mutedText,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'O essencial, sem ruído',
          description:
              'Uma experiência direta para cadastrar alunos, cobrar mensalidades e entender o caixa do mês.',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 28) / 3
                : constraints.maxWidth;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: const _BenefitItem(
                    icon: Icons.payments_outlined,
                    title: 'Cobrança em poucos cliques',
                    description:
                        'Pix, QR Code e mensagem pronta saem do mesmo fluxo.',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _BenefitItem(
                    icon: Icons.groups_2_outlined,
                    title: 'Base de alunos organizada',
                    description:
                        'Dados de cadastro, mensalidade e vencimento ficam em ordem.',
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _BenefitItem(
                    icon: Icons.insert_chart_outlined_rounded,
                    title: 'Resumo claro do mês',
                    description:
                        'Recebido, pendente e atrasado aparecem sem planilha paralela.',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 680),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _LandingColors.text,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: _LandingColors.softText,
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _LandingColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: _LandingColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _LandingColors.primaryStrong.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: _LandingColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _LandingColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: _LandingColors.mutedText,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({required this.onLoginTap, required this.onContactTap});

  final VoidCallback onLoginTap;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide.none,
          horizontal: BorderSide(color: _LandingColors.border),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Sua cobrança mais previsível começa aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _LandingColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Entre no painel ou solicite acesso para conhecer o fluxo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _LandingColors.softText, fontSize: 15),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                height: 46,
                child: FilledButton(
                  onPressed: onLoginTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _LandingColors.primary,
                    foregroundColor: _LandingColors.background,
                  ),
                  child: const Text('Entrar agora'),
                ),
              ),
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: onContactTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _LandingColors.text,
                    side: const BorderSide(color: _LandingColors.border),
                  ),
                  child: const Text('Solicitar acesso'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
