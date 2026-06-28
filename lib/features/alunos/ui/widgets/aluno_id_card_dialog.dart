import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../configuracoes/providers/config_providers.dart';
import '../../models/aluno.dart';
import '../../providers/alunos_providers.dart';

class AlunoIdCardDialog extends ConsumerStatefulWidget {
  const AlunoIdCardDialog({
    super.key,
    required this.alunoId,
  });

  final String alunoId;

  @override
  ConsumerState<AlunoIdCardDialog> createState() => _AlunoIdCardDialogState();
}

class _AlunoIdCardDialogState extends ConsumerState<AlunoIdCardDialog> {
  ui.Image? _logoImage;
  Uint8List? _generatedBytes;
  bool _isLoading = true;
  String? _error;

  String? _lastGymName;
  Aluno? _lastAluno;
  String? _lastPortalLink;

  @override
  void initState() {
    super.initState();
    _initLogo();
  }

  Future<void> _initLogo() async {
    try {
      final img = await _loadLogo();
      if (mounted) {
        setState(() {
          _logoImage = img;
        });
      }
    } catch (_) {}
  }

  Future<ui.Image> _loadLogo() async {
    final data = await rootBundle.load('assets/images/logo-gympix-pb.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _generateImage(String gymName, Aluno aluno, String portalLink) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logo = _logoImage ?? await _loadLogo();
      _logoImage = logo;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 800, 504));

      const width = 800.0;
      const height = 504.0;

