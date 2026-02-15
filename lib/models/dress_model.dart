// lib/models/dress_model.dart
// Data Models for the App

class Dress {
  final int dressId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? brand;
  final String? color;
  final String? material;
  final String imageUrl;
  final bool isActive;
  final double? averageRating;
  final int? totalReviews;
  final List<DressSize> sizes;
  final DateTime? createdAt;

  Dress({
    required this.dressId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.brand,
    this.color,
    this.material,
    required this.imageUrl,
    this.isActive = true,
    this.averageRating,
    this.totalReviews,
    this.sizes = const [],
    this.createdAt,
  });

  factory Dress.fromJson(Map<String, dynamic> json) {
    // Parse sizes if they come as string (from database GROUP_CONCAT)
    List<DressSize> sizesList = [];
    if (json['sizes'] != null) {
      if (json['sizes'] is String) {
        // Format: "S:10,M:15,L:20"
        String sizesStr = json['sizes'];
        sizesList = sizesStr.split(',').map((s) {
          var parts = s.split(':');
          return DressSize(
            sizeName: parts[0],
            stockQuantity: int.tryParse(parts[1]) ?? 0,
          );
        }).toList();
      } else if (json['sizes'] is List) {
        sizesList = (json['sizes'] as List)
            .map((s) => DressSize.fromJson(s))
            .toList();
      }
    }

    return Dress(
      dressId: json['dress_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'],
      brand: json['brand'],
      color: json['color'],
      material: json['material'],
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      totalReviews: json['total_reviews'],
      sizes: sizesList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dress_id': dressId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'brand': brand,
      'color': color,
      'material': material,
      'image_url': imageUrl,
      'is_active': isActive,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'sizes': sizes.map((s) => s.toJson()).toList(),
    };
  }
}

class DressSize {
  final String sizeName;
  final int stockQuantity;

  DressSize({
    required this.sizeName,
    required this.stockQuantity,
  });

  factory DressSize.fromJson(Map<String, dynamic> json) {
    return DressSize(
      sizeName: json['size'] ?? json['size_name'] ?? '',
      stockQuantity: json['stock'] ?? json['stock_quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': sizeName,
      'stock': stockQuantity,
    };
  }

  bool get inStock => stockQuantity > 0;
}

class Review {
  final int reviewId;
  final int dressId;
  final String? customerName;
  final String? customerEmail;
  final int rating;
  final String? reviewText;
  final bool isVerified;
  final DateTime? createdAt;

  Review({
    required this.reviewId,
    required this.dressId,
    this.customerName,
    this.customerEmail,
    required this.rating,
    this.reviewText,
    this.isVerified = false,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'] ?? 0,
      dressId: json['dress_id'] ?? 0,
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      rating: json['rating'] ?? 0,
      reviewText: json['review_text'],
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

class CartItem {
  final Dress dress;
  final String selectedSize;
  int quantity;

  CartItem({
    required this.dress,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get subtotal => dress.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'dress_id': dress.dressId,
      'size_name': selectedSize,
      'quantity': quantity,
    };
  }
}

class Order {
  final String orderId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final String? stripePaymentId;
  final String? receiptUrl;
  final List<OrderItem> items;
  final DateTime? createdAt;

  Order({
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.stripePaymentId,
    this.receiptUrl,
    this.items = const [],
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerPhone: json['customer_phone'],
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      stripePaymentId: json['stripe_payment_id'],
      receiptUrl: json['receipt_url'],
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  bool get isPending => paymentStatus == 'pending';
  bool get isCompleted => paymentStatus == 'completed';
  bool get isFailed => paymentStatus == 'failed';
}

class OrderItem {
  final int itemId;
  final String orderId;
  final int dressId;
  final String dressName;
  final String sizeName;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItem({
    required this.itemId,
    required this.orderId,
    required this.dressId,
    required this.dressName,
    required this.sizeName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'] ?? 0,
      orderId: json['order_id'] ?? '',
      dressId: json['dress_id'] ?? 0,
      dressName: json['dress_name'] ?? '',
      sizeName: json['size_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
    );
  }
}

class TryOnResult {
  final String resultUrl;
  final int dressId;
  final String dressName;
  final bool aiGenerated;
  final String? method;

  TryOnResult({
    required this.resultUrl,
    required this.dressId,
    required this.dressName,
    required this.aiGenerated,
    this.method,
  });

  factory TryOnResult.fromJson(Map<String, dynamic> json) {
    return TryOnResult(
      resultUrl: json['resultUrl'] ?? '',
      dressId: json['dressId'] ?? 0,
      dressName: json['dressName'] ?? '',
      aiGenerated: json['aiGenerated'] ?? false,
      method: json['method'],
    );
  }
}