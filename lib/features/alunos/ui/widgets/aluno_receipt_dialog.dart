import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../models/aluno.dart';

class AlunoCobrarSheet extends ConsumerStatefulWidget {
  const AlunoCobrarSheet({
    super.key,
    required this.aluno,
    required this.pixPayload,
    required this.valorCobranca,
    required this.lembrete,
  });

  final Aluno aluno;
  final String pixPayload;
  final String valorCobranca;
  final String lembrete;

  static Future<void> show({
    required BuildContext context,
    required Aluno aluno,
    required String pixPayload,
    required String valorCobranca,
    required String lembrete,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: AlunoCobrarSheet(
            aluno: aluno,
            pixPayload: pixPayload,
            valorCobranca: valorCobranca,
            lembrete: lembrete,
          ),
        ),
      ),
    );
  }

  /// Gera os bytes de imagem PNG do QR Code e recibo de cobrança premium.
  static Future<Uint8List?> buildPixQrPngBytes({
    required Aluno aluno,
    required String pixPayload,
    required String valorCobranca,
  }) async {
    final painter = QrPainter(
      data: pixPayload,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
    );
    final imageData = await painter.toImageData(
      920,
      format: ui.ImageByteFormat.png,
    );
    if (imageData == null) return null;

    final codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
    );
    final frame = await codec.getNextFrame();
    final qrImage = frame.image;

    const canvasWidth = 1280.0;
    const canvasHeight = 1580.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      Paint()..color = Colors.white,
    );

    final cardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(64, 64, 1152, 1452),
      const Radius.circular(40),
    );
    canvas.drawRRect(cardRect, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final qrContainer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(150, 140, 980, 980),
      const Radius.circular(28),
    );
    canvas.drawRRect(qrContainer, Paint()..color = Colors.white);
    canvas.drawRRect(
      qrContainer,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    const qrRect = Rect.fromLTWH(180, 170, 920, 920);
    canvas.drawImageRect(
      qrImage,
      Rect.fromLTWH(0, 0, qrImage.width.toDouble(), qrImage.height.toDouble()),
      qrRect,
      Paint(),
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.text = TextSpan(
      text: aluno.nome,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 56,
        fontWeight: FontWeight.w800,
      ),
    );
    textPainter.layout(maxWidth: 1152);
    textPainter.paint(
      canvas,
      Offset(64 + (1152 - textPainter.width) / 2, 1180),
    );

    textPainter.text = TextSpan(
      text: valorCobranca,
      style: const TextStyle(
        color: Color(0xFF2563EB),
        fontSize: 72,
        fontWeight: FontWeight.w900,
      ),
    );
    textPainter.layout(maxWidth: 1152);
    textPainter.paint(
      canvas,
      Offset(64 + (1152 - textPainter.width) / 2, 1260),
    );

    textPainter.text = const TextSpan(
      text: 'QR Code Pix para pagamento',
      style: TextStyle(
        color: Color(0xFF64748B),
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout(maxWidth: 1152);
    textPainter.paint(
      canvas,
      Offset(64 + (1152 - textPainter.width) / 2, 1370),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());
    final pngData = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngData?.buffer.asUint8List();
  }

  /// Gera e compartilha o recibo Pix diretamente.
  static Future<void> sharePixQr({
    required Aluno aluno,
    required String pixPayload,
    required String valorCobranca,
    required String message,
  }) async {
    final pngBytes = await buildPixQrPngBytes(
      aluno: aluno,
      pixPayload: pixPayload,
      valorCobranca: valorCobranca,
    );
    if (pngBytes == null) {
      throw Exception('Não foi possível gerar a imagem do QR Code.');
    }

    final xFile = XFile.fromData(
      pngBytes,
      mimeType: 'image/png',
      name: 'cobranca_gympix.png',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        text: message,
      ),
    );
  }

  @override
  ConsumerState<AlunoCobrarSheet> createState() => _AlunoCobrarSheetState();
}

class _AlunoCobrarSheetState extends ConsumerState<AlunoCobrarSheet> {
  bool _isGeneratingImage = false;

  Future<void> _copyPixPayload(
    String payload, {
    required String successMessage,
  }) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
  }

  Future<void> _sharePixQrPng({
    required String pixPayload,
    required String message,
  }) async {
    if (_isGeneratingImage) return;
    setState(() => _isGeneratingImage = true);

    try {
      await AlunoCobrarSheet.sharePixQr(
        aluno: widget.aluno,
        pixPayload: pixPayload,
        valorCobranca: widget.valorCobranca,
        message: message,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível compartilhar o QR Code Pix.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        12,
        AppTheme.spacingLg,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cobrar com Pix',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusSm,
                    ),
                  ),
                  child: QrImageView(
                    data: widget.pixPayload,
                    size: 208,
                    version: QrVersions.auto,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.aluno.nome,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.valorCobranca,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pix cópia e cola',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SelectableText(
            widget.pixPayload,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _copyPixPayload(
                    widget.pixPayload,
                    successMessage: 'Código Pix copiado.',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: _isGeneratingImage
                      ? null
                      : () => _sharePixQrPng(
                            pixPayload: widget.pixPayload,
                            message:
                                'QR Code Pix - ${widget.aluno.nome} - ${widget.valorCobranca}',
                          ),
                  child: _isGeneratingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Compartilhar QR'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: _isGeneratingImage
                ? null
                : () => _sharePixQrPng(
                      pixPayload: widget.pixPayload,
                      message: widget.lembrete,
                    ),
            icon: const Icon(Icons.message_outlined, size: 18),
            label: const Text('Enviar mensagem pronta'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: widget.lembrete));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cobrança copiada.')),
              );
            },
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: const Text('Copiar mensagem pronta'),
          ),
        ],
      ),
    );
  }
}
