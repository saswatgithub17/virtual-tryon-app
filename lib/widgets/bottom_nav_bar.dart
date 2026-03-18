import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

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
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checkroom_outlined),
          activeIcon: Icon(Icons.checkroom),
          label: 'Try On',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
      ],
    );
  }
}

// Hidden admin access — tap Cart (index 2) 5 times quickly
class _AdminAccessCounter {
  static int _tapCount = 0;
  static DateTime? _lastTapTime;

  static bool checkTap() {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds > 800) {
      _tapCount = 0;
    }
    _lastTapTime = now;
    _tapCount++;
    if (_tapCount >= 5) {
      _tapCount = 0;
      return true;
    }
    return false;
  }
}

// Admin-access-enabled nav bar — use this wherever you want the hidden trigger
class AdminAwareBottomNavBar extends ConsumerStatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminAwareBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  ConsumerState<AdminAwareBottomNavBar> createState() =>
      _AdminAwareBottomNavBarState();
}

class _AdminAwareBottomNavBarState
    extends ConsumerState<AdminAwareBottomNavBar> {
  void _showAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings,
                color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Admin Access'),
          ],
        ),
        content: const Text(
            'Would you like to access the Admin Dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.router.push(const AdminLoginRoute());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            child: const Text('Go to Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == 2 && _AdminAccessCounter.checkTap()) {
          _showAdminDialog();
        }
        widget.onTap(index);
      },
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.checkroom_outlined),
          activeIcon: Icon(Icons.checkroom),
          label: 'Try On',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
      ],
    );
  }
}