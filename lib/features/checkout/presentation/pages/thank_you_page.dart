import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';
import 'package:virtual_tryon_app/features/checkout/presentation/controllers/checkout_controller.dart';

@RoutePage()
class ThankYouPage extends ConsumerStatefulWidget {
  const ThankYouPage({super.key});

  @override
  ConsumerState<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends ConsumerState<ThankYouPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;
  
  Timer? _redirectTimer;
  int _countdown = 5;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Scale animation for checkmark
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Fade animation for text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );
    
    // Rotate animation for stars
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_rotateController);

    // Confetti animation
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
    
    // Start countdown timer
    _startCountdown();
  }

  void _startCountdown() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        if (_countdown <= 0) {
          timer.cancel();
          _navigateToReceipt();
        }
      }
    });
  }

  void _navigateToReceipt() {
    if (mounted) {
      // Get order ID from checkout controller
      final checkoutState = ref.read(checkoutControllerProvider);
      final orderId = checkoutState.currentOrder?.orderId ?? 'N/A';
      
      context.router.replace(ReceiptRoute(orderId: orderId));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _rotateController.dispose();
    _confettiController.dispose();
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.secondaryColor.withOpacity(0.2),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
              ),
            ),
          ),
          
          // Animated confetti
          AnimatedBuilder(
            animation: _confettiController,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(
                  animationValue: _confettiController.value,
                  random: _random,
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),
            
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Beautiful success image with animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.successColor,
                            AppTheme.successColor.withOpacity(0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successColor.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 4,
                              ),
                            ),
                          ),
                          // Success icon
                          const Icon(
                            Icons.check_circle,
                            size: 100,
                            color: Colors.white,
                          ),
                          // Stars around
                          ...List.generate(5, (index) {
                            final angle = (index * 72) * pi / 180;
                            return Positioned(
                              left: 80 + cos(angle) * 70 - 12,
                              top: 80 + sin(angle) * 70 - 12,
                              child: Transform.rotate(
                                angle: _rotateAnimation.value * 2 * pi,
                                child: Icon(
                                  Icons.star,
                                  color: Colors.yellow,
                                  size: 24,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Thank you message
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Thank You! 🎉',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successColor.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Your Order is Confirmed!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Thank you for shopping with us.\nWe appreciate your trust!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Auto-redirect countdown
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Redirecting to receipt in $_countdown seconds',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Skip button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: TextButton.icon(
                      onPressed: _navigateToReceipt,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip to Receipt'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Confetti painter for celebration effect
class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final Random random;
  
  ConfettiPainter({required this.animationValue, required this.random});
  
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    
    for (var i = 0; i < 30; i++) {
      final startX = random.nextDouble() * size.width;
      final progress = (animationValue + i * 0.03) % 1.0;
      final y = progress * size.height;
      final x = startX + sin(progress * 10 + i) * 20;
      final opacity = progress < 0.8 ? 1.0 - progress : 0.0;
      
      final paint = Paint()
        ..color = colors[i % colors.length].withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;
      
      // Draw different shapes
      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), 4 + random.nextDouble() * 4, paint);
      } else if (i % 3 == 1) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 8,
            height: 8,
          ),
          paint,
        );
      } else {
        final path = Path();
        path.moveTo(x, y - 6);
        path.lineTo(x + 5, y + 5);
        path.lineTo(x - 5, y + 5);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
