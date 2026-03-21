import 'package:intl/intl.dart';

import '../../alunos/models/aluno.dart';

class CobrancaTemplateService {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  String render({
    required String template,
    required Aluno aluno,
    required PagamentoMensal pagamento,
    required int diasRelativos,
    required String competencia,
    required String pixPayload,
    required String cobrancaLink,
  }) {
    final diasLabel = _buildDiasLabel(diasRelativos);
    final valor = _currencyFormatter.format(pagamento.valor);
    final vencimento = pagamento.diaVencimento.toString().padLeft(2, '0');

    final map = <String, String>{
      '{nome}': aluno.nome,
      '{telefone}': aluno.telefone,
      '{competencia}': competencia.replaceAll('-', '/'),
      '{valor}': valor,
      '{vencimento}': vencimento,
      '{status}': pagamento.statusLabel,
      '{dias_label}': diasLabel,
      '{pix}': pixPayload,
      '{link}': cobrancaLink,
    };

    var mensagem = template.trim();
    if (mensagem.isEmpty) {
      mensagem =
          'Ola {nome}, sua mensalidade {competencia} no valor de {valor} '
          'vence/venceu dia {vencimento} ({dias_label}). Pix: {pix}';
    }

    for (final entry in map.entries) {
      mensagem = mensagem.replaceAll(entry.key, entry.value);
    }

    return mensagem.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  String _buildDiasLabel(int diasRelativos) {
    if (diasRelativos == 0) return 'hoje';
    if (diasRelativos < 0) {
      final dias = -diasRelativos;
      return dias == 1 ? 'em 1 dia' : 'em $dias dias';
    }
    return diasRelativos == 1 ? 'ha 1 dia' : 'ha $diasRelativos dias';
  }
}
