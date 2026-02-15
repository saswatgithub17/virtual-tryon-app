import 'package:dart_mappable/dart_mappable.dart';

part 'review_model.mapper.dart';

@MappableClass(caseStyle: CaseStyle.snakeCase)
class Review with ReviewMappable {
  final int reviewId;
  final int dressId;
  final String? customerName;
  final String? customerEmail;
  final int rating;
  final String? reviewText;
  final bool isVerified;
  final DateTime? createdAt;

  Review({
    required this.reviewId,
    required this.dressId,
    this.customerName,
    this.customerEmail,
    required this.rating,
    this.reviewText,
    this.isVerified = false,
    this.createdAt,
  });

  static const fromMap = ReviewMapper.fromMap;
  static const fromJson = ReviewMapper.fromJson;
}
