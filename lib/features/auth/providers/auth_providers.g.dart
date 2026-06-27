// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'9f97e644bdc6bf6dd2d0b234710028ac9e3012c5';

@ProviderFor(authUserChanges)
final authUserChangesProvider = AuthUserChangesProvider._();

final class AuthUserChangesProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  AuthUserChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authUserChangesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authUserChangesHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authUserChanges(ref);
  }
}

String _$authUserChangesHash() => r'3589daf9f7d77eefbf8901e35f13b18f6ea6455b';

@ProviderFor(authAccessState)
final authAccessStateProvider = AuthAccessStateProvider._();

final class AuthAccessStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthAccessState>,
          AuthAccessState,
          Stream<AuthAccessState>
        >
    with $FutureModifier<AuthAccessState>, $StreamProvider<AuthAccessState> {
  AuthAccessStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authAccessStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authAccessStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthAccessState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AuthAccessState> create(Ref ref) {
    return authAccessState(ref);
  }
}

String _$authAccessStateHash() => r'b1c15907a381f87c354f48da9bad68b431057d72';

@ProviderFor(authSession)
final authSessionProvider = AuthSessionProvider._();

final class AuthSessionProvider
    extends $FunctionalProvider<AuthSession?, AuthSession?, AuthSession?>
    with $Provider<AuthSession?> {
  AuthSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authSessionHash();

  @$internal
  @override
  $ProviderElement<AuthSession?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthSession? create(Ref ref) {
    return authSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthSession?>(value),
    );
  }
}

String _$authSessionHash() => r'b44de13393536bb4657add13c83fc6f333bb646d';

@ProviderFor(authAccessSnapshot)
final authAccessSnapshotProvider = AuthAccessSnapshotProvider._();

final class AuthAccessSnapshotProvider
    extends
        $FunctionalProvider<AuthAccessState, AuthAccessState, AuthAccessState>
    with $Provider<AuthAccessState> {
  AuthAccessSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authAccessSnapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authAccessSnapshotHash();

  @$internal
  @override
  $ProviderElement<AuthAccessState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthAccessState create(Ref ref) {
    return authAccessSnapshot(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthAccessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthAccessState>(value),
    );
  }
}

String _$authAccessSnapshotHash() =>
    r'4853731cb7f40d13d7b558f62d608ccb5a648e27';
