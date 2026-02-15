// lib/services/validation_service.dart
// Form Validation Service

import 'package:virtual_tryon_app/core/utils/app_config.dart';

class ValidationService {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    if (!AppConfig.isValidEmail(value)) {
      return 'Please enter a valid email address';
    }

    return null; // Valid
  }

  // Name validation
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (value.trim().length < AppConfig.minNameLength) {
      return '$fieldName must be at least ${AppConfig.minNameLength} characters';
    }

    if (value.trim().length > AppConfig.maxNameLength) {
      return '$fieldName must not exceed ${AppConfig.maxNameLength} characters';
    }

    // Check if contains only letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName can only contain letters and spaces';
    }

    return null; // Valid
  }

  // Phone validation (Indian format)
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Phone number is required' : null;
    }

    // Remove spaces and dashes
    final phone = value.replaceAll(RegExp(r'[\s-]'), '');

    if (!AppConfig.isValidPhone(phone)) {
      return 'Please enter a valid 10-digit mobile number';
    }

    return null; // Valid
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    if (value.length > 20) {
      return 'Password must not exceed 20 characters';
    }

    return null; // Valid
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null; // Valid
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Number validation
  static String? validateNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null; // Valid
  }

  // Price validation
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }

    if (price <= 0) {
      return 'Price must be greater than 0';
    }

    return null; // Valid
  }

  // Quantity validation
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid quantity';
    }

    if (quantity <= 0) {
      return 'Quantity must be at least 1';
    }

    if (quantity > AppConfig.maxCartQuantity) {
      return 'Maximum quantity is ${AppConfig.maxCartQuantity}';
    }

    return null; // Valid
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }

    if (value.trim().length < 10) {
      return 'Please enter a complete address (minimum 10 characters)';
    }

    if (value.trim().length > 200) {
      return 'Address is too long (maximum 200 characters)';
    }

    return null; // Valid
  }

  // Pincode validation (Indian)
  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }

    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }

    return null; // Valid
  }

  // Review text validation
  static String? validateReviewText(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Review text is required' : null;
    }

    if (value.trim().length < AppConfig.minReviewLength) {
      return 'Review must be at least ${AppConfig.minReviewLength} characters';
    }

    if (value.trim().length > AppConfig.maxReviewLength) {
      return 'Review must not exceed ${AppConfig.maxReviewLength} characters';
    }

    return null; // Valid
  }

  // Rating validation
  static String? validateRating(int? value) {
    if (value == null || value == 0) {
      return 'Please select a rating';
    }

    if (value < 1 || value > 5) {
      return 'Rating must be between 1 and 5';
    }

    return null; // Valid
  }

  // URL validation
  static String? validateUrl(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'URL is required' : null;
    }

    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlPattern.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null; // Valid
  }

  // Username validation
  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }

    if (value.length > 20) {
      return 'Username must not exceed 20 characters';
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null; // Valid
  }

  // Date validation (not in future)
  static String? validatePastDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isAfter(DateTime.now())) {
      return '$fieldName cannot be in the future';
    }

    return null; // Valid
  }

  // Date validation (not in past)
  static String? validateFutureDate(DateTime? value, {String fieldName = 'Date'}) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isBefore(DateTime.now())) {
      return '$fieldName cannot be in the past';
    }

    return null; // Valid
  }

  // Credit card number validation (basic)
  static String? validateCardNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Card number is required';
    }

    final cardNumber = value.replaceAll(RegExp(r'\s'), '');

    if (cardNumber.length != 16) {
      return 'Card number must be 16 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(cardNumber)) {
      return 'Card number can only contain digits';
    }

    return null; // Valid
  }

  // CVV validation
  static String? validateCVV(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'CVV is required';
    }

    if (value.length != 3 && value.length != 4) {
      return 'CVV must be 3 or 4 digits';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'CVV can only contain digits';
    }

    return null; // Valid
  }

  // Expiry date validation (MM/YY)
  static String? validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expiry date is required';
    }

    if (!RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(value)) {
      return 'Please enter a valid expiry date (MM/YY)';
    }

    final parts = value.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse('20${parts[1]}');
    final now = DateTime.now();
    final expiryDate = DateTime(year, month);

    if (expiryDate.isBefore(DateTime(now.year, now.month))) {
      return 'Card has expired';
    }

    return null; // Valid
  }
}