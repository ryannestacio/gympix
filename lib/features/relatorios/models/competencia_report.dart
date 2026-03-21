import '../../alunos/models/aluno.dart';

class CompetenciaReportItem {
  const CompetenciaReportItem({
    required this.alunoId,
    required this.nome,
    required this.telefone,
    required this.ativoNoFechamento,
    required this.diaVencimento,
    required this.valor,
    required this.status,
    this.pagoEm,
    this.comprovanteUrl,
    this.observacao,
  });

  final String alunoId;
  final String nome;
  final String telefone;
  final bool ativoNoFechamento;
  final int diaVencimento;
  final double valor;
  final PagamentoStatus status;
  final DateTime? pagoEm;
  final String? comprovanteUrl;
  final String? observacao;

  bool get pago => status == PagamentoStatus.pago;

  String get statusLabel {
    switch (status) {
      case PagamentoStatus.pago:
        return 'Pago';
      case PagamentoStatus.atrasado:
        return 'Atrasado';
      case PagamentoStatus.pendente:
        return 'Pendente';
    }
  }

  factory CompetenciaReportItem.fromAluno(Aluno aluno, DateTime referencia) {
    final pagamento = aluno.pagamentoDoMes(referencia);
    return CompetenciaReportItem(
      alunoId: aluno.id,
      nome: aluno.nome,
      telefone: aluno.telefone,
      ativoNoFechamento: aluno.ativo,
      diaVencimento: pagamento.diaVencimento,
      valor: pagamento.valor,
      status: pagamento.status,
      pagoEm: pagamento.pagoEm,
      comprovanteUrl: pagamento.comprovanteUrl,
      observacao: pagamento.observacao,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'alunoId': alunoId,
      'nome': nome,
      'telefone': telefone,
      'ativoNoFechamento': ativoNoFechamento,
      'diaVencimento': diaVencimento,
      'valor': valor,
      'status': status.name,
      'pagoEm': pagoEm?.toIso8601String(),
      'comprovanteUrl': comprovanteUrl,
      'observacao': observacao,
    };
  }

  factory CompetenciaReportItem.fromMap(Map<String, dynamic> map) {
    final statusName = map['status'] as String? ?? PagamentoStatus.pendente.name;
    final status = PagamentoStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => PagamentoStatus.pendente,
    );

    return CompetenciaReportItem(
      alunoId: map['alunoId'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      telefone: map['telefone'] as String? ?? '',
      ativoNoFechamento: map['ativoNoFechamento'] as bool? ?? true,
      diaVencimento: (map['diaVencimento'] as num?)?.toInt() ?? 1,
      valor: (map['valor'] as num?)?.toDouble() ?? 0,
      status: status,
      pagoEm: _parseDate(map['pagoEm']),
      comprovanteUrl: map['comprovanteUrl'] as String?,
      observacao: map['observacao'] as String?,
    );
  }
}

class CompetenciaReportTotals {
  const CompetenciaReportTotals({
    required this.totalAlunos,
    required this.pendentes,
    required this.atrasados,
    required this.recebidoMes,
    required this.previstoMes,
    required this.inadimplenciaPercent,
  });

  final int totalAlunos;
  final int pendentes;
  final int atrasados;
  final double recebidoMes;
  final double previstoMes;
  final double inadimplenciaPercent;

