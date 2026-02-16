import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:virtual_tryon_app/features/catalog/presentation/pages/catalog_page.dart';
import 'package:virtual_tryon_app/features/catalog/presentation/pages/dress_detail_page.dart';
import 'package:virtual_tryon_app/features/catalog/presentation/pages/splash_screen.dart';
import 'package:virtual_tryon_app/features/cart/presentation/pages/cart_page.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/pages/checkout_page.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/pages/payment_page.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/pages/receipt_page.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/pages/thank_you_page.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/pages/tryon_page.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/pages/camera_page.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/pages/result_page.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashRoute.page, initial: true, path: '/'),
        AutoRoute(page: CatalogRoute.page, path: '/catalog'),
        AutoRoute(page: DressDetailRoute.page, path: '/dress'),
        AutoRoute(page: CartRoute.page, path: '/cart'),
        AutoRoute(page: CheckoutRoute.page, path: '/checkout'),
        AutoRoute(page: PaymentRoute.page, path: '/payment'),
        AutoRoute(page: ReceiptRoute.page, path: '/receipt'),
        AutoRoute(page: ThankYouRoute.page, path: '/thank-you'),
        AutoRoute(page: TryOnRoute.page, path: '/tryon'),
        AutoRoute(page: CameraRoute.page, path: '/camera'),
        AutoRoute(page: ResultRoute.page, path: '/result'),
      ];
}
