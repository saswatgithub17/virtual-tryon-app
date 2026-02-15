import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import '../../data/catalog_repository_impl.dart';
import '../../domain/catalog_repository.dart';
import '../../../../core/network/api_service.dart';

part 'catalog_controller.g.dart';

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CatalogRepositoryImpl(apiService);
}

@riverpod
class CatalogController extends _$CatalogController {
  @override
  FutureOr<List<Dress>> build() async {
    return _fetchDresses();
  }

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  Future<List<Dress>> _fetchDresses({String? query}) async {
    final repo = ref.read(catalogRepositoryProvider);
    return repo.getDresses(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      query: query,
    );
  }

  Future<void> setCategory(String category) async {
    _selectedCategory = category;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDresses());
  }

  Future<void> searchDresses(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDresses(query: query));
  }
}
