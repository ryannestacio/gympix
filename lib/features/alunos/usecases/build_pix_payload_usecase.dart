import '../../../core/constants/app_constants.dart';
import '../../cobranca/services/pix_payload_service.dart';
import '../../configuracoes/repository/config_repository.dart';
import '../models/aluno.dart';

abstract class PixConfigReader {
  Future<String?> getPixCode();
}

class ConfigRepositoryPixReader implements PixConfigReader {
  ConfigRepositoryPixReader(this._configRepository);
  final ConfigRepository _configRepository;

  @override
  Future<String?> getPixCode() {
    return _configRepository.getPixCode();
  }
}

class BuildPixPayloadUseCase {
  BuildPixPayloadUseCase({
    required PixConfigReader configReader,
    required PixPayloadService pixPayloadService,
    String merchantName = AppConstants.appName,
    String merchantCity = 'BRASIL',
  }) : _configReader = configReader,
       _pixPayloadService = pixPayloadService,
       _merchantName = merchantName,
       _merchantCity = merchantCity;

  final PixConfigReader _configReader;
  final PixPayloadService _pixPayloadService;
  final String _merchantName;
  final String _merchantCity;

  Future<String?> call(Aluno aluno) async {
    final pixKey = await _configReader.getPixCode();
    final normalized = (pixKey ?? '').trim();
    if (normalized.isEmpty) return null;

    return _pixPayloadService.resolvePayload(
      pixCodeOrKey: normalized,
      amount: aluno.pagamentoDoMes().valor,
      merchantName: _merchantName,
      merchantCity: _merchantCity,
      txid: _buildPixTxid(aluno.id),
    );
  }

  String _buildPixTxid(String alunoId) {
    final normalized = alunoId.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalized.isEmpty) return 'GYMPIX';
    final suffix = normalized.length <= 18
        ? normalized
        : normalized.substring(normalized.length - 18);
    return 'GYMPIX$suffix';
  }
}
