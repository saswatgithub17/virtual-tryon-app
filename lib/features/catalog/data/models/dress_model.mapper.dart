// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'dress_model.dart';

class DressMapper extends ClassMapperBase<Dress> {
  DressMapper._();

  static DressMapper? _instance;
  static DressMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DressMapper._());
      DressSizeMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Dress';

  static int _$dressId(Dress v) => v.dressId;
  static const Field<Dress, int> _f$dressId =
      Field('dressId', _$dressId, key: r'dress_id');
  static String _$name(Dress v) => v.name;
  static const Field<Dress, String> _f$name = Field('name', _$name);
  static String? _$description(Dress v) => v.description;
  static const Field<Dress, String> _f$description =
      Field('description', _$description, opt: true);
  static double _$price(Dress v) => v.price;
  static const Field<Dress, double> _f$price = Field('price', _$price);
  static String? _$category(Dress v) => v.category;
  static const Field<Dress, String> _f$category =
      Field('category', _$category, opt: true);
  static String? _$brand(Dress v) => v.brand;
  static const Field<Dress, String> _f$brand =
      Field('brand', _$brand, opt: true);
  static String? _$color(Dress v) => v.color;
  static const Field<Dress, String> _f$color =
      Field('color', _$color, opt: true);
  static String? _$material(Dress v) => v.material;
  static const Field<Dress, String> _f$material =
      Field('material', _$material, opt: true);
  // ── gender field ──────────────────────────────────────────────────────────
  static String? _$gender(Dress v) => v.gender;
  static const Field<Dress, String> _f$gender =
      Field('gender', _$gender, opt: true);
  // ─────────────────────────────────────────────────────────────────────────
  static String _$imageUrl(Dress v) => v.imageUrl;
  static const Field<Dress, String> _f$imageUrl =
      Field('imageUrl', _$imageUrl, key: r'image_url');
  static bool _$isActive(Dress v) => v.isActive;
  static const Field<Dress, bool> _f$isActive =
      Field('isActive', _$isActive, key: r'is_active', opt: true, def: true);
  static double? _$averageRating(Dress v) => v.averageRating;
  static const Field<Dress, double> _f$averageRating = Field(
      'averageRating', _$averageRating,
      key: r'average_rating', opt: true);
  static int? _$totalReviews(Dress v) => v.totalReviews;
  static const Field<Dress, int> _f$totalReviews =
      Field('totalReviews', _$totalReviews, key: r'total_reviews', opt: true);
  static List<DressSize> _$sizes(Dress v) => v.sizes;
  static const Field<Dress, List<DressSize>> _f$sizes =
      Field('sizes', _$sizes, opt: true, def: const [], hook: DressSizeHook());
  static DateTime? _$createdAt(Dress v) => v.createdAt;
  static const Field<Dress, DateTime> _f$createdAt =
      Field('createdAt', _$createdAt, key: r'created_at', opt: true);

  @override
  final MappableFields<Dress> fields = const {
    #dressId: _f$dressId,
    #name: _f$name,
    #description: _f$description,
    #price: _f$price,
    #category: _f$category,
    #brand: _f$brand,
    #color: _f$color,
    #material: _f$material,
    #gender: _f$gender,
    #imageUrl: _f$imageUrl,
    #isActive: _f$isActive,
    #averageRating: _f$averageRating,
    #totalReviews: _f$totalReviews,
    #sizes: _f$sizes,
    #createdAt: _f$createdAt,
  };

  static Dress _instantiate(DecodingData data) {
    return Dress(
        dressId: data.dec(_f$dressId),
        name: data.dec(_f$name),
        description: data.dec(_f$description),
        price: data.dec(_f$price),
        category: data.dec(_f$category),
        brand: data.dec(_f$brand),
        color: data.dec(_f$color),
        material: data.dec(_f$material),
        gender: data.dec(_f$gender),
        imageUrl: data.dec(_f$imageUrl),
        isActive: data.dec(_f$isActive),
        averageRating: data.dec(_f$averageRating),
        totalReviews: data.dec(_f$totalReviews),
        sizes: data.dec(_f$sizes),
        createdAt: data.dec(_f$createdAt));
  }

  @override
  final Function instantiate = _instantiate;

  static Dress fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Dress>(map);
  }

  static Dress fromJson(String json) {
    return ensureInitialized().decodeJson<Dress>(json);
  }
}

