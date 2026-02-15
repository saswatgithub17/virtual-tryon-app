// lib/models/order_model.dart
// Order & Order Item Models

class OrderModel {
  final String orderId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final String? stripePaymentId;
  final String? receiptUrl;
  final List<OrderItemModel> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
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
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['order_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerPhone: json['customer_phone'],
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      stripePaymentId: json['stripe_payment_id'],
      receiptUrl: json['receipt_url'],
      items: json['items'] != null
          ? (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'stripe_payment_id': stripePaymentId,
      'receipt_url': receiptUrl,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Payment status checks
  bool get isPending => paymentStatus.toLowerCase() == 'pending';
  bool get isCompleted => paymentStatus.toLowerCase() == 'completed';
  bool get isFailed => paymentStatus.toLowerCase() == 'failed';
  bool get isCanceled => paymentStatus.toLowerCase() == 'canceled';

  // Receipt availability
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  // Get total items count
  int get itemCount => items.length;

  // Get total quantity of all items
  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get formatted total
  String get formattedTotal => '₹${totalAmount.toStringAsFixed(2)}';

  // Get formatted date
  String get formattedDate {
    if (createdAt == null) return '';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${createdAt!.day} ${months[createdAt!.month - 1]} ${createdAt!.year}';
  }

  // Get status display text
  String get statusDisplayText {
    switch (paymentStatus.toLowerCase()) {
      case 'pending':
        return 'Payment Pending';
      case 'completed':
        return 'Order Completed';
      case 'failed':
        return 'Payment Failed';
      case 'canceled':
        return 'Order Canceled';
      default:
        return paymentStatus;
    }
  }

  // Get status color
  String get statusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'completed':
        return 'green';
      case 'pending':
        return 'orange';
      case 'failed':
      case 'canceled':
        return 'red';
      default:
        return 'gray';
    }
  }

  // Copy with
  OrderModel copyWith({
    String? orderId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    double? totalAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? stripePaymentId,
    String? receiptUrl,
    List<OrderItemModel>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerPhone: customerPhone ?? this.customerPhone,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      stripePaymentId: stripePaymentId ?? this.stripePaymentId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Order Item Model
class OrderItemModel {
  final int itemId;
  final String orderId;
  final int dressId;
  final String dressName;
  final String sizeName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? imageUrl;

  OrderItemModel({
    required this.itemId,
    required this.orderId,
    required this.dressId,
    required this.dressName,
    required this.sizeName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.imageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      itemId: json['item_id'] ?? 0,
      orderId: json['order_id'] ?? '',
      dressId: json['dress_id'] ?? 0,
      dressName: json['dress_name'] ?? '',
      sizeName: json['size_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'order_id': orderId,
      'dress_id': dressId,
      'dress_name': dressName,
      'size_name': sizeName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'image_url': imageUrl,
    };
  }

  // Get formatted price
  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  // Get formatted subtotal
  String get formattedSubtotal => '₹${subtotal.toStringAsFixed(2)}';

  // Copy with
  OrderItemModel copyWith({
    int? itemId,
    String? orderId,
    int? dressId,
    String? dressName,
    String? sizeName,
    int? quantity,
    double? price,
    double? subtotal,
    String? imageUrl,
  }) {
    return OrderItemModel(
      itemId: itemId ?? this.itemId,
      orderId: orderId ?? this.orderId,
      dressId: dressId ?? this.dressId,
      dressName: dressName ?? this.dressName,
      sizeName: sizeName ?? this.sizeName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

// Order Status enum
enum OrderStatus {
  pending,
  processing,
  completed,
  failed,
  canceled,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Payment Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.failed:
        return 'Failed';
      case OrderStatus.canceled:
        return 'Canceled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  bool get isActive {
    return this == OrderStatus.pending || this == OrderStatus.processing;
  }

  bool get isFinished {
    return this == OrderStatus.completed ||
        this == OrderStatus.failed ||
        this == OrderStatus.canceled ||
        this == OrderStatus.refunded;
  }
}