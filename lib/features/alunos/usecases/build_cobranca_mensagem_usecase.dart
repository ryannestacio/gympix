import '../../cobranca/services/cobranca_service.dart';
import '../../configuracoes/repository/config_repository.dart';
import '../models/aluno.dart';

abstract class CobrancaMessageConfigReader {
  Future<String?> getCustomCobrancaMessage();
}

class ConfigRepositoryCobrancaMessageReader
    implements CobrancaMessageConfigReader {
  ConfigRepositoryCobrancaMessageReader(this._configRepository);
  final ConfigRepository _configRepository;

  @override
  Future<String?> getCustomCobrancaMessage() {
    return _configRepository.getCustomCobrancaMessage();
  }
}

class BuildCobrancaMensagemUseCase {
  BuildCobrancaMensagemUseCase({
    required CobrancaMessageConfigReader configReader,
    required CobrancaService cobrancaService,
  }) : _configReader = configReader,
       _cobrancaService = cobrancaService;

  final CobrancaMessageConfigReader _configReader;
  final CobrancaService _cobrancaService;

  Future<String> call({
    required Aluno aluno,
    required String pixPayload,
  }) async {
    String? customPhrase;
    try {
      customPhrase = await _configReader.getCustomCobrancaMessage();
    } catch (_) {
      customPhrase = null;
    }

    return _cobrancaService.buildMensagemLembrete(
      aluno: aluno,
      pixCode: pixPayload,
      customPhrase: customPhrase,
    );
  }
}
