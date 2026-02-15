// lib/models/review_model.dart
// Review & Rating Models

class ReviewModel {
  final int reviewId;
  final int dressId;
  final String? customerName;
  final String? customerEmail;
  final int rating;
  final String? reviewText;
  final bool isVerified;
  final bool isHelpful;
  final int helpfulCount;
  final DateTime? createdAt;

  ReviewModel({
    required this.reviewId,
    required this.dressId,
    this.customerName,
    this.customerEmail,
    required this.rating,
    this.reviewText,
    this.isVerified = false,
    this.isHelpful = false,
    this.helpfulCount = 0,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      reviewId: json['review_id'] ?? 0,
      dressId: json['dress_id'] ?? 0,
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      rating: json['rating'] ?? 0,
      reviewText: json['review_text'],
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      isHelpful: json['is_helpful'] == 1 || json['is_helpful'] == true,
      helpfulCount: json['helpful_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'review_id': reviewId,
      'dress_id': dressId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'rating': rating,
      'review_text': reviewText,
      'is_verified': isVerified,
      'is_helpful': isHelpful,
      'helpful_count': helpfulCount,
    };
  }

  // Display name (fallback to "Anonymous" if null)
  String get displayName => customerName ?? 'Anonymous';

  // Check if review has text
  bool get hasReviewText => reviewText != null && reviewText!.isNotEmpty;

  // Get star rating as string
  String get starsDisplay => '⭐' * rating;

  // Get time ago string
  String get timeAgo {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

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

  // Copy with
  ReviewModel copyWith({
    int? reviewId,
    int? dressId,
    String? customerName,
    String? customerEmail,
    int? rating,
    String? reviewText,
    bool? isVerified,
    bool? isHelpful,
    int? helpfulCount,
    DateTime? createdAt,
  }) {
    return ReviewModel(
      reviewId: reviewId ?? this.reviewId,
      dressId: dressId ?? this.dressId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      isVerified: isVerified ?? this.isVerified,
      isHelpful: isHelpful ?? this.isHelpful,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Rating Summary
class RatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 100, 4: 50, 3: 20, 2: 10, 1: 5}

  RatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      averageRating: double.tryParse(json['average_rating']?.toString() ?? '0') ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      ratingDistribution: _parseRatingDistribution(json['distribution']),
    );
  }

  static Map<int, int> _parseRatingDistribution(dynamic data) {
    if (data == null) {
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    }
    if (data is Map) {
      return {
        5: int.tryParse(data['5']?.toString() ?? '0') ?? 0,
        4: int.tryParse(data['4']?.toString() ?? '0') ?? 0,
        3: int.tryParse(data['3']?.toString() ?? '0') ?? 0,
        2: int.tryParse(data['2']?.toString() ?? '0') ?? 0,
        1: int.tryParse(data['1']?.toString() ?? '0') ?? 0,
      };
    }
    return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  }

  // Get percentage for each rating
  double getPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    final count = ratingDistribution[rating] ?? 0;
    return (count / totalReviews) * 100;
  }

  // Get count for rating
  int getCount(int rating) {
    return ratingDistribution[rating] ?? 0;
  }

  // Get formatted average rating
  String get formattedAverage => averageRating.toStringAsFixed(1);

  // Get star display
  String get starsDisplay {
    final stars = averageRating.round();
    return '⭐' * stars;
  }

  // Check if has reviews
  bool get hasReviews => totalReviews > 0;

  // Get most common rating
  int get mostCommonRating {
    int maxRating = 5;
    int maxCount = 0;

    ratingDistribution.forEach((rating, count) {
      if (count > maxCount) {
        maxCount = count;
        maxRating = rating;
      }
    });

    return maxRating;
  }
}

// Review Filter
enum ReviewFilter {
  all,
  fiveStar,
  fourStar,
  threeStar,
  twoStar,
  oneStar,
  verified,
  withText,
}

extension ReviewFilterExtension on ReviewFilter {
  String get label {
    switch (this) {
      case ReviewFilter.all:
        return 'All Reviews';
      case ReviewFilter.fiveStar:
        return '5 Stars';
      case ReviewFilter.fourStar:
        return '4 Stars';
      case ReviewFilter.threeStar:
        return '3 Stars';
      case ReviewFilter.twoStar:
        return '2 Stars';
      case ReviewFilter.oneStar:
        return '1 Star';
      case ReviewFilter.verified:
        return 'Verified';
      case ReviewFilter.withText:
        return 'With Text';
    }
  }

  int? get rating {
    switch (this) {
      case ReviewFilter.fiveStar:
        return 5;
      case ReviewFilter.fourStar:
        return 4;
      case ReviewFilter.threeStar:
        return 3;
      case ReviewFilter.twoStar:
        return 2;
      case ReviewFilter.oneStar:
        return 1;
      default:
        return null;
    }
  }
}

// Review Sort
enum ReviewSort {
  newest,
  oldest,
  highestRating,
  lowestRating,
  mostHelpful,
}

extension ReviewSortExtension on ReviewSort {
  String get label {
    switch (this) {
      case ReviewSort.newest:
        return 'Newest First';
      case ReviewSort.oldest:
        return 'Oldest First';
      case ReviewSort.highestRating:
        return 'Highest Rating';
      case ReviewSort.lowestRating:
        return 'Lowest Rating';
      case ReviewSort.mostHelpful:
        return 'Most Helpful';
    }
  }
}