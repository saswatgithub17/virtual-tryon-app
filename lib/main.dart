import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/network/stripe_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Stripe init — wrapped in try-catch so a missing/invalid key
  // does NOT crash the app before runApp(). The rest of the app
  // works normally; only card payments will fail until a real key
  // is added to stripe_config.dart.
  try {
    await StripeConfig.init();
  } catch (e) {
    debugPrint('⚠️ Stripe not initialised: $e');
    debugPrint('   Add your real key to stripe_config.dart to enable card payments.');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AuraTry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _appRouter.config(),
    );
  }
}