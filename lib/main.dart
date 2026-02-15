import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtual_tryon_app/models/dress_model.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/dress_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/checkout/payment_screen.dart';
import 'screens/receipt/receipt_screen.dart';
import 'screens/tryon/tryon_screen.dart';
import 'screens/tryon/camera_screen.dart';
import 'screens/tryon/result_screen.dart';

// Providers
import 'providers/cart_provider.dart';
import 'providers/dress_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/tryon_provider.dart';

// Config
import 'config/theme_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Stripe when ready
  // await StripeConfig.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DressProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => TryOnProvider()),
      ],
      child: MaterialApp(
        title: 'AuraTry',
        debugShowCheckedModeBanner: false,

        // Use your existing theme_config.dart
        theme: ThemeConfig.lightTheme,

        // Start with splash screen
        initialRoute: '/',

        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
          '/payment': (context) => const PaymentScreen(),
          '/receipt': (context) => const ReceiptScreen(),
          '/tryon': (context) => const TryOnScreen(),
        },

        // For routes that need arguments
        onGenerateRoute: (settings) {
          // Dress Detail Screen with dress argument
          if (settings.name == '/dress-detail') {
            final dress = settings.arguments as Dress;
            return MaterialPageRoute(
              builder: (context) => DressDetailScreen(dress: dress),
            );
          }

          // Camera Screen with dress argument
          if (settings.name == '/camera') {
            final dress = settings.arguments;
            return MaterialPageRoute(
              builder: (context) => CameraScreen(dress: dress),
            );
          }

          // Result Screen with arguments
          if (settings.name == '/result') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => ResultScreen(
                imagePath: args['imagePath'],
                dress: args['dress'],
              ),
            );
          }

          return null;
        },
      ),
    );
  }
}