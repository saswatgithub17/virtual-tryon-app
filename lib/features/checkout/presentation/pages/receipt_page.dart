import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/controllers/checkout_controller.dart';

@RoutePage()
class ReceiptPage extends ConsumerStatefulWidget {
  final String orderId;
  const ReceiptPage({super.key, required this.orderId});

  @override
  ConsumerState<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends ConsumerState<ReceiptPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppTheme.successColor,
                                AppTheme.successColor.withOpacity(0.7)
                              ]),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        AppTheme.successColor.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 10)
                              ]),
                          child: const Icon(Icons.check,
                              size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text('Payment Successful!',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                          SizedBox(height: 12),
                          Text('Thank you for your order',
                              style: TextStyle(
                                  fontSize: 16, color: AppTheme.textSecondary),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildOrderDetailsCard(checkoutState),
                    const SizedBox(height: 24),
                    if (checkoutState.receiptUrl != null)
                      _buildReceiptCard(checkoutState),
                  ],
                ),
              ),
            ),
            _buildBottomActions(checkoutState),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard(CheckoutState state) {
    final totalAmount = state.currentOrder?.totalAmount ?? 0.0;
    final formattedTotal = '₹${totalAmount.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withOpacity(0.1),
          AppTheme.secondaryColor.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          _buildDetailRow('Order ID', state.currentOrder?.orderId ?? 'N/A',
              Icons.receipt_long),
          const Divider(height: 24),
          _buildDetailRow('Amount Paid', formattedTotal, Icons.payments),
          const Divider(height: 24),
          _buildDetailRow('Payment Method', 'Stripe', Icons.credit_card),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.description, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Receipt Available',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check,
                    color: AppTheme.successColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Your receipt is ready to download',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(CheckoutState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.receiptUrl != null)
              ElevatedButton.icon(
                onPressed: () => Helpers.showSuccess(
                    context, 'Receipt: ${state.receiptUrl}'),
                icon: const Icon(Icons.download),
                label: const Text('Download Receipt'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.router.popUntilRoot(),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}
