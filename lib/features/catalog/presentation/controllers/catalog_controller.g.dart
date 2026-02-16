// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$catalogRepositoryHash() => r'9c5980028ed043f89a73fd18c943ace87ca0ad78';

/// See also [catalogRepository].
@ProviderFor(catalogRepository)
final catalogRepositoryProvider = Provider<CatalogRepository>.internal(
  catalogRepository,
  name: r'catalogRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$catalogRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CatalogRepositoryRef = ProviderRef<CatalogRepository>;
String _$catalogControllerHash() => r'e8d809199961fba2c51e8bd29cbcee3c7dda3b2a';

/// See also [CatalogController].
@ProviderFor(CatalogController)
final catalogControllerProvider =
    AutoDisposeAsyncNotifierProvider<CatalogController, List<Dress>>.internal(
  CatalogController.new,
  name: r'catalogControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$catalogControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CatalogController = AutoDisposeAsyncNotifier<List<Dress>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
