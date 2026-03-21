import '../models/aluno.dart';
import '../repository/alunos_repository.dart';
import 'aluno_cadastro_input.dart';

abstract class AlunosWriteRepository {
  Future<void> createAluno({
    required String nome,
    required String telefone,
    required String observacao,
    required int diaVencimento,
    required double mensalidade,
    required bool pago,
  });

  Future<void> updateAluno(Aluno aluno);

  Future<void> setPago({
    required Aluno aluno,
    required bool pago,
    double? valor,
    String? comprovanteUrl,
    String? observacao,
    DateTime? pagoEm,
  });

  Future<void> syncPagamentoDoMesAtual(Aluno aluno);
}

class AlunosRepositoryWriteAdapter implements AlunosWriteRepository {
  AlunosRepositoryWriteAdapter(this._repository);
  final AlunosRepository _repository;

  @override
  Future<void> createAluno({
    required String nome,
    required String telefone,
    required String observacao,
    required int diaVencimento,
    required double mensalidade,
    required bool pago,
  }) {
    return _repository.createAluno(
      nome: nome,
      telefone: telefone,
      observacao: observacao,
      diaVencimento: diaVencimento,
      mensalidade: mensalidade,
      pago: pago,
    );
  }

  @override
  Future<void> setPago({
    required Aluno aluno,
    required bool pago,
    double? valor,
    String? comprovanteUrl,
    String? observacao,
    DateTime? pagoEm,
  }) {
    return _repository.setPago(
      aluno: aluno,
      pago: pago,
      valor: valor,
      comprovanteUrl: comprovanteUrl,
      observacao: observacao,
      pagoEm: pagoEm,
    );
  }

  @override
  Future<void> syncPagamentoDoMesAtual(Aluno aluno) {
    return _repository.syncPagamentoDoMesAtual(aluno);
  }

  @override
  Future<void> updateAluno(Aluno aluno) {
    return _repository.updateAluno(aluno);
  }
}

class SalvarAlunoUseCase {
  SalvarAlunoUseCase(this._repository);

  final AlunosWriteRepository _repository;

  Future<void> criar(AlunoCadastroInput input) {
    return _repository.createAluno(
      nome: input.nome,
      telefone: input.telefone,
      observacao: input.observacao,
      diaVencimento: input.diaVencimento,
      mensalidade: input.mensalidade,
      pago: input.pago,
    );
  }

  Future<void> atualizar({
    required Aluno original,
    required AlunoCadastroInput input,
  }) async {
    final atualizado = original.copyWith(
      nome: input.nome,
      telefone: input.telefone,
      observacao: input.observacao,
      diaVencimento: input.diaVencimento,
      mensalidade: input.mensalidade,
    );

    final mensalidadeMudou = input.mensalidade != original.mensalidade;
    final vencimentoMudou = input.diaVencimento != original.diaVencimento;

    await _repository.updateAluno(atualizado);

    if (input.pago != original.pago) {
      await _repository.setPago(aluno: atualizado, pago: input.pago);
      return;
    }

    if (mensalidadeMudou || vencimentoMudou) {
      await _repository.syncPagamentoDoMesAtual(atualizado);
    }
  }
}
