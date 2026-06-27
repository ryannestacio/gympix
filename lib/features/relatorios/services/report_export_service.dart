import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../alunos/models/aluno.dart';
import '../models/competencia_report.dart';

class ReportExportService {
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

    const lineColor = PdfColor.fromInt(0xFFE2E8F0);
    const textMuted = PdfColor.fromInt(0xFF718096);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GymPix',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF0F172A),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Relatorio Financeiro - Competencia ${report.competencia}',
                    style: const pw.TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Gerado em $dataGeracao',
                    style: const pw.TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
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
            children: [
              pw.Text(
                'GymPix - Controle de mensalidades de academia',
                style: const pw.TextStyle(fontSize: 8, color: textMuted),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Destaques financeiros (KPIs)
          _buildKpiSection(
            previsto: previsto,
            recebido: recebido,
            totalAlunos: alunosOrdenados.length,
            pagos: pagos.length,
            pendentes: pendentes.length,
            atrasados: atrasados.length,
            inadimplencia: report.totais.inadimplenciaPercent,
            moeda: moeda,
          ),
          pw.SizedBox(height: 10),
          // Tabela de Alunos
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
              color: const PdfColor.fromInt(0xFF1E293B),
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9),
              border: pw.Border(
                top: pw.BorderSide(color: lineColor, width: 1),
                bottom: pw.BorderSide(color: lineColor, width: 1),
              ),
            ),
            headerHeight: 28,
            cellHeight: 28,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.4),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(1.5), // Aumentado para evitar quebra de "Vencimento"
              3: const pw.FlexColumnWidth(1.1),
              4: const pw.FlexColumnWidth(1.3),
              5: const pw.FlexColumnWidth(1.3),
            },
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: lineColor, width: 0.5),
              ),
            ),
            data: alunosOrdenados.map((aluno) {
              final statusColor = switch (aluno.status) {
                PagamentoStatus.pago => const PdfColor.fromInt(0xFF15803D), // Verde
                PagamentoStatus.atrasado => const PdfColor.fromInt(0xFFB91C1C), // Vermelho
                PagamentoStatus.pendente => const PdfColor.fromInt(0xFFB45309), // Laranja
              };

              return [
                aluno.nome,
                aluno.telefone.isEmpty ? '-' : aluno.telefone,
                'Dia ${aluno.diaVencimento}',
                moeda.format(aluno.valor),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      aluno.statusLabel,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
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
      fallbackText: 'Relatorio mensal ${report.competencia} em PDF.',
      subject: 'Relatorio mensal ${report.competencia}',
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

    final inadimplencia = alunosOrdenados.isEmpty
        ? 0.0
        : (atrasados.length / alunosOrdenados.length) * 100;

    const lineColor = PdfColor.fromInt(0xFFE2E8F0);
    const textMuted = PdfColor.fromInt(0xFF718096);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GymPix',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF0F172A),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Relatorio Financeiro - Competencia $competencia',
                    style: const pw.TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Gerado em $dataGeracao',
                    style: const pw.TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
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
            children: [
              pw.Text(
                'GymPix - Controle de mensalidades de academia',
                style: const pw.TextStyle(fontSize: 8, color: textMuted),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Destaques financeiros (KPIs)
          _buildKpiSection(
            previsto: previsto,
            recebido: recebido,
            totalAlunos: alunosOrdenados.length,
            pagos: pagos.length,
            pendentes: pendentes.length,
            atrasados: atrasados.length,
            inadimplencia: inadimplencia,
            moeda: moeda,
          ),
          pw.SizedBox(height: 10),
          // Tabela de Alunos
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
              color: const PdfColor.fromInt(0xFF1E293B),
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9),
              border: pw.Border(
                top: pw.BorderSide(color: lineColor, width: 1),
                bottom: pw.BorderSide(color: lineColor, width: 1),
              ),
            ),
            headerHeight: 28,
            cellHeight: 28,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.4),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(1.5), // Aumentado para evitar quebra de "Vencimento"
              3: const pw.FlexColumnWidth(1.1),
              4: const pw.FlexColumnWidth(1.3),
              5: const pw.FlexColumnWidth(1.3),
            },
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: lineColor, width: 0.5),
              ),
            ),
            data: alunosOrdenados.map((aluno) {
              final p = aluno.pagamentoDoMes(mesReferencia);
              final statusColor = switch (p.status) {
                PagamentoStatus.pago => const PdfColor.fromInt(0xFF15803D),
                PagamentoStatus.atrasado => const PdfColor.fromInt(0xFFB91C1C),
                PagamentoStatus.pendente => const PdfColor.fromInt(0xFFB45309),
              };

              return [
                aluno.nome,
                aluno.telefone.isEmpty ? '-' : aluno.telefone,
                'Dia ${aluno.diaVencimento}',
                moeda.format(p.valor),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      p.statusLabel,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
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
      fallbackText: 'Relatorio mensal $competencia em PDF.',
      subject: 'Relatorio mensal $competencia',
    );
  }

  Future<void> exportarPdfCadastroGeral(List<Aluno> alunos) async {
    final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dataGeracao = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final alunosOrdenados = [...alunos]
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    final totalCadastrados = alunosOrdenados.length;
    final ativos = alunosOrdenados.where((a) => a.ativo).toList().length;
    final inativos = totalCadastrados - ativos;

    const lineColor = PdfColor.fromInt(0xFFE2E8F0);
    const textMuted = PdfColor.fromInt(0xFF718096);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 20),
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GymPix',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF0F172A),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Ficha Cadastral Geral de Alunos',
                    style: const pw.TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Gerado em $dataGeracao',
                    style: const pw.TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
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
            children: [
              pw.Text(
                'GymPix - Cadastro Geral de Alunos',
                style: const pw.TextStyle(fontSize: 8, color: textMuted),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ),
        build: (context) => [
          // Destaques de cadastro
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                _buildKpiCard('Total Cadastrados', '$totalCadastrados alunos', color: const PdfColor.fromInt(0xFF2563EB)),
                pw.SizedBox(width: 14),
                _buildKpiCard('Alunos Ativos', '$ativos ativos', color: const PdfColor.fromInt(0xFF16A34A)),
                pw.SizedBox(width: 14),
                _buildKpiCard('Alunos Inativos', '$inativos inativos', color: const PdfColor.fromInt(0xFFDC2626)),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          // Tabela de Alunos
          pw.TableHelper.fromTextArray(
            headers: const [
              'Matricula',
              'Aluno',
              'Telefone',
              'Vencimento',
              'Mensalidade',
              'Situacao',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: const PdfColor.fromInt(0xFF1E293B),
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9),
              border: pw.Border(
                top: pw.BorderSide(color: lineColor, width: 1),
                bottom: pw.BorderSide(color: lineColor, width: 1),
              ),
            ),
            headerHeight: 28,
            cellHeight: 28,
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(2.4),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FlexColumnWidth(1.5), // Vencimento aumentado para 1.5
              4: const pw.FlexColumnWidth(1.3),
              5: const pw.FlexColumnWidth(1.2),
            },
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: lineColor, width: 0.5),
              ),
            ),
            data: alunosOrdenados.map((aluno) {
              final statusColor = aluno.ativo
                  ? const PdfColor.fromInt(0xFF15803D) // Verde
                  : const PdfColor.fromInt(0xFFB91C1C); // Vermelho
              final situacaoLabel = aluno.ativo ? 'Ativo' : 'Inativo';

              return [
                aluno.matricula ?? '-',
                aluno.nome,
                aluno.telefone.isEmpty ? '-' : aluno.telefone,
                'Dia ${aluno.diaVencimento}',
                moeda.format(aluno.mensalidade),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 7,
                      height: 7,
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      situacaoLabel,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _shareFile(
      bytes: bytes,
      fileName: 'cadastro_geral_alunos.pdf',
      mimeType: 'application/pdf',
      fallbackText: 'Ficha Cadastral Geral de Alunos em PDF.',
      subject: 'Ficha Cadastral Geral de Alunos',
    );
  }

  pw.Widget _buildKpiSection({
    required double previsto,
    required double recebido,
    required int totalAlunos,
    required int pagos,
    required int pendentes,
    required int atrasados,
    required double inadimplencia,
    required NumberFormat moeda,
  }) {
    final emAberto = previsto - recebido;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _buildKpiCard('Total Alunos', '$totalAlunos ativos', color: const PdfColor.fromInt(0xFF2563EB)),
          _buildKpiCard('Faturamento Previsto', moeda.format(previsto)),
          _buildKpiCard('Recebido', moeda.format(recebido), color: const PdfColor.fromInt(0xFF16A34A)),
          _buildKpiCard('Em Aberto', moeda.format(emAberto > 0 ? emAberto : 0), color: const PdfColor.fromInt(0xFFD97706)),
          _buildKpiCard('Inadimplencia', '${inadimplencia.toStringAsFixed(0)}%', color: const PdfColor.fromInt(0xFFDC2626)),
        ],
      ),
    );
  }

  pw.Widget _buildKpiCard(String label, String value, {PdfColor? color}) {
    return pw.Container(
      width: 104,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 6.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color ?? const PdfColor.fromInt(0xFF0F172A),
            ),
          ),
        ],
      ),
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
}
