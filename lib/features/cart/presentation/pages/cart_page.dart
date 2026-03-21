import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/widgets/cart_item_widget.dart';
import 'package:virtual_tryon_app/widgets/error_widget.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

@RoutePage()
class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final cartController = ref.read(cartControllerProvider.notifier);

    final totalAmount = ref.watch(cartControllerProvider.notifier
        .select((c) => c.totalAmount));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Shopping Cart',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () => _showClearCartDialog(cartController),
              child: const Text('Clear',
                  style: TextStyle(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? EmptyStateWidget.emptyCart(
              onShop: () => context.router.pop())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Dismissible(
                          key: Key(
                              '${item.dress.dressId}_${item.selectedSize}'),
                          background: _buildDismissBackground(
                              Colors.red, Alignment.centerLeft),
                          secondaryBackground: _buildDismissBackground(
                              Colors.red, Alignment.centerRight),
                          confirmDismiss: (direction) =>
                              _confirmDelete(item.dress.name),
                          onDismissed: (direction) {
                            cartController.removeItem(index);
                            Helpers.showSuccess(
                                context, 'Removed from cart');
                          },
                          child: CartItemWidget(
                            item: item,
                            onRemove: () {
                              cartController.removeItem(index);
                              Helpers.showSuccess(
                                  context, 'Removed from cart');
                            },
                            onIncrease: () =>
                                cartController.increaseItem(index),
                            onDecrease: () =>
                                cartController.decreaseItem(index),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildSummarySection(cartItems, totalAmount),
                ],
              ),
            ),
      // Q10 FIX: bottomNavigationBar is null when cart is empty — button never renders.
      // An additional guard inside _buildCheckoutButton ensures onPressed is null-safe
      // even if this widget is ever reused in a context where isEmpty isn't checked first.
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : _buildCheckoutButton(totalAmount, cartItems.isEmpty),
    );
  }

  Widget _buildDismissBackground(Color color, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      alignment: alignment,
      child: const Icon(Icons.delete, color: Colors.white, size: 32),
    );
  }

  Widget _buildSummarySection(
      List<dynamic> items, double totalAmount) {
    final totalQuantity =
        ref.watch(cartControllerProvider.notifier.select((c) => c.totalQuantity));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withOpacity(0.1),
          AppTheme.secondaryColor.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Items', '${items.length}'),
          const SizedBox(height: 12),
          _buildSummaryRow('Total Quantity', '$totalQuantity'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(AppConfig.formatPrice(totalAmount),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
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
        Text(label,
            style: const TextStyle(
                fontSize: 15, color: AppTheme.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // Q10 FIX: [isCartEmpty] is passed explicitly so onPressed is definitively null
  // when the cart is empty — prevents any edge case navigation to an empty checkout.
  Widget _buildCheckoutButton(double totalAmount, bool isCartEmpty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          // Q10 FIX: null onPressed renders a visually disabled button and blocks
          // navigation — one guard that covers both UI and accidental programmatic calls.
          onPressed: isCartEmpty
              ? null
              : () => context.router.push(const CheckoutRoute()),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Proceed to Checkout',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(AppConfig.formatPriceShort(totalAmount),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String itemName) {
    return Helpers.showConfirmDialog(context,
        title: 'Remove Item',
        message: 'Remove "$itemName" from cart?',
        confirmText: 'Remove',
        cancelText: 'Cancel');
  }

  Future<void> _showClearCartDialog(CartController controller) async {
    final confirm = await Helpers.showConfirmDialog(context,
        title: 'Clear Cart',
        message:
            'Are you sure you want to remove all items from cart?',
        confirmText: 'Clear All',
        cancelText: 'Cancel');
    if (confirm == true) {
      controller.clearCart();
      if (mounted) Helpers.showSuccess(context, 'Cart cleared');
    }
  }
}