// lib/providers/tryon_provider.dart
// Virtual Try-On State Management

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/dress_model.dart';
import '../services/api_service.dart';

class TryOnProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  File? _userPhoto;
  final List<Dress> _selectedDresses = [];
  List<TryOnResult> _results = [];

  bool _isProcessing = false;
  bool _hasProcessed = false;
  String? _error;
  double _progress = 0.0;
  String _statusMessage = '';

  // Getters
  File? get userPhoto => _userPhoto;
  List<Dress> get selectedDresses => _selectedDresses;
  List<TryOnResult> get results => _results;
  bool get isProcessing => _isProcessing;
  bool get hasProcessed => _hasProcessed;
  bool get hasResults => _results.isNotEmpty;
  bool get hasUserPhoto => _userPhoto != null;
  String? get error => _error;
  double get progress => _progress;
  int get percentage => (_progress * 100).toInt();
  String get statusMessage => _statusMessage;
  int get selectedCount => _selectedDresses.length;
  bool get canProcess => _userPhoto != null && _selectedDresses.isNotEmpty;

  // Maximum dresses to try on at once
  static const int maxDresses = 5;

  // Set user photo
  void setUserPhoto(File? photo) {
    _userPhoto = photo;
    _error = null;
    notifyListeners();
  }

  // Toggle dress selection
  void toggleDressSelection(Dress dress) {
    final index = _selectedDresses.indexWhere((d) => d.dressId == dress.dressId);

    if (index >= 0) {
      // Dress already selected, remove it
      _selectedDresses.removeAt(index);
    } else {
      // Check if we haven't exceeded the limit
      if (_selectedDresses.length < maxDresses) {
        _selectedDresses.add(dress);
      } else {
        _error = 'You can select maximum $maxDresses dresses at a time';
      }
    }

    notifyListeners();
  }

  // Check if dress is selected
  bool isDressSelected(int dressId) {
    return _selectedDresses.any((dress) => dress.dressId == dressId);
  }

  // Clear dress selection
  void clearSelection() {
    _selectedDresses.clear();
    notifyListeners();
  }

  // Remove specific dress from selection
  void removeDress(int dressId) {
    _selectedDresses.removeWhere((dress) => dress.dressId == dressId);
    notifyListeners();
  }

  // Process virtual try-on
  Future<bool> processTryOn() async {
    if (!canProcess) {
      _error = 'Please capture a photo and select at least one dress';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    _hasProcessed = false;
    _error = null;
    _progress = 0.0;
    _statusMessage = 'Preparing your photos...';
    notifyListeners();

    try {
      // Get dress IDs
      final dressIds = _selectedDresses.map((d) => d.dressId).toList();

      // Update progress
      _progress = 0.2;
      _statusMessage = 'Uploading to AI server...';
      notifyListeners();

      // Simulate progress updates during processing
      _simulateProgress();

      // Call API
      _results = await _apiService.processTryOn(
        userPhoto: _userPhoto!,
        dressIds: dressIds,
      );

      // Processing complete
      _progress = 1.0;
      _statusMessage = 'Try-on complete!';
      _hasProcessed = true;
      _error = null;

      notifyListeners();
      return true;

    } catch (e) {
      _error = e.toString();
      _statusMessage = 'Try-on failed';
      _hasProcessed = false;
      debugPrint('Try-on error: $e');
      notifyListeners();
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // Simulate progress during AI processing
  void _simulateProgress() {
    // This runs in background while API processes
    Future.delayed(const Duration(seconds: 10), () {
      if (_isProcessing && _progress < 0.4) {
        _progress = 0.4;
        _statusMessage = 'AI is processing your images...';
        notifyListeners();
      }
    });

    Future.delayed(const Duration(seconds: 30), () {
      if (_isProcessing && _progress < 0.6) {
        _progress = 0.6;
        _statusMessage = 'Generating try-on images...';
        notifyListeners();
      }
    });

    Future.delayed(const Duration(seconds: 60), () {
      if (_isProcessing && _progress < 0.8) {
        _progress = 0.8;
        _statusMessage = 'Almost done...';
        notifyListeners();
      }
    });
  }

  // Get successful try-on results
  List<TryOnResult> get successfulResults {
    return _results.where((result) => result.aiGenerated).toList();
  }

  // Get failed try-on results
  List<TryOnResult> get failedResults {
    return _results.where((result) => !result.aiGenerated).toList();
  }

  // Clear results
  void clearResults() {
    _results.clear();
    _hasProcessed = false;
    _progress = 0.0;
    _statusMessage = '';
    notifyListeners();
  }

  // Clear all data (reset)
  void reset() {
    _userPhoto = null;
    _selectedDresses.clear();
    _results.clear();
    _isProcessing = false;
    _hasProcessed = false;
    _error = null;
    _progress = 0.0;
    _statusMessage = '';
    notifyListeners();
  }

  // Clear only photo (keep selections)
  void clearPhoto() {
    _userPhoto = null;
    notifyListeners();
  }

  // Get result for specific dress
  TryOnResult? getResultForDress(int dressId) {
    try {
      return _results.firstWhere((result) => result.dressId == dressId);
    } catch (e) {
      return null;
    }
  }

  // Check if we can add more dresses
  bool get canAddMoreDresses {
    return _selectedDresses.length < maxDresses;
  }

  // Get remaining selection slots
  int get remainingSlots {
    return maxDresses - _selectedDresses.length;
  }

  // Validate before processing
  String? validateForProcessing() {
    if (_userPhoto == null) {
      return 'Please capture or select a photo of yourself';
    }
    if (_selectedDresses.isEmpty) {
      return 'Please select at least one dress to try on';
    }
    if (_selectedDresses.length > maxDresses) {
      return 'Maximum $maxDresses dresses allowed at once';
    }
    return null; // Valid
  }
}