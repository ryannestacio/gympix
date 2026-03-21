import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/operation_lock.dart';
import '../../cobranca/services/cobranca_service.dart';
import '../../cobranca/services/pix_payload_service.dart';
import '../../configuracoes/providers/config_providers.dart';
import '../models/aluno.dart';
import '../providers/alunos_providers.dart';
import '../repository/alunos_repository.dart';
import '../usecases/aluno_cadastro_input.dart';
import '../usecases/build_cobranca_mensagem_usecase.dart';
import '../usecases/build_pix_payload_usecase.dart';
import '../usecases/salvar_aluno_usecase.dart';

final alunosActionsControllerProvider = Provider<AlunosActionsController>((
  ref,
) {
  final alunosRepository = ref.watch(alunosRepositoryProvider);
  final configRepository = ref.watch(configRepositoryProvider);

  return AlunosActionsController(
    salvarAlunoUseCase: SalvarAlunoUseCase(
      AlunosRepositoryWriteAdapter(alunosRepository),
    ),
    buildPixPayloadUseCase: BuildPixPayloadUseCase(
      configReader: ConfigRepositoryPixReader(configRepository),
      pixPayloadService: const PixPayloadService(),
    ),
    buildCobrancaMensagemUseCase: BuildCobrancaMensagemUseCase(
      configReader: ConfigRepositoryCobrancaMessageReader(configRepository),
      cobrancaService: CobrancaService(),
    ),
    repository: alunosRepository,
  );
});

class AlunosActionsController {
  AlunosActionsController({
    required SalvarAlunoUseCase salvarAlunoUseCase,
    required BuildPixPayloadUseCase buildPixPayloadUseCase,
    required BuildCobrancaMensagemUseCase buildCobrancaMensagemUseCase,
    required AlunosRepository repository,
    OperationLock? operationLock,
  }) : _salvarAlunoUseCase = salvarAlunoUseCase,
       _buildPixPayloadUseCase = buildPixPayloadUseCase,
       _buildCobrancaMensagemUseCase = buildCobrancaMensagemUseCase,
       _repository = repository,
       _operationLock = operationLock ?? OperationLock();

  final SalvarAlunoUseCase _salvarAlunoUseCase;
  final BuildPixPayloadUseCase _buildPixPayloadUseCase;
  final BuildCobrancaMensagemUseCase _buildCobrancaMensagemUseCase;
  final AlunosRepository _repository;
  final OperationLock _operationLock;

  Future<void> criarAluno(AlunoCadastroInput input, {String? operationId}) {
    return _runLocked(
      operationId ?? _createAlunoOperationId(input),
      () => _salvarAlunoUseCase.criar(input),
    );
  }

  Future<void> atualizarAluno({
    required Aluno original,
    required AlunoCadastroInput input,
    String? operationId,
  }) {
    return _runLocked(
      operationId ?? 'aluno:update:${original.id}',
      () => _salvarAlunoUseCase.atualizar(original: original, input: input),
    );
  }

  Future<void> registrarPagamento({
    required Aluno aluno,
    required double valor,
    required DateTime pagoEm,
    String? comprovanteUrl,
    String? observacao,
    String? operationId,
  }) {
    return _runLocked(
      operationId ??
          'aluno:pagamento:registrar:${aluno.id}:${Aluno.competenciaAtual()}',
      () => _repository.setPago(
        aluno: aluno,
        pago: true,
        valor: valor,
        pagoEm: pagoEm,
        comprovanteUrl: comprovanteUrl,
        observacao: observacao,
      ),
    );
  }

  Future<void> desfazerPagamento(Aluno aluno, {String? operationId}) {
    return _runLocked(
      operationId ??
          'aluno:pagamento:desfazer:${aluno.id}:${Aluno.competenciaAtual()}',
      () => _repository.setPago(aluno: aluno, pago: false),
    );
  }

  Future<void> inativarAluno(String id, {String? operationId}) {
    return _runLocked(
      operationId ?? 'aluno:inativar:$id',
      () => _repository.archiveAluno(id),
    );
  }

  Future<void> ativarAluno(String id, {String? operationId}) {
    return _runLocked(
      operationId ?? 'aluno:ativar:$id',
      () => _repository.unarchiveAluno(id),
    );
  }

  Future<String?> gerarPixPayload(Aluno aluno) {
    return _buildPixPayloadUseCase.call(aluno);
  }

  Future<String> montarMensagemCobranca({
    required Aluno aluno,
    required String pixPayload,
  }) {
    return _buildCobrancaMensagemUseCase.call(
      aluno: aluno,
      pixPayload: pixPayload,
    );
  }

  String _createAlunoOperationId(AlunoCadastroInput input) {
    final nome = input.nome.trim().toLowerCase();
    final telefone = input.telefone.replaceAll(RegExp(r'\D'), '');
    final observacao = input.observacao.trim().toLowerCase();
    final mensalidade = input.mensalidade.toStringAsFixed(2);
    return 'aluno:criar:$nome|$telefone|$observacao|${input.diaVencimento}|$mensalidade|${input.pago}';
  }

  Future<void> _runLocked(String operationId, Future<void> Function() action) {
    return _operationLock.run(operationId, action);
  }
}
