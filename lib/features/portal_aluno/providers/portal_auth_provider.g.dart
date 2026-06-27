// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PortalAuth)
final portalAuthProvider = PortalAuthProvider._();

final class PortalAuthProvider
    extends $NotifierProvider<PortalAuth, PortalAuthState> {
  PortalAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portalAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portalAuthHash();

  @$internal
  @override
  PortalAuth create() => PortalAuth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PortalAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PortalAuthState>(value),
    );
  }
}

String _$portalAuthHash() => r'7544521b5ebea64e50ced8db899651aa2bf79e93';

abstract class _$PortalAuth extends $Notifier<PortalAuthState> {
  PortalAuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PortalAuthState, PortalAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PortalAuthState, PortalAuthState>,
              PortalAuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(portalPixPayload)
final portalPixPayloadProvider = PortalPixPayloadProvider._();

final class PortalPixPayloadProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  PortalPixPayloadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'portalPixPayloadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$portalPixPayloadHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return portalPixPayload(ref);
  }
}

String _$portalPixPayloadHash() => r'54df20c7368baec44c239b02fea9c206ac2437ee';
