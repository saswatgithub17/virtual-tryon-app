// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [CameraPage]
class CameraRoute extends PageRouteInfo<CameraRouteArgs> {
  CameraRoute({Key? key, Dress? dress, List<PageRouteInfo>? children})
      : super(
          CameraRoute.name,
          args: CameraRouteArgs(key: key, dress: dress),
          initialChildren: children,
        );

  static const String name = 'CameraRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<CameraRouteArgs>(
        orElse: () => const CameraRouteArgs(),
      );
      return CameraPage(key: args.key, dress: args.dress);
    },
  );
}

class CameraRouteArgs {
  const CameraRouteArgs({this.key, this.dress});

  final Key? key;

  final Dress? dress;

  @override
  String toString() {
    return 'CameraRouteArgs{key: $key, dress: $dress}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CameraRouteArgs) return false;
    return key == other.key && dress == other.dress;
  }

  @override
  int get hashCode => key.hashCode ^ dress.hashCode;
}

/// generated route for
/// [CartPage]
class CartRoute extends PageRouteInfo<void> {
  const CartRoute({List<PageRouteInfo>? children})
      : super(CartRoute.name, initialChildren: children);

  static const String name = 'CartRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CartPage();
    },
  );
}

/// generated route for
/// [CatalogPage]
class CatalogRoute extends PageRouteInfo<void> {
  const CatalogRoute({List<PageRouteInfo>? children})
      : super(CatalogRoute.name, initialChildren: children);

  static const String name = 'CatalogRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CatalogPage();
    },
  );
}

/// generated route for
/// [CheckoutPage]
class CheckoutRoute extends PageRouteInfo<void> {
  const CheckoutRoute({List<PageRouteInfo>? children})
      : super(CheckoutRoute.name, initialChildren: children);

  static const String name = 'CheckoutRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CheckoutPage();
    },
  );
}

/// generated route for
/// [DressDetailPage]
class DressDetailRoute extends PageRouteInfo<DressDetailRouteArgs> {
  DressDetailRoute({
    Key? key,
    required Dress dress,
    List<PageRouteInfo>? children,
  }) : super(
          DressDetailRoute.name,
          args: DressDetailRouteArgs(key: key, dress: dress),
          initialChildren: children,
        );

  static const String name = 'DressDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<DressDetailRouteArgs>();
      return DressDetailPage(key: args.key, dress: args.dress);
    },
  );
}

class DressDetailRouteArgs {
  const DressDetailRouteArgs({this.key, required this.dress});

  final Key? key;

  final Dress dress;

  @override
  String toString() {
    return 'DressDetailRouteArgs{key: $key, dress: $dress}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DressDetailRouteArgs) return false;
    return key == other.key && dress == other.dress;
  }

  @override
  int get hashCode => key.hashCode ^ dress.hashCode;
}

/// generated route for
/// [PaymentPage]
class PaymentRoute extends PageRouteInfo<void> {
  const PaymentRoute({List<PageRouteInfo>? children})
      : super(PaymentRoute.name, initialChildren: children);

  static const String name = 'PaymentRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PaymentPage();
    },
  );
}

/// generated route for
/// [ReceiptPage]
class ReceiptRoute extends PageRouteInfo<ReceiptRouteArgs> {
  ReceiptRoute({
    Key? key,
    required String orderId,
    List<PageRouteInfo>? children,
  }) : super(
          ReceiptRoute.name,
          args: ReceiptRouteArgs(key: key, orderId: orderId),
          initialChildren: children,
        );

  static const String name = 'ReceiptRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ReceiptRouteArgs>();
      return ReceiptPage(key: args.key, orderId: args.orderId);
    },
  );
}

class ReceiptRouteArgs {
  const ReceiptRouteArgs({this.key, required this.orderId});

  final Key? key;

  final String orderId;

  @override
  String toString() {
    return 'ReceiptRouteArgs{key: $key, orderId: $orderId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReceiptRouteArgs) return false;
    return key == other.key && orderId == other.orderId;
  }

  @override
  int get hashCode => key.hashCode ^ orderId.hashCode;
}

/// generated route for
/// [ResultPage]
class ResultRoute extends PageRouteInfo<void> {
  const ResultRoute({List<PageRouteInfo>? children})
      : super(ResultRoute.name, initialChildren: children);

  static const String name = 'ResultRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ResultPage();
    },
  );
}

/// generated route for
/// [TryOnPage]
class TryOnRoute extends PageRouteInfo<void> {
  const TryOnRoute({List<PageRouteInfo>? children})
      : super(TryOnRoute.name, initialChildren: children);

  static const String name = 'TryOnRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TryOnPage();
    },
  );
}
