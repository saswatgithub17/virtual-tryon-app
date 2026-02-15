// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'order_model.dart';

class OrderMapper extends ClassMapperBase<Order> {
  OrderMapper._();

  static OrderMapper? _instance;
  static OrderMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = OrderMapper._());
      OrderItemMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Order';

  static String _$orderId(Order v) => v.orderId;
  static const Field<Order, String> _f$orderId =
      Field('orderId', _$orderId, key: r'order_id');
  static String _$customerName(Order v) => v.customerName;
  static const Field<Order, String> _f$customerName =
      Field('customerName', _$customerName, key: r'customer_name');
  static String _$customerEmail(Order v) => v.customerEmail;
  static const Field<Order, String> _f$customerEmail =
      Field('customerEmail', _$customerEmail, key: r'customer_email');
  static String? _$customerPhone(Order v) => v.customerPhone;
  static const Field<Order, String> _f$customerPhone = Field(
      'customerPhone', _$customerPhone,
      key: r'customer_phone', opt: true);
  static double _$totalAmount(Order v) => v.totalAmount;
  static const Field<Order, double> _f$totalAmount =
      Field('totalAmount', _$totalAmount, key: r'total_amount');
  static String _$paymentStatus(Order v) => v.paymentStatus;
  static const Field<Order, String> _f$paymentStatus =
      Field('paymentStatus', _$paymentStatus, key: r'payment_status');
  static String? _$paymentMethod(Order v) => v.paymentMethod;
  static const Field<Order, String> _f$paymentMethod = Field(
      'paymentMethod', _$paymentMethod,
      key: r'payment_method', opt: true);
  static String? _$stripePaymentId(Order v) => v.stripePaymentId;
  static const Field<Order, String> _f$stripePaymentId = Field(
      'stripePaymentId', _$stripePaymentId,
      key: r'stripe_payment_id', opt: true);
  static String? _$receiptUrl(Order v) => v.receiptUrl;
  static const Field<Order, String> _f$receiptUrl =
      Field('receiptUrl', _$receiptUrl, key: r'receipt_url', opt: true);
  static List<OrderItem> _$items(Order v) => v.items;
  static const Field<Order, List<OrderItem>> _f$items =
      Field('items', _$items, opt: true, def: const []);
  static DateTime? _$createdAt(Order v) => v.createdAt;
  static const Field<Order, DateTime> _f$createdAt =
      Field('createdAt', _$createdAt, key: r'created_at', opt: true);

  @override
  final MappableFields<Order> fields = const {
    #orderId: _f$orderId,
    #customerName: _f$customerName,
    #customerEmail: _f$customerEmail,
    #customerPhone: _f$customerPhone,
    #totalAmount: _f$totalAmount,
    #paymentStatus: _f$paymentStatus,
    #paymentMethod: _f$paymentMethod,
    #stripePaymentId: _f$stripePaymentId,
    #receiptUrl: _f$receiptUrl,
    #items: _f$items,
    #createdAt: _f$createdAt,
  };

  static Order _instantiate(DecodingData data) {
    return Order(
        orderId: data.dec(_f$orderId),
        customerName: data.dec(_f$customerName),
        customerEmail: data.dec(_f$customerEmail),
        customerPhone: data.dec(_f$customerPhone),
        totalAmount: data.dec(_f$totalAmount),
        paymentStatus: data.dec(_f$paymentStatus),
        paymentMethod: data.dec(_f$paymentMethod),
        stripePaymentId: data.dec(_f$stripePaymentId),
        receiptUrl: data.dec(_f$receiptUrl),
        items: data.dec(_f$items),
        createdAt: data.dec(_f$createdAt));
  }

  @override
  final Function instantiate = _instantiate;

  static Order fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Order>(map);
  }

  static Order fromJson(String json) {
    return ensureInitialized().decodeJson<Order>(json);
  }
}

mixin OrderMappable {
  String toJson() {
    return OrderMapper.ensureInitialized().encodeJson<Order>(this as Order);
  }

  Map<String, dynamic> toMap() {
    return OrderMapper.ensureInitialized().encodeMap<Order>(this as Order);
  }

  OrderCopyWith<Order, Order, Order> get copyWith =>
      _OrderCopyWithImpl<Order, Order>(this as Order, $identity, $identity);
  @override
  String toString() {
    return OrderMapper.ensureInitialized().stringifyValue(this as Order);
  }

  @override
  bool operator ==(Object other) {
    return OrderMapper.ensureInitialized().equalsValue(this as Order, other);
  }

  @override
  int get hashCode {
    return OrderMapper.ensureInitialized().hashValue(this as Order);
  }
}

