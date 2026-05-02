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
    final hoje = referenceDate.day.toString().padLeft(2, '0');
    final valor = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    ).format(pagamentoAtual.valor);

    final diff = referenceDate.day - aluno.diaVencimento;
    if (diff > 0) {
      final dias = diff == 1 ? '1 dia' : '$diff dias';
      return 'Ol\u00E1, ${aluno.nome}! \u{1F44B}\n\n'
          'Sua mensalidade est\u00E1 em atraso h\u00E1 $dias.\n\n'
          '\u{1F4B0} Valor: $valor\n'
          '\u{1F4C5} Vencimento: dia $vencimento\n'
          '\u{1F4CC} Compet\u00EAncia: $competencia\n\n'
          'Para evitar juros, pedimos que realize o pagamento o quanto antes.\n\n'
          'QR Code enviado \u{1F447}\n\n'
          'Ou Pix copia e cola:\n'
          '$pixCode\n\n'
          'Se j\u00E1 pagou, desconsidere \u{1F609}';
    }

    if (diff == 0) {
      return 'Ol\u00E1, ${aluno.nome}! \u{1F44B}\n\n'
          'Sua mensalidade vence hoje.\n\n'
          '\u{1F4B0} Valor: $valor\n'
          '\u{1F4C5} Vencimento: hoje ($hoje)\n'
          '\u{1F4CC} Compet\u00EAncia: $competencia\n\n'
          'O QR Code est\u00E1 anexado \u{1F447}\n\n'
          'Ou use o Pix copia e cola:\n'
          '$pixCode\n\n'
          'Qualquer d\u00FAvida, me chama \u{1F44D}';
    }

    final diasRestantes = aluno.diaVencimento - referenceDate.day;
    final diasTexto = diasRestantes == 1 ? '1 dia' : '$diasRestantes dias';
    return 'Ol\u00E1, ${aluno.nome}! \u{1F44B}\n\n'
        'Estamos antecipando sua cobran\u00E7a para te ajudar na organiza\u00E7\u00E3o.\n\n'
        '\u{1F4C5} Vencimento: dia $vencimento (em $diasTexto)\n'
        '\u{1F4B0} Valor: $valor\n'
        '\u{1F4CC} Compet\u00EAncia: $competencia\n\n'
        'O QR Code j\u00E1 foi enviado \u{1F447}\n\n'
        'Ou use o Pix copia e cola:\n'
        '$pixCode\n\n'
        'Se j\u00E1 pagou, pode ignorar \u{1F609}';
  }
}
