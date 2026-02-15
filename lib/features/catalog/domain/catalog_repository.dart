import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import '../data/models/review_model.dart';

abstract class CatalogRepository {
  Future<List<Dress>> getDresses({String? category, String? query});
  Future<Dress?> getDressById(int id);
  Future<List<Review>> getReviews(int dressId);
  Future<void> addReview(Review review);
}
