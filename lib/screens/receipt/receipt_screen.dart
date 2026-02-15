// lib/screens/receipt/receipt_screen.dart
// Premium Receipt Screen with A1++ UI - FINAL SCREEN!

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../config/theme_config.dart';
import '../../config/api_config.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/helpers.dart';

class ReceiptScreen extends StatefulWidget {
  final String orderId;

  const ReceiptScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadReceipt();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadReceipt() async {
    final payment = Provider.of<PaymentProvider>(context, listen: false);
    await payment.loadReceipt(widget.orderId);

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
      body: SafeArea(
        child: _isLoading
            ? LoadingWidget.withMessage('Loading receipt...')
            : _buildSuccessContent(),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Consumer<PaymentProvider>(
      builder: (context, payment, child) {
        return Column(
          children: [
            // Success animation
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Success icon
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ThemeConfig.successColor,
                                ThemeConfig.successColor.withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ThemeConfig.successColor.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Success message
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Column(
                        children: [
                          Text(
                            'Payment Successful!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Thank you for your order',
                            style: TextStyle(
                              fontSize: 16,
                              color: ThemeConfig.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Order details card
                    _buildOrderDetailsCard(payment),

                    const SizedBox(height: 24),

                    // Receipt info
                    if (payment.hasReceipt) _buildReceiptCard(payment),
                  ],
                ),
              ),
            ),

            // Bottom actions
            _buildBottomActions(payment),
          ],
        );
      },
    );
  }

  Widget _buildOrderDetailsCard(PaymentProvider payment) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.primaryColor.withOpacity(0.1),
            ThemeConfig.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeConfig.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Order ID',
            payment.orderId ?? 'N/A',
            Icons.receipt_long,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Amount Paid',
            payment.formattedTotal,
            Icons.payments,
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Payment Method',
            'Stripe',
            Icons.credit_card,
          ),
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
            color: ThemeConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: ThemeConfig.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: ThemeConfig.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard(PaymentProvider payment) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.description,
                color: ThemeConfig.primaryColor,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Receipt Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThemeConfig.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: ThemeConfig.successColor,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your receipt is ready to download',
            style: TextStyle(
              fontSize: 13,
              color: ThemeConfig.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(PaymentProvider payment) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (payment.hasReceipt)
              ElevatedButton.icon(
                onPressed: () => _downloadReceipt(payment.receiptUrl!),
                icon: const Icon(Icons.download),
                label: const Text('Download Receipt'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadReceipt(String receiptUrl) {
    final fullUrl = ApiConfig.getUploadUrl(receiptUrl);
    Helpers.showSuccess(context, 'Receipt URL: $fullUrl');
    // In a real app, implement actual download functionality
    // using url_launcher or similar package
  }
}