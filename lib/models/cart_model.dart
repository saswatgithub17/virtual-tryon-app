// lib/models/cart_model.dart
// Shopping Cart Models

import 'dress_model.dart';

class Cart {
  final List<CartItem> items;
  final DateTime? lastUpdated;

  Cart({
    this.items = const [],
    this.lastUpdated,
  });

  // Calculate total amount
  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Get total quantity of all items
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total number of unique items
  int get itemCount => items.length;

  // Check if cart is empty
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  // Find item by dress and size
  CartItem? findItem(int dressId, String size) {
    try {
      return items.firstWhere(
            (item) => item.dress.dressId == dressId && item.selectedSize == size,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if item exists
  bool hasItem(int dressId, String size) {
    return items.any(
          (item) => item.dress.dressId == dressId && item.selectedSize == size,
    );
  }

  // Get item quantity
  int getItemQuantity(int dressId, String size) {
    final item = findItem(dressId, size);
    return item?.quantity ?? 0;
  }

  // Add item to cart
  Cart addItem(Dress dress, String size, {int quantity = 1}) {
    final existingIndex = items.indexWhere(
          (item) => item.dress.dressId == dress.dressId && item.selectedSize == size,
    );

    List<CartItem> updatedItems = List.from(items);

    if (existingIndex >= 0) {
      // Update quantity of existing item
      final existingItem = updatedItems[existingIndex];
      updatedItems[existingIndex] = CartItem(
        dress: existingItem.dress,
        selectedSize: existingItem.selectedSize,
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item
      updatedItems.add(CartItem(
        dress: dress,
        selectedSize: size,
        quantity: quantity,
      ));
    }

    return Cart(
      items: updatedItems,
      lastUpdated: DateTime.now(),
    );
  }

  // Remove item from cart
  Cart removeItem(int dressId, String size) {
    final updatedItems = items.where(
          (item) => !(item.dress.dressId == dressId && item.selectedSize == size),
    ).toList();

    return Cart(
      items: updatedItems,
      lastUpdated: DateTime.now(),
    );
  }

  // Update item quantity
  Cart updateQuantity(int dressId, String size, int quantity) {
    if (quantity <= 0) {
      return removeItem(dressId, size);
    }

    final updatedItems = items.map((item) {
      if (item.dress.dressId == dressId && item.selectedSize == size) {
        return CartItem(
          dress: item.dress,
          selectedSize: item.selectedSize,
          quantity: quantity,
        );
      }
      return item;
    }).toList();

    return Cart(
      items: updatedItems,
      lastUpdated: DateTime.now(),
    );
  }

  // Clear cart
  Cart clear() {
    return Cart(
      items: [],
      lastUpdated: DateTime.now(),
    );
  }

  // Convert to JSON for API
  List<Map<String, dynamic>> toApiFormat() {
    return items.map((item) => item.toJson()).toList();
  }

  // Copy with
  Cart copyWith({
    List<CartItem>? items,
    DateTime? lastUpdated,
  }) {
    return Cart(
      items: items ?? this.items,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'Cart(items: ${items.length}, total: ₹${totalAmount.toStringAsFixed(2)})';
  }
}

// Cart Summary for display
class CartSummary {
  final int itemCount;
  final int totalQuantity;
  final double subtotal;
  final double discount;
  final double tax;
  final double shipping;
  final double total;

  CartSummary({
    required this.itemCount,
    required this.totalQuantity,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    this.shipping = 0.0,
  }) : total = subtotal - discount + tax + shipping;

  factory CartSummary.fromCart(Cart cart, {
    double discount = 0.0,
    double tax = 0.0,
    double shipping = 0.0,
  }) {
    return CartSummary(
      itemCount: cart.itemCount,
      totalQuantity: cart.totalQuantity,
      subtotal: cart.totalAmount,
      discount: discount,
      tax: tax,
      shipping: shipping,
    );
  }

  bool get hasDiscount => discount > 0;
  bool get hasTax => tax > 0;
  bool get hasShipping => shipping > 0;

  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';
  String get formattedDiscount => '₹${discount.toStringAsFixed(2)}';
  String get formattedTax => '₹${tax.toStringAsFixed(2)}';
  String get formattedShipping => '₹${shipping.toStringAsFixed(2)}';
  String get formattedTotal => '₹${total.toStringAsFixed(2)}';
}