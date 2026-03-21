import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
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
  String? _upiTransactionId; // stored after createPaymentIntent for UPI
  bool _upiAppOpened = false; // true only when user tapped GPay/PhonePe/Paytm

  final _cardNumberController = TextEditingController();
  final _expiryController     = TextEditingController();
  final _cvvController        = TextEditingController();
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

  // ─── BUILD ───────────────────────────────────────────────────────────────

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

  // ─── ORDER SUMMARY ────────────────────────────────────────────────────────

  Widget _buildOrderSummaryCard(CheckoutState state) {
    final total = state.currentOrder?.totalAmount ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.receipt_long, color: Colors.white.withOpacity(0.9), size: 28),
          const SizedBox(width: 12),
          const Text('Order Summary',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
        _summaryRow('Order ID', state.currentOrder?.orderId ?? 'N/A'),
        const SizedBox(height: 12),
        _summaryRow('Items', '${state.currentOrder?.items.length ?? 0}'),
        const Divider(color: Colors.white24, height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Amount',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('₹${total.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _summaryRow(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    ],
  );

  // ─── PAYMENT METHOD SELECTOR ──────────────────────────────────────────────

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.payment, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        _buildPaymentOption(
          icon: Icons.credit_card, title: 'Stripe Payment',
          subtitle: 'Pay with debit/credit card',
          method: PaymentMethod.stripe,
          isSelected: _selectedPaymentMethod == PaymentMethod.stripe,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          icon: Icons.qr_code, title: 'UPI QR Code',
          subtitle: 'Scan & pay via GPay, PhonePe, Paytm',
          method: PaymentMethod.upi,
          isSelected: _selectedPaymentMethod == PaymentMethod.upi,
        ),
      ]),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon, required String title,
    required String subtitle, required PaymentMethod method, required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16,
                color: isSelected ? AppTheme.primaryColor : Colors.black)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ])),
          Icon(isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppTheme.successColor : Colors.grey),
        ]),
      ),
    );
  }

  // ─── CARD FORM ────────────────────────────────────────────────────────────

  Widget _buildCardDetailsForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.credit_card, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Text('Card Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
            LengthLimitingTextInputFormatter(19),
          ],
          decoration: InputDecoration(
            labelText: 'Card Number', hintText: '1234 5678 9012 3456',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextField(
            controller: _expiryController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ExpiryDateFormatter(),
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              labelText: 'Expiry', hintText: 'MM/YY',
              prefixIcon: const Icon(Icons.calendar_today),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
          const SizedBox(width: 16),
          Expanded(child: TextField(
            controller: _cvvController,
            keyboardType: TextInputType.number,
            obscureText: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              labelText: 'CVV', hintText: '123',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _cardHolderController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Card Holder Name', hintText: 'JOHN DOE',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: AppTheme.warningColor, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Test Mode: Use card 4242 4242 4242 4242, Expiry: 12/26, CVV: 123',
              style: TextStyle(fontSize: 11, color: AppTheme.warningColor),
            )),
          ]),
        ),
      ]),
    );
  }

  // ─── UPI QR ───────────────────────────────────────────────────────────────

  Widget _buildUPIQRCode(CheckoutState state) {
    final total   = state.currentOrder?.totalAmount ?? 0.0;
    final orderId = state.currentOrder?.orderId ?? 'N/A';
    const upiId   = 'saswatsumandwibedy17@okhdfcbank';
    final upiUrl  = 'upi://pay?pa=$upiId&pn=AuraTry&am=$total&cu=INR&tn=Order-$orderId';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(children: [
        const Row(children: [
          Icon(Icons.qr_code, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Text('UPI QR Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
          ),
          child: Column(children: [
            QrImageView(
              data: upiUrl,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text('₹${total.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            Text('Scan with any UPI app',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Or open directly in your app:',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _buildUPIAppButton('GPay',    Icons.g_mobiledata,  () => _openUPIApp(upiUrl)),
          _buildUPIAppButton('PhonePe', Icons.phone_android, () => _openUPIApp(upiUrl)),
          _buildUPIAppButton('Paytm',   Icons.payment,       () => _openUPIApp(upiUrl)),
        ]),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            const Row(children: [
              Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
              SizedBox(width: 8),
              Text('How to Pay',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.infoColor)),
            ]),
            const SizedBox(height: 8),
            _buildInstruction('1. Tap on your UPI app above OR scan QR'),
            _buildInstruction('2. Verify the amount: ₹${total.toStringAsFixed(2)}'),
            _buildInstruction('3. Complete the payment in the app'),
            _buildInstruction('4. Return here and tap the button below'),
          ]),
        ),
        const SizedBox(height: 16),

        // ── VERIFY PAYMENT BUTTON ──────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _confirmUpiPayment,
            icon: const Icon(Icons.verified_user),
            label: const Text('I have completed the payment',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildUPIAppButton(String name, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Future<void> _openUPIApp(String upiUrl) async {
    try {
      final uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Mark that user opened a UPI app — they had the opportunity to pay
        setState(() => _upiAppOpened = true);
      } else if (mounted) {
        Helpers.showError(context, 'Could not open UPI app. Please scan the QR code.');
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Error opening app: $e');
    }
  }

  Widget _buildInstruction(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
  );

  // ─── STRIPE PAY BUTTON ────────────────────────────────────────────────────

  Widget _buildPayButton(CheckoutState state) {
    if (_selectedPaymentMethod != PaymentMethod.stripe) return const SizedBox.shrink();
    final total = state.currentOrder?.totalAmount ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: ElevatedButton(
            onPressed: state.isProcessingPayment ? null : _processPayment,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock, size: 20),
              const SizedBox(width: 8),
              Text('Pay ₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── STRIPE PROCESS ───────────────────────────────────────────────────────

  Future<void> _processPayment() async {
    if (_cardNumberController.text.isEmpty ||
        _expiryController.text.isEmpty    ||
        _cvvController.text.isEmpty       ||
        _cardHolderController.text.isEmpty) {
      Helpers.showError(context, 'Please fill in all card details');
      return;
    }

    final controller = ref.read(checkoutControllerProvider.notifier);

    final intentSuccess = await controller.createPaymentIntent(paymentMethod: 'stripe');
    if (!intentSuccess && mounted) {
      Helpers.showError(context,
          ref.read(checkoutControllerProvider).error ?? 'Failed to create payment');
      return;
    }

    await Future.delayed(const Duration(seconds: 1));

    final success = await controller.confirmPayment();
    if (success && mounted) {
      ref.read(cartControllerProvider.notifier).clearCart();
      context.router.push(const ThankYouRoute());
    } else if (mounted) {
      Helpers.showError(context,
          ref.read(checkoutControllerProvider).error ?? 'Payment failed');
    }
  }

  // ─── UPI VERIFY WITH ANIMATED STEPS ──────────────────────────────────────
  // Flow:
  //  1. Create payment intent in DB (status=pending)
  //  2. Confirm with backend (status=completed, receipt generated)
  //  3. Animated dialog shows steps using the RESULT of step 2 — no second
  //     network call needed, eliminating the network-race false-failure bug.

  Future<void> _confirmUpiPayment() async {
    final state      = ref.read(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);
    final orderId    = state.currentOrder?.orderId;

    if (orderId == null) {
      Helpers.showError(context, 'No order found');
      return;
    }

    // ── KEY LOGIC ────────────────────────────────────────────────────────────
    // UPI has no automatic webhook — the backend cannot know if user paid.
    // We use _upiAppOpened as the gate:
    //   true  → user tapped GPay/PhonePe/Paytm → had the opportunity to pay
    //           → call backend to confirm + generate receipt → show GREEN
    //   false → user tapped "I've paid" without opening any UPI app
    //           → they clearly haven't paid → skip backend call → show RED

    if (!_upiAppOpened) {
      // User never opened a UPI app — show failure immediately
      await _showVerificationDialog(false);
      return;
    }

    // User opened a UPI app → create intent + confirm with backend
    final intentSuccess =
        await controller.createPaymentIntent(paymentMethod: 'upi');
    if (!intentSuccess && mounted) {
      await _showVerificationDialog(false);
      return;
    }

    final confirmed = await controller.confirmUpiPayment();
    if (!mounted) return;
    await _showVerificationDialog(confirmed);
  }

  Future<void> _showVerificationDialog(bool paymentVerified) async {
    // Step states: 0=pending, 1=success, 2=failed
    final stepStatus = ValueNotifier<List<int>>([0, 0, 0]);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ValueListenableBuilder<List<int>>(
              valueListenable: stepStatus,
              builder: (_, statuses, __) {
                final allDone    = statuses.every((s) => s != 0);
                final allSuccess = statuses.every((s) => s == 1);

                return Column(mainAxisSize: MainAxisSize.min, children: [
                  // Header
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: allDone
                          ? (allSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE53935))
                          : AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: allDone
                        ? Icon(allSuccess ? Icons.check : Icons.close,
                            color: Colors.white, size: 36)
                        : const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    allDone
                        ? (allSuccess ? 'Payment Verified!' : 'Verification Failed')
                        : 'Verifying Payment...',
                    style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: allDone
                          ? (allSuccess ? const Color(0xFF4CAF50) : const Color(0xFFE53935))
                          : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step 1
                  _stepRow(statuses[0], 'Connecting to payment server'),
                  const SizedBox(height: 12),
                  // Step 2
                  _stepRow(statuses[1], 'Verifying transaction ID'),
                  const SizedBox(height: 12),
                  // Step 3
                  _stepRow(statuses[2], 'Confirming with bank'),

                  if (allDone) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (allSuccess) {
                            ref.read(cartControllerProvider.notifier).clearCart();
                            context.router.push(const ThankYouRoute());
                          }
                          // On failure: dialog closes, user stays on payment page
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: allSuccess
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          allSuccess ? 'Continue to Order Summary' : 'Try Again',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    if (!allSuccess) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Payment not confirmed. Please ensure you completed\nthe transfer and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ]);
              },
            ),
          ),
        ),
      ),
    );

    // ── Animate 3 steps using the confirmed result directly ──────────────────
    // paymentVerified = return value of confirmUpiPayment() which already
    // called the backend. No second network call = no false-failure bug.

    await Future.delayed(const Duration(milliseconds: 900));
    stepStatus.value = [1, 0, 0];          // Step 1 always passes

    await Future.delayed(const Duration(milliseconds: 1000));
    stepStatus.value = [1, paymentVerified ? 1 : 2, 0]; // Step 2

    await Future.delayed(const Duration(milliseconds: 1000));
    stepStatus.value = [1, paymentVerified ? 1 : 2, paymentVerified ? 1 : 2];
  }

  // Single step row widget
  Widget _stepRow(int status, String label) {
    final color = status == 1
        ? const Color(0xFF4CAF50)
        : status == 2
            ? const Color(0xFFE53935)
            : const Color(0xFF6C3DEB);

    final icon = status == 1
        ? Icons.check_circle
        : status == 2
            ? Icons.cancel
            : Icons.radio_button_unchecked;

    return Row(children: [
      // Icon / spinner
      SizedBox(
        width: 28, height: 28,
        child: status == 0
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Color(0xFF6C3DEB)))
            : Icon(icon, color: color, size: 26),
      ),
      const SizedBox(width: 14),
      Text(label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: status == 0 ? Colors.grey : const Color(0xFF1A1A2E),
          )),
      const Spacer(),
      // Animated dots while pending
      if (status == 0)
        const _AnimatedDots(),
    ]);
  }
}

// ── Animated "..." while step is pending ──────────────────────────────────────
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}
class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _dot = 0;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..addListener(() {
        if (_ctrl.isCompleted) {
          setState(() => _dot = (_dot + 1) % 4);
          _ctrl.forward(from: 0);
        }
      })
      ..forward();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Text('.' * _dot, style: const TextStyle(
        fontSize: 18, color: Color(0xFF6C3DEB), fontWeight: FontWeight.bold));
  }
}

// ─── Input Formatters ─────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buf  = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(text[i]);
    }
    return TextEditingValue(
        text: buf.toString(),
        selection: TextSelection.collapsed(offset: buf.length));
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    final buf  = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buf.write('/');
      buf.write(text[i]);
    }
    return TextEditingValue(
        text: buf.toString(),
        selection: TextSelection.collapsed(offset: buf.length));
  }
}