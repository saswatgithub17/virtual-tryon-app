// lib/models/app_state_model.dart
// App State & Error Handling Models

enum LoadingState {
  initial,
  loading,
  success,
  error,
  empty,
}

class AppState<T> {
  final LoadingState state;
  final T? data;
  final String? errorMessage;
  final Exception? exception;

  AppState({
    required this.state,
    this.data,
    this.errorMessage,
    this.exception,
  });

  factory AppState.initial() {
    return AppState(state: LoadingState.initial);
  }

  factory AppState.loading() {
    return AppState(state: LoadingState.loading);
  }

  factory AppState.success(T data) {
    return AppState(state: LoadingState.success, data: data);
  }

  factory AppState.error(String message, [Exception? exception]) {
    return AppState(
      state: LoadingState.error,
      errorMessage: message,
      exception: exception,
    );
  }

  factory AppState.empty() {
    return AppState(state: LoadingState.empty);
  }

  bool get isInitial => state == LoadingState.initial;
  bool get isLoading => state == LoadingState.loading;
  bool get isSuccess => state == LoadingState.success;
  bool get isError => state == LoadingState.error;
  bool get isEmpty => state == LoadingState.empty;
  bool get hasData => data != null;
}

// API Response Model
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      error: json['error'],
      statusCode: json['statusCode'],
    );
  }

  factory ApiResponse.success({T? data, String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.failure({String? message, dynamic error, int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      error: error,
      statusCode: statusCode,
    );
  }
}

// Filter State
class FilterState {
  final String? category;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;
  final String? searchQuery;

  FilterState({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.searchQuery,
  });

  factory FilterState.initial() {
    return FilterState(
      category: 'All',
      sortBy: 'created_at',
    );
  }

  FilterState copyWith({
    String? category,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? searchQuery,
  }) {
    return FilterState(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasFilters =>
      (category != null && category != 'All') ||
          minPrice != null ||
          maxPrice != null ||
          (searchQuery != null && searchQuery!.isNotEmpty);

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (category != null && category != 'All') params['category'] = category;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (sortBy != null) params['sortBy'] = sortBy;
    return params;
  }
}

// Pagination State
class PaginationState<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasMore;
  final bool isLoadingMore;

  PaginationState({
    this.items = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

// Form Validation Error
class ValidationError {
  final String field;
  final String message;

  ValidationError({
    required this.field,
    required this.message,
  });

  @override
  String toString() => message;
}

// Progress State (for uploads, try-on, etc.)
class ProgressState {
  final double progress; // 0.0 to 1.0
  final String? message;
  final bool isCompleted;
  final bool isCanceled;
  final String? error;

  ProgressState({
    required this.progress,
    this.message,
    this.isCompleted = false,
    this.isCanceled = false,
    this.error,
  });

  factory ProgressState.initial() {
    return ProgressState(progress: 0.0);
  }

  factory ProgressState.inProgress(double progress, [String? message]) {
    return ProgressState(progress: progress, message: message);
  }

  factory ProgressState.completed([String? message]) {
    return ProgressState(
      progress: 1.0,
      message: message,
      isCompleted: true,
    );
  }

  factory ProgressState.canceled() {
    return ProgressState(
      progress: 0.0,
      isCanceled: true,
    );
  }

  factory ProgressState.error(String error) {
    return ProgressState(
      progress: 0.0,
      error: error,
    );
  }

  int get percentage => (progress * 100).toInt();
  bool get hasError => error != null;
  bool get isInProgress => progress > 0 && progress < 1.0 && !isCompleted;
}

// Network State
enum NetworkStatus {
  online,
  offline,
  unknown,
}

class NetworkState {
  final NetworkStatus status;
  final DateTime lastChecked;

  NetworkState({
    required this.status,
    required this.lastChecked,
  });

  factory NetworkState.initial() {
    return NetworkState(
      status: NetworkStatus.unknown,
      lastChecked: DateTime.now(),
    );
  }

  bool get isOnline => status == NetworkStatus.online;
  bool get isOffline => status == NetworkStatus.offline;
  bool get isUnknown => status == NetworkStatus.unknown;
}

// Cache Entry
class CacheEntry<T> {
  final T data;
  final DateTime cachedAt;
  final Duration validity;

  CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.validity,
  });

  bool get isExpired {
    final expiryTime = cachedAt.add(validity);
    return DateTime.now().isAfter(expiryTime);
  }

  bool get isValid => !isExpired;

  Duration get timeRemaining {
    final expiryTime = cachedAt.add(validity);
    return expiryTime.difference(DateTime.now());
  }
}