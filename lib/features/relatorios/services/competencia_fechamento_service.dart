import '../models/competencia_report.dart';
import '../repository/competencia_fechamento_repository.dart';

class CompetenciaFechamentoService {
  CompetenciaFechamentoService(this._repository);

  final CompetenciaFechamentoRepository _repository;

  Future<void> fecharCompetencia(CompetenciaReportData report) async {
    final existente = await _repository.getFechamento(report.competencia);
    if (existente?.fechada == true) return;
    await _repository.salvarFechamento(report.toFechada());
  }
}
