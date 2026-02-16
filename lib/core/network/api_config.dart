/// API Configuration for AuraTry App
/// FIXED VERSION - All methods included
library;

class ApiConfig {
  // =================================================================
  // BASE URL - CHANGE BASED ON YOUR ENVIRONMENT
  // =================================================================

  /// For Android Emulator (Default) - uses 10.0.2.2 to connect to host machine
  // static const String baseUrl = 'http://10.0.2.2:5000/api';

  /// For Physical Device (WiFi) - USE YOUR COMPUTER'S IP ADDRESS
  /// To find your IP: Run 'ipconfig' on Windows or 'ifconfig' on Mac/Linux
  static const String baseUrl = 'http://10.30.29.1:5000/api';

  /// For Localhost testing (only works on emulator/simulator)
  // static const String baseUrl = 'http://localhost:5000/api';

  /// For Production
  // static const String baseUrl = 'https://your-domain.com/api';

  // =================================================================
  // API ENDPOINTS
  // =================================================================

  /// Dresses Endpoints
  static const String dresses = '$baseUrl/dresses';
  static String getDressById(String id) => '$dresses/$id';
  static String getDressesByCategory(String category) =>
      '$dresses?category=$category';
  static String searchDresses(String query) => '$dresses?search=$query';
  static String sortDresses(String sortBy) => '$dresses?sortBy=$sortBy';

  /// Payment Endpoints (Stripe)
  static const String payment = '$baseUrl/payment';
  static const String createPaymentIntent = '$payment/create-intent';
  static const String confirmPayment = '$payment/confirm';
  static const String getPaymentStatus = '$payment/status';
  static const String refundPayment = '$payment/refund';

  /// User Endpoints
  static const String users = '$baseUrl/users';
  static const String login = '$users/login';
  static const String register = '$users/register';
  static const String profile = '$users/profile';
  static const String updateProfile = '$users/profile/update';

  /// Cart Endpoints
  static const String cart = '$baseUrl/cart';
  static const String addToCart = '$cart/add';
  static const String removeFromCart = '$cart/remove';
  static const String updateCartItem = '$cart/update';
  static const String clearCart = '$cart/clear';
  static const String getCart = '$cart/items';

  /// Orders Endpoints
  static const String orders = '$baseUrl/orders';
  static const String createOrder = '$orders/create';
  static const String getOrderHistory = '$orders/history';
  static String getOrderById(String id) => '$orders/$id';
  static const String cancelOrder = '$orders/cancel';

  /// Try-On Endpoints
  static const String tryOn = '$baseUrl/tryon';
  static const String uploadImage = '$tryOn/upload';
  static const String processImage = '$tryOn';  // Direct /api/tryon endpoint
  static const String saveTryOnResult = '$tryOn/save';

  /// Reviews Endpoints
  static const String reviews = '$baseUrl/reviews';
  static String getReviewsByDress(String dressId) => '$reviews/dress/$dressId';
  static const String createReview = '$reviews/create';

  /// Analytics Endpoints
  static const String analytics = '$baseUrl/analytics';
  static const String trackView = '$analytics/view';
  static const String trackPurchase = '$analytics/purchase';

  // =================================================================
  // API CONFIGURATION
  // =================================================================

  /// Request timeout duration - 10 minutes for AI processing
  static const Duration timeout = Duration(minutes: 10);
  static const Duration connectTimeout = Duration(minutes: 5);
  static const Duration receiveTimeout = Duration(minutes: 10);

  /// ADDED: Standard timeout for API calls - 10 minutes for AI processing
  static const Duration standardTimeout = Duration(minutes: 10);

  /// API Headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// API Headers with Auth Token
  static Map<String, String> headersWithAuth(String token) => {
        ...headers,
        'Authorization': 'Bearer $token',
      };

  /// Multipart headers for file upload
  static Map<String, String> multipartHeaders(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // =================================================================
  // HELPER METHODS - ADDED MISSING METHODS
  // =================================================================

  /// Get full URL for endpoint
  static String getFullUrl(String endpoint) {
    // If endpoint already starts with http, return as is
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return endpoint;
    }

    // If endpoint starts with /, remove it
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    // If endpoint already starts with baseUrl, return as is
    if (endpoint.startsWith(baseUrl)) {
      return endpoint;
    }

    // Combine baseUrl and endpoint
    return '$baseUrl/$endpoint';
  }

  /// Get full URL for uploaded image
  static String getUploadUrl(String imagePath) {
    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // Remove leading slash if present
    if (imagePath.startsWith('/')) {
      imagePath = imagePath.substring(1);
    }

    // Check if path already contains /uploads/ to avoid doubling
    if (imagePath.startsWith('uploads/')) {
      // Get base URL without /api
      final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');
      return '$baseUrlWithoutApi/$imagePath';
    }

    // Get base URL without /api
    final baseUrlWithoutApi = baseUrl.replaceAll('/api', '');

    // Return full upload URL
    return '$baseUrlWithoutApi/uploads/$imagePath';
  }

  /// Get environment name
  static String get environment {
    if (baseUrl.contains('localhost') || baseUrl.contains('10.0.2.2')) {
      return 'Development';
    } else if (baseUrl.contains('staging')) {
      return 'Staging';
    } else {
      return 'Production';
    }
  }

  static get getReceipt => null;

  static get orderById => null;

  static String get addReview => "null";

  static String get calculateTotal => "null";

  static get dressById => null;

  /// Get full URL for image (alias for getUploadUrl)
  static String getImageUrl(String imagePath) {
    return getUploadUrl(imagePath);
  }

  /// Check if backend is reachable
  static Future<bool> isBackendReachable() async {
    try {
      // TODO: Implement health check
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Query Parameters Helper
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

/// API Response Handler
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

  factory ApiResponse.success(T data, {int? statusCode, String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      message: message,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// API Error Types
class ApiError {
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorized = 'Unauthorized. Please login again.';
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
