import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';

class CobrancaPage extends StatelessWidget {
  const CobrancaPage({
    super.key,
    required this.nome,
    required this.pixCode,
    required this.valor,
  });

  final String nome;
  final String pixCode;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pix = pixCode.trim();
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nome.trim().isEmpty ? 'Olá!' : 'Olá ${nome.trim()}!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clique abaixo para pagar sua mensalidade${valor.trim().isEmpty ? '' : ' (R\$ $valor)'}.\n'
                    'Você pode escanear o QR Code ou copiar o Pix.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (pix.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Código Pix não informado no link.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        child: QrImageView(
                          data: pix,
                          size: 240,
                          backgroundColor: scheme.surface,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: pix.isEmpty
                          ? null
                          : () async {
                              await Clipboard.setData(ClipboardData(text: pix));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Código Pix copiado.'),
                                ),
                              );
                            },
                      child: const Text('Copiar código Pix'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
