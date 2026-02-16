// lib/config/app_config.dart
// App Configuration & Constants

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConfig {
  // App Information
  static const String appName = 'Virtual Try-On';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-Powered Virtual Dress Try-On';

  // App Features
  static const bool enableVirtualTryOn = true;
  static const bool enablePayments = true;
  static const bool enableReviews = true;

  // Limits
  static const int maxTryOnDresses = 5;
  static const int maxCartQuantity = 10;
  static const int maxCartItems = 20;
  static const int minOrderAmount = 100; // Minimum ₹100

  // Categories
  static const List<String> categories = [
    'All',
    'Evening Wear',
    'Casual',
    'Party',
    'Beach',
    'Summer',
    'Winter',
    'Formal',
    'Cocktail',
  ];

  // Sizes
  static const List<String> availableSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  // Sort Options
  static const List<Map<String, String>> sortOptions = [
    {'label': 'Newest First', 'value': 'created_at'},
    {'label': 'Price: Low to High', 'value': 'price_asc'},
    {'label': 'Price: High to Low', 'value': 'price_desc'},
    {'label': 'Highest Rated', 'value': 'rating'},
    {'label': 'Name (A-Z)', 'value': 'name'},
  ];

  // Price Range
  static const double minPrice = 0;
  static const double maxPrice = 10000;
  static const double defaultMinPrice = 0;
  static const double defaultMaxPrice = 5000;

  // UI Settings
  static const int dressGridCrossAxisCount = 2;
  static const double dressCardAspectRatio = 0.7;
  static const int searchDebounceMilliseconds = 500;

  // Messages
  static const String emptyCartMessage = 'Your cart is empty';
  static const String emptySearchMessage = 'No dresses found';
  static const String tryOnMessage = 'Take a photo to try on dresses virtually';
  static const String loadingMessage = 'Loading...';
  static const String errorMessage = 'Something went wrong';
  static const String noInternetMessage = 'No internet connection';
  static const String paymentSuccessMessage =
      'Payment successful! Thank you for your order.';
  static const String paymentFailedMessage =
      'Payment failed. Please try again.';

  // Try-On Messages
  static const String tryOnProcessingMessage =
      'AI is processing your images...';
  static const String tryOnSuccessMessage =
      'Try-on complete! Check your results.';
  static const String tryOnFailedMessage = 'Try-on failed. Please try again.';
  static const String selectDressesMessage =
      'Select up to $maxTryOnDresses dresses to try on';
  static const String capturePhotoMessage =
      'Capture a full-body photo for best results';

  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minReviewLength = 10;
  static const int maxReviewLength = 500;

  // Image Settings
  static const int maxImageSizeMB = 10;
  static const int imageQuality = 80; // 0-100
  static const int maxImageWidth = 1080;
  static const int maxImageHeight = 1920;

  // Cache Settings
  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCachedImages = 100;

  // Stripe Test Card (for development)
  static const String stripeTestCard = '4242 4242 4242 4242';
  static const String stripeTestExpiry = '12/34';
  static const String stripeTestCVC = '123';

  // Support
  static const String supportEmail = 'support@virtualtryon.com';
  static const String supportPhone = '+91 1234567890';
  static const String privacyPolicyUrl = 'https://virtualtryon.com/privacy';
  static const String termsUrl = 'https://virtualtryon.com/terms';

  // Social Media (Optional)
  static const String facebookUrl = 'https://facebook.com/virtualtryon';
  static const String instagramUrl = 'https://instagram.com/virtualtryon';
  static const String twitterUrl = 'https://twitter.com/virtualtryon';

  // Helper Methods

  // Get category display name
  static String getCategoryDisplayName(String category) {
    return category;
  }

  // Format price
  static String formatPrice(double price) {
    return '₹${price.toStringAsFixed(2)}';
  }

  // Format rupees without decimals
  static String formatPriceShort(double price) {
    return '₹${price.toStringAsFixed(0)}';
  }

  // Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Validate phone (Indian format)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  // Validate name
  static bool isValidName(String name) {
    return name.trim().length >= minNameLength &&
        name.trim().length <= maxNameLength;
  }

  // Get rating stars
  static String getRatingStars(double rating) {
    final stars = rating.round();
    return '⭐' * stars;
  }

  // Get file size in MB
  static double getFileSizeInMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  // Check if image size is valid
  static bool isValidImageSize(int bytes) {
    return getFileSizeInMB(bytes) <= maxImageSizeMB;
  }

  // Get time ago string
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Format date
  static String formatDate(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  // Get payment method icon
  static String getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'stripe':
      case 'card':
        return '💳';
      case 'upi':
        return '📱';
      case 'cod':
        return '💵';
      default:
        return '💰';
    }
  }

  // Get order status color
  static String getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'green';
      case 'pending':
        return 'orange';
      case 'failed':
        return 'red';
      default:
        return 'gray';
    }
  }

  // Debug mode
  static const bool debugMode = true; // Set to false in production

  // Log messages (only in debug mode)
  static void log(String message) {
    if (debugMode) {
      debugPrint('🔹 [VirtualTryOn] $message');
    }
  }

  // Log errors
  static void logError(String error) {
    if (debugMode) {
      debugPrint('❌ [VirtualTryOn ERROR] $error');
    }
  }
}
