// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(configRepository)
final configRepositoryProvider = ConfigRepositoryProvider._();

final class ConfigRepositoryProvider
    extends
        $FunctionalProvider<
          ConfigRepository,
          ConfigRepository,
          ConfigRepository
        >
    with $Provider<ConfigRepository> {
  ConfigRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configRepositoryHash();

  @$internal
  @override
  $ProviderElement<ConfigRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConfigRepository create(Ref ref) {
    return configRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfigRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfigRepository>(value),
    );
  }
}

String _$configRepositoryHash() => r'6a48c7c5e81086c89911a66818b1e02558f2a26f';

@ProviderFor(pixCodeStream)
final pixCodeStreamProvider = PixCodeStreamProvider._();

final class PixCodeStreamProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  PixCodeStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pixCodeStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pixCodeStreamHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return pixCodeStream(ref);
  }
}

String _$pixCodeStreamHash() => r'6820b04f6055791f6471653fd14ba5293393c8eb';

@ProviderFor(defaultMensalidadeStream)
final defaultMensalidadeStreamProvider = DefaultMensalidadeStreamProvider._();

final class DefaultMensalidadeStreamProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, Stream<double?>>
    with $FutureModifier<double?>, $StreamProvider<double?> {
  DefaultMensalidadeStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultMensalidadeStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultMensalidadeStreamHash();

  @$internal
  @override
  $StreamProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double?> create(Ref ref) {
    return defaultMensalidadeStream(ref);
  }
}

String _$defaultMensalidadeStreamHash() =>
    r'e80c46cf104f407cfbc4b42d1828e5039aac2d9f';

@ProviderFor(cobrancaReguaConfigStream)
final cobrancaReguaConfigStreamProvider = CobrancaReguaConfigStreamProvider._();

final class CobrancaReguaConfigStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<CobrancaReguaConfig>,
          CobrancaReguaConfig,
          Stream<CobrancaReguaConfig>
        >
    with
        $FutureModifier<CobrancaReguaConfig>,
        $StreamProvider<CobrancaReguaConfig> {
  CobrancaReguaConfigStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cobrancaReguaConfigStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cobrancaReguaConfigStreamHash();

  @$internal
  @override
  $StreamProviderElement<CobrancaReguaConfig> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<CobrancaReguaConfig> create(Ref ref) {
    return cobrancaReguaConfigStream(ref);
  }
}

String _$cobrancaReguaConfigStreamHash() =>
    r'b82b195e1958268f2b5a774e18cb051f2316137f';

@ProviderFor(inadimplenciaConfigStream)
final inadimplenciaConfigStreamProvider = InadimplenciaConfigStreamProvider._();

final class InadimplenciaConfigStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<InadimplenciaConfig>,
          InadimplenciaConfig,
          Stream<InadimplenciaConfig>
        >
    with
        $FutureModifier<InadimplenciaConfig>,
        $StreamProvider<InadimplenciaConfig> {
  InadimplenciaConfigStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inadimplenciaConfigStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inadimplenciaConfigStreamHash();

  @$internal
  @override
  $StreamProviderElement<InadimplenciaConfig> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<InadimplenciaConfig> create(Ref ref) {
    return inadimplenciaConfigStream(ref);
  }
}

String _$inadimplenciaConfigStreamHash() =>
    r'cd73eb30ae7e83932aa34238621590712bab3df0';

@ProviderFor(tenantSlugStream)
final tenantSlugStreamProvider = TenantSlugStreamProvider._();

final class TenantSlugStreamProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  TenantSlugStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantSlugStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantSlugStreamHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return tenantSlugStream(ref);
  }
}

String _$tenantSlugStreamHash() => r'694e7340c5e41e5f1a174e041ccd41a91e4c747e';

@ProviderFor(tenantNameStream)
final tenantNameStreamProvider = TenantNameStreamProvider._();

final class TenantNameStreamProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  TenantNameStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tenantNameStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tenantNameStreamHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return tenantNameStream(ref);
  }
}

String _$tenantNameStreamHash() => r'cf649df158ff0f01eeccfcd1577bb7519c3755f9';
