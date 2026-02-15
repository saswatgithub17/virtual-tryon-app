import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/core/services/validation_service.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:virtual_tryon_app/widgets/loading_widget.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

@RoutePage()
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Checkout',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LoadingOverlay(
        isLoading:
            checkoutState.isCreatingOrder || checkoutState.isProcessingPayment,
        message: checkoutState.isCreatingOrder
            ? 'Creating order...'
            : 'Processing payment...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Customer Information'),
                const SizedBox(height: 16),
                _buildCustomerForm(),
                const SizedBox(height: 32),
                _buildSectionTitle('Order Summary'),
                const SizedBox(height: 16),
                _buildOrderSummary(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(checkoutState),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold));
  }

  Widget _buildCustomerForm() {
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
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            validator: ValidationService.validateName,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email, color: AppTheme.primaryColor),
            ),
            validator: ValidationService.validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number (Optional)',
              prefixIcon: Icon(Icons.phone, color: AppTheme.primaryColor),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final cartItems = ref.read(cartControllerProvider);
    final cartController = ref.read(cartControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withOpacity(0.1),
          AppTheme.secondaryColor.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          ...cartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                        child: Text('${item.dress.name} (${item.selectedSize})',
                            style: const TextStyle(fontSize: 14))),
                    Text('x${item.quantity}',
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.textSecondary)),
                    const SizedBox(width: 12),
                    Text(AppConfig.formatPriceShort(item.subtotal),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(AppConfig.formatPrice(cartController.totalAmount),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CheckoutState state) {
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
        child: ElevatedButton(
          onPressed: state.isCreatingOrder || state.isProcessingPayment
              ? null
              : _proceedToPayment,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Proceed to Payment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    if (!_formKey.currentState!.validate()) {
      Helpers.showError(context, 'Please fill in all required fields');
      return;
    }

    final cartItems = ref.read(cartControllerProvider);
    final checkoutController = ref.read(checkoutControllerProvider.notifier);

    checkoutController.setCustomerInfo(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    final orderSuccess = await checkoutController.createOrder(cartItems);
    if (orderSuccess) {
      final paymentIntentSuccess =
          await checkoutController.createPaymentIntent();
      if (paymentIntentSuccess && mounted) {
        // In real app, we would show a custom payment screen or use Stripe SDK directly
        // Here we'll push to a PaymentScreen (to be created)
        context.router.push(const PaymentRoute());
      } else if (mounted) {
        Helpers.showError(
            context,
            ref.read(checkoutControllerProvider).error ??
                'Failed to initiate payment');
      }
    } else {
      if (mounted) {
        Helpers.showError(
            context,
            ref.read(checkoutControllerProvider).error ??
                'Failed to create order');
      }
    }
  }
}