  factory CompetenciaReportTotals.fromAlunos(
    List<Aluno> alunos,
    DateTime referencia,
  ) {
    final pagamentosMes = alunos.map((a) => a.pagamentoDoMes(referencia)).toList();

    final pendentes = pagamentosMes
        .where((p) => p.status == PagamentoStatus.pendente)
        .length;
    final atrasados = pagamentosMes
        .where((p) => p.status == PagamentoStatus.atrasado)
        .length;
    final recebidoMes = pagamentosMes
        .where((p) => p.status == PagamentoStatus.pago)
        .fold<double>(0, (s, p) => s + p.valor);
    final previstoMes = pagamentosMes.fold<double>(0, (s, p) => s + p.valor);
    final totalNaoPago = pendentes + atrasados;
    final inadimplenciaPercent = alunos.isEmpty
        ? 0.0
        : (totalNaoPago / alunos.length) * 100.0;

    return CompetenciaReportTotals(
      totalAlunos: alunos.length,
      pendentes: pendentes,
      atrasados: atrasados,
      recebidoMes: recebidoMes,
      previstoMes: previstoMes,
      inadimplenciaPercent: inadimplenciaPercent,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'totalAlunos': totalAlunos,
      'pendentes': pendentes,
      'atrasados': atrasados,
      'recebidoMes': recebidoMes,
      'previstoMes': previstoMes,
      'inadimplenciaPercent': inadimplenciaPercent,
    };
  }

  factory CompetenciaReportTotals.fromMap(Map<String, dynamic> map) {
    return CompetenciaReportTotals(
      totalAlunos: (map['totalAlunos'] as num?)?.toInt() ?? 0,
      pendentes: (map['pendentes'] as num?)?.toInt() ?? 0,
      atrasados: (map['atrasados'] as num?)?.toInt() ?? 0,
      recebidoMes: (map['recebidoMes'] as num?)?.toDouble() ?? 0,
      previstoMes: (map['previstoMes'] as num?)?.toDouble() ?? 0,
      inadimplenciaPercent:
          (map['inadimplenciaPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CompetenciaReportData {
  const CompetenciaReportData({
    required this.competencia,
    required this.totais,
    required this.alunosSnapshot,
    this.fechada = false,
    this.fechadoEm,
    this.schemaVersion = 1,
  });

  final String competencia;
  final bool fechada;
  final DateTime? fechadoEm;
  final int schemaVersion;
  final CompetenciaReportTotals totais;
  final List<CompetenciaReportItem> alunosSnapshot;

  factory CompetenciaReportData.fromLive({
    required DateTime referencia,
    required List<Aluno> alunosDashboard,
    required List<Aluno> alunosFechamento,
  }) {
    final competencia = Aluno.competenciaAtual(referencia);
    final itens = alunosFechamento
        .map((aluno) => CompetenciaReportItem.fromAluno(aluno, referencia))
        .toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return CompetenciaReportData(
      competencia: competencia,
      totais: CompetenciaReportTotals.fromAlunos(alunosDashboard, referencia),
      alunosSnapshot: itens,
    );
  }

  CompetenciaReportData toFechada([DateTime? now]) {
    return CompetenciaReportData(
      competencia: competencia,
      fechada: true,
      fechadoEm: now ?? DateTime.now(),
      schemaVersion: schemaVersion,
      totais: totais,
      alunosSnapshot: alunosSnapshot,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'competencia': competencia,
      'status': fechada ? 'fechado' : 'aberto',
      'fechadoEm': fechadoEm?.toIso8601String(),
      'schemaVersion': schemaVersion,
      'totais': totais.toMap(),
      'alunosSnapshot': alunosSnapshot.map((item) => item.toMap()).toList(),
    };
  }

  factory CompetenciaReportData.fromFirestore(Map<String, dynamic> map) {
    final rawItens = map['alunosSnapshot'];
    final itens = <CompetenciaReportItem>[];

    if (rawItens is List) {
      for (final item in rawItens) {
        if (item is Map<String, dynamic>) {
          itens.add(CompetenciaReportItem.fromMap(item));
        } else if (item is Map) {
          itens.add(CompetenciaReportItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return CompetenciaReportData(
      competencia: map['competencia'] as String? ?? '',
      fechada: (map['status'] as String? ?? '') == 'fechado',
      fechadoEm: _parseDate(map['fechadoEm']),
      schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      totais: CompetenciaReportTotals.fromMap(
        Map<String, dynamic>.from(map['totais'] as Map? ?? const {}),
      ),
      alunosSnapshot: itens,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
