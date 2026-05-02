import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../cobranca/models/cobranca_envio.dart';
import '../../../cobranca/models/cobranca_regua.dart';
import '../../../cobranca/providers/cobranca_regua_providers.dart';
import '../../models/aluno.dart';

class AlunoCobrancaPanelSheet extends ConsumerWidget {
  const AlunoCobrancaPanelSheet({super.key, required this.aluno});

  final Aluno aluno;

  static Future<void> show(BuildContext context, {required Aluno aluno}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingSm,
          AppTheme.spacingLg,
          AppTheme.spacingLg,
        ),
        child: AlunoCobrancaPanelSheet(aluno: aluno),
      ),
    );
  }

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final envioAsync = ref.watch(cobrancaEnviosAlunoProvider(aluno.id));
    final regua =
        ref.watch(cobrancaReguaConfigStreamProvider).value ??
        CobrancaReguaConfig.defaults;
    final agora = DateTime.now();
    final pagamento = aluno.pagamentoDoMes(agora);
    final vencimento = Aluno.dataVencimento(aluno.diaVencimento, agora);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Painel de cobran\u00e7a - ${aluno.nome}',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status atual: ${pagamento.statusLabel}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Compet\u00eancia ${pagamento.competencia} - Vencimento dia ${vencimento.day.toString().padLeft(2, '0')} - Valor ${_currencyFormatter.format(pagamento.valor)}',
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          'R\u00e9gua configurada',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: regua.passos
              .map(
                (passo) => Chip(
                  label: Text(
                    '${_offsetLabel(passo.diasRelativos)} - ${DateFormat('dd/MM').format(vencimento.add(Duration(days: passo.diasRelativos)))}',
                  ),
                  avatar: Icon(
                    passo.ativo
                        ? Icons.check_circle_outline
                        : Icons.block_outlined,
                    size: 16,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Hist\u00f3rico de envios',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Flexible(
          child: envioAsync.when(
            data: (envios) {
              if (envios.isEmpty) {
                return Center(
                  child: Text(
                    'Nenhum envio registrado para este aluno.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                itemCount: envios.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppTheme.spacingSm),
                itemBuilder: (context, index) {
                  final envio = envios[index];
                  return _EnvioTile(envio: envio);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Erro ao carregar envios: $e',
                style: textTheme.bodyMedium?.copyWith(color: scheme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _offsetLabel(int dias) {
    if (dias == 0) return 'D0';
    if (dias > 0) return 'D+$dias';
    return 'D$dias';
  }
}

class _EnvioTile extends StatelessWidget {
  const _EnvioTile({required this.envio});

  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final CobrancaEnvio envio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final resumo = envio.mensagem.replaceAll('\n', ' ');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_canalLabel(envio.canal)} - ${envio.statusLabel}',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _dateFormatter.format(envio.enviadoEm),
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Compet\u00eancia ${envio.competencia} - ${_offsetLabel(envio.diasRelativos)}',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            resumo,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _canalLabel(CobrancaCanal canal) {
    return switch (canal) {
      CobrancaCanal.manualCopia => 'Manual (c\u00f3pia)',
      CobrancaCanal.manualCompartilhamento => 'Manual (compartilhar)',
      CobrancaCanal.manualWhatsapp => 'Manual (WhatsApp)',
      CobrancaCanal.automacaoLocal => 'Automa\u00e7\u00e3o local',
      CobrancaCanal.automacaoPush => 'Automa\u00e7\u00e3o push',
    };
  }

  String _offsetLabel(int dias) {
    if (dias == 0) return 'D0';
    if (dias > 0) return 'D+$dias';
    return 'D$dias';
  }
}

extension on CobrancaEnvio {
  String get statusLabel {
    return switch (status) {
      PagamentoStatus.pago => 'Pago',
      PagamentoStatus.pendente => 'Pendente',
      PagamentoStatus.atrasado => 'Atrasado',
    };
  }
}
