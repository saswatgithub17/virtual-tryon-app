// lib/screens/tryon/tryon_screen.dart
// Premium Try-On Dress Selection Screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/tryon_provider.dart';
import '../../providers/dress_provider.dart';
import '../../config/api_config.dart';
import '../../config/theme_config.dart';
import '../../config/app_config.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/helpers.dart';
import 'result_screen.dart';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDresses();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadDresses() async {
    final provider = Provider.of<DressProvider>(context, listen: false);
    await provider.loadDresses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConfig.backgroundColor,
      appBar: _buildAppBar(),
      body: Consumer2<TryOnProvider, DressProvider>(
        builder: (context, tryOnProvider, dressProvider, child) {
          if (tryOnProvider.isProcessing) {
            return _buildProcessingView(tryOnProvider);
          }

          return Column(
            children: [
              _buildUserPhotoHeader(tryOnProvider),
              _buildSelectionCounter(tryOnProvider),
              Expanded(
                child: _buildDressGrid(tryOnProvider, dressProvider),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Select Dresses to Try On',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildUserPhotoHeader(TryOnProvider provider) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.primaryColor.withOpacity(0.1),
            ThemeConfig.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // User photo thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              provider.userPhoto!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),

          // Instructions
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Select up to ${AppConfig.maxTryOnDresses} dresses to try on',
                  style: TextStyle(
                    fontSize: 13,
                    color: ThemeConfig.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCounter(TryOnProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Selected Dresses',
            style: TextStyle(
              fontSize: 14,
              color: ThemeConfig.textSecondary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  ThemeConfig.primaryColor,
                  ThemeConfig.secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${provider.selectedCount}/${AppConfig.maxTryOnDresses}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDressGrid(
      TryOnProvider tryOnProvider,
      DressProvider dressProvider,
      ) {
    if (dressProvider.isLoading) {
      return const SkeletonGrid();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: dressProvider.dresses.length,
      itemBuilder: (context, index) {
        final dress = dressProvider.dresses[index];
        final isSelected = tryOnProvider.isDressSelected(dress.dressId);

        return GestureDetector(
          onTap: () => tryOnProvider.toggleDressSelection(dress),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? ThemeConfig.primaryColor
                    : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? ThemeConfig.primaryColor.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Dress card
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: ApiConfig.getUploadUrl(dress.imageUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),

                      // Info
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dress.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppConfig.formatPriceShort(dress.price),
                              style: const TextStyle(
                                color: ThemeConfig.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            ThemeConfig.primaryColor,
                            ThemeConfig.secondaryColor,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConfig.primaryColor.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingView(TryOnProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gradient circle
            RotationTransition(
              turns: _progressAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: SweepGradient(
                    colors: [
                      ThemeConfig.primaryColor,
                      ThemeConfig.secondaryColor,
                      ThemeConfig.primaryColor,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: ThemeConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${provider.percentage}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status message
            Text(
              provider.statusMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take 2-3 minutes for the first request',
              style: TextStyle(
                fontSize: 13,
                color: ThemeConfig.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Consumer<TryOnProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: provider.canProcess && !provider.isProcessing
                  ? _processTryOn
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                provider.selectedCount > 0
                    ? 'Try On ${provider.selectedCount} Dress${provider.selectedCount > 1 ? 'es' : ''}'
                    : 'Select Dresses to Try On',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _processTryOn() async {
    final provider = Provider.of<TryOnProvider>(context, listen: false);

    // Validate
    final error = provider.validateForProcessing();
    if (error != null) {
      Helpers.showError(context, error);
      return;
    }

    // Process try-on
    final success = await provider.processTryOn();

    if (mounted) {
      if (success) {
        // Navigate to results
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ResultScreen(),
          ),
        );
      } else {
        Helpers.showError(
          context,
          provider.error ?? 'Try-on failed. Please try again.',
        );
      }
    }
  }
}