import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/controllers/tryon_controller.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

@RoutePage()
class TryOnPage extends ConsumerStatefulWidget {
  const TryOnPage({super.key});

  @override
  ConsumerState<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends ConsumerState<TryOnPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tryOnState = ref.watch(tryOnControllerProvider);
    final catalogState = ref.watch(catalogControllerProvider);

    if (tryOnState.isProcessing) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: _buildProcessingView(tryOnState),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Select Dresses to Try On',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildUserPhotoHeader(tryOnState),
          _buildSelectionCounter(tryOnState),
          Expanded(
            child: catalogState.when(
              data: (dresses) => _buildDressGrid(tryOnState, dresses),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(tryOnState),
    );
  }

  Widget _buildUserPhotoHeader(TryOnState state) {
    if (state.userPhoto == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withOpacity(0.1),
          AppTheme.secondaryColor.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(state.userPhoto!,
                width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Photo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Select up to 5 dresses to try on',
                    style:
                        TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCounter(TryOnState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Selected Dresses',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${state.selectedDresses.length}/5',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDressGrid(TryOnState state, dynamic dresses) {
    final list = dresses as List;
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final dress = list[index];
        final isSelected =
            state.selectedDresses.any((d) => d.dressId == dress.dressId);

        return GestureDetector(
          onTap: () => ref
              .read(tryOnControllerProvider.notifier)
              .toggleDressSelection(dress),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 3),
              boxShadow: [
                BoxShadow(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: ApiConfig.getUploadUrl(dress.imageUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dress.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(AppConfig.formatPriceShort(dress.price),
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor
                          ]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                blurRadius: 8)
                          ]),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProcessingView(TryOnState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _progressAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: SweepGradient(colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor,
                    AppTheme.primaryColor
                  ]),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30)),
              child: Text('${(state.progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ),
            const SizedBox(height: 16),
            Text(state.statusMessage,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('This may take 2-3 minutes for the first request',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(TryOnState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: state.selectedDresses.isNotEmpty && !state.isProcessing
              ? _processTryOn
              : null,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: Text(
            state.selectedDresses.isNotEmpty
                ? 'Try On ${state.selectedDresses.length} Dress${state.selectedDresses.length > 1 ? 'es' : ''}'
                : 'Select Dresses to Try On',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _processTryOn() async {
    final controller = ref.read(tryOnControllerProvider.notifier);
    final success = await controller.processTryOn();

    if (mounted) {
      if (success) {
        context.router.push(const ResultRoute());
      } else {
        Helpers.showError(context,
            ref.read(tryOnControllerProvider).error ?? 'Try-on failed');
      }
    }
  }
}