mixin DressMappable {
  String toJson() {
    return DressMapper.ensureInitialized().encodeJson<Dress>(this as Dress);
  }

  Map<String, dynamic> toMap() {
    return DressMapper.ensureInitialized().encodeMap<Dress>(this as Dress);
  }

  DressCopyWith<Dress, Dress, Dress> get copyWith =>
      _DressCopyWithImpl<Dress, Dress>(this as Dress, $identity, $identity);
  @override
  String toString() {
    return DressMapper.ensureInitialized().stringifyValue(this as Dress);
  }

  @override
  bool operator ==(Object other) {
    return DressMapper.ensureInitialized().equalsValue(this as Dress, other);
  }

  @override
  int get hashCode {
    return DressMapper.ensureInitialized().hashValue(this as Dress);
  }
}

extension DressValueCopy<$R, $Out> on ObjectCopyWith<$R, Dress, $Out> {
  DressCopyWith<$R, Dress, $Out> get $asDress =>
      $base.as((v, t, t2) => _DressCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DressCopyWith<$R, $In extends Dress, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, DressSize, DressSizeCopyWith<$R, DressSize, DressSize>>
      get sizes;
  $R call(
      {int? dressId,
      String? name,
      String? description,
      double? price,
      String? category,
      String? brand,
      String? color,
      String? material,
      String? gender,
      String? imageUrl,
      bool? isActive,
      double? averageRating,
      int? totalReviews,
      List<DressSize>? sizes,
      DateTime? createdAt});
  DressCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DressCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Dress, $Out>
    implements DressCopyWith<$R, Dress, $Out> {
  _DressCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Dress> $mapper = DressMapper.ensureInitialized();
  @override
  ListCopyWith<$R, DressSize, DressSizeCopyWith<$R, DressSize, DressSize>>
      get sizes => ListCopyWith(
          $value.sizes, (v, t) => v.copyWith.$chain(t), (v) => call(sizes: v));
  @override
  $R call(
          {int? dressId,
          String? name,
          Object? description = $none,
          double? price,
          Object? category = $none,
          Object? brand = $none,
          Object? color = $none,
          Object? material = $none,
          Object? gender = $none,
          String? imageUrl,
          bool? isActive,
          Object? averageRating = $none,
          Object? totalReviews = $none,
          List<DressSize>? sizes,
          Object? createdAt = $none}) =>
      $apply(FieldCopyWithData({
        if (dressId != null) #dressId: dressId,
        if (name != null) #name: name,
        if (description != $none) #description: description,
        if (price != null) #price: price,
        if (category != $none) #category: category,
        if (brand != $none) #brand: brand,
        if (color != $none) #color: color,
        if (material != $none) #material: material,
        if (gender != $none) #gender: gender,
        if (imageUrl != null) #imageUrl: imageUrl,
        if (isActive != null) #isActive: isActive,
        if (averageRating != $none) #averageRating: averageRating,
        if (totalReviews != $none) #totalReviews: totalReviews,
        if (sizes != null) #sizes: sizes,
        if (createdAt != $none) #createdAt: createdAt
      }));
  @override
  Dress $make(CopyWithData data) => Dress(
      dressId: data.get(#dressId, or: $value.dressId),
      name: data.get(#name, or: $value.name),
      description: data.get(#description, or: $value.description),
      price: data.get(#price, or: $value.price),
      category: data.get(#category, or: $value.category),
      brand: data.get(#brand, or: $value.brand),
      color: data.get(#color, or: $value.color),
      material: data.get(#material, or: $value.material),
      gender: data.get(#gender, or: $value.gender),
      imageUrl: data.get(#imageUrl, or: $value.imageUrl),
      isActive: data.get(#isActive, or: $value.isActive),
      averageRating: data.get(#averageRating, or: $value.averageRating),
      totalReviews: data.get(#totalReviews, or: $value.totalReviews),
      sizes: data.get(#sizes, or: $value.sizes),
      createdAt: data.get(#createdAt, or: $value.createdAt));

  @override
  DressCopyWith<$R2, Dress, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _DressCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class DressSizeMapper extends ClassMapperBase<DressSize> {
  DressSizeMapper._();

  static DressSizeMapper? _instance;
  static DressSizeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = DressSizeMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'DressSize';

  static String _$sizeName(DressSize v) => v.sizeName;
  static const Field<DressSize, String> _f$sizeName =
      Field('sizeName', _$sizeName, key: r'size');
  static int _$stockQuantity(DressSize v) => v.stockQuantity;
  static const Field<DressSize, int> _f$stockQuantity =
      Field('stockQuantity', _$stockQuantity, key: r'stock');

  @override
  final MappableFields<DressSize> fields = const {
    #sizeName: _f$sizeName,
    #stockQuantity: _f$stockQuantity,
  };

  static DressSize _instantiate(DecodingData data) {
    return DressSize(
        sizeName: data.dec(_f$sizeName),
        stockQuantity: data.dec(_f$stockQuantity));
  }

  @override
  final Function instantiate = _instantiate;

  static DressSize fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<DressSize>(map);
  }

  static DressSize fromJson(String json) {
    return ensureInitialized().decodeJson<DressSize>(json);
  }
}

mixin DressSizeMappable {
  String toJson() {
    return DressSizeMapper.ensureInitialized()
        .encodeJson<DressSize>(this as DressSize);
  }

  Map<String, dynamic> toMap() {
    return DressSizeMapper.ensureInitialized()
        .encodeMap<DressSize>(this as DressSize);
  }

  DressSizeCopyWith<DressSize, DressSize, DressSize> get copyWith =>
      _DressSizeCopyWithImpl<DressSize, DressSize>(
          this as DressSize, $identity, $identity);
  @override
  String toString() {
    return DressSizeMapper.ensureInitialized()
        .stringifyValue(this as DressSize);
  }

  @override
  bool operator ==(Object other) {
    return DressSizeMapper.ensureInitialized()
        .equalsValue(this as DressSize, other);
  }

  @override
  int get hashCode {
    return DressSizeMapper.ensureInitialized().hashValue(this as DressSize);
  }
}

extension DressSizeValueCopy<$R, $Out> on ObjectCopyWith<$R, DressSize, $Out> {
  DressSizeCopyWith<$R, DressSize, $Out> get $asDressSize =>
      $base.as((v, t, t2) => _DressSizeCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class DressSizeCopyWith<$R, $In extends DressSize, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? sizeName, int? stockQuantity});
  DressSizeCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _DressSizeCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, DressSize, $Out>
    implements DressSizeCopyWith<$R, DressSize, $Out> {
  _DressSizeCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<DressSize> $mapper =
      DressSizeMapper.ensureInitialized();
  @override
  $R call({String? sizeName, int? stockQuantity}) =>
      $apply(FieldCopyWithData({
        if (sizeName != null) #sizeName: sizeName,
        if (stockQuantity != null) #stockQuantity: stockQuantity
      }));
  @override
  DressSize $make(CopyWithData data) => DressSize(
      sizeName: data.get(#sizeName, or: $value.sizeName),
      stockQuantity: data.get(#stockQuantity, or: $value.stockQuantity));

  @override
  DressSizeCopyWith<$R2, DressSize, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _DressSizeCopyWithImpl<$R2, $Out2>($value, $cast, t);
}