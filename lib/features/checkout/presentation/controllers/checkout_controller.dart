import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:virtual_tryon_app/features/cart/data/models/cart_model.dart';
import 'package:virtual_tryon_app/features/checkout/data/models/order_model.dart';
import 'package:virtual_tryon_app/core/network/api_service.dart';

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
      final response = await apiService.createOrder(
        customerName: state.customerName,
        customerEmail: state.customerEmail,
        customerPhone: state.customerPhone.isEmpty ? null : state.customerPhone,
        items: items.map((e) => e.toJson()).toList(),
      );

      final order = Order.fromMap(response['order']);

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

  Future<bool> createPaymentIntent() async {
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
      );

      state = state.copyWith(
        clientSecret: response['client_secret'],
        paymentIntentId: response['payment_intent_id'],
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
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      paymentSuccessful: paymentSuccessful ?? this.paymentSuccessful,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
      error: error ?? this.error,
    );
  }
}
