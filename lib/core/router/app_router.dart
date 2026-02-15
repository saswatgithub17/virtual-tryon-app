import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:virtual_tryon_app/features/catalog/presentation/pages/catalog_page.dart';
import 'package:virtual_tryon_app/features/catalog/presentation/pages/dress_detail_page.dart';
import 'package:virtual_tryon_app/features/cart/presentation/pages/cart_page.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/pages/payment_page.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/pages/receipt_page.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/pages/tryon_page.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/pages/camera_page.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/pages/result_page.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: CatalogRoute.page, initial: true),
        AutoRoute(page: DressDetailRoute.page),
        AutoRoute(page: CartRoute.page),
        AutoRoute(page: CheckoutRoute.page),
        AutoRoute(page: PaymentRoute.page),
        AutoRoute(page: ReceiptRoute.page),
        AutoRoute(page: TryOnRoute.page),
        AutoRoute(page: CameraRoute.page),
        AutoRoute(page: ResultRoute.page),
      ];
}
