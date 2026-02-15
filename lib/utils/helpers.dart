// lib/utils/helpers.dart
// Helper Functions

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';

class Helpers {
  // Format price
  static String formatPrice(double price) {
    return AppConfig.formatPrice(price);
  }

  // Format price without decimals
  static String formatPriceShort(double price) {
    return AppConfig.formatPriceShort(price);
  }

  // Format date
  static String formatDate(DateTime date) {
    return AppConfig.formatDate(date);
  }

  // Format date with time
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  // Get time ago
  static String timeAgo(DateTime dateTime) {
    return AppConfig.getTimeAgo(dateTime);
  }

  // Truncate text
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Capitalize each word
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Get initials from name
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // Format phone number
  static String formatPhoneNumber(String phone) {
    if (phone.length != 10) return phone;
    return '${phone.substring(0, 5)} ${phone.substring(5)}';
  }

  // Get file size in readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  // Generate random color
  static Color randomColor() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return Color((random & 0xFFFFFF) | 0xFF000000);
  }

  // Get contrast color (black or white) for background
  static Color getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  // Parse HTML color string
  static Color parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  // Show snackbar
  static void showSnackBar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show dialog
  static Future<bool?> showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = 'Confirm',
        String cancelText = 'Cancel',
      }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  // Dismiss loading dialog
  static void dismissDialog(BuildContext context) {
    Navigator.pop(context);
  }

  // Open URL
  static Future<void> launchURL(String url) async {
    // TODO: Implement url_launcher
    debugPrint('Opening URL: $url');
  }

  // Copy to clipboard
  static Future<void> copyToClipboard(String text) async {
    // TODO: Implement Clipboard.setData
    debugPrint('Copied to clipboard: $text');
  }

  // Validate email
  static bool isValidEmail(String email) {
    return AppConfig.isValidEmail(email);
  }

  // Validate phone
  static bool isValidPhone(String phone) {
    return AppConfig.isValidPhone(phone);
  }

  // Get rating stars
  static String getRatingStars(double rating) {
    return AppConfig.getRatingStars(rating);
  }

  // Calculate discount percentage
  static double calculateDiscountPercentage(double original, double discounted) {
    if (original <= 0) return 0;
    return ((original - discounted) / original) * 100;
  }

  // Format discount
  static String formatDiscount(double original, double discounted) {
    final percentage = calculateDiscountPercentage(original, discounted);
    return '${percentage.toStringAsFixed(0)}% OFF';
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  // Delay execution
  static Future<void> delay(Duration duration) {
    return Future.delayed(duration);
  }

  // Debounce function
  static void Function() debounce(
      Function() func,
      Duration duration,
      ) {
    Future? timer;
    return () {
      timer?.ignore();
      timer = Future.delayed(duration, func);
    };
  }

  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Check if list is empty or null
  static bool isListEmpty(List? list) {
    return list == null || list.isEmpty;
  }

  // Safe divide
  static double safeDivide(double a, double b) {
    return b == 0 ? 0 : a / b;
  }

  // Clamp value
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}