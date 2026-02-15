// lib/providers/cart_provider.dart
// FIXED VERSION - Consistent method signatures

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/dress_model.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;

  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // Initialize cart from local storage
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart');

      if (cartData != null) {
        final List<dynamic> decoded = jsonDecode(cartData);
        _items = decoded.map((item) {
          return CartItem(
            dress: Dress.fromJson(item['dress']),
            selectedSize: item['selectedSize'],
            quantity: item['quantity'],
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_items.map((item) => {
        'dress': item.dress.toJson(),
        'selectedSize': item.selectedSize,
        'quantity': item.quantity,
      }).toList());

      await prefs.setString('cart', cartData);
    } catch (e) {
      debugPrint('Error saving cart: $e');
    }
  }

  // FIXED: Updated signature to match usage in dress_detail_screen.dart
  void addToCart(Dress dress, {int quantity = 1, String? size}) {
    // Use default size if not provided
    final selectedSize = size ?? 'M';

    // Check if item already exists
    final existingIndex = _items.indexWhere(
          (item) => item.dress.dressId == dress.dressId && item.selectedSize == selectedSize,
    );

    if (existingIndex >= 0) {
      // Update quantity of existing item
      _items[existingIndex].quantity += quantity;
    } else {
      // Add new item
      _items.add(CartItem(
        dress: dress,
        selectedSize: selectedSize,
        quantity: quantity,
      ));
    }

    _saveCart();
    notifyListeners();
  }

  // LEGACY: Keep for backward compatibility
  void addItem(Dress dress, String selectedSize, {int quantity = 1}) {
    addToCart(dress, quantity: quantity, size: selectedSize);
  }

  // Remove item from cart
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      _saveCart();
      notifyListeners();
    }
  }

  // Remove item by dress ID and size
  void removeItemByDressAndSize(int dressId, String size) {
    _items.removeWhere(
          (item) => item.dress.dressId == dressId && item.selectedSize == size,
    );
    _saveCart();
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length) {
      if (quantity <= 0) {
        removeItem(index);
      } else {
        _items[index].quantity = quantity;
        _saveCart();
        notifyListeners();
      }
    }
  }

  // Increase quantity
  void increaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      _items[index].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  // Decrease quantity
  void decreaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        _saveCart();
        notifyListeners();
      } else {
        removeItem(index);
      }
    }
  }

  // Clear entire cart
  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  // Check if specific dress with size is in cart
  bool isInCart(int dressId, String size) {
    return _items.any(
          (item) => item.dress.dressId == dressId && item.selectedSize == size,
    );
  }

  // Get quantity of specific item
  int getQuantity(int dressId, String size) {
    final item = _items.firstWhere(
          (item) => item.dress.dressId == dressId && item.selectedSize == size,
      orElse: () => CartItem(
        dress: Dress(dressId: 0, name: '', price: 0, imageUrl: ''),
        selectedSize: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Get cart items for API (simplified format)
  List<Map<String, dynamic>> getItemsForAPI() {
    return _items.map((item) => item.toJson()).toList();
  }
}