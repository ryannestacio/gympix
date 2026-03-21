import '../../alunos/models/aluno.dart';
import '../../configuracoes/repository/config_repository.dart';
import '../models/cobranca_envio.dart';
import '../repository/cobranca_regua_repository.dart';
import 'cobranca_notification_service.dart';
import 'cobranca_regua_planner.dart';
import 'cobranca_template_service.dart';
import 'pix_payload_service.dart';

class CobrancaReguaAutomationService {
  CobrancaReguaAutomationService({
    required CobrancaReguaRepository reguaRepository,
    required ConfigRepository configRepository,
    required CobrancaReguaPlanner planner,
    required CobrancaTemplateService templateService,
    required CobrancaNotificationService notificationService,
    required PixPayloadService pixPayloadService,
  }) : _reguaRepository = reguaRepository,
       _configRepository = configRepository,
       _planner = planner,
       _templateService = templateService,
       _notificationService = notificationService,
       _pixPayloadService = pixPayloadService;

  final CobrancaReguaRepository _reguaRepository;
  final ConfigRepository _configRepository;
  final CobrancaReguaPlanner _planner;
  final CobrancaTemplateService _templateService;
  final CobrancaNotificationService _notificationService;
  final PixPayloadService _pixPayloadService;

  Future<int> processarHoje(List<Aluno> alunos, {DateTime? now}) async {
    final config = await _reguaRepository.getReguaConfig();
    final referencia = _dateOnly(now ?? DateTime.now());
    final acoes = _planner.planejarHoje(
      alunos: alunos,
      config: config,
      now: referencia,
    );
    if (acoes.isEmpty) return 0;

    final pixCode = (await _configRepository.getPixCode())?.trim() ?? '';
    var enviados = 0;

    for (final acao in acoes) {
      final exists = await _reguaRepository.hasAutomacaoRegistro(
        alunoId: acao.aluno.id,
        competencia: acao.competencia,
        diasRelativos: acao.diasRelativos,
        status: acao.pagamento.status,
      );
      if (exists) continue;

      final pixPayload = _buildPixPayload(
        pixCode: pixCode,
        aluno: acao.aluno,
        pagamento: acao.pagamento,
      );
      final cobrancaLink = _buildCobrancaLink(
        baseUrl: config.linkBaseUrl,
        aluno: acao.aluno,
        valor: acao.pagamento.valor,
        pixPayload: pixPayload,
      );
      final template = config.templateByStatus(acao.pagamento.status);
      final mensagem = _templateService.render(
        template: template,
        aluno: acao.aluno,
        pagamento: acao.pagamento,
        diasRelativos: acao.diasRelativos,
        competencia: acao.competencia,
        pixPayload: pixPayload,
        cobrancaLink: cobrancaLink,
      );

      final envio = CobrancaEnvio(
        alunoId: acao.aluno.id,
        competencia: acao.competencia,
        status: acao.pagamento.status,
        diasRelativos: acao.diasRelativos,
        canal: config.notificacaoPushAtiva
            ? CobrancaCanal.automacaoPush
            : CobrancaCanal.automacaoLocal,
        automatico: true,
        mensagem: mensagem,
        enviadoEm: referencia,
        templateUsado: template,
        pixPayload: pixPayload,
        cobrancaLink: cobrancaLink,
      );

      final docId = CobrancaReguaRepository.buildAutomacaoDocId(
        competencia: acao.competencia,
        diasRelativos: acao.diasRelativos,
        status: acao.pagamento.status,
      );
      await _reguaRepository.registrarEnvio(envio, customId: docId);

      if (config.notificacaoPushAtiva) {
        await _reguaRepository.enqueuePush(envio);
      }
      if (config.notificacaoLocalAtiva) {
        await _notificationService.notify(
          idempotencyKey: '${acao.aluno.id}::$docId',
          title: 'Lembrete de cobranca',
          body:
              '${acao.aluno.nome} (${acao.pagamento.statusLabel}) - ${acao.competencia.replaceAll('-', '/')}',
          payload: acao.aluno.id,
        );
      }
      enviados++;
    }

    return enviados;
  }

  String buildMensagemManual({
    required Aluno aluno,
    required String competencia,
    required PagamentoMensal pagamento,
    required int diasRelativos,
    required String pixPayload,
    required String cobrancaLink,
    required String template,
  }) {
    return _templateService.render(
      template: template,
      aluno: aluno,
      pagamento: pagamento,
      diasRelativos: diasRelativos,
      competencia: competencia,
      pixPayload: pixPayload,
      cobrancaLink: cobrancaLink,
    );
  }

  String buildCobrancaLink({
    required String baseUrl,
    required Aluno aluno,
    required double valor,
    required String pixPayload,
  }) {
    return _buildCobrancaLink(
      baseUrl: baseUrl,
      aluno: aluno,
      valor: valor,
      pixPayload: pixPayload,
    );
  }

  String _buildPixPayload({
    required String pixCode,
    required Aluno aluno,
    required PagamentoMensal pagamento,
  }) {
    if (pixCode.trim().isEmpty) return '';
    try {
      return _pixPayloadService.resolvePayload(
        pixCodeOrKey: pixCode,
        amount: pagamento.valor,
        merchantName: 'GYMPIX',
        merchantCity: 'BRASIL',
        txid: _buildTxid(aluno.id),
      );
    } catch (_) {
      return '';
    }
  }

  String _buildCobrancaLink({
    required String baseUrl,
    required Aluno aluno,
    required double valor,
    required String pixPayload,
  }) {
    if (baseUrl.trim().isEmpty) return '';
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null) return '';
    final withPath = uri.replace(
      path: '/cobranca',
      queryParameters: {
        'nome': aluno.nome,
        'pix': pixPayload,
        'valor': valor.toStringAsFixed(2),
      },
    );
    return withPath.toString();
  }

  String _buildTxid(String alunoId) {
    final normalized = alunoId.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalized.isEmpty) return 'GYMPIX';
    final suffix = normalized.length <= 18
        ? normalized
        : normalized.substring(normalized.length - 18);
    return 'RGUA$suffix';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
