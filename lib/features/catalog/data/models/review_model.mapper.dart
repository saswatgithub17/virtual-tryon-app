// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'review_model.dart';

class ReviewMapper extends ClassMapperBase<Review> {
  ReviewMapper._();

  static ReviewMapper? _instance;
  static ReviewMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ReviewMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Review';

  static int _$reviewId(Review v) => v.reviewId;
  static const Field<Review, int> _f$reviewId =
      Field('reviewId', _$reviewId, key: r'review_id');
  static int _$dressId(Review v) => v.dressId;
  static const Field<Review, int> _f$dressId =
      Field('dressId', _$dressId, key: r'dress_id');
  static String? _$customerName(Review v) => v.customerName;
  static const Field<Review, String> _f$customerName =
      Field('customerName', _$customerName, key: r'customer_name', opt: true);
  static String? _$customerEmail(Review v) => v.customerEmail;
  static const Field<Review, String> _f$customerEmail = Field(
      'customerEmail', _$customerEmail,
      key: r'customer_email', opt: true);
  static int _$rating(Review v) => v.rating;
  static const Field<Review, int> _f$rating = Field('rating', _$rating);
  static String? _$reviewText(Review v) => v.reviewText;
  static const Field<Review, String> _f$reviewText =
      Field('reviewText', _$reviewText, key: r'review_text', opt: true);
  static bool _$isVerified(Review v) => v.isVerified;
  static const Field<Review, bool> _f$isVerified = Field(
      'isVerified', _$isVerified,
      key: r'is_verified', opt: true, def: false);
  static DateTime? _$createdAt(Review v) => v.createdAt;
  static const Field<Review, DateTime> _f$createdAt =
      Field('createdAt', _$createdAt, key: r'created_at', opt: true);

  @override
  final MappableFields<Review> fields = const {
    #reviewId: _f$reviewId,
    #dressId: _f$dressId,
    #customerName: _f$customerName,
    #customerEmail: _f$customerEmail,
    #rating: _f$rating,
    #reviewText: _f$reviewText,
    #isVerified: _f$isVerified,
    #createdAt: _f$createdAt,
  };

  static Review _instantiate(DecodingData data) {
    return Review(
        reviewId: data.dec(_f$reviewId),
        dressId: data.dec(_f$dressId),
        customerName: data.dec(_f$customerName),
        customerEmail: data.dec(_f$customerEmail),
        rating: data.dec(_f$rating),
        reviewText: data.dec(_f$reviewText),
        isVerified: data.dec(_f$isVerified),
        createdAt: data.dec(_f$createdAt));
  }

  @override
  final Function instantiate = _instantiate;

  static Review fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Review>(map);
  }

  static Review fromJson(String json) {
    return ensureInitialized().decodeJson<Review>(json);
  }
}

mixin ReviewMappable {
  String toJson() {
    return ReviewMapper.ensureInitialized().encodeJson<Review>(this as Review);
  }

  Map<String, dynamic> toMap() {
    return ReviewMapper.ensureInitialized().encodeMap<Review>(this as Review);
  }

  ReviewCopyWith<Review, Review, Review> get copyWith =>
      _ReviewCopyWithImpl<Review, Review>(this as Review, $identity, $identity);
  @override
  String toString() {
    return ReviewMapper.ensureInitialized().stringifyValue(this as Review);
  }

  @override
  bool operator ==(Object other) {
    return ReviewMapper.ensureInitialized().equalsValue(this as Review, other);
  }

  @override
  int get hashCode {
    return ReviewMapper.ensureInitialized().hashValue(this as Review);
  }
}

extension ReviewValueCopy<$R, $Out> on ObjectCopyWith<$R, Review, $Out> {
  ReviewCopyWith<$R, Review, $Out> get $asReview =>
      $base.as((v, t, t2) => _ReviewCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ReviewCopyWith<$R, $In extends Review, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {int? reviewId,
      int? dressId,
      String? customerName,
      String? customerEmail,
      int? rating,
      String? reviewText,
      bool? isVerified,
      DateTime? createdAt});
  ReviewCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ReviewCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Review, $Out>
    implements ReviewCopyWith<$R, Review, $Out> {
  _ReviewCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Review> $mapper = ReviewMapper.ensureInitialized();
  @override
  $R call(
          {int? reviewId,
          int? dressId,
          Object? customerName = $none,
          Object? customerEmail = $none,
          int? rating,
          Object? reviewText = $none,
          bool? isVerified,
          Object? createdAt = $none}) =>
      $apply(FieldCopyWithData({
        if (reviewId != null) #reviewId: reviewId,
        if (dressId != null) #dressId: dressId,
        if (customerName != $none) #customerName: customerName,
        if (customerEmail != $none) #customerEmail: customerEmail,
        if (rating != null) #rating: rating,
        if (reviewText != $none) #reviewText: reviewText,
        if (isVerified != null) #isVerified: isVerified,
        if (createdAt != $none) #createdAt: createdAt
      }));
  @override
  Review $make(CopyWithData data) => Review(
      reviewId: data.get(#reviewId, or: $value.reviewId),
      dressId: data.get(#dressId, or: $value.dressId),
      customerName: data.get(#customerName, or: $value.customerName),
      customerEmail: data.get(#customerEmail, or: $value.customerEmail),
      rating: data.get(#rating, or: $value.rating),
      reviewText: data.get(#reviewText, or: $value.reviewText),
      isVerified: data.get(#isVerified, or: $value.isVerified),
      createdAt: data.get(#createdAt, or: $value.createdAt));

  @override
  ReviewCopyWith<$R2, Review, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ReviewCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
