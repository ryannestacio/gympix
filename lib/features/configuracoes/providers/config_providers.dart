import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/inadimplencia_config.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cobranca/models/cobranca_regua.dart';
import '../repository/config_repository.dart';

part 'config_providers.g.dart';

@riverpod
ConfigRepository configRepository(Ref ref) {
  final session = ref.watch(authSessionProvider);
  if (session == null) {
    throw StateError('Sessao invalida para acessar configuracoes.');
  }
  return ConfigRepository(ref.watch(firestoreProvider), session.tenantId);
}

@riverpod
Stream<String?> pixCodeStream(Ref ref) {
  return ref.watch(configRepositoryProvider).watchPixCode();
}

@riverpod
Stream<double?> defaultMensalidadeStream(Ref ref) {
  return ref.watch(configRepositoryProvider).watchDefaultMensalidade();
}

@riverpod
Stream<CobrancaReguaConfig> cobrancaReguaConfigStream(Ref ref) {
  return ref.watch(configRepositoryProvider).watchCobrancaReguaConfig();
}

@riverpod
Stream<InadimplenciaConfig> inadimplenciaConfigStream(Ref ref) {
  return ref.watch(configRepositoryProvider).watchInadimplenciaConfig();
}
