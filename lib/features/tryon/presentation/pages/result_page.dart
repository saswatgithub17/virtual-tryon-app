import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/controllers/tryon_controller.dart';
import 'package:virtual_tryon_app/features/tryon/data/models/tryon_model.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

@RoutePage()
class ResultPage extends ConsumerStatefulWidget {
  const ResultPage({super.key});

  @override
  ConsumerState<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends ConsumerState<ResultPage> {
  late PageController _pageController;
  int _currentPage = 0;
  final Set<int> _selectedForCart = <int>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncCartSelection(TryOnState state) {
    final idsFromResults = state.results
        .where((r) => r.dressId != null)
        .map((r) => r.dressId!)
        .toSet();
    final ids = idsFromResults.isNotEmpty
        ? idsFromResults
        : state.selectedDresses.map((d) => d.dressId).toSet();

    if (_selectedForCart.isEmpty) {
      _selectedForCart.addAll(ids);
    } else {
      _selectedForCart.removeWhere((id) => !ids.contains(id));
      if (_selectedForCart.isEmpty) _selectedForCart.addAll(ids);
    }
  }

  void _toggleCartSelection(int? dressId, bool selected) {
    if (dressId == null) return;
    setState(() {
      if (selected) {
        _selectedForCart.add(dressId);
      } else {
        _selectedForCart.remove(dressId);
      }
    });
  }

  // ─── Add selected dresses to cart then navigate ───────────────────────────
  void _addSelectedToCart() {
    // Read selected dresses BEFORE any navigation so AutoDispose doesn't
    // wipe the state mid-call.
    final List<Dress> selectedDresses =
        List.from(ref.read(tryOnControllerProvider).selectedDresses);

    final dressesToAdd = selectedDresses
        .where((d) => _selectedForCart.contains(d.dressId))
        .toList();

    if (dressesToAdd.isEmpty) {
      Helpers.showError(context, 'Select at least one dress to add to cart.');
      return;
    }

    final cartSize =
        ref.read(tryOnControllerProvider).tryOnCartSize;
    final cartController = ref.read(cartControllerProvider.notifier);
    for (final dress in dressesToAdd) {
      cartController.addToCart(dress, quantity: 1, size: cartSize);
    }

    final count = dressesToAdd.length;
    Helpers.showSuccess(
      context,
      '$count dress${count > 1 ? "es" : ""} added to cart!',
    );

    // Navigate AFTER adding so cart state is written to SharedPreferences first
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) context.router.push(const CartRoute());
    });
  }

  Future<void> _showRetryGuidance() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Retake Tips',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('• Keep full body visible (head to feet).'),
            const Text('• Use bright, even lighting.'),
            const Text('• Keep camera steady to avoid blur.'),
            const Text('• Face camera directly for best fit.'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(tryOnControllerProvider.notifier).reset();
                      context.router.pop();
                    },
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tryOnState = ref.watch(tryOnControllerProvider);
    _syncCartSelection(tryOnState);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.router.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () => context.router.push(const CartRoute()),
          ),
        ],
      ),
      body: tryOnState.results.isEmpty
          ? const Center(
              child: Text('No results available',
                  style: TextStyle(color: Colors.white)))
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: tryOnState.results.length,
                    itemBuilder: (context, index) {
                      final result = tryOnState.results[index];

                      // ── Q1 FIX: look up original dress image from selectedDresses ──
                      // Match by dressId so the original catalogue photo can be shown
                      // side-by-side with the AI try-on result.
                      final Dress? originalDress = tryOnState.selectedDresses
                          .cast<Dress?>()
                          .firstWhere(
                            (d) => d?.dressId == result.dressId,
                            orElse: () => null,
                          );
                      final String? originalImageUrl =
                          originalDress?.imageUrl;

                      return _buildResultCard(
                        result,
                        originalImageUrl: originalImageUrl,
                      );
                    },
                  ),
                ),
                _buildPageIndicator(tryOnState.results.length),
                _buildBottomActions(tryOnState),
              ],
            ),
    );
  }

  // ─── Q1 FIX: [originalImageUrl] added ────────────────────────────────────
  // When an original dress image URL is available the card shows a labelled
  // side-by-side layout: "Original" on the left, "Try-On" on the right.
  // When it is null the card falls back to the single full-width result image
  // (same behaviour as before).
  Widget _buildResultCard(
    TryOnResult result, {
    String? originalImageUrl,
  }) {
    final imageUrl = result.displayUrl;
    final include = result.dressId != null &&
        _selectedForCart.contains(result.dressId);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Image area ────────────────────────────────────────────────────
          Expanded(
            child: originalImageUrl != null
                // ── Q1 FIX: side-by-side comparison ──────────────────────
                ? Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            // Left panel — original catalogue image
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Original',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      child: CachedNetworkImage(
                                        imageUrl: ApiConfig.getUploadUrl(
                                            originalImageUrl),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (_, __) =>
                                            const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white),
                                        ),
                                        errorWidget: (_, __, ___) =>
                                            const Center(
                                          child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.white54,
                                              size: 32),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Divider
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 1,
                                    height: 60,
                                    color: Colors.white24,
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 6),
                                    child: Icon(Icons.compare_arrows,
                                        color: Colors.white54, size: 18),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 60,
                                    color: Colors.white24,
                                  ),
                                ],
                              ),
                            ),

                            // Right panel — AI try-on result
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.8),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Try-On',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      child: imageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl:
                                                  ApiConfig.getUploadUrl(
                                                      imageUrl),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              placeholder: (_, __) =>
                                                  const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color:
                                                            Colors.white),
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  const Center(
                                                child: Icon(
                                                    Icons.error,
                                                    color: Colors.white,
                                                    size: 32),
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(
                                                  Icons
                                                      .image_not_supported,
                                                  color: Colors.white,
                                                  size: 32),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Q1 FIX: pattern accuracy disclaimer badge ────────
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.amber, size: 13),
                            SizedBox(width: 6),
                            Text(
                              'Pattern accuracy may vary',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                // ── Fallback: single result image (original behaviour) ────
                : Hero(
                    tag: 'result_${result.dressIndex ?? result.dressId}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: ApiConfig.getUploadUrl(imageUrl),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white)),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                child: Icon(Icons.error,
                                    color: Colors.white, size: 48),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.white, size: 48),
                            ),
                    ),
                  ),
          ),

          // ── Info card (unchanged) ─────────────────────────────────────────
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Text(result.dressName ?? 'Dress',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                if (result.dressId != null)
                  CheckboxListTile(
                    value: include,
                    onChanged: (v) =>
                        _toggleCartSelection(result.dressId, v ?? false),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Add this dress to cart'),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: result.aiGenerated
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          result.aiGenerated
                              ? Icons.check_circle
                              : Icons.info,
                          size: 16,
                          color: result.aiGenerated
                              ? AppTheme.successColor
                              : AppTheme.warningColor),
                      const SizedBox(width: 6),
                      Text(
                          result.method ??
                              (result.aiGenerated
                                  ? 'AI Generated'
                                  : 'Preview Mode'),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: result.aiGenerated
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primaryColor
                    : Colors.grey,
                borderRadius: BorderRadius.circular(4)),
          );
        }),
      ),
    );
  }

  Widget _buildBottomActions(TryOnState tryOnState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent
            ]),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showRetryGuidance,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Try Again',
                    style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _addSelectedToCart,
                icon: const Icon(Icons.shopping_cart),
                label: Text(
                  _selectedForCart.isNotEmpty
                      ? 'Add ${_selectedForCart.length} to Cart'
                      : 'Add to Cart',
                ),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}