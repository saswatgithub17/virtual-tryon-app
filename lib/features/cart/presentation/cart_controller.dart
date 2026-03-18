import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/cart_model.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';

part 'cart_controller.g.dart';

// Fix 2: keepAlive:true — cart must NOT be AutoDisposed.
// With AutoDispose, the first call to addToCart creates the provider,
// build() returns [] and fires loadCart() async. addToCart then adds
// to []. When loadCart() resolves it OVERWRITES state with SharedPreferences
// data, wiping the just-added items. keepAlive prevents this by ensuring
// build() only ever runs once per app session.
@Riverpod(keepAlive: true)
class CartController extends _$CartController {
  @override
  List<CartItem> build() {
    _loadCartOnce();
    return [];
  }

  Future<void> _loadCartOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart');
      if (cartData != null) {
        final List<dynamic> decoded = jsonDecode(cartData);
        state = decoded.map((item) {
          if (item is String) {
            return CartItem.fromJson(item);
          } else if (item is Map<String, dynamic>) {
            return CartItem.fromMap(item);
          } else {
            return CartItem.fromMap(
                Map<String, dynamic>.from(item as Map));
          }
        }).toList();
      }
    } catch (_) {
      // Start with empty cart on error
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'cart', jsonEncode(state.map((e) => e.toMap()).toList()));
    } catch (_) {}
  }

  void addToCart(Dress dress, {int quantity = 1, String? size}) {
    final selectedSize = size ?? 'M';
    final existingIndex = state.indexWhere(
      (item) =>
          item.dress.dressId == dress.dressId &&
          item.selectedSize == selectedSize,
    );

    if (existingIndex >= 0) {
      final newState = List<CartItem>.from(state);
      newState[existingIndex] = newState[existingIndex]
          .copyWith(quantity: newState[existingIndex].quantity + quantity);
      state = newState;
    } else {
      state = [
        ...state,
        CartItem(
            dress: dress, selectedSize: selectedSize, quantity: quantity),
      ];
    }
    _saveCart();
  }

  void increaseItem(int index) {
    if (index < 0 || index >= state.length) return;
    final newState = List<CartItem>.from(state);
    newState[index] =
        newState[index].copyWith(quantity: newState[index].quantity + 1);
    state = newState;
    _saveCart();
  }

  void decreaseItem(int index) {
    if (index < 0 || index >= state.length) return;
    if (state[index].quantity <= 1) {
      removeItem(index);
      return;
    }
    final newState = List<CartItem>.from(state);
    newState[index] =
        newState[index].copyWith(quantity: newState[index].quantity - 1);
    state = newState;
    _saveCart();
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.length) {
      state = List<CartItem>.from(state)..removeAt(index);
      _saveCart();
    }
  }

  void clearCart() {
    state = [];
    _saveCart();
  }

  double get totalAmount =>
      state.fold(0.0, (val, item) => val + item.subtotal);

  int get totalQuantity =>
      state.fold(0, (val, item) => val + item.quantity);
}