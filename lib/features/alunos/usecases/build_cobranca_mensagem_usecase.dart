import '../../cobranca/services/cobranca_service.dart';
import '../models/aluno.dart';

class BuildCobrancaMensagemUseCase {
  BuildCobrancaMensagemUseCase({required CobrancaService cobrancaService})
    : _cobrancaService = cobrancaService;

  final CobrancaService _cobrancaService;

  Future<String> call({
    required Aluno aluno,
    required String pixPayload,
  }) async {
    return _cobrancaService.buildMensagemLembrete(
      aluno: aluno,
      pixCode: pixPayload,
    );
  }
}
