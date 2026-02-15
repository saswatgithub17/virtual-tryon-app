// lib/providers/dress_provider.dart
// Dress Catalog State Management

import 'package:flutter/foundation.dart';
import '../models/dress_model.dart';
import '../services/api_service.dart';

class DressProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Dress> _allDresses = [];
  List<Dress> _filteredDresses = [];
  List<Review> _currentReviews = [];

  bool _isLoading = false;
  bool _isLoadingReviews = false;
  String? _error;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'created_at';

  // Getters
  List<Dress> get dresses => _filteredDresses;
  List<Dress> get allDresses => _allDresses;
  List<Review> get currentReviews => _currentReviews;
  bool get isLoading => _isLoading;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get hasDresses => _filteredDresses.isNotEmpty;

  // Categories
  List<String> get categories => [
    'All',
    'Evening Wear',
    'Casual',
    'Party',
    'Beach',
    'Summer',
    'Winter',
    'Formal',
  ];

  // Load all dresses
  Future<void> loadDresses({bool forceRefresh = false}) async {
    if (_isLoading) return;

    // Don't reload if we already have data and not forcing refresh
    if (_allDresses.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allDresses = await _apiService.getDresses(sortBy: _sortBy);
      _applyFilters();
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading dresses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apply current filters
  void _applyFilters() {
    _filteredDresses = _allDresses;

    // Apply category filter
    if (_selectedCategory != 'All') {
      _filteredDresses = _filteredDresses
          .where((dress) => dress.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      _filteredDresses = _filteredDresses.where((dress) {
        return dress.name.toLowerCase().contains(query) ||
            (dress.description?.toLowerCase().contains(query) ?? false) ||
            (dress.brand?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  // Set category filter
  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _applyFilters();
      notifyListeners();
    }
  }

  // Search dresses
  Future<void> searchDresses(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _applyFilters();
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Use API search for better results
      _filteredDresses = await _apiService.searchDresses(query);
      _error = null;
    } catch (e) {
      // Fallback to local filtering
      _applyFilters();
      debugPrint('API search failed, using local filter: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  // Sort dresses
  void sortBy(String sortField) {
    _sortBy = sortField;

    switch (sortField) {
      case 'price_asc':
        _filteredDresses.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        _filteredDresses.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        _filteredDresses.sort((a, b) {
          final ratingA = a.averageRating ?? 0;
          final ratingB = b.averageRating ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'name':
        _filteredDresses.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
      // created_at (newest first) - default from API
        break;
    }

    notifyListeners();
  }

  // Get dress by ID
  Dress? getDressById(int id) {
    try {
      return _allDresses.firstWhere((dress) => dress.dressId == id);
    } catch (e) {
      return null;
    }
  }

  // Load dress details (with fresh data from API)
  Future<Dress?> loadDressDetails(int id) async {
    try {
      final dress = await _apiService.getDressById(id);

      // Update in local list if exists
      final index = _allDresses.indexWhere((d) => d.dressId == id);
      if (index >= 0) {
        _allDresses[index] = dress;
        _applyFilters();
        notifyListeners();
      }

      return dress;
    } catch (e) {
      debugPrint('Error loading dress details: $e');
      return null;
    }
  }

  // Load reviews for a dress
  Future<void> loadReviews(int dressId) async {
    _isLoadingReviews = true;
    notifyListeners();

    try {
      _currentReviews = await _apiService.getReviews(dressId);
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      _currentReviews = [];
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  // Add review
  Future<bool> addReview({
    required int dressId,
    required int rating,
    String? customerName,
    String? reviewText,
  }) async {
    try {
      await _apiService.addReview(
        dressId: dressId,
        rating: rating,
        customerName: customerName,
        reviewText: reviewText,
      );

      // Reload reviews
      await loadReviews(dressId);

      // Reload dress to get updated rating
      await loadDressDetails(dressId);

      return true;
    } catch (e) {
      debugPrint('Error adding review: $e');
      return false;
    }
  }

  // Filter by price range
  void filterByPriceRange(double minPrice, double maxPrice) {
    _filteredDresses = _allDresses.where((dress) {
      return dress.price >= minPrice && dress.price <= maxPrice;
    }).toList();

    // Apply other filters
    _applyFilters();
    notifyListeners();
  }

  // Get dresses by category (for quick access)
  List<Dress> getDressesByCategory(String category) {
    if (category == 'All') return _allDresses;
    return _allDresses.where((dress) => dress.category == category).toList();
  }

  // Refresh data
  Future<void> refresh() async {
    await loadDresses(forceRefresh: true);
  }
}