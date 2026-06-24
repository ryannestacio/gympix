import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gympix/features/alunos/controllers/alunos_actions_controller.dart';
import 'package:gympix/features/alunos/models/aluno.dart';
import 'package:gympix/features/alunos/ui/widgets/aluno_card.dart';
import 'package:gympix/core/domain/inadimplencia_config.dart';
import 'package:gympix/features/configuracoes/providers/config_providers.dart';
import 'package:gympix/features/alunos/usecases/aluno_cadastro_input.dart';
import 'package:gympix/features/alunos/providers/alunos_providers.dart';

class FakeAlunosActionsController implements AlunosActionsController {
  bool quitarPendenciasAcumuladasChamado = false;
  Aluno? ultimoAlunoQuitacao;

  @override
  Future<void> quitarPendenciasAcumuladas(Aluno aluno, {String? operationId}) async {
    quitarPendenciasAcumuladasChamado = true;
    ultimoAlunoQuitacao = aluno;
  }

  @override
  Future<void> criarAluno(AlunoCadastroInput input, {String? operationId}) async {}

  @override
  Future<void> atualizarAluno({
    required Aluno original,
    required AlunoCadastroInput input,
    String? operationId,
  }) async {}

  @override
  Future<void> registrarPagamento({
    required Aluno aluno,
    required double valor,
    required DateTime pagoEm,
    String? comprovanteUrl,
    String? observacao,
    String? operationId,
  }) async {}

  @override
  Future<void> desfazerPagamento(Aluno aluno, {String? operationId}) async {}

  @override
  Future<void> inativarAluno(String id, {String? operationId}) async {}

  @override
  Future<void> ativarAluno(String id, {String? operationId}) async {}

  @override
  Future<String?> gerarPixPayload(Aluno aluno) async => 'FAKE_PIX';

  @override
  Future<String> montarMensagemCobranca({
    required Aluno aluno,
    required String pixPayload,
  }) async => 'FAKE_MESSAGE';
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets(
    'aluno com mes atual pago e 1 pendencia retroativa; clicar em Quitar 1 pendencia abre dialog e executa quitacao',
    (WidgetTester tester) async {
      final now = DateTime.now();
      final lastMonthDate = DateTime(now.year, now.month - 1);
      final currentMonthCompetencia = Aluno.competenciaAtual(now);
      final lastMonthCompetencia = Aluno.competenciaAtual(lastMonthDate);

      final aluno = Aluno(
        id: 'student_123',
        nome: 'Aluno Teste',
        telefone: '(11) 99999-9999',
        observacao: '',
        diaVencimento: 10,
        mensalidade: 60.0,
        criadoEm: lastMonthDate,
        pagamentos: {
          currentMonthCompetencia: PagamentoMensal(
            competencia: currentMonthCompetencia,
            valor: 60.0,
            status: PagamentoStatus.pago,
            diaVencimento: 10,
            pagoEm: now,
          ),
          lastMonthCompetencia: PagamentoMensal(
            competencia: lastMonthCompetencia,
            valor: 60.0,
            status: PagamentoStatus.pendente,
            diaVencimento: 10,
          ),
        },
        ativo: true,
      );

      final fakeController = FakeAlunosActionsController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inadimplenciaConfigStreamProvider.overrideWith(
              (ref) => Stream.value(InadimplenciaConfig.defaults),
            ),
            alunosActionsControllerProvider.overrideWithValue(fakeController),
            alunoProvider(aluno.id).overrideWithValue(aluno),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AlunoCard(
                  alunoId: aluno.id,
                  defaultMensalidade: 60.0,
                  onSynced: () {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica se o botao "Quitar 1 pendencia" esta na tela (com ou sem acento, usando RegExp ou unicode)
      final buttonFinder = find.textContaining('Quitar 1 pend');
      expect(buttonFinder, findsOneWidget);

      // Clica no botao de quitacao
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Verifica se o dialog de confirmacao abriu
      expect(find.text('Quitar pend\u00eancias acumuladas'), findsOneWidget);
      expect(
        find.textContaining('Quitar 1 compet\u00eancia em aberto de Aluno Teste'),
        findsOneWidget,
      );

      // Clica no botao "Quitar" dentro do dialog
      final confirmButtonFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Quitar'),
      );
      expect(confirmButtonFinder, findsOneWidget);

      await tester.tap(confirmButtonFinder);
      await tester.pumpAndSettle();

      // Verifica se o controller foi acionado
      expect(fakeController.quitarPendenciasAcumuladasChamado, isTrue);
      expect(fakeController.ultimoAlunoQuitacao?.id, 'student_123');
    },
  );
}
