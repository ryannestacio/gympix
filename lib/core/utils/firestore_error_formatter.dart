import 'package:cloud_firestore/cloud_firestore.dart';

/// Formata exceoes do Firestore em mensagens humanizadas para o usuario final.
/// Padronizado conforme o modelo de _firebaseErrorMessage do AuthRepository.
String formatFirestoreError(Object error) {
  if (error is! FirebaseException) {
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  return switch (error.code) {
    // Rede e disponibilidade
    'unavailable' =>
      'Servico temporariamente indisponivel. Verifique sua conexao e tente novamente.',
    'deadline-exceeded' =>
      'Tempo de resposta excedido. Tentando novamente...',
    'network-request-failed' =>
      'Falha de rede. Verifique sua conexao e tente novamente.',

    // Autorizacao
    'permission-denied' => 'Voce nao tem permissao para realizar esta acao.',
    'unauthenticated' => 'Sessao expirada. Faca login novamente.',

    // Dados
    'not-found' => 'Registro nao encontrado. Ele pode ter sido removido.',
    'already-exists' => 'Registro ja existe no banco de dados.',
    'data-loss' => 'Erro de integridade de dados. Tente novamente.',

    // Concorrencia
    'aborted' =>
      'Operacao abortada por conflito. Verifique os dados e tente novamente.',
    'cancelled' => 'Operacao cancelada.',

    // Recursos
    'resource-exhausted' =>
      'Limite de operacoes excedido. Aguarde um momento e tente novamente.',
    'out-of-range' => 'Dados fora do formato esperado.',

    // Interno
    'internal' => 'Erro interno do servidor. Tente novamente mais tarde.',
    'unknown' => 'Ocorreu um erro inesperado. Tente novamente.',

    _ => 'Erro ao acessar dados. Tente novamente.',
  };
}
