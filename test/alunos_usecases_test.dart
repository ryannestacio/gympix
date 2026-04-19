import 'package:flutter_test/flutter_test.dart';
import 'package:gympix/features/alunos/models/aluno.dart';
import 'package:gympix/features/alunos/usecases/aluno_cadastro_input.dart';
import 'package:gympix/features/alunos/usecases/build_cobranca_mensagem_usecase.dart';
import 'package:gympix/features/alunos/usecases/build_pix_payload_usecase.dart';
import 'package:gympix/features/alunos/usecases/salvar_aluno_usecase.dart';
import 'package:gympix/features/cobranca/services/cobranca_service.dart';
import 'package:gympix/features/cobranca/services/pix_payload_service.dart';

void main() {
  group('SalvarAlunoUseCase', () {
    test(
      'quando pago muda, sincroniza via setPago e nao faz sync do mes',
      () async {
        final repo = _FakeAlunosWriteRepository();
        final useCase = SalvarAlunoUseCase(repo);
        final original = _buildAlunoBase();

        await useCase.atualizar(
          original: original,
          input: const AlunoCadastroInput(
            nome: 'Aluno Editado',
            telefone: '(11) 99999-9999',
            observacao: 'obs',
            diaVencimento: 12,
            mensalidade: 120,
            pago: true,
          ),
        );

        expect(repo.updateCalls, 1);
        expect(repo.setPagoCalls, 1);
        expect(repo.syncCalls, 0);
        expect(repo.lastSetPagoValue, isTrue);
        expect(repo.updatedAluno?.nome, 'Aluno Editado');
      },
    );

    test(
      'quando mensalidade/vencimento mudam sem alterar pago, faz sync do mes',
      () async {
        final repo = _FakeAlunosWriteRepository();
        final useCase = SalvarAlunoUseCase(repo);
        final original = _buildAlunoBase();

        await useCase.atualizar(
          original: original,
          input: const AlunoCadastroInput(
            nome: 'Aluno Teste',
            telefone: '(11) 99999-9999',
            observacao: '',
            diaVencimento: 25,
            mensalidade: 180,
            pago: false,
          ),
        );

        expect(repo.updateCalls, 1);
        expect(repo.setPagoCalls, 0);
        expect(repo.syncCalls, 1);
        expect(repo.syncedAluno?.diaVencimento, 25);
        expect(repo.syncedAluno?.mensalidade, 180);
      },
    );
  });

  group('BuildPixPayloadUseCase', () {
    test('retorna null quando pix nao esta configurado', () async {
      final fakeReader = _FakePixConfigReader(pixCode: null);
      final fakeService = _FakePixPayloadService();
      final useCase = BuildPixPayloadUseCase(
        configReader: fakeReader,
        pixPayloadService: fakeService,
      );

      final result = await useCase.call(_buildAlunoBase());
      expect(result, isNull);
      expect(fakeService.called, isFalse);
    });

    test('gera payload com dados esperados', () async {
      final fakeReader = _FakePixConfigReader(pixCode: 'chave-pix');
      final fakeService = _FakePixPayloadService(returnValue: 'PIX_PAYLOAD');
      final useCase = BuildPixPayloadUseCase(
        configReader: fakeReader,
        pixPayloadService: fakeService,
      );

      final aluno = _buildAlunoBase().copyWith(id: 'abc-123');
      final result = await useCase.call(aluno);

      expect(result, 'PIX_PAYLOAD');
      expect(fakeService.called, isTrue);
      expect(fakeService.capturedPixCodeOrKey, 'chave-pix');
      expect(fakeService.capturedAmount, aluno.pagamentoDoMes().valor);
      expect(fakeService.capturedMerchantName, isNotEmpty);
      expect(fakeService.capturedMerchantCity, 'BRASIL');
      expect(fakeService.capturedTxid, startsWith('GYMPIX'));
    });
  });

  group('BuildCobrancaMensagemUseCase', () {
    test('inclui pix payload na mensagem', () async {
      final useCase = BuildCobrancaMensagemUseCase(
        cobrancaService: CobrancaService(),
      );

      final result = await useCase.call(
        aluno: _buildAlunoBase(),
        pixPayload: 'PIX-COPIA-COLA',
      );

      expect(result, contains('PIX-COPIA-COLA'));
    });
  });
}

Aluno _buildAlunoBase() {
  return Aluno(
    id: '1',
    nome: 'Aluno Teste',
    telefone: '(11) 99999-9999',
    observacao: '',
    diaVencimento: 10,
    mensalidade: 100,
    criadoEm: DateTime(2026, 1, 1),
    pagamentos: const {},
  );
}

class _FakeAlunosWriteRepository implements AlunosWriteRepository {
  int createCalls = 0;
  int updateCalls = 0;
  int setPagoCalls = 0;
  int syncCalls = 0;
  bool? lastSetPagoValue;
  Aluno? updatedAluno;
  Aluno? syncedAluno;

  @override
  Future<void> createAluno({
    required String nome,
    required String telefone,
    required String observacao,
    required int diaVencimento,
    required double mensalidade,
    required bool pago,
  }) async {
    createCalls++;
  }

  @override
  Future<void> setPago({
    required Aluno aluno,
    required bool pago,
    double? valor,
    String? comprovanteUrl,
    String? observacao,
    DateTime? pagoEm,
  }) async {
    setPagoCalls++;
    lastSetPagoValue = pago;
  }

  @override
  Future<void> syncPagamentoDoMesAtual(Aluno aluno) async {
    syncCalls++;
    syncedAluno = aluno;
  }

  @override
  Future<void> updateAluno(Aluno aluno) async {
    updateCalls++;
    updatedAluno = aluno;
  }
}

class _FakePixConfigReader implements PixConfigReader {
  _FakePixConfigReader({required this.pixCode});
  final String? pixCode;

  @override
  Future<String?> getPixCode() async => pixCode;
}

class _FakePixPayloadService extends PixPayloadService {
  _FakePixPayloadService({this.returnValue = 'payload'});

  final String returnValue;
  bool called = false;
  String? capturedPixCodeOrKey;
  double? capturedAmount;
  String? capturedMerchantName;
  String? capturedMerchantCity;
  String? capturedTxid;

  @override
  String resolvePayload({
    required String pixCodeOrKey,
    required double amount,
    required String merchantName,
    required String merchantCity,
    String txid = 'GYMPIX',
  }) {
    called = true;
    capturedPixCodeOrKey = pixCodeOrKey;
    capturedAmount = amount;
    capturedMerchantName = merchantName;
    capturedMerchantCity = merchantCity;
    capturedTxid = txid;
    return returnValue;
  }
}
