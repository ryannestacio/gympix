// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alunos_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(alunosRepository)
const alunosRepositoryProvider = AlunosRepositoryProvider._();

final class AlunosRepositoryProvider
    extends
        $FunctionalProvider<
          AlunosRepository,
          AlunosRepository,
          AlunosRepository
        >
    with $Provider<AlunosRepository> {
  const AlunosRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alunosRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alunosRepositoryHash();

  @$internal
  @override
  $ProviderElement<AlunosRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlunosRepository create(Ref ref) {
    return alunosRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlunosRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlunosRepository>(value),
    );
  }
}

String _$alunosRepositoryHash() => r'd24f8bb998c809391830e754212477e0cb773eb8';

@ProviderFor(alunosStream)
const alunosStreamProvider = AlunosStreamProvider._();

final class AlunosStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Aluno>>,
          List<Aluno>,
          Stream<List<Aluno>>
        >
    with $FutureModifier<List<Aluno>>, $StreamProvider<List<Aluno>> {
  const AlunosStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alunosStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alunosStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Aluno>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Aluno>> create(Ref ref) {
    return alunosStream(ref);
  }
}

String _$alunosStreamHash() => r'5d1f7a4f89fa7c5f11ee7d37517b1d178d79a809';

@ProviderFor(AlunosFiltro)
const alunosFiltroProvider = AlunosFiltroProvider._();

final class AlunosFiltroProvider
    extends $NotifierProvider<AlunosFiltro, AlunoFiltro> {
  const AlunosFiltroProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alunosFiltroProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alunosFiltroHash();

  @$internal
  @override
  AlunosFiltro create() => AlunosFiltro();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlunoFiltro value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlunoFiltro>(value),
    );
  }
}

String _$alunosFiltroHash() => r'409eb8eedf9a6136cb5df691d9192823c0f9f02c';

abstract class _$AlunosFiltro extends $Notifier<AlunoFiltro> {
  AlunoFiltro build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AlunoFiltro, AlunoFiltro>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AlunoFiltro, AlunoFiltro>,
              AlunoFiltro,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(alunosFiltrados)
const alunosFiltradosProvider = AlunosFiltradosProvider._();

final class AlunosFiltradosProvider
    extends $FunctionalProvider<List<Aluno>, List<Aluno>, List<Aluno>>
    with $Provider<List<Aluno>> {
  const AlunosFiltradosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alunosFiltradosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alunosFiltradosHash();

  @$internal
  @override
  $ProviderElement<List<Aluno>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Aluno> create(Ref ref) {
    return alunosFiltrados(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Aluno> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Aluno>>(value),
    );
  }
}

String _$alunosFiltradosHash() => r'42c56820afba351c007fa2d421a41ef4f1cb24b8';

@ProviderFor(dashboardStats)
const dashboardStatsProvider = DashboardStatsProvider._();

final class DashboardStatsProvider
    extends $FunctionalProvider<DashboardStats, DashboardStats, DashboardStats>
    with $Provider<DashboardStats> {
  const DashboardStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardStatsHash();

  @$internal
  @override
  $ProviderElement<DashboardStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DashboardStats create(Ref ref) {
    return dashboardStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DashboardStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DashboardStats>(value),
    );
  }
}

String _$dashboardStatsHash() => r'4cc7953448a68f4466039622951d45a76a77566b';
