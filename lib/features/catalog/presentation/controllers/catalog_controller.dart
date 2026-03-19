import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/network/api_service.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';

part 'catalog_controller.g.dart';

@riverpod
class CatalogController extends _$CatalogController {
  // Persisted across invalidations — instance vars survive ref.invalidateSelf()
  String _selectedCategory = 'All';
  String _selectedGender = 'all'; // 'all' | 'men' | 'women'
  String? _searchQuery;

  @override
  Future<List<Dress>> build() async {
    return _fetchDresses();
  }

  // ─── Internal fetch ───────────────────────────────────────────────────────
  Future<List<Dress>> _fetchDresses() async {
    try {
      final apiService = ref.read(apiServiceProvider);

      // apiService.get() accepts only a plain URL string.
      // Build query params manually and append them.
      final params = <String, String>{};

      if (_selectedCategory != 'All') {
        params['category'] = _selectedCategory;
      }
      if (_selectedGender != 'all') {
        params['gender'] = _selectedGender;
      }
      if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
        params['search'] = _searchQuery!.trim();
      }
      params['limit'] = '100';

      String url = ApiConfig.dresses;
      if (params.isNotEmpty) {
        final queryString = params.entries
            .map((e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await apiService.get(url);

      // Backend returns { success: true, data: [...] }
      List<dynamic> rawList;
      if (response is Map && response['data'] != null) {
        rawList = response['data'] as List<dynamic>;
      } else if (response is List) {
        rawList = response;
      } else {
        rawList = [];
      }

      final dresses = rawList
          .map((item) =>
              Dress.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();

      // Shuffle when "All" so men/women are interleaved instead of batched
      if (_selectedGender == 'all') {
        dresses.shuffle();
      }

      return dresses;
    } catch (e) {
      throw Exception('Failed to load dresses: $e');
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  void setGender(String gender) {
    if (_selectedGender == gender) return;
    _selectedGender = gender;
    ref.invalidateSelf();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    ref.invalidateSelf();
  }

  void searchDresses(String query) {
    _searchQuery = query;
    ref.invalidateSelf();
  }

  void refresh() => ref.invalidateSelf();

  // ─── Getters ──────────────────────────────────────────────────────────────
  String get selectedCategory => _selectedCategory;
  String get selectedGender => _selectedGender;
  String? get searchQuery => _searchQuery;
}