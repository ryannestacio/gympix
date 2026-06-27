class AlunoCadastroInput {
  const AlunoCadastroInput({
    required this.nome,
    required this.telefone,
    required this.observacao,
    required this.diaVencimento,
    required this.mensalidade,
    required this.pago,
    this.matricula,
    this.senha,
  });

  final String nome;
  final String telefone;
  final String observacao;
  final int diaVencimento;
  final double mensalidade;
  final bool pago;
  final String? matricula;
  final String? senha;
}
