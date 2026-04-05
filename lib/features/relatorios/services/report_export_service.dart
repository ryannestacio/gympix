import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../alunos/models/aluno.dart';
import '../models/competencia_report.dart';

class ReportExportService {
  Future<void> exportarCsvCompetencia(CompetenciaReportData report) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'nome,telefone,dia_vencimento,valor,status,competencia,pago_em,comprovante,observacao',
    );

    for (final aluno in report.alunosSnapshot) {
      final pagoEm = aluno.pagoEm == null
          ? ''
          : DateFormat('yyyy-MM-dd HH:mm').format(aluno.pagoEm!);
      final row = [
        _csvCell(aluno.nome),
        _csvCell(aluno.telefone),
        aluno.diaVencimento,
        aluno.valor.toStringAsFixed(2),
        aluno.status.name,
        report.competencia,
        _csvCell(pagoEm),
        _csvCell(aluno.comprovanteUrl ?? ''),
        _csvCell(aluno.observacao ?? ''),
      ].join(',');
      buffer.writeln(row);
    }

    await _shareFile(
      bytes: Uint8List.fromList(buffer.toString().codeUnits),
      fileName: 'relatorio_${report.competencia}.csv',
      mimeType: 'text/csv',
      fallbackText: buffer.toString(),
      subject: 'Relatório mensal ${report.competencia}',
    );
  }

  Future<void> exportarCsvMensal(
    List<Aluno> alunos, {
    DateTime? referencia,
  }) async {
    final mesReferencia = referencia ?? DateTime.now();
    final competencia = Aluno.competenciaAtual(mesReferencia);
    final buffer = StringBuffer();
    buffer.writeln(
      'nome,telefone,dia_vencimento,valor,status,competencia,pago_em,comprovante,observacao',
    );

    for (final aluno in alunos) {
      final p = aluno.pagamentoDoMes(mesReferencia);
      final pagoEm = p.pagoEm == null
          ? ''
          : DateFormat('yyyy-MM-dd HH:mm').format(p.pagoEm!);
      final row = [
        _csvCell(aluno.nome),
        _csvCell(aluno.telefone),
        aluno.diaVencimento,
        p.valor.toStringAsFixed(2),
        p.status.name,
        competencia,
        _csvCell(pagoEm),
        _csvCell(p.comprovanteUrl ?? ''),
        _csvCell(p.observacao ?? ''),
      ].join(',');
      buffer.writeln(row);
    }

    await _shareFile(
      bytes: Uint8List.fromList(buffer.toString().codeUnits),
      fileName: 'relatorio_$competencia.csv',
      mimeType: 'text/csv',
      fallbackText: buffer.toString(),
      subject: 'Relatório mensal $competencia',
    );
  }

  Future<void> exportarPdfCompetencia(CompetenciaReportData report) async {
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dataGeracao = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final alunosOrdenados = [...report.alunosSnapshot]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    final pagos = alunosOrdenados.where((a) => a.pago).toList();
    final atrasados = alunosOrdenados
        .where((a) => a.status == PagamentoStatus.atrasado)
        .toList();
    final pendentes = alunosOrdenados
        .where((a) => a.status == PagamentoStatus.pendente)
        .toList();
    final recebido = pagos.fold<double>(0, (s, a) => s + a.valor);
    final previsto = alunosOrdenados.fold<double>(0, (s, a) => s + a.valor);
    const lineColor = PdfColor.fromInt(0xFFBDBDBD);
    const textMuted = PdfColor.fromInt(0xFF666666);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: lineColor, width: 0.8),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GymPix',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Relatorio mensal - Competencia ${report.competencia}',
                style: const pw.TextStyle(fontSize: 11, color: textMuted),
              ),
              pw.Text(
                'Gerado em $dataGeracao',
                style: const pw.TextStyle(fontSize: 10, color: textMuted),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: lineColor, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Totais',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Alunos: ${alunosOrdenados.length}  |  Pagos: ${pagos.length}  |  Pendentes: ${pendentes.length}  |  Atrasados: ${atrasados.length}',
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                  pw.Text(
                    'Previsto: ${moeda.format(previsto)}  |  Recebido: ${moeda.format(recebido)}',
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                ],
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Aluno',
              'Telefone',
              'Vencimento',
              'Valor',
              'Status',
              'Pago em',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: lineColor, width: 0.8),
                bottom: pw.BorderSide(color: lineColor, width: 0.8),
              ),
            ),
            headerHeight: 26,
            cellHeight: 26,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.8),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.3),
            },
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: lineColor, width: 0.4),
              ),
            ),
            data: alunosOrdenados.map((aluno) {
              return [
                aluno.nome,
                aluno.telefone.isEmpty ? '-' : aluno.telefone,
                'Dia ${aluno.diaVencimento}',
                moeda.format(aluno.valor),
                aluno.statusLabel,
                aluno.pagoEm == null
                    ? '-'
                    : DateFormat('dd/MM/yyyy').format(aluno.pagoEm!),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _shareFile(
      bytes: bytes,
      fileName: 'relatorio_${report.competencia}.pdf',
      mimeType: 'application/pdf',
      fallbackText:
          'Relatório em PDF não disponível no Web. Use a exportação CSV.',
      subject: 'Relatório mensal ${report.competencia}',
    );
  }

  Future<void> exportarPdfMensal(
    List<Aluno> alunos, {
    DateTime? referencia,
  }) async {
    final mesReferencia = referencia ?? DateTime.now();
    final competencia = Aluno.competenciaAtual(mesReferencia);
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dataGeracao = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final alunosOrdenados = [...alunos]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    final pagos = alunosOrdenados
        .where((a) => a.pagamentoDoMes(mesReferencia).pago)
        .toList();
    final atrasados = alunosOrdenados
        .where(
          (a) =>
              a.pagamentoDoMes(mesReferencia).status ==
              PagamentoStatus.atrasado,
        )
        .toList();
    final pendentes = alunosOrdenados
        .where(
          (a) =>
              a.pagamentoDoMes(mesReferencia).status ==
              PagamentoStatus.pendente,
        )
        .toList();
    final recebido = pagos.fold<double>(
      0,
      (s, a) => s + a.pagamentoDoMes(mesReferencia).valor,
    );
    final previsto = alunosOrdenados.fold<double>(
      0,
      (s, a) => s + a.pagamentoDoMes(mesReferencia).valor,
    );
    const lineColor = PdfColor.fromInt(0xFFBDBDBD);
    const textMuted = PdfColor.fromInt(0xFF666666);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: lineColor, width: 0.8),
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GymPix',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Relatorio mensal - Competencia $competencia',
                style: const pw.TextStyle(fontSize: 11, color: textMuted),
              ),
              pw.Text(
                'Gerado em $dataGeracao',
                style: const pw.TextStyle(fontSize: 10, color: textMuted),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: lineColor, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Totais',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Alunos: ${alunosOrdenados.length}  |  Pagos: ${pagos.length}  |  Pendentes: ${pendentes.length}  |  Atrasados: ${atrasados.length}',
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                  pw.Text(
                    'Previsto: ${moeda.format(previsto)}  |  Recebido: ${moeda.format(recebido)}',
                    style: const pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                ],
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Aluno',
              'Telefone',
              'Vencimento',
              'Valor',
              'Status',
              'Pago em',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: lineColor, width: 0.8),
                bottom: pw.BorderSide(color: lineColor, width: 0.8),
              ),
            ),
            headerHeight: 26,
            cellHeight: 26,
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.8),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(1.1),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.3),
            },
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: lineColor, width: 0.4),
              ),
            ),
            data: alunosOrdenados.map((aluno) {
              final p = aluno.pagamentoDoMes(mesReferencia);
              return [
                aluno.nome,
                aluno.telefone.isEmpty ? '-' : aluno.telefone,
                'Dia ${aluno.diaVencimento}',
                moeda.format(p.valor),
                p.statusLabel,
                p.pagoEm == null
                    ? '-'
                    : DateFormat('dd/MM/yyyy').format(p.pagoEm!),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _shareFile(
      bytes: bytes,
      fileName: 'relatorio_$competencia.pdf',
      mimeType: 'application/pdf',
      fallbackText:
          'Relatório em PDF não disponível no Web. Use a exportação CSV.',
      subject: 'Relatório mensal $competencia',
    );
  }

  Future<void> _shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String fallbackText,
    required String subject,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
        subject: subject,
        text: fallbackText,
      ),
    );
  }

  String _csvCell(String raw) {
    final escaped = raw.replaceAll('"', '""');
    return '"$escaped"';
  }
}
