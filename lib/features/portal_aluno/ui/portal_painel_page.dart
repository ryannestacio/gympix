import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../alunos/models/aluno.dart';
import '../providers/portal_auth_provider.dart';

class PortalPainelPage extends ConsumerStatefulWidget {
  const PortalPainelPage({super.key});

  @override
  ConsumerState<PortalPainelPage> createState() => _PortalPainelPageState();
}

class _PortalPainelPageState extends ConsumerState<PortalPainelPage> {
  final _currencyFormatter = NumberFormat.simpleCurrency(locale: 'pt_BR');

  void _copiarPix(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: payload));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código Pix Copia e Cola copiado para a área de transferência!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPaymentDialog(PagamentoMensal pagamento, Aluno aluno) {
    final bool estaPago = pagamento.status == PagamentoStatus.pago;
    final valor = estaPago ? aluno.mensalidade : pagamento.valor;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            estaPago ? 'Adiantar Mensalidade' : 'Pagar Mensalidade',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      estaPago
                          ? 'Mensalidade seguinte'
                          : 'Competência: ${pagamento.competencia}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Valor: ${_currencyFormatter.format(valor)}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carregamento ou QR Code via Riverpod FutureProvider
                    Consumer(
                      builder: (context, ref, _) {
                        final pixPayloadAsync = ref.watch(portalPixPayloadProvider);
                        return pixPayloadAsync.when(
                          data: (payload) {
                            if (payload == null || payload.isEmpty) {
                              return const Center(child: Text('Erro ao gerar código Pix.'));
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: QrImageView(
                                      data: payload,
                                      version: QrVersions.auto,
                                      size: 180.0,
                                      gapless: false,
                                      errorStateBuilder: (cxt, err) {
                                        return const Center(child: Text('Erro ao gerar QR Code'));
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: () => _copiarPix(payload),
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text(
                                    'Copiar Código Copia e Cola',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (err, _) => Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              err.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', ''),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ao realizar o pagamento, enviar o comprovante ao proprietário.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(ThemeData theme, ColorScheme scheme, PagamentoMensal pagamento, Aluno aluno) {
    final bool estaPago = pagamento.status == PagamentoStatus.pago;
    final label = estaPago ? 'Adiantar mensalidade' : 'Pagar mensalidade';

    final buttonStyle = estaPago
        ? OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          )
        : FilledButton.styleFrom(
            backgroundColor: pagamento.status == PagamentoStatus.atrasado ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          );

    void onPressed() => _showPaymentDialog(pagamento, aluno);

    if (estaPago) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        style: buttonStyle,
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.payment_rounded),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: buttonStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final authState = ref.watch(portalAuthProvider);
    final aluno = authState.aluno;

    // Gate de proteção: Redireciona se não estiver logado
    if (aluno == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/portal');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pagamentoAtual = aluno.pagamentoDoMes();
    final inadimplencia = aluno.inadimplencia();

    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1115),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo-gympix-pb.png',
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text(
                'Portal do Aluno',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                ref.read(portalAuthProvider.notifier).logout();
                context.go('/portal');
              },
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Sair do Portal',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingMd),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Perfil Aluno
                    _buildProfileCard(theme, scheme, aluno),
                    const SizedBox(height: 20),

                    // Card de Status Financeiro Atual
                    _buildStatusCard(theme, scheme, pagamentoAtual, inadimplencia),
                    const SizedBox(height: 20),

                    // Botão de Pagamento / Adiantamento
                    _buildActionButton(theme, scheme, pagamentoAtual, aluno),
                    const SizedBox(height: 20),

                    // Histórico de Pagamentos
                    _buildHistorySection(theme, scheme, aluno),
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

  Widget _buildProfileCard(ThemeData theme, ColorScheme scheme, Aluno aluno) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primaryContainer,
              child: Icon(Icons.person_rounded, color: scheme.onPrimaryContainer, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno.nome,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Matrícula: ${aluno.matricula ?? "N/A"}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
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

  Widget _buildStatusCard(
    ThemeData theme,
    ColorScheme scheme,
    PagamentoMensal pagamento,
    dynamic inadimplencia,
  ) {
    final bool estaPago = pagamento.status == PagamentoStatus.pago;
    final color = estaPago
        ? Colors.green
        : (pagamento.status == PagamentoStatus.atrasado ? Colors.red : Colors.orange);
    final icon = estaPago
        ? Icons.check_circle_rounded
        : (pagamento.status == PagamentoStatus.atrasado ? Icons.error_rounded : Icons.pending_actions_rounded);

    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Mensalidade de ${pagamento.competencia}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              estaPago ? 'EM DIA' : (pagamento.status == PagamentoStatus.atrasado ? 'ATRASADA' : 'PENDENTE'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Valor: ${_currencyFormatter.format(pagamento.valor)}',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildHistorySection(ThemeData theme, ColorScheme scheme, Aluno aluno) {
    // Ordenar as competências de forma decrescente
    final sortedKeys = aluno.pagamentos.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Histórico de Mensalidades',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (sortedKeys.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nenhum histórico encontrado.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedKeys.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final pagamento = aluno.pagamentos[key]!;
              final bool estaPago = pagamento.status == PagamentoStatus.pago;
              final statusColor = estaPago
                  ? Colors.green
                  : (pagamento.status == PagamentoStatus.atrasado ? Colors.red : Colors.orange);

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                title: Text(
                  'Mensalidade $key',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: pagamento.pagoEm != null
                    ? Text('Pago em: ${DateFormat('dd/MM/yyyy').format(pagamento.pagoEm!)}')
                    : Text('Vence dia ${pagamento.diaVencimento}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currencyFormatter.format(pagamento.valor),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        pagamento.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
