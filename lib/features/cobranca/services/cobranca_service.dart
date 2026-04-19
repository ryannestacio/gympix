import 'package:intl/intl.dart';

import '../../alunos/models/aluno.dart';

class CobrancaService {
  String buildMensagemLembrete({
    required Aluno aluno,
    required String pixCode,
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final pagamentoAtual = aluno.pagamentoDoMes();
    final competencia = Aluno.competenciaAtual().replaceAll('-', '/');
    final vencimento = aluno.diaVencimento.toString().padLeft(2, '0');
    final valor = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(pagamentoAtual.valor);
    final cabecalho = _buildOpeningMessage(
      aluno: aluno,
      referencia: referenceDate,
      competencia: competencia,
    );
    return '$cabecalho\n\n'
        'Aluno: ${aluno.nome}\n'
        'Vencimento: dia $vencimento\n'
        'Valor: $valor\n'
        'Forma de pagamento: Pix\n'
        'Competencia: $competencia\n'
        '\n'
        'Enviei o QR Code em anexo para facilitar o pagamento.\n'
        'Se preferir, voce tambem pode usar o Pix copia e cola abaixo:\n'
        '$pixCode\n\n'
        'Assim que o pagamento for realizado, se puder, envie o comprovante para confirmacao.\n\n'
        'Equipe GymPix';
  }

  String _buildOpeningMessage({
    required Aluno aluno,
    required DateTime referencia,
    required String competencia,
  }) {
    final diff = referencia.day - aluno.diaVencimento;
    if (diff > 0) {
      final dias = diff == 1 ? '1 dia' : '$diff dias';
      return 'Ola, ${aluno.nome}! Consta em nosso sistema que a sua mensalidade da academia referente a $competencia esta em atraso ha $dias. Para evitar juros e manter seu cadastro regularizado, pedimos que realize o pagamento o quanto antes.';
    }

    if (diff == 0) {
      return 'Ola, ${aluno.nome}! Passando para lembrar que a sua mensalidade da academia vence hoje. Para facilitar, ja estou enviando abaixo os dados do pagamento por Pix.';
    }

    final diasRestantes = aluno.diaVencimento - referencia.day;
    final diasTexto = diasRestantes == 1 ? '1 dia' : '$diasRestantes dias';
    return 'Ola, ${aluno.nome}! Estamos enviando sua cobranca de forma antecipada para facilitar sua organizacao. A mensalidade da academia referente a $competencia vence em $diasTexto, no dia ${aluno.diaVencimento.toString().padLeft(2, '0')}.';
  }
}
