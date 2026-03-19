import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';

/// Main bottom nav bar used by all non-admin pages.
/// Automatically watches the cart and shows a live badge on the Cart tab.
class AppBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart — badge updates instantly when items are added/removed
    final cartItems = ref.watch(cartControllerProvider);
    final cartCount =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      elevation: 12,
      backgroundColor: Colors.white,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.style_outlined),
          activeIcon: Icon(Icons.style),
          label: 'Try On',
        ),
        BottomNavigationBarItem(
          icon: _CartBadgeIcon(count: cartCount, isActive: false),
          activeIcon: _CartBadgeIcon(count: cartCount, isActive: true),
          label: 'Cart',
        ),
      ],
    );
  }
}

/// Cart icon with an animated badge showing item count.
class _CartBadgeIcon extends StatelessWidget {
  final int count;
  final bool isActive;

  const _CartBadgeIcon({required this.count, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined,
    );

    if (count == 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -6,
          right: -8,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF4444), Color(0xFFFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}