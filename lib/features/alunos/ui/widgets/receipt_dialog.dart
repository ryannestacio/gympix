import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_saver/file_saver.dart';
import '../../../configuracoes/providers/config_providers.dart';
import '../../models/aluno.dart';

class ReceiptDialog extends ConsumerStatefulWidget {
  const ReceiptDialog({
    super.key,
    required this.aluno,
    required this.pagamento,
  });

  final Aluno aluno;
  final PagamentoMensal pagamento;

  static Future<void> show(
    BuildContext context, {
    required Aluno aluno,
    required PagamentoMensal pagamento,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => ReceiptDialog(aluno: aluno, pagamento: pagamento),
    );
  }

  @override
  ConsumerState<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends ConsumerState<ReceiptDialog> {
  ui.Image? _logoImage;
  Uint8List? _generatedBytes;
  bool _isLoading = true;
  bool _isSharing = false;
  bool _isDownloading = false;
  String? _error;

  String? _lastGymName;
  Aluno? _lastAluno;
  PagamentoMensal? _lastPagamento;

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
    final data = await rootBundle.load('assets/images/logo-gympix-colorida.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  String _gerarCodigoControle(String alunoId, String competencia, DateTime? pagoEm) {
    final input = '$alunoId-$competencia-${pagoEm?.millisecondsSinceEpoch ?? 0}';
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final rawHex = hash.abs().toRadixString(16).padLeft(8, '0').toUpperCase();
    final timeHex = (pagoEm?.millisecondsSinceEpoch ?? 0).toRadixString(16).toUpperCase();
    final combined = '$rawHex$timeHex'.padRight(12, '0');
    return combined.substring(combined.length - 12);
  }

  String _competenciaLabelExtenso(String competencia) {
    final parts = competencia.split('-');
    if (parts.length != 2) return competencia;
    final ano = int.tryParse(parts[0]);
    final mes = int.tryParse(parts[1]);
    if (ano == null || mes == null) return competencia;

    const meses = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    if (mes < 1 || mes > 12) return competencia;
    return '${meses[mes]} de $ano';
  }

  Future<void> _generateImage(String gymName, Aluno aluno, PagamentoMensal pagamento) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logo = _logoImage ?? await _loadLogo();
      _logoImage = logo;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 600, 800));

      const width = 600.0;
      const height = 800.0;

      // 1. Fundo cinza claro suave
      final outerRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(24),
      );
      final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
      canvas.drawRRect(outerRRect, bgPaint);

      // Borda decorativa cinza neutro
      final borderPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRRect(outerRRect, borderPaint);

      // Card interno branco
      final innerRRect = RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 24, width - 48, height - 48),
        const Radius.circular(20),
      );
      final innerCardPaint = Paint()..color = Colors.white;
      canvas.drawRRect(innerRRect, innerCardPaint);

      final innerBorderPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(innerRRect, innerBorderPaint);

      // 2. Cabeçalho Clean
      final titlePainter = TextPainter(
        text: const TextSpan(
          text: 'COMPROVANTE DE PAGAMENTO',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      titlePainter.layout();
      titlePainter.paint(canvas, const Offset(48, 48));

      // Nome da Academia
      final gymPainter = TextPainter(
        text: TextSpan(
          text: gymName.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      gymPainter.layout(maxWidth: 340);
      gymPainter.paint(canvas, const Offset(48, 74));

      // Logo GymPix no cabeçalho
      final srcRect = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());
      final logoWidth = (logo.width * 36) / logo.height;
      final destRect = Rect.fromLTWH(600 - 48 - logoWidth, 48, logoWidth, 36);
      canvas.drawImageRect(logo, srcRect, destRect, Paint());

      // Linha divisória horizontal
      final dividerPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.0;
      canvas.drawLine(const Offset(48, 110), const Offset(600 - 48, 110), dividerPaint);

      // 3. Informações em duas colunas (estilo recibo de banco)
      double currentY = 140.0;

      void drawInfoRow(String label, String value) {
        final labelPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        labelPainter.layout();
        labelPainter.paint(canvas, Offset(48, currentY));

        final valuePainter = TextPainter(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        );
        valuePainter.layout(maxWidth: 320);
        valuePainter.paint(canvas, Offset(600 - 48 - valuePainter.width, currentY));

        currentY += 40.0;
      }

      drawInfoRow('Aluno', aluno.nome);
      drawInfoRow('Matrícula', aluno.matricula?.trim().isNotEmpty == true ? aluno.matricula! : 'N/A');
      drawInfoRow('Referência', _competenciaLabelExtenso(pagamento.competencia));
      
      final dataPgto = pagamento.pagoEm != null 
          ? DateFormat('dd/MM/yyyy HH:mm').format(pagamento.pagoEm!)
          : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      drawInfoRow('Data/Hora', dataPgto);

      final codControle = _gerarCodigoControle(aluno.id, pagamento.competencia, pagamento.pagoEm);
      drawInfoRow('Cód. Controle', codControle);

      // 4. Painel de Valor Recebido (Caixa Verde Claro Moderno)
      currentY += 10.0;
      final valueRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(48, currentY, 600 - 96, 100),
        const Radius.circular(16),
      );
      final valueBgPaint = Paint()..color = const Color(0xFFF0FDF4);
      canvas.drawRRect(valueRRect, valueBgPaint);

      final valueBorderPaint = Paint()
        ..color = const Color(0xFFBBF7D0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(valueRRect, valueBorderPaint);

      final valLabelPainter = TextPainter(
        text: const TextSpan(
          text: 'VALOR RECEBIDO',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      valLabelPainter.layout();
      valLabelPainter.paint(canvas, Offset(72, currentY + 18));

      final currencyStr = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(pagamento.valor);

      final valValuePainter = TextPainter(
        text: TextSpan(
          text: currencyStr,
          style: const TextStyle(
            color: Color(0xFF14532D),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      valValuePainter.layout();
      valValuePainter.paint(canvas, Offset(72, currentY + 38));

      currentY += 124.0;

      // 5. Observações (se houver)
      if (pagamento.observacao?.trim().isNotEmpty == true) {
        final obsTitlePainter = TextPainter(
          text: const TextSpan(
            text: 'Observações:',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        obsTitlePainter.layout();
        obsTitlePainter.paint(canvas, Offset(48, currentY));

        currentY += 18.0;

        final obsTextPainter = TextPainter(
          text: TextSpan(
            text: pagamento.observacao!,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontFamily: 'Roboto',
            ),
          ),
          textDirection: ui.TextDirection.ltr,
          maxLines: 2,
          ellipsis: '...',
        );
        obsTextPainter.layout(maxWidth: 600 - 96);
        obsTextPainter.paint(canvas, Offset(48, currentY));
      }

      // 6. Linha tracejada horizontal de corte (picote)
      final dashPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      double startX = 48;
      const dashWidth = 8;
      const dashSpace = 6;
      while (startX < 600 - 48) {
        canvas.drawLine(Offset(startX, 710), Offset(startX + dashWidth, 710), dashPaint);
        startX += dashWidth + dashSpace;
      }

      // 7. Rodapé Oficial
      final digitalPainter = TextPainter(
        text: const TextSpan(
          text: 'COMPROVANTE OFICIAL EMITIDO VIA GYMPIX',
          style: TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      digitalPainter.layout();
      digitalPainter.paint(canvas, Offset(48, 740));

      final checkPainter = TextPainter(
        text: const TextSpan(
          text: '✓ AUTENTICADO',
          style: TextStyle(
            color: Color(0xFF16A34A),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      checkPainter.layout();
      checkPainter.paint(canvas, Offset(600 - 48 - checkPainter.width, 740));

      // Encerrar gravação e obter bytes
      final picture = recorder.endRecording();
      final img = await picture.toImage(600, 800);
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

  Future<void> _compartilhar(String gymName) async {
    final bytes = _generatedBytes;
    if (bytes == null) return;

    setState(() => _isSharing = true);

    final dataPgtoStr = widget.pagamento.pagoEm != null 
        ? DateFormat('dd/MM/yyyy').format(widget.pagamento.pagoEm!)
        : DateFormat('dd/MM/yyyy').format(DateTime.now());

    final currencyStr = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(widget.pagamento.valor);

    final text = '=== COMPROVANTE DE PAGAMENTO ===\n'
        'Academia: $gymName\n'
        'Aluno: ${widget.aluno.nome}\n'
        'Competência: ${_competenciaLabelExtenso(widget.pagamento.competencia)}\n'
        'Data de Pagamento: $dataPgtoStr\n'
        'Valor Recebido: $currencyStr\n'
        'Código de Controle: ${_gerarCodigoControle(widget.aluno.id, widget.pagamento.competencia, widget.pagamento.pagoEm)}\n'
        '================================';

    try {
      final fileName = 'recibo_${widget.aluno.matricula ?? widget.aluno.id}_${widget.pagamento.competencia}.png';
      if (!kIsWeb) {
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: text,
        );
        if (mounted) setState(() => _isSharing = false);
        return;
      } else {
        final xFile = XFile.fromData(
          bytes,
          name: fileName,
          mimeType: 'image/png',
        );
        await Share.shareXFiles(
          [xFile],
          text: text,
        );
        if (mounted) setState(() => _isSharing = false);
        return;
      }
    } catch (_) {
      // Fallback
    }

    try {
      await Share.share(text);
    } catch (_) {}

    if (mounted) setState(() => _isSharing = false);
  }

  Future<void> _baixar() async {
    final bytes = _generatedBytes;
    if (bytes == null) return;

    setState(() => _isDownloading = true);

    try {
      final fileName = 'recibo_${widget.aluno.matricula ?? widget.aluno.id}_${widget.pagamento.competencia}.png';
      await saveAndDownloadFile(bytes, fileName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recibo salvo no dispositivo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar recibo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymName = ref.watch(tenantNameStreamProvider).value ?? 'GymPix';
    
    if (_lastGymName != gymName || _lastAluno != widget.aluno || _lastPagamento != widget.pagamento) {
      _lastGymName = gymName;
      _lastAluno = widget.aluno;
      _lastPagamento = widget.pagamento;
      _generateImage(gymName, widget.aluno, widget.pagamento);
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recibo de Pagamento',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              if (_isLoading)
                const SizedBox(
                  height: 250,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Gerando recibo oficial...',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_error != null)
                SizedBox(
                  height: 250,
                  child: Center(
                    child: Text(
                      'Erro ao gerar imagem: $_error',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                )
              else if (_generatedBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    color: Colors.black12,
                    child: AspectRatio(
                      aspectRatio: 600 / 800,
                      child: Image.memory(
                        _generatedBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading || _isDownloading || _isSharing ? null : _baixar,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: const Text('Baixar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading || _isDownloading || _isSharing
                          ? null
                          : () => _compartilhar(gymName),
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: const Text('Compartilhar'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
