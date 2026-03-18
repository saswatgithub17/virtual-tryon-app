import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/controllers/checkout_controller.dart';
import 'package:virtual_tryon_app/widgets/loading_widget.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

enum PaymentMethod { stripe, upi }

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
  
  PaymentMethod _selectedPaymentMethod = PaymentMethod.stripe;
  
  // Card details controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

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
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
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
              if (_selectedPaymentMethod == PaymentMethod.stripe)
                _buildCardDetailsForm(),
              if (_selectedPaymentMethod == PaymentMethod.upi)
                _buildUPIQRCode(checkoutState),
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
          
          // Stripe Payment Option
          _buildPaymentOption(
            icon: Icons.credit_card,
            title: 'Stripe Payment',
            subtitle: 'Pay with debit/credit card',
            method: PaymentMethod.stripe,
            isSelected: _selectedPaymentMethod == PaymentMethod.stripe,
          ),
          const SizedBox(height: 12),
          
          // UPI QR Code Option
          _buildPaymentOption(
            icon: Icons.qr_code,
            title: 'UPI QR Code',
            subtitle: 'Scan & pay via GPay, PhonePe, Paytm',
            method: PaymentMethod.upi,
            isSelected: _selectedPaymentMethod == PaymentMethod.upi,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required PaymentMethod method,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryColor 
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, 
                color: isSelected ? Colors.white : Colors.grey, 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          color: isSelected ? AppTheme.primaryColor : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppTheme.successColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetailsForm() {
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
              Icon(Icons.credit_card, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('Card Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Card Number
          TextField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
              LengthLimitingTextInputFormatter(19),
            ],
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Expiry and CVV Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryDateFormatter(),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Expiry',
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Card Holder Name
          TextField(
            controller: _cardHolderController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Card Holder Name',
              hintText: 'JOHN DOE',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Test Card Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.warningColor, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Test Mode: Use card 4242 4242 4242 4242, Expiry: 12/26, CVV: 123',
                    style: TextStyle(fontSize: 11, color: AppTheme.warningColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUPIQRCode(CheckoutState state) {
    final totalAmount = state.currentOrder?.totalAmount ?? 0.0;
    final orderId = state.currentOrder?.orderId ?? 'N/A';
    
    // UPI payment URL format
    final upiId = 'saswatsumandwibedy17@okhdfcbank';
    final upiUrl = 'upi://pay?pa=$upiId&pn=AuraTry&am=$totalAmount&cu=INR&tn=Order-$orderId';

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
          const Row(
            children: [
              Icon(Icons.qr_code, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Text('UPI QR Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          
          // QR Code Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: upiUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (ctx, err) {
                    return const Center(
                      child: Text('Error generating QR code'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan with any UPI app',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // UPI Apps Quick Access Buttons
          const Text(
            'Or open directly in your app:',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildUPIAppButton('GPay', Icons.g_mobiledata, () => _openUPIApp('gpay', upiUrl)),
              _buildUPIAppButton('PhonePe', Icons.phone_android, () => _openUPIApp('phonepe', upiUrl)),
              _buildUPIAppButton('Paytm', Icons.payment, () => _openUPIApp('paytm', upiUrl)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                    SizedBox(width: 8),
                    Text('How to Pay',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: AppTheme.infoColor)),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInstruction('1. Tap on your UPI app above OR scan QR'),
                _buildInstruction('2. Verify the amount: ₹${totalAmount.toStringAsFixed(2)}'),
                _buildInstruction('3. Complete the payment in the app'),
                _buildInstruction('4. Return here and confirm payment'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Confirm Payment Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _confirmUpiPayment,
              icon: const Icon(Icons.check_circle),
              label: const Text('I have completed the payment'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.successColor),
                foregroundColor: AppTheme.successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUPIAppButton(String name, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _openUPIApp(String app, String upiUrl) async {
    String url;
    
    // Try to open the specific app first
    switch (app) {
      case 'gpay':
        url = upiUrl; // GPay handles UPI deep links
        break;
      case 'phonepe':
        url = upiUrl; // PhonePe handles UPI deep links
        break;
      case 'paytm':
        url = upiUrl; // Paytm handles UPI deep links
        break;
      default:
        url = upiUrl;
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          Helpers.showError(context, 'Unable to open $app. Please install the app or scan QR code.');
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Error opening app: $e');
      }
    }
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildPayButton(CheckoutState state) {
    final totalAmount = state.currentOrder?.totalAmount ?? 0.0;
    final formattedTotal = '₹${totalAmount.toStringAsFixed(2)}';

    // Only show Stripe pay button when Stripe is selected
    if (_selectedPaymentMethod != PaymentMethod.stripe) {
      return const SizedBox.shrink();
    }

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
    // Validate card details
    if (_cardNumberController.text.isEmpty || 
        _expiryController.text.isEmpty || 
        _cvvController.text.isEmpty ||
        _cardHolderController.text.isEmpty) {
      Helpers.showError(context, 'Please fill in all card details');
      return;
    }

    final controller = ref.read(checkoutControllerProvider.notifier);

    // Create payment intent with Stripe
    final intentSuccess = await controller.createPaymentIntent(paymentMethod: 'stripe');
    if (!intentSuccess && mounted) {
      Helpers.showError(context,
          ref.read(checkoutControllerProvider).error ?? 'Failed to create payment');
      return;
    }

    // Simulate real delay
    await Future.delayed(const Duration(seconds: 1));

    final success = await controller.confirmPayment();
    if (success && mounted) {
      ref.read(cartControllerProvider.notifier).clearCart();
      // Navigate to Thank You page first, then to receipt
      context.router.push(const ThankYouRoute());
    } else if (mounted) {
      Helpers.showError(context,
          ref.read(checkoutControllerProvider).error ?? 'Payment failed');
    }
  }

  Future<void> _confirmUpiPayment() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: const Text(
          'Have you completed the UPI payment? Make sure you have paid the exact amount shown in the QR code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Yes, I Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final controller = ref.read(checkoutControllerProvider.notifier);
      
      // For UPI, we create a payment intent with 'upi' method
      final intentSuccess = await controller.createPaymentIntent(paymentMethod: 'upi');
      if (!intentSuccess && mounted) {
        Helpers.showError(context,
            ref.read(checkoutControllerProvider).error ?? 'Failed to create payment');
        return;
      }
      
      // For UPI, we mark as successful since user confirmed payment
      final success = await controller.confirmUpiPayment();
      if (success && mounted) {
        ref.read(cartControllerProvider.notifier).clearCart();
        // Navigate to Thank You page
        context.router.push(const ThankYouRoute());
      } else if (mounted) {
        Helpers.showError(context,
            ref.read(checkoutControllerProvider).error ?? 'Payment failed');
      }
    }
  }
}

// Formatter for card number (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Formatter for expiry date (adds slash after 2 digits)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
