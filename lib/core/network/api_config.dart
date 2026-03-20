/// API Configuration for AuraTry App
library;

class ApiConfig {
  // =================================================================
  // BASE URL
  // =================================================================
  static const String baseUrl = 'http://10.0.24.59:5000/api';

  // =================================================================
  // API ENDPOINTS
  // =================================================================

  static const String dresses = '$baseUrl/dresses';
  static String getDressById(int id) => '$dresses/$id';
  static String getDressesByCategory(String category) =>
      '$dresses?category=$category';
  static String searchDresses(String query) => '$dresses?search=$query';
  static String sortDresses(String sortBy) => '$dresses?sortBy=$sortBy';

  static const String payment = '$baseUrl/payment';
  static const String createPaymentIntent = '$payment/create-intent';
  static const String confirmPayment = '$payment/confirm';
  static const String getPaymentStatus = '$payment/status';
  static const String refundPayment = '$payment/refund';

  // Fix 8: getReceipt is now a proper method, not null
  static String getReceipt(String orderId) => '$payment/receipt/$orderId';

  static const String users = '$baseUrl/users';
  static const String login = '$users/login';
  static const String register = '$users/register';
  static const String profile = '$users/profile';
  static const String updateProfile = '$users/profile/update';

  static const String cart = '$baseUrl/cart';
  static const String addToCart = '$cart/add';
  static const String removeFromCart = '$cart/remove';
  static const String updateCartItem = '$cart/update';
  static const String clearCart = '$cart/clear';
  static const String getCart = '$cart/items';

  static const String orders = '$baseUrl/orders';
  static const String createOrder = '$orders/create';
  static const String getOrderHistory = '$orders/history';
  // Fix 8: orderById is now a proper method, not null
  static String orderById(String id) => '$orders/$id';
  static const String cancelOrder = '$orders/cancel';
  // Fix 8: calculateTotal is now a real endpoint, not null
  static const String calculateTotal = '$orders/calculate';

  static const String tryOn = '$baseUrl/tryon';
  static const String uploadImage = '$tryOn/upload';
  static const String processImage = '$tryOn';
  static const String saveTryOnResult = '$tryOn/save';

  static const String reviews = '$baseUrl/reviews';
  // Fix 8: getReviewsByDress is now a proper method
  static String getReviewsByDress(String dressId) =>
      '$reviews/$dressId';
  static const String createReview = '$reviews';
  // Fix 8: addReview is now a proper String constant, not "null"
  static const String addReview = '$reviews';

  static const String analytics = '$baseUrl/analytics';
  static const String trackView = '$analytics/view';
  static const String trackPurchase = '$analytics/purchase';

  // =================================================================
  // TIMEOUTS
  // =================================================================
  static const Duration timeout = Duration(minutes: 10);
  static const Duration connectTimeout = Duration(minutes: 5);
  static const Duration receiveTimeout = Duration(minutes: 10);
  static const Duration standardTimeout = Duration(minutes: 10);

  // =================================================================
  // HEADERS
  // =================================================================
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> headersWithAuth(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };

  static Map<String, String> multipartHeaders(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // =================================================================
  // HELPER METHODS
  // =================================================================

  static String getFullUrl(String endpoint) {
    if (endpoint.startsWith('http://') ||
        endpoint.startsWith('https://')) {
      return endpoint;
    }
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }
    if (endpoint.startsWith(baseUrl)) {
      return endpoint;
    }
    return '$baseUrl/$endpoint';
  }

  static String getUploadUrl(String imagePath) {
    if (imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return imagePath;
    }
    if (imagePath.startsWith('/')) {
      imagePath = imagePath.substring(1);
    }
    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
    if (imagePath.startsWith('uploads/')) {
      return '$baseUrlWithoutApi/$imagePath';
    }
    return '$baseUrlWithoutApi/uploads/$imagePath';
  }

  static String getImageUrl(String imagePath) => getUploadUrl(imagePath);

  static String get environment {
    if (baseUrl.contains('localhost') ||
        baseUrl.contains('10.0.2.2')) {
      return 'Development';
    } else if (baseUrl.contains('staging')) {
      return 'Staging';
    } else {
      return 'Production';
    }
  }

  static Future<bool> isBackendReachable() async {
    return true;
  }
}

class ApiQueryParams {
  static String build(Map<String, dynamic> params) {
    if (params.isEmpty) return '';
    final queryParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) =>
            '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
    return queryParams.isNotEmpty ? '?$queryParams' : '';
  }
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final String? message;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.message,
  });

  factory ApiResponse.success(T data,
      {int? statusCode, String? message}) {
    return ApiResponse(
        success: true,
        data: data,
        statusCode: statusCode,
        message: message);
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
        success: false, error: error, statusCode: statusCode);
  }
}

class ApiError {
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError =
      'Server error. Please try again later.';
  static const String unauthorized =
      'Unauthorized. Please login again.';
  static const String notFound = 'Resource not found.';
  static const String timeout = 'Request timeout. Please try again.';
  static const String unknown = 'An unexpected error occurred.';

  static String fromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request.';
      case 401:
        return unauthorized;
      case 403:
        return 'Access forbidden.';
      case 404:
        return notFound;
      case 500:
        return serverError;
      case 503:
        return 'Service unavailable.';
      default:
        return unknown;
    }
  }
}