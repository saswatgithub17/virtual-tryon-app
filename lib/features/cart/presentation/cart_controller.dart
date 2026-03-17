import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/cart_model.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';

part 'cart_controller.g.dart';

@riverpod
class CartController extends _$CartController {
  @override
  List<CartItem> build() {
    loadCart();
    return [];
  }

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart');

      if (cartData != null) {
        final List<dynamic> decoded = jsonDecode(cartData);
        // Support both map and json string formats when decoding
        state = decoded.map((item) {
          if (item is String) {
            return CartItem.fromJson(item);
          } else if (item is Map<String, dynamic>) {
            return CartItem.fromMap(item);
          } else {
            // Fall back to decoding via mapper using the map representation
            return CartItem.fromMap(Map<String, dynamic>.from(item as Map));
          }
        }).toList();
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(state.map((item) => item.toMap()).toList());
      await prefs.setString('cart', cartData);
    } catch (e) {
      // Handle error
    }
  }

  void addToCart(Dress dress, {int quantity = 1, String? size}) {
    final selectedSize = size ?? 'M';
    final existingIndex = state.indexWhere(
      (item) =>
          item.dress.dressId == dress.dressId &&
          item.selectedSize == selectedSize,
    );

    if (existingIndex >= 0) {
      final item = state[existingIndex];
      final updatedItem = item.copyWith(quantity: item.quantity + quantity);
      final newState = [...state];
      newState[existingIndex] = updatedItem;
      state = newState;
    } else {
      state = [
        ...state,
        CartItem(dress: dress, selectedSize: selectedSize, quantity: quantity),
      ];
    }
    _saveCart();
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.length) {
      state = [...state]..removeAt(index);
      _saveCart();
    }
  }

  void clearCart() {
    state = [];
    _saveCart();
  }

  double get totalAmount => state.fold(0.0, (val, item) => val + item.subtotal);
  int get totalQuantity => state.fold(0, (val, item) => val + item.quantity);
}
