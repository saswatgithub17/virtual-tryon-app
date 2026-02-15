// lib/screens/cart/cart_screen.dart
// Premium Shopping Cart Screen with A1++ UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme_config.dart';
import '../../config/app_config.dart';
import '../../widgets/cart_item_widget.dart';
import '../../utils/helpers.dart';
import '../../widgets/error_widget.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _showClearCartDialog(cart),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: ThemeConfig.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return EmptyStateWidget.emptyCart(
              onShop: () => Navigator.pop(context),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Cart items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Dismissible(
                        key: Key('${item.dress.dressId}_${item.selectedSize}'),
                        background: _buildDismissBackground(Colors.red, Alignment.centerLeft),
                        secondaryBackground: _buildDismissBackground(Colors.red, Alignment.centerRight),
                        confirmDismiss: (direction) => _confirmDelete(item.dress.name),
                        onDismissed: (direction) {
                          cart.removeItem(index);
                          Helpers.showSuccess(context, 'Removed from cart');
                        },
                        child: CartItemWidget(
                          item: item,
                          onRemove: () {
                            cart.removeItem(index);
                            Helpers.showSuccess(context, 'Removed from cart');
                          },
                          onIncrease: () => cart.increaseQuantity(index),
                          onDecrease: () => cart.decreaseQuantity(index),
                        ),
                      );
                    },
                  ),
                ),

                // Summary section
                _buildSummarySection(cart),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildCheckoutButton(),
    );
  }

  Widget _buildDismissBackground(Color color, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      child: const Icon(
        Icons.delete,
        color: Colors.white,
        size: 32,
      ),
    );
  }

  Widget _buildSummarySection(CartProvider cart) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.primaryColor.withOpacity(0.1),
            ThemeConfig.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeConfig.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Items', '${cart.itemCount}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Total Quantity', '${cart.totalQuantity}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppConfig.formatPrice(cart.totalAmount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: ThemeConfig.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckoutScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppConfig.formatPriceShort(cart.totalAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(String itemName) {
    return Helpers.showConfirmDialog(
      context,
      title: 'Remove Item',
      message: 'Remove "$itemName" from cart?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
    );
  }

  Future<void> _showClearCartDialog(CartProvider cart) async {
    final confirm = await Helpers.showConfirmDialog(
      context,
      title: 'Clear Cart',
      message: 'Are you sure you want to remove all items from cart?',
      confirmText: 'Clear All',
      cancelText: 'Cancel',
    );

    if (confirm == true) {
      cart.clearCart();
      if (mounted) {
        Helpers.showSuccess(context, 'Cart cleared');
      }
    }
  }
}