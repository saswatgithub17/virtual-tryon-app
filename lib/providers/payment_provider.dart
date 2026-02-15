// lib/providers/payment_provider.dart
// Payment & Order State Management

import 'package:flutter/foundation.dart';
import '../models/dress_model.dart';
import '../services/api_service.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Customer Info
  String _customerName = '';
  String _customerEmail = '';
  String _customerPhone = '';

  // Order
  Order? _currentOrder;
  String? _orderId;

  // Payment
  String? _paymentIntentId;
  String? _clientSecret;
  bool _isProcessingPayment = false;
  bool _paymentSuccessful = false;

  // Receipt
  String? _receiptUrl;

  // State
  bool _isCreatingOrder = false;
  bool _isLoadingReceipt = false;
  String? _error;

  // Getters
  String get customerName => _customerName;
  String get customerEmail => _customerEmail;
  String get customerPhone => _customerPhone;
  Order? get currentOrder => _currentOrder;
  String? get orderId => _orderId;
  String? get paymentIntentId => _paymentIntentId;
  String? get clientSecret => _clientSecret;
  bool get isProcessingPayment => _isProcessingPayment;
  bool get paymentSuccessful => _paymentSuccessful;
  String? get receiptUrl => _receiptUrl;
  bool get isCreatingOrder => _isCreatingOrder;
  bool get isLoadingReceipt => _isLoadingReceipt;
  String? get error => _error;
  bool get hasOrder => _currentOrder != null;
  bool get hasReceipt => _receiptUrl != null;

  // Set customer information
  void setCustomerInfo({
    required String name,
    required String email,
    String? phone,
  }) {
    _customerName = name;
    _customerEmail = email;
    _customerPhone = phone ?? '';
    notifyListeners();
  }

  // Validate customer info
  String? validateCustomerInfo() {
    if (_customerName.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (_customerEmail.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!_isValidEmail(_customerEmail)) {
      return 'Please enter a valid email address';
    }
    return null; // Valid
  }

  // Email validation
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Create order
  Future<bool> createOrder(List<CartItem> items) async {
    if (items.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return false;
    }

    // Validate customer info first
    final validationError = validateCustomerInfo();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }

    _isCreatingOrder = true;
    _error = null;
    notifyListeners();

    try {
      _currentOrder = await _apiService.createOrder(
        customerName: _customerName,
        customerEmail: _customerEmail,
        customerPhone: _customerPhone.isEmpty ? null : _customerPhone,
        items: items,
      );

      _orderId = _currentOrder!.orderId;
      _error = null;

      debugPrint('Order created: $_orderId');
      return true;

    } catch (e) {
      _error = e.toString();
      _currentOrder = null;
      _orderId = null;
      debugPrint('Error creating order: $e');
      return false;
    } finally {
      _isCreatingOrder = false;
      notifyListeners();
    }
  }

  // Create payment intent (Stripe)
  Future<bool> createPaymentIntent() async {
    if (_currentOrder == null) {
      _error = 'No order found. Please create order first.';
      notifyListeners();
      return false;
    }

    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.createPaymentIntent(
        orderId: _currentOrder!.orderId,
        amount: _currentOrder!.totalAmount,
      );

      _clientSecret = response['client_secret'];
      _paymentIntentId = response['payment_intent_id'];

      debugPrint('Payment intent created: $_paymentIntentId');
      return true;

    } catch (e) {
      _error = e.toString();
      _clientSecret = null;
      _paymentIntentId = null;
      debugPrint('Error creating payment intent: $e');
      return false;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  // Confirm payment after Stripe processing
  Future<bool> confirmPayment() async {
    if (_orderId == null || _paymentIntentId == null) {
      _error = 'Missing order or payment information';
      notifyListeners();
      return false;
    }

    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.confirmPayment(
        orderId: _orderId!,
        paymentIntentId: _paymentIntentId!,
      );

      _paymentSuccessful = true;
      _receiptUrl = response['receipt_url'];

      debugPrint('Payment confirmed! Receipt: $_receiptUrl');
      return true;

    } catch (e) {
      _error = e.toString();
      _paymentSuccessful = false;
      debugPrint('Error confirming payment: $e');
      return false;
    } finally {
      _isProcessingPayment = false;
      notifyListeners();
    }
  }

  // Complete payment flow (create order + payment intent)
  Future<bool> initiatePayment(List<CartItem> items) async {
    // Step 1: Create order
    final orderCreated = await createOrder(items);
    if (!orderCreated) {
      return false;
    }

    // Step 2: Create payment intent
    final paymentIntentCreated = await createPaymentIntent();
    if (!paymentIntentCreated) {
      return false;
    }

    return true;
  }

  // Load receipt
  Future<bool> loadReceipt(String orderId) async {
    _isLoadingReceipt = true;
    _error = null;
    notifyListeners();

    try {
      _receiptUrl = await _apiService.getReceipt(orderId);
      debugPrint('Receipt loaded: $_receiptUrl');
      return true;
    } catch (e) {
      _error = e.toString();
      _receiptUrl = null;
      debugPrint('Error loading receipt: $e');
      return false;
    } finally {
      _isLoadingReceipt = false;
      notifyListeners();
    }
  }

  // Get order details
  Future<bool> loadOrder(String orderId) async {
    try {
      _currentOrder = await _apiService.getOrder(orderId);
      _orderId = orderId;

      // If order is completed, try to load receipt
      if (_currentOrder!.isCompleted && _currentOrder!.receiptUrl != null) {
        _receiptUrl = _currentOrder!.receiptUrl;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading order: $e');
      return false;
    }
  }

  // Get order summary for display
  Map<String, dynamic> getOrderSummary() {
    if (_currentOrder == null) {
      return {
        'items': [],
        'subtotal': 0.0,
        'total': 0.0,
        'itemCount': 0,
      };
    }

    return {
      'items': _currentOrder!.items,
      'subtotal': _currentOrder!.totalAmount,
      'total': _currentOrder!.totalAmount,
      'itemCount': _currentOrder!.items.length,
    };
  }

  // Reset payment state
  void resetPayment() {
    _paymentIntentId = null;
    _clientSecret = null;
    _isProcessingPayment = false;
    _paymentSuccessful = false;
    _error = null;
    notifyListeners();
  }

  // Clear all data (after successful order)
  void clearOrder() {
    _currentOrder = null;
    _orderId = null;
    _paymentIntentId = null;
    _clientSecret = null;
    _paymentSuccessful = false;
    _receiptUrl = null;
    _error = null;
    notifyListeners();
  }

  // Complete reset (for new session)
  void reset() {
    _customerName = '';
    _customerEmail = '';
    _customerPhone = '';
    _currentOrder = null;
    _orderId = null;
    _paymentIntentId = null;
    _clientSecret = null;
    _isProcessingPayment = false;
    _paymentSuccessful = false;
    _receiptUrl = null;
    _isCreatingOrder = false;
    _isLoadingReceipt = false;
    _error = null;
    notifyListeners();
  }

  // Get payment status message
  String getPaymentStatusMessage() {
    if (_paymentSuccessful) {
      return 'Payment successful! Your order has been confirmed.';
    }
    if (_isProcessingPayment) {
      return 'Processing payment...';
    }
    if (_error != null) {
      return 'Payment failed: $_error';
    }
    return 'Ready to process payment';
  }

  // Check if can proceed to payment
  bool get canProceedToPayment {
    return _currentOrder != null &&
        _clientSecret != null &&
        !_isProcessingPayment &&
        !_paymentSuccessful;
  }

  // Get formatted total
  String get formattedTotal {
    if (_currentOrder == null) return '₹0.00';
    return '₹${_currentOrder!.totalAmount.toStringAsFixed(2)}';
  }

  // Get item count
  int get itemCount {
    if (_currentOrder == null) return 0;
    return _currentOrder!.items.length;
  }
}