import 'package:dart_mappable/dart_mappable.dart';

part 'order_model.mapper.dart';

@MappableClass(caseStyle: CaseStyle.snakeCase)
class Order with OrderMappable {
  final String orderId;
  final String? customerName;
  final String? customerEmail;
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
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.stripePaymentId,
    this.receiptUrl,
    this.items = const [],
    this.createdAt,
  });

  bool get isPending => paymentStatus == 'pending';
  bool get isCompleted => paymentStatus == 'completed';
  bool get isFailed => paymentStatus == 'failed';

  static const fromMap = OrderMapper.fromMap;
  static const fromJson = OrderMapper.fromJson;
}

@MappableClass(caseStyle: CaseStyle.snakeCase)
class OrderItem with OrderItemMappable {
  final int? itemId;
  final String? orderId;
  final int? dressId;
  final String? dressName;
  final String? sizeName;
  final int? quantity;
  final double? price;
  final double? subtotal;

  OrderItem({
    this.itemId,
    this.orderId,
    this.dressId,
    this.dressName,
    this.sizeName,
    this.quantity,
    this.price,
    this.subtotal,
  });

  static const fromMap = OrderItemMapper.fromMap;
  static const fromJson = OrderItemMapper.fromJson;
}