      // 1. Draw outer background with rounded corners
      final outerRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(24),
      );
      
      final bgPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(800, 504),
          const [
            Color(0xFF252E3C),
            Color(0xFF161B24),
          ],
        );
      canvas.drawRRect(outerRRect, bgPaint);

      // Border paint
      final borderPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRRect(outerRRect, borderPaint);

      // 2. Draw Header
      final headerPath = Path()
        ..addRRect(RRect.fromRectAndCorners(
          const Rect.fromLTWH(0, 0, 800, 80),
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
        ));
      final headerPaint = Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.15);
      canvas.drawPath(headerPath, headerPaint);
      
      final headerBorderPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(const Offset(0, 80), const Offset(800, 80), headerBorderPaint);

      // Draw Gym Name
      final namePainter = TextPainter(
        text: TextSpan(
          text: 'GYMPIX - ${gymName.toUpperCase()}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      namePainter.layout(maxWidth: 500);
      namePainter.paint(canvas, const Offset(32, 26));

      // Draw GymPix logo image
      final srcRect = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());
      final logoWidth = (logo.width * 36) / logo.height;
      final destRect = Rect.fromLTWH(800 - 32 - logoWidth, 22, logoWidth, 36);
      canvas.drawImageRect(logo, srcRect, destRect, Paint());

      // 3. Draw Profile Avatar placeholder
      final photoRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(48, 120, 150, 180),
        const Radius.circular(16),
      );
      final photoPaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
      canvas.drawRRect(photoRRect, photoPaint);
      
      final photoBorderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(photoRRect, photoBorderPaint);

      // Draw Vector Avatar inside box (Centered at x: 123, y: 210)
      final avatarPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
      // Head
      canvas.drawCircle(const Offset(123, 190), 24, avatarPaint);
      // Shoulders
      canvas.drawPath(
        Path()
          ..addOval(Rect.fromCenter(center: const Offset(123, 255), width: 75, height: 45)),
        avatarPaint,
      );

      // 4. Draw ALUNO badge (Centered below photo at x: 123, y: 320)
      final badgeRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(48, 320, 150, 36),
        const Radius.circular(8),
      );
      final badgePaint = Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.12);
      canvas.drawRRect(badgeRRect, badgePaint);
      
      final badgeBorderPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(badgeRRect, badgeBorderPaint);

      // ALUNO Text
      final alunoTextPainter = TextPainter(
        text: const TextSpan(
          text: 'ALUNO',
          style: TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      alunoTextPainter.layout();
      alunoTextPainter.paint(
        canvas,
        Offset(123 - alunoTextPainter.width / 2, 338 - alunoTextPainter.height / 2),
      );

      // 5. Draw Details
      const detailsX = 240.0;
      
      // Nome do Aluno
      _paintInfoField(
        canvas: canvas,
        label: 'NOME DO ALUNO',
        value: aluno.nome.toUpperCase(),
        x: detailsX,
        y: 125,
        maxWidth: 512,
        maxLines: 2,
        valFontSize: 24,
      );

      // Matrícula
      _paintInfoField(
        canvas: canvas,
        label: 'MATRÍCULA',
        value: aluno.matricula ?? 'N/A',
        x: detailsX,
        y: 285,
        maxWidth: 240,
        maxLines: 1,
        valFontSize: 24,
      );

      // Senha
      final senhaDisplay = aluno.senha?.trim().isNotEmpty == true 
          ? aluno.senha! 
          : (aluno.matricula ?? '');
      _paintInfoField(
        canvas: canvas,
        label: 'SENHA DE ACESSO',
        value: senhaDisplay,
        x: 520,
        y: 285,
        maxWidth: 240,
        maxLines: 1,
        valFontSize: 24,
      );

      // 6. Draw footer text
      final emitidoPainter = TextPainter(
        text: TextSpan(
          text: 'Emitido pelo GymPix',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 14,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      emitidoPainter.layout();
      emitidoPainter.paint(canvas, const Offset(32, 450));

      final digitalPainter = TextPainter(
        text: const TextSpan(
          text: 'CARTEIRINHA DIGITAL',
          style: TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      digitalPainter.layout();
      digitalPainter.paint(canvas, Offset(800 - 32 - digitalPainter.width, 450));

      // End recording and convert to PNG bytes
      final picture = recorder.endRecording();
      final img = await picture.toImage(800, 504);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      if (mounted) {
        setState(() {
          _generatedBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _paintInfoField({
    required Canvas canvas,
    required String label,
    required String value,
    required double x,
    required double y,
    required double maxWidth,
    required int maxLines,
    required double valFontSize,
  }) {
    // Label text
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    labelPainter.layout(maxWidth: maxWidth);
    labelPainter.paint(canvas, Offset(x, y));

    // Value text
    final valuePainter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: Colors.white,
          fontSize: valFontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '...',
    );
    valuePainter.layout(maxWidth: maxWidth);
    valuePainter.paint(canvas, Offset(x, y + 26));
  }

  Future<void> _shareCard(String gymName, Aluno aluno, String portalLink) async {
    final bytes = _generatedBytes;
    if (bytes == null) return;

    setState(() => _isSharing = true);
    
    final senhaDisplay = aluno.senha?.trim().isNotEmpty == true 
        ? aluno.senha! 
        : (aluno.matricula ?? '');

    final text = '=== CARTEIRINHA DIGITAL ===\n'
        'Academia: $gymName\n'
        'Aluno: ${aluno.nome}\n'
        'Matrícula: ${aluno.matricula ?? "N/A"}\n'
        'Senha: $senhaDisplay\n'
        '---------------------------\n'
        'Acesse o Portal: $portalLink\n'
        '===========================';

    try {
      if (!kIsWeb) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/carteirinha_${aluno.matricula ?? aluno.id}.png');
        await file.writeAsBytes(bytes);
        
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: text,
        );
        if (mounted) setState(() => _isSharing = false);
        return;
      }
    } catch (e) {
      // Fallback em caso de erro de IO/Repaint
    }

    // Fallback / Web: Compartilha como texto corrido
    // ignore: deprecated_member_use
    await Share.share(text);
    if (mounted) setState(() => _isSharing = false);
  }

  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final aluno = ref.watch(alunoProvider(widget.alunoId));
    final gymNameAsync = ref.watch(tenantNameStreamProvider);
    final slugAsync = ref.watch(tenantSlugStreamProvider);

    if (aluno == null) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacingLg),
          child: Text('Aluno não encontrado.'),
        ),
      );
    }

    final gymName = gymNameAsync.value ?? 'GymPix Academia';
    final slug = slugAsync.value ?? '';
    final portalLink = slug.isNotEmpty 
        ? 'https://gympixapp.web.app/portal?tenant=$slug'
        : 'https://gympixapp.web.app/portal';

    // Trigger image generation reactively if properties change
    if (aluno != _lastAluno || gymName != _lastGymName || portalLink != _lastPortalLink || _logoImage == null) {
      _lastAluno = aluno;
      _lastGymName = gymName;
      _lastPortalLink = portalLink;
      Future.microtask(() => _generateImage(gymName, aluno, portalLink));
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                    Text(
                      'Carteirinha do Aluno',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),

                // Exibição do Preview da Imagem Gerada
                if (_isLoading || _generatedBytes == null)
                  AspectRatio(
                    aspectRatio: 1.586,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2.5),
                            const SizedBox(height: 12),
                            Text(
                              'Gerando carteirinha...',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_error != null)
                  AspectRatio(
                    aspectRatio: 1.586,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          'Erro ao gerar imagem:\n$_error',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                  )
                else
                  // Apenas exibe o arquivo de imagem PNG resultante
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      _generatedBytes!,
                      fit: BoxFit.contain,
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Botões de Ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Fechar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLoading || _generatedBytes == null || _isSharing
                            ? null
                            : () => _shareCard(gymName, aluno, portalLink),
                        icon: _isSharing 
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : const Icon(Icons.share_rounded),
                        label: Text(_isSharing ? 'Compartilhando...' : 'Compartilhar'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
