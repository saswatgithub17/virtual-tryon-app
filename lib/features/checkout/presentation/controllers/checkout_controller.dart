import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_tryon_app/features/cart/data/models/cart_model.dart';
import 'package:virtual_tryon_app/features/checkout/data/models/order_model.dart';
import 'package:virtual_tryon_app/core/network/api_service.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';

part 'checkout_controller.g.dart';

@riverpod
class CheckoutController extends _$CheckoutController {
  @override
  CheckoutState build() {
    return const CheckoutState();
  }

  void setCustomerInfo({
    required String name,
    required String email,
    String? phone,
  }) {
    state = state.copyWith(
      customerName: name,
      customerEmail: email,
      customerPhone: phone ?? '',
      error: null,
    );
  }

  Future<bool> createOrder(List<CartItem> items) async {
    if (items.isEmpty) {
      state = state.copyWith(error: 'Cart is empty');
      return false;
    }

    if (state.customerName.isEmpty || state.customerEmail.isEmpty) {
      state = state.copyWith(error: 'Please enter customer information');
      return false;
    }

    state = state.copyWith(isCreatingOrder: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);

      // Convert items to simple JSON format
      final itemsJson = items.map((e) => e.toSimpleJson()).toList();

      print('DEBUG: Sending items: $itemsJson');

      final response = await apiService.createOrder(
        customerName: state.customerName,
        customerEmail: state.customerEmail,
        customerPhone: state.customerPhone.isEmpty ? null : state.customerPhone,
        items: itemsJson,
      );

      // DEBUG: Print full response
      print('DEBUG: Full response: $response');
      print('DEBUG: Response keys: ${response?.keys.toList()}');
      print('DEBUG: Response type: ${response.runtimeType}');

      // Check if response is valid
      if (response == null) {
        state = state.copyWith(
          error: 'Invalid response from server',
          isCreatingOrder: false,
        );
        return false;
      }

      // Try different possible keys for order data
      final orderData = response['order'] ?? response['data'] ?? response;
      print('DEBUG: Order data: $orderData');

      if (orderData == null || orderData is! Map) {
        state = state.copyWith(
          error: 'No order data in response',
          isCreatingOrder: false,
        );
        return false;
      }

      final order = Order.fromMap(orderData as Map<String, dynamic>);

      state = state.copyWith(
        currentOrder: order,
        isCreatingOrder: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isCreatingOrder: false,
      );
      return false;
    }
  }

  Future<bool> createPaymentIntent({String paymentMethod = 'stripe'}) async {
    if (state.currentOrder == null) {
      state = state.copyWith(error: 'No order found');
      return false;
    }

    state = state.copyWith(isProcessingPayment: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.createPaymentIntent(
        orderId: state.currentOrder!.orderId,
        amount: state.currentOrder!.totalAmount,
        paymentMethod: paymentMethod,
      );

      if (response == null) {
        state = state.copyWith(
          error: 'Invalid payment response',
          isProcessingPayment: false,
        );
        return false;
      }

      state = state.copyWith(
        clientSecret: response['client_secret'],
        paymentIntentId: response['payment_intent_id'],
        paymentMethod: paymentMethod,
        isProcessingPayment: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessingPayment: false,
      );
      return false;
    }
  }

  Future<bool> confirmPayment() async {
    if (state.currentOrder == null || state.paymentIntentId == null) {
      state = state.copyWith(error: 'Missing order or payment info');
      return false;
    }

    state = state.copyWith(isProcessingPayment: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.confirmPayment(
        orderId: state.currentOrder!.orderId,
        paymentIntentId: state.paymentIntentId!,
      );

      if (response == null) {
        state = state.copyWith(
          error: 'Invalid payment confirmation response',
          isProcessingPayment: false,
        );
        return false;
      }

      state = state.copyWith(
        paymentSuccessful: true,
        receiptUrl: response['receipt_url'],
        isProcessingPayment: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        paymentSuccessful: false,
        isProcessingPayment: false,
      );
      return false;
    }
  }

  // ─── FIX: UPI payment now calls backend to confirm and get PDF receipt URL ───
  Future<bool> confirmUpiPayment() async {
    if (state.currentOrder == null) {
      state = state.copyWith(error: 'No order found');
      return false;
    }

    state = state.copyWith(isProcessingPayment: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);

      // Call backend /payment/confirm with order_id and payment_method=upi.
      // This triggers receipt PDF generation on the backend and returns receipt_url.
      final response = await apiService.post(
        ApiConfig.confirmPayment,
        data: {
          'order_id': state.currentOrder!.orderId,
          'payment_method': 'upi',
        },
      );

      print('DEBUG UPI confirm response: $response');

      state = state.copyWith(
        paymentSuccessful: true,
        // receipt_url comes back as '/uploads/receipts/receipt-ORD-xxx.pdf'
        receiptUrl: response?['receipt_url'] ?? response?['receiptUrl'],
        isProcessingPayment: false,
      );
      return true;
    } catch (e) {
      print('DEBUG UPI confirm error: $e');
      // Payment was already made by user — mark success even if backend call fails,
      // but receipt URL will be null (handled gracefully in receipt_page).
      state = state.copyWith(
        paymentSuccessful: true,
        isProcessingPayment: false,
        error: null,
      );
      return true;
    }
  }

  void reset() {
    state = const CheckoutState();
  }
}

class CheckoutState {
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Order? currentOrder;
  final String? clientSecret;
  final String? paymentIntentId;
  final String paymentMethod;
  final bool isProcessingPayment;
  final bool paymentSuccessful;
  final String? receiptUrl;
  final bool isCreatingOrder;
  final String? error;

  const CheckoutState({
    this.customerName = '',
    this.customerEmail = '',
    this.customerPhone = '',
    this.currentOrder,
    this.clientSecret,
    this.paymentIntentId,
    this.paymentMethod = 'stripe',
    this.isProcessingPayment = false,
    this.paymentSuccessful = false,
    this.receiptUrl,
    this.isCreatingOrder = false,
    this.error,
  });

  CheckoutState copyWith({
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    Order? currentOrder,
    String? clientSecret,
    String? paymentIntentId,
    String? paymentMethod,
    bool? isProcessingPayment,
    bool? paymentSuccessful,
    String? receiptUrl,
    bool? isCreatingOrder,
    String? error,
  }) {
    return CheckoutState(
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      currentOrder: currentOrder ?? this.currentOrder,
      clientSecret: clientSecret ?? this.clientSecret,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      paymentSuccessful: paymentSuccessful ?? this.paymentSuccessful,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
      error: error ?? this.error,
    );
  }
}