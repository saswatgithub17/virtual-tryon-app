import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_config.dart';

part 'api_service.g.dart';

@Riverpod(keepAlive: true)
ApiService apiService(Ref ref) {
  return ApiService();
}

class ApiService {
  // Headers
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // GET Request
  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParameters}) async {
    try {
      var url = Uri.parse(ApiConfig.getFullUrl(endpoint));
      if (queryParameters != null) {
        url = url.replace(queryParameters: queryParameters);
      }
      final response = await http
          .get(url, headers: _headers)
          .timeout(ApiConfig.standardTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final url = Uri.parse(ApiConfig.getFullUrl(endpoint));
      final response = await http
          .post(url,
              headers: _headers, body: data != null ? jsonEncode(data) : null)
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

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Virtual Try-On
  Future<dynamic> processTryOn({
    required File userPhoto,
    required List<int> dressIds,
  }) async {
    return uploadMultipart(
      ApiConfig.processImage,
      userPhoto,
      {'dressIds': dressIds.join(',')},
      'person_image',
    );
  }

  // Create Order
  Future<dynamic> createOrder({
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    required List<dynamic> items,
  }) async {
    return post(ApiConfig.createOrder, data: {
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'items': items,
    });
  }

  // Create Payment Intent
  Future<dynamic> createPaymentIntent({
    required String orderId,
    required double amount,
  }) async {
    return post(ApiConfig.createPaymentIntent, data: {
      'order_id': orderId,
      'amount': (amount * 100).toInt(),
      'currency': 'inr',
    });
  }

  // Confirm Payment
  Future<dynamic> confirmPayment({
    required String orderId,
    required String paymentIntentId,
  }) async {
    return post(ApiConfig.confirmPayment, data: {
      'order_id': orderId,
      'payment_intent_id': paymentIntentId,
    });
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
}
