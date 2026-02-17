import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  bool _isDownloading = false;

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
          _buildDetailRow('Payment Method', state.paymentMethod == 'upi' ? 'UPI QR Code' : 'Stripe Card', Icons.credit_card),
          const Divider(height: 24),
          _buildDetailRow('Date', _getCurrentDate(), Icons.calendar_today),
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
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
                  child: Text('Receipt Details',
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
          const SizedBox(height: 16),
          
          // Order items
          if (state.currentOrder?.items != null && state.currentOrder!.items.isNotEmpty) ...[
            ...state.currentOrder!.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.checkroom, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.dressName ?? 'Product',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Size: ${item.sizeName ?? "N/A"} | Qty: ${item.quantity ?? 0}',
                          style: const TextStyle(
                            fontSize: 12, 
                            color: AppTheme.textSecondary
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(item.subtotal ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₹${state.currentOrder?.totalAmount.toStringAsFixed(2) ?? "0.00"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18,
                    color: AppTheme.primaryColor
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text(
              'Your receipt is ready to download',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
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
            // Download/Share Receipt Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : () => _shareReceipt(state),
                    icon: _isDownloading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.share),
                    label: Text(_isDownloading ? 'Sharing...' : 'Share Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading ? null : () => _downloadReceipt(state),
                    icon: const Icon(Icons.download),
                    label: const Text('Save to Device'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
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

  Future<void> _shareReceipt(CheckoutState state) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Generate receipt content
      final receiptContent = _generateReceiptText(state);
      
      // Get temp directory
      final directory = await getTemporaryDirectory();
      final orderId = state.currentOrder?.orderId ?? 'receipt';
      final fileName = 'receipt_$orderId.txt';
      final filePath = '${directory.path}/$fileName';
      
      // Write the file
      final file = File(filePath);
      await file.writeAsString(receiptContent);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Order Receipt from Aura Try',
        subject: 'Receipt - Order #$orderId',
      );
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        Helpers.showError(context, 'Failed to share receipt: $e');
      }
    }
  }

  Future<void> _downloadReceipt(CheckoutState state) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Generate receipt content
      final receiptContent = _generateReceiptText(state);
      
      // Get the downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final orderId = state.currentOrder?.orderId ?? 'receipt';
      final fileName = 'receipt_$orderId.txt';
      final filePath = '${directory.path}/$fileName';
      
      // Write the file
      final file = File(filePath);
      await file.writeAsString(receiptContent);
      
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        
        // Show success message with option to share
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.successColor, size: 60),
                const SizedBox(height: 16),
                const Text('Receipt Saved!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Saved as: $fileName',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _shareReceipt(state);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.done),
                        label: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        Helpers.showError(context, 'Failed to download receipt: $e');
      }
    }
  }

  String _generateReceiptText(CheckoutState state) {
    final order = state.currentOrder;
    final orderId = order?.orderId ?? 'N/A';
    final totalAmount = order?.totalAmount ?? 0.0;
    final date = _getCurrentDate();
    final paymentMethod = state.paymentMethod == 'upi' ? 'UPI QR Code' : 'Stripe Card';
    
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln('              AURA TRY - RECEIPT            ');
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Order ID: $orderId');
    buffer.writeln('Date: $date');
    buffer.writeln('Payment Method: $paymentMethod');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────');
    buffer.writeln('ITEMS');
    buffer.writeln('───────────────────────────────────────────');
    
    if (order?.items != null && order!.items.isNotEmpty) {
      for (final item in order.items) {
        final name = item.dressName ?? 'Product';
        final size = item.sizeName ?? 'N/A';
        final qty = item.quantity ?? 0;
        final price = item.subtotal ?? 0.0;
        buffer.writeln('$name');
        buffer.writeln('  Size: $size | Qty: $qty');
        buffer.writeln('  Price: ₹${price.toStringAsFixed(2)}');
        buffer.writeln();
      }
    } else {
      buffer.writeln('No items found');
      buffer.writeln();
    }
    
    buffer.writeln('───────────────────────────────────────────');
    buffer.writeln('TOTAL: ₹${totalAmount.toStringAsFixed(2)}');
    buffer.writeln('═══════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Thank you for shopping with Aura Try!');
    buffer.writeln('For support: support@virtualtryon.com');
    buffer.writeln();
    buffer.writeln('This is a computer-generated receipt.');
    buffer.writeln('No signature required.');
    
    return buffer.toString();
  }
}
