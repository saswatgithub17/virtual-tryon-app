// lib/services/api_service.dart
// HTTP API Service for Backend Communication

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';
import '../models/dress_model.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // GET Request
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
      final response = await http
          .get(url, headers: _headers)
          .timeout(ApiConfig.standardTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
      final response = await http
          .post(url, headers: _headers, body: jsonEncode(data))
          .timeout(ApiConfig.standardTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
      final response = await http
          .put(url, headers: _headers, body: jsonEncode(data))
          .timeout(ApiConfig.standardTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
      final response = await http
          .delete(url, headers: _headers)
          .timeout(ApiConfig.standardTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Multipart Request (for file uploads)
  Future<dynamic> uploadMultipart(
      String endpoint,
      File file,
      Map<String, String> fields,
      String fileFieldName,
      ) async {
    try {
      final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
      var request = http.MultipartRequest('POST', url);

      // Add fields
      request.fields.addAll(fields);

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        fileFieldName,
        file.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse =
      await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Handle Response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw HttpException(
        'Request failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }

  // Handle Errors
  String _handleError(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    } else if (error is HttpException) {
      return error.message;
    } else if (error is FormatException) {
      return 'Invalid response format from server.';
    } else {
      return 'An unexpected error occurred: $error';
    }
  }

  // ==================== API METHODS ====================

  // DRESSES
  Future<List<Dress>> getDresses({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
  }) async {
    String endpoint = ApiConfig.dresses;
    List<String> params = [];

    if (category != null) params.add('category=$category');
    if (minPrice != null) params.add('minPrice=$minPrice');
    if (maxPrice != null) params.add('maxPrice=$maxPrice');
    if (sortBy != null) params.add('sortBy=$sortBy');

    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }

    final response = await get(endpoint);
    if (response['success'] == true) {
      List<Dress> dresses = (response['data'] as List)
          .map((json) => Dress.fromJson(json))
          .toList();
      return dresses;
    }
    throw Exception(response['message'] ?? 'Failed to load dresses');
  }

  Future<Dress> getDressById(int id) async {
    final response = await get('${ApiConfig.dressById}$id');
    if (response['success'] == true) {
      return Dress.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to load dress');
  }

  Future<List<Dress>> searchDresses(String query) async {
    final response = await get('${ApiConfig.searchDresses}?q=$query');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => Dress.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Search failed');
  }

  // REVIEWS
  Future<List<Review>> getReviews(int dressId) async {
    final response = await get('${ApiConfig.reviews}$dressId');
    if (response['success'] == true) {
      return (response['data'] as List)
          .map((json) => Review.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<void> addReview({
    required int dressId,
    required int rating,
    String? customerName,
    String? reviewText,
  }) async {
    await post(ApiConfig.addReview, {
      'dress_id': dressId,
      'rating': rating,
      'customer_name': customerName ?? 'Anonymous',
      'review_text': reviewText,
    });
  }

  // ORDERS
  Future<Map<String, dynamic>> calculateTotal(List<CartItem> items) async {
    final response = await post(
      ApiConfig.calculateTotal,
      {'items': items.map((item) => item.toJson()).toList()},
    );
    if (response['success'] == true) {
      return response['data'];
    }
    throw Exception('Failed to calculate total');
  }

  Future<Order> createOrder({
    required String customerName,
    required String customerEmail,
    required String? customerPhone,
    required List<CartItem> items,
  }) async {
    final response = await post(ApiConfig.orders, {
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
    });

    if (response['success'] == true) {
      return Order.fromJson(response['data']);
    }
    throw Exception(response['message'] ?? 'Failed to create order');
  }

  Future<Order> getOrder(String orderId) async {
    final response = await get('${ApiConfig.orderById}$orderId');
    if (response['success'] == true) {
      return Order.fromJson(response['data']);
    }
    throw Exception('Failed to load order');
  }

  // PAYMENT
  Future<Map<String, dynamic>> createPaymentIntent({
    required String orderId,
    required double amount,
  }) async {
    final response = await post(ApiConfig.createPaymentIntent, {
      'order_id': orderId,
      'amount': amount,
    });

    if (response['success'] == true) {
      return response['data'];
    }
    throw Exception('Failed to create payment intent');
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String orderId,
    required String paymentIntentId,
  }) async {
    final response = await post(ApiConfig.confirmPayment, {
      'order_id': orderId,
      'payment_intent_id': paymentIntentId,
    });

    if (response['success'] == true) {
      return response['data'];
    }
    throw Exception('Payment confirmation failed');
  }

  Future<String> getReceipt(String orderId) async {
    final response = await get('${ApiConfig.getReceipt}$orderId');
    if (response['success'] == true) {
      return response['data']['receipt_url'];
    }
    throw Exception('Failed to get receipt');
  }

  // VIRTUAL TRY-ON
  Future<List<TryOnResult>> processTryOn({
    required File userPhoto,
    required List<int> dressIds,
  }) async {
    final response = await uploadMultipart(
      ApiConfig.tryOn,
      userPhoto,
      {'dress_ids': jsonEncode(dressIds)},
      'userPhoto',
    );

    if (response['success'] == true) {
      return (response['data']['results'] as List)
          .map((json) => TryOnResult.fromJson(json))
          .toList();
    }
    throw Exception(response['message'] ?? 'Try-on failed');
  }
}