import 'package:dart_mappable/dart_mappable.dart';

part 'dress_model.mapper.dart';

@MappableClass(caseStyle: CaseStyle.snakeCase)
class Dress with DressMappable {
  final int dressId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? brand;
  final String? color;
  final String? material;

  /// 'men' | 'women' | 'unisex' — nullable for backward compat with old rows
  final String? gender;

  final String imageUrl;
  final bool isActive;
  final double? averageRating;
  final int? totalReviews;

  @MappableField(hook: DressSizeHook())
  final List<DressSize> sizes;

  final DateTime? createdAt;

  Dress({
    required this.dressId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.brand,
    this.color,
    this.material,
    this.gender,
    required this.imageUrl,
    this.isActive = true,
    this.averageRating,
    this.totalReviews,
    this.sizes = const [],
    this.createdAt,
  });

  static const fromMap = DressMapper.fromMap;
  static const fromJson = DressMapper.fromJson;
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class DressSize with DressSizeMappable {
  @MappableField(key: 'size')
  final String sizeName;
  @MappableField(key: 'stock')
  final int stockQuantity;

  DressSize({
    required this.sizeName,
    required this.stockQuantity,
  });

  bool get inStock => stockQuantity > 0;

  static const fromMap = DressSizeMapper.fromMap;
  static const fromJson = DressSizeMapper.fromJson;
}

class DressSizeHook extends MappingHook {
  const DressSizeHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is String) {
      // Handle the "S:10,M:15,L:20" format from the legacy database
      return value.split(',').map((s) {
        final parts = s.split(':');
        return {
          'size': parts[0].trim(),
          'stock': parts.length > 1 ? (int.tryParse(parts[1].trim()) ?? 0) : 0,
        };
      }).toList();
    }
    return value;
  }
}