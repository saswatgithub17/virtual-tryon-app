import '../domain/catalog_repository.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import '../data/models/review_model.dart';
import '../../../../core/network/api_service.dart';
import '../data/models/dress_response.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final ApiService _apiService;

  CatalogRepositoryImpl(this._apiService);

  @override
  Future<List<Dress>> getDresses({String? category, String? query}) async {
    final response = await _apiService.get('/dresses', queryParameters: {
      if (category != null) 'category': category,
      if (query != null) 'q': query,
    });
    return DressResponse.fromMap(response).data;
  }

  @override
  Future<Dress?> getDressById(int id) async {
    final response = await _apiService.get('/dresses/$id');
    if (response != null) {
      return Dress.fromJson(response);
    }
    return null;
  }

  @override
  Future<List<Review>> getReviews(int dressId) async {
    final response = await _apiService.get('/dresses/$dressId/reviews');
    if (response is List) {
      return response.map((json) => Review.fromJson(json)).toList();
    }
    return [];
  }

  @override
  Future<void> addReview(Review review) async {
    await _apiService.post('/reviews', data: review.toMap());
  }
}
