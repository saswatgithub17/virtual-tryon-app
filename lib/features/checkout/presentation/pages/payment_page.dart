import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:virtual_tryon_app/widgets/loading_widget.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

@RoutePage()
class PaymentPage extends ConsumerStatefulWidget {
  const PaymentPage({super.key});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
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
      appBar: AppBar(
        title: const Text('Payment',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LoadingOverlay(
        isLoading: checkoutState.isProcessingPayment,
        message: 'Processing payment...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderSummaryCard(checkoutState),
              const SizedBox(height: 24),
              _buildPaymentMethodCard(),
              const SizedBox(height: 24),
              _buildTestCardInfo(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildPayButton(checkoutState),
    );
  }

  Widget _buildOrderSummaryCard(CheckoutState state) {
    final totalAmount = state.currentOrder?.totalAmount ?? 0.0;
    final formattedTotal = '₹${totalAmount.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long,
                  color: Colors.white.withOpacity(0.9), size: 28),
              const SizedBox(width: 12),
              const Text('Order Summary',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ID',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14)),
              Text(state.currentOrder?.orderId ?? 'N/A',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 14)),
              Text('${state.currentOrder?.items.length ?? 0}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(formattedTotal,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.credit_card,
                      color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stripe Payment',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Secure payment via Stripe',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppTheme.successColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCardInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
              SizedBox(width: 8),
              Text('Test Mode',
                  style: TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          SizedBox(height: 8),
          Text('Use test card: 4242 4242 4242 4242',
              style: TextStyle(fontSize: 12)),
          Text('Expiry: 12/26, CVV: 123', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPayButton(CheckoutState state) {
    final totalAmount = state.currentOrder?.totalAmount ?? 0.0;
    final formattedTotal = '₹${totalAmount.toStringAsFixed(2)}';

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
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: ElevatedButton(
            onPressed: state.isProcessingPayment ? null : _processPayment,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 20),
                const SizedBox(width: 8),
                Text('Pay $formattedTotal',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    final controller = ref.read(checkoutControllerProvider.notifier);

    // Simulate real delay
    await Future.delayed(const Duration(seconds: 1));

    final success = await controller.confirmPayment();
    if (success && mounted) {
      ref.read(cartControllerProvider.notifier).clearCart();
      Helpers.showSuccess(context, 'Payment successful!');
      context.router.push(ReceiptRoute(
          orderId: ref.read(checkoutControllerProvider).currentOrder!.orderId));
    } else if (mounted) {
      Helpers.showError(context,
          ref.read(checkoutControllerProvider).error ?? 'Payment failed');
    }
  }
}
