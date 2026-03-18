import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/controllers/tryon_controller.dart';
import 'package:virtual_tryon_app/features/tryon/data/camera_service.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';

@RoutePage()
class DressDetailPage extends ConsumerStatefulWidget {
  final Dress dress;

  const DressDetailPage({
    super.key,
    required this.dress,
  });

  @override
  ConsumerState<DressDetailPage> createState() => _DressDetailPageState();
}

class _DressDetailPageState extends ConsumerState<DressDetailPage> {
  int _selectedSize = 1; // Default to 'S'
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL'];
  int _quantity = 1;

  // ─── Check whether current dress + size combo is already in cart ──────────
  bool _isInCart(List cartItems) {
    return cartItems.any((item) =>
        item.dress.dressId == widget.dress.dressId &&
        item.selectedSize == _sizes[_selectedSize]);
  }

  @override
  Widget build(BuildContext context) {
    // Watch cart so button updates reactively when size changes or cart is modified
    final cartItems = ref.watch(cartControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.router.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'dress_${widget.dress.dressId}',
                child: CachedNetworkImage(
                  imageUrl: ApiConfig.getUploadUrl(widget.dress.imageUrl),
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.dress.name,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(widget.dress.category ?? 'Dress',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor
                          ]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            '₹${widget.dress.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Size',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sizes.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedSize == index;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedSize = index),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 60,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(_sizes[index],
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Quantity',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_quantity > 1)
                              setState(() => _quantity--);
                          }),
                      Text(_quantity.toString(),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              setState(() => _quantity++)),
                    ],
                  ),
                  if (widget.dress.brand != null) ...[
                    const SizedBox(height: 24),
                    const Text('Brand',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(widget.dress.brand!,
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey[700])),
                  ],
                  if (widget.dress.color != null) ...[
                    const SizedBox(height: 24),
                    const Text('Color',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(widget.dress.color!,
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey[700])),
                  ],
                  if (widget.dress.material != null) ...[
                    const SizedBox(height: 24),
                    const Text('Material',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(widget.dress.material!,
                        style: TextStyle(
                            fontSize: 15, color: Colors.grey[700])),
                  ],
                  if (widget.dress.averageRating != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('Rating',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        ...List.generate(5, (index) {
                          final rating = widget.dress.averageRating!;
                          return Icon(
                            index < rating.floor()
                                ? Icons.star
                                : (index < rating
                                    ? Icons.star_half
                                    : Icons.star_border),
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '(${widget.dress.totalReviews ?? 0} reviews)',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('Description',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                      widget.dress.description ??
                          'No description available.',
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[700])),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Try-on buttons row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _startTryOn,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _uploadImageForTryOn,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.primaryColor.withOpacity(0.8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ─── Add to Cart / Go to Cart button ────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: _isInCart(cartItems)
                    ? ElevatedButton.icon(
                        onPressed: () =>
                            context.router.push(const CartRoute()),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Go to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _addToCart,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart() {
    ref.read(cartControllerProvider.notifier).addToCart(
          widget.dress,
          quantity: _quantity,
          size: _sizes[_selectedSize],
        );
    // No snackbar here — button visually changes to "Go to Cart"
    // which is a clearer signal than a transient toast
  }

  void _startTryOn() {
    ref.read(tryOnControllerProvider.notifier).clearSelection();
    ref
        .read(tryOnControllerProvider.notifier)
        .toggleDressSelection(widget.dress);
    context.router.push(CameraRoute(dress: widget.dress));
  }

  Future<void> _uploadImageForTryOn() async {
    try {
      final cameraService = CameraService();
      final PickedImage? image = await cameraService.pickFromGallery();

      if (image != null && mounted) {
        final error = await cameraService.validateImage(image);
        if (error != null) {
          if (mounted) Helpers.showError(context, error);
          return;
        }

        ref.read(tryOnControllerProvider.notifier).clearSelection();
        ref
            .read(tryOnControllerProvider.notifier)
            .toggleDressSelection(widget.dress);
        ref.read(tryOnControllerProvider.notifier).setUserPhoto(image);

        if (mounted) {
          context.router.push(const TryOnRoute());
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to upload image');
      }
    }
  }
}