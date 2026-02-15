// lib/models/analytics_model.dart
// Analytics & Dashboard Data Models

class DashboardAnalytics {
  final int totalDresses;
  final int totalOrders;
  final double totalRevenue;
  final int pendingOrders;
  final int completedOrders;
  final List<TopDress> topDresses;
  final List<RecentOrder> recentOrders;
  final SalesAnalytics? salesAnalytics;

  DashboardAnalytics({
    required this.totalDresses,
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.completedOrders,
    this.topDresses = const [],
    this.recentOrders = const [],
    this.salesAnalytics,
  });

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    return DashboardAnalytics(
      totalDresses: json['total_dresses'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '0') ?? 0.0,
      pendingOrders: json['pending_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      topDresses: json['top_dresses'] != null
          ? (json['top_dresses'] as List)
          .map((item) => TopDress.fromJson(item))
          .toList()
          : [],
      recentOrders: json['recent_orders'] != null
          ? (json['recent_orders'] as List)
          .map((item) => RecentOrder.fromJson(item))
          .toList()
          : [],
      salesAnalytics: json['sales_analytics'] != null
          ? SalesAnalytics.fromJson(json['sales_analytics'])
          : null,
    );
  }

  double get averageOrderValue =>
      totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

  int get failedOrders => totalOrders - completedOrders - pendingOrders;

  double get completionRate =>
      totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;
}

class TopDress {
  final int dressId;
  final String name;
  final int orderCount;
  final double revenue;
  final String? imageUrl;

  TopDress({
    required this.dressId,
    required this.name,
    required this.orderCount,
    required this.revenue,
    this.imageUrl,
  });

  factory TopDress.fromJson(Map<String, dynamic> json) {
    return TopDress(
      dressId: json['dress_id'] ?? 0,
      name: json['name'] ?? '',
      orderCount: json['order_count'] ?? 0,
      revenue: double.tryParse(json['revenue']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'],
    );
  }
}

class RecentOrder {
  final String orderId;
  final String customerName;
  final double totalAmount;
  final String paymentStatus;
  final DateTime? createdAt;

  RecentOrder({
    required this.orderId,
    required this.customerName,
    required this.totalAmount,
    required this.paymentStatus,
    this.createdAt,
  });

  factory RecentOrder.fromJson(Map<String, dynamic> json) {
    return RecentOrder(
      orderId: json['order_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  bool get isPending => paymentStatus == 'pending';
  bool get isCompleted => paymentStatus == 'completed';
  bool get isFailed => paymentStatus == 'failed';
}

class SalesAnalytics {
  final Map<String, double> dailySales;
  final Map<String, double> monthlySales;
  final Map<String, int> categoryWiseSales;

  SalesAnalytics({
    required this.dailySales,
    required this.monthlySales,
    required this.categoryWiseSales,
  });

  factory SalesAnalytics.fromJson(Map<String, dynamic> json) {
    return SalesAnalytics(
      dailySales: _parseMap(json['daily_sales']),
      monthlySales: _parseMap(json['monthly_sales']),
      categoryWiseSales: _parseIntMap(json['category_wise_sales']),
    );
  }

  static Map<String, double> _parseMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      return data.map((key, value) =>
          MapEntry(key.toString(), double.tryParse(value.toString()) ?? 0.0));
    }
    return {};
  }

  static Map<String, int> _parseIntMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) {
      return data.map((key, value) =>
          MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0));
    }
    return {};
  }
}

// Transaction Model
class Transaction {
  final String orderId;
  final String customerName;
  final String customerEmail;
  final double amount;
  final String paymentStatus;
  final String? paymentMethod;
  final String? stripePaymentId;
  final DateTime? createdAt;
  final List<TransactionItem> items;

  Transaction({
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    required this.amount,
    required this.paymentStatus,
    this.paymentMethod,
    this.stripePaymentId,
    this.createdAt,
    this.items = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      orderId: json['order_id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      amount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'],
      stripePaymentId: json['stripe_payment_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
          .map((item) => TransactionItem.fromJson(item))
          .toList()
          : [],
    );
  }

  bool get isPending => paymentStatus == 'pending';
  bool get isCompleted => paymentStatus == 'completed';
  bool get isFailed => paymentStatus == 'failed';
}

class TransactionItem {
  final String dressName;
  final int quantity;
  final double price;
  final String sizeName;

  TransactionItem({
    required this.dressName,
    required this.quantity,
    required this.price,
    required this.sizeName,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      dressName: json['dress_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      sizeName: json['size_name'] ?? '',
    );
  }

  double get subtotal => price * quantity;
}

// Try-On History Model
class TryOnHistory {
  final int historyId;
  final String sessionId;
  final List<int> dressIds;
  final String userImagePath;
  final List<String> resultImagePaths;
  final DateTime? createdAt;

  TryOnHistory({
    required this.historyId,
    required this.sessionId,
    required this.dressIds,
    required this.userImagePath,
    required this.resultImagePaths,
    this.createdAt,
  });

  factory TryOnHistory.fromJson(Map<String, dynamic> json) {
    return TryOnHistory(
      historyId: json['history_id'] ?? 0,
      sessionId: json['session_id'] ?? '',
      dressIds: _parseDressIds(json['dress_ids']),
      userImagePath: json['user_image_path'] ?? '',
      resultImagePaths: _parseResultPaths(json['result_image_paths']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  static List<int> _parseDressIds(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      return data.split(',').map((id) => int.tryParse(id) ?? 0).toList();
    }
    if (data is List) {
      return data.map((id) => int.tryParse(id.toString()) ?? 0).toList();
    }
    return [];
  }

  static List<String> _parseResultPaths(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      return data.split(',').where((path) => path.isNotEmpty).toList();
    }
    if (data is List) {
      return data.map((path) => path.toString()).toList();
    }
    return [];
  }

  int get dressCount => dressIds.length;
  int get resultCount => resultImagePaths.length;
}