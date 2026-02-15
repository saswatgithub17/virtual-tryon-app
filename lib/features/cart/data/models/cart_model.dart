import 'package:dart_mappable/dart_mappable.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';

part 'cart_model.mapper.dart';

@MappableClass(caseStyle: CaseStyle.snakeCase)
class CartItem with CartItemMappable {
  final Dress dress;
  final String selectedSize;
  final int quantity;

  CartItem({
    required this.dress,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get subtotal => dress.price * quantity;

  static const fromMap = CartItemMapper.fromMap;
  static const fromJson = CartItemMapper.fromJson;

  // Custom toJson to match legacy expectaitons if needed,
  // but dart_mappable's toMap will work fine.
}