extension OrderValueCopy<$R, $Out> on ObjectCopyWith<$R, Order, $Out> {
  OrderCopyWith<$R, Order, $Out> get $asOrder =>
      $base.as((v, t, t2) => _OrderCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class OrderCopyWith<$R, $In extends Order, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, OrderItem, OrderItemCopyWith<$R, OrderItem, OrderItem>>
      get items;
  $R call(
      {String? orderId,
      String? customerName,
      String? customerEmail,
      String? customerPhone,
      double? totalAmount,
      String? paymentStatus,
      String? paymentMethod,
      String? stripePaymentId,
      String? receiptUrl,
      List<OrderItem>? items,
      DateTime? createdAt});
  OrderCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _OrderCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Order, $Out>
    implements OrderCopyWith<$R, Order, $Out> {
  _OrderCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Order> $mapper = OrderMapper.ensureInitialized();
  @override
  ListCopyWith<$R, OrderItem, OrderItemCopyWith<$R, OrderItem, OrderItem>>
      get items => ListCopyWith(
          $value.items, (v, t) => v.copyWith.$chain(t), (v) => call(items: v));
  @override
  $R call(
          {String? orderId,
          String? customerName,
          String? customerEmail,
          Object? customerPhone = $none,
          double? totalAmount,
          String? paymentStatus,
          Object? paymentMethod = $none,
          Object? stripePaymentId = $none,
          Object? receiptUrl = $none,
          List<OrderItem>? items,
          Object? createdAt = $none}) =>
      $apply(FieldCopyWithData({
        if (orderId != null) #orderId: orderId,
        if (customerName != null) #customerName: customerName,
        if (customerEmail != null) #customerEmail: customerEmail,
        if (customerPhone != $none) #customerPhone: customerPhone,
        if (totalAmount != null) #totalAmount: totalAmount,
        if (paymentStatus != null) #paymentStatus: paymentStatus,
        if (paymentMethod != $none) #paymentMethod: paymentMethod,
        if (stripePaymentId != $none) #stripePaymentId: stripePaymentId,
        if (receiptUrl != $none) #receiptUrl: receiptUrl,
        if (items != null) #items: items,
        if (createdAt != $none) #createdAt: createdAt
      }));
  @override
  Order $make(CopyWithData data) => Order(
      orderId: data.get(#orderId, or: $value.orderId),
      customerName: data.get(#customerName, or: $value.customerName),
      customerEmail: data.get(#customerEmail, or: $value.customerEmail),
      customerPhone: data.get(#customerPhone, or: $value.customerPhone),
      totalAmount: data.get(#totalAmount, or: $value.totalAmount),
      paymentStatus: data.get(#paymentStatus, or: $value.paymentStatus),
      paymentMethod: data.get(#paymentMethod, or: $value.paymentMethod),
      stripePaymentId: data.get(#stripePaymentId, or: $value.stripePaymentId),
      receiptUrl: data.get(#receiptUrl, or: $value.receiptUrl),
      items: data.get(#items, or: $value.items),
      createdAt: data.get(#createdAt, or: $value.createdAt));

  @override
  OrderCopyWith<$R2, Order, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _OrderCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class OrderItemMapper extends ClassMapperBase<OrderItem> {
  OrderItemMapper._();

  static OrderItemMapper? _instance;
  static OrderItemMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = OrderItemMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'OrderItem';

  static int _$itemId(OrderItem v) => v.itemId;
  static const Field<OrderItem, int> _f$itemId =
      Field('itemId', _$itemId, key: r'item_id');
  static String _$orderId(OrderItem v) => v.orderId;
  static const Field<OrderItem, String> _f$orderId =
      Field('orderId', _$orderId, key: r'order_id');
  static int _$dressId(OrderItem v) => v.dressId;
  static const Field<OrderItem, int> _f$dressId =
      Field('dressId', _$dressId, key: r'dress_id');
  static String _$dressName(OrderItem v) => v.dressName;
  static const Field<OrderItem, String> _f$dressName =
      Field('dressName', _$dressName, key: r'dress_name');
  static String _$sizeName(OrderItem v) => v.sizeName;
  static const Field<OrderItem, String> _f$sizeName =
      Field('sizeName', _$sizeName, key: r'size_name');
  static int _$quantity(OrderItem v) => v.quantity;
  static const Field<OrderItem, int> _f$quantity =
      Field('quantity', _$quantity);
  static double _$price(OrderItem v) => v.price;
  static const Field<OrderItem, double> _f$price = Field('price', _$price);
  static double _$subtotal(OrderItem v) => v.subtotal;
  static const Field<OrderItem, double> _f$subtotal =
      Field('subtotal', _$subtotal);

  @override
  final MappableFields<OrderItem> fields = const {
    #itemId: _f$itemId,
    #orderId: _f$orderId,
    #dressId: _f$dressId,
    #dressName: _f$dressName,
    #sizeName: _f$sizeName,
    #quantity: _f$quantity,
    #price: _f$price,
    #subtotal: _f$subtotal,
  };

  static OrderItem _instantiate(DecodingData data) {
    return OrderItem(
        itemId: data.dec(_f$itemId),
        orderId: data.dec(_f$orderId),
        dressId: data.dec(_f$dressId),
        dressName: data.dec(_f$dressName),
        sizeName: data.dec(_f$sizeName),
        quantity: data.dec(_f$quantity),
        price: data.dec(_f$price),
        subtotal: data.dec(_f$subtotal));
  }

  @override
  final Function instantiate = _instantiate;

  static OrderItem fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<OrderItem>(map);
  }

  static OrderItem fromJson(String json) {
    return ensureInitialized().decodeJson<OrderItem>(json);
  }
}

mixin OrderItemMappable {
  String toJson() {
    return OrderItemMapper.ensureInitialized()
        .encodeJson<OrderItem>(this as OrderItem);
  }

  Map<String, dynamic> toMap() {
    return OrderItemMapper.ensureInitialized()
        .encodeMap<OrderItem>(this as OrderItem);
  }

  OrderItemCopyWith<OrderItem, OrderItem, OrderItem> get copyWith =>
      _OrderItemCopyWithImpl<OrderItem, OrderItem>(
          this as OrderItem, $identity, $identity);
  @override
  String toString() {
    return OrderItemMapper.ensureInitialized()
        .stringifyValue(this as OrderItem);
  }

  @override
  bool operator ==(Object other) {
    return OrderItemMapper.ensureInitialized()
        .equalsValue(this as OrderItem, other);
  }

  @override
  int get hashCode {
    return OrderItemMapper.ensureInitialized().hashValue(this as OrderItem);
  }
}

extension OrderItemValueCopy<$R, $Out> on ObjectCopyWith<$R, OrderItem, $Out> {
  OrderItemCopyWith<$R, OrderItem, $Out> get $asOrderItem =>
      $base.as((v, t, t2) => _OrderItemCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class OrderItemCopyWith<$R, $In extends OrderItem, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {int? itemId,
      String? orderId,
      int? dressId,
      String? dressName,
      String? sizeName,
      int? quantity,
      double? price,
      double? subtotal});
  OrderItemCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _OrderItemCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, OrderItem, $Out>
    implements OrderItemCopyWith<$R, OrderItem, $Out> {
  _OrderItemCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<OrderItem> $mapper =
      OrderItemMapper.ensureInitialized();
  @override
  $R call(
          {int? itemId,
          String? orderId,
          int? dressId,
          String? dressName,
          String? sizeName,
          int? quantity,
          double? price,
          double? subtotal}) =>
      $apply(FieldCopyWithData({
        if (itemId != null) #itemId: itemId,
        if (orderId != null) #orderId: orderId,
        if (dressId != null) #dressId: dressId,
        if (dressName != null) #dressName: dressName,
        if (sizeName != null) #sizeName: sizeName,
        if (quantity != null) #quantity: quantity,
        if (price != null) #price: price,
        if (subtotal != null) #subtotal: subtotal
      }));
  @override
  OrderItem $make(CopyWithData data) => OrderItem(
      itemId: data.get(#itemId, or: $value.itemId),
      orderId: data.get(#orderId, or: $value.orderId),
      dressId: data.get(#dressId, or: $value.dressId),
      dressName: data.get(#dressName, or: $value.dressName),
      sizeName: data.get(#sizeName, or: $value.sizeName),
      quantity: data.get(#quantity, or: $value.quantity),
      price: data.get(#price, or: $value.price),
      subtotal: data.get(#subtotal, or: $value.subtotal));

  @override
  OrderItemCopyWith<$R2, OrderItem, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _OrderItemCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
