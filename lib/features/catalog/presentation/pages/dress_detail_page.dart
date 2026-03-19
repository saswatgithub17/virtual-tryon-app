import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

@RoutePage()
class DressDetailPage extends ConsumerStatefulWidget {
  final Dress dress;
  const DressDetailPage({super.key, required this.dress});

  @override
  ConsumerState<DressDetailPage> createState() => _DressDetailPageState();
}

class _DressDetailPageState extends ConsumerState<DressDetailPage> {
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _descExpanded = false;

  // ─── Sizes ────────────────────────────────────────────────────────────────

  List<DressSize> get _sizes {
    final raw = widget.dress.sizes;
    if (raw.isEmpty) {
      return [
        DressSize(sizeName: 'S', stockQuantity: 10),
        DressSize(sizeName: 'M', stockQuantity: 15),
        DressSize(sizeName: 'L', stockQuantity: 12),
        DressSize(sizeName: 'XL', stockQuantity: 8),
      ];
    }
    return raw;
  }

  DressSize get _sel => _sizes[_selectedSizeIndex];
  int get _stock => _sel.stockQuantity;
  bool get _isLow => _stock > 0 && _stock < 3;
  bool get _isOOS => _stock == 0;

  bool _inCart(List items) => items.any((i) =>
      i.dress.dressId == widget.dress.dressId &&
      i.selectedSize == _sel.sizeName);

  @override
  void initState() {
    super.initState();
    final idx = _sizes.indexWhere((s) => s.stockQuantity > 0);
    if (idx >= 0) _selectedSizeIndex = idx;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final inCart = _inCart(cartItems);

    return Scaffold(
      // ── FIX: No bottomNavigationBar — the button lives INSIDE the
      // SingleChildScrollView so it is ALWAYS visible and can NEVER
      // expand to fill the screen (which caused the blank white screen bug).
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.pop(),
        ),
        title: Text(
          widget.dress.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Image ────────────────────────────────────────────────────
            _image(),

            // ── 2. Price + Rating ────────────────────────────────────────────
            _priceRow(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── 3. Info chips ────────────────────────────────────────────────
            _infoChips(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── 4. Size selector ────────────────────────────────────────────
            _sizeSection(),

            // ── 5. Low stock warning ─────────────────────────────────────────
            if (_isLow) _lowStockBanner(),
            if (_isOOS) _oosBanner(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // ── 6. Description ───────────────────────────────────────────────
            _description(),
            const SizedBox(height: 24),

            // ── 7. Quantity + CTA — INSIDE scroll, always visible ────────────
            _cartSection(inCart),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── 1. Image ─────────────────────────────────────────────────────────────

  Widget _image() {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: CachedNetworkImage(
        imageUrl: ApiConfig.getUploadUrl(widget.dress.imageUrl),
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 300,
          color: const Color(0xFFEEEEEE),
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 300,
          color: const Color(0xFFEEEEEE),
          child: const Icon(Icons.image_not_supported,
              size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  // ─── 2. Price + Rating ────────────────────────────────────────────────────

  Widget _priceRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${widget.dress.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Text(
                  'Inclusive of all taxes',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if ((widget.dress.averageRating ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.dress.averageRating!.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── 3. Info chips ────────────────────────────────────────────────────────

  Widget _infoChips() {
    final infos = <MapEntry<String, String>>[];
    if (widget.dress.brand != null)
      infos.add(MapEntry('Brand', widget.dress.brand!));
    if (widget.dress.color != null)
      infos.add(MapEntry('Color', widget.dress.color!));
    if (widget.dress.material != null)
      infos.add(MapEntry('Material', widget.dress.material!));

    if (infos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: infos
            .map((e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepPurple.shade100),
                  ),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A148C)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── 4. Size selector ─────────────────────────────────────────────────────

  Widget _sizeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Size',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_sizes.length, (i) {
              final s = _sizes[i];
              final sel = _selectedSizeIndex == i;
              final oos = s.stockQuantity == 0;
              final low = s.stockQuantity > 0 && s.stockQuantity < 3;

              return GestureDetector(
                onTap: oos
                    ? null
                    : () => setState(() {
                          _selectedSizeIndex = i;
                          _quantity = 1;
                        }),
                child: Container(
                  width: 68,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: oos
                        ? Colors.grey[100]
                        : sel
                            ? AppTheme.primaryColor
                            : low
                                ? const Color(0xFFFFF0F0)
                                : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: sel ? 2 : 1,
                      color: oos
                          ? Colors.grey[300]!
                          : sel
                              ? AppTheme.primaryColor
                              : low
                                  ? Colors.red
                                  : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.sizeName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: oos
                              ? Colors.grey[400]
                              : sel
                                  ? Colors.white
                                  : Colors.black87,
                          decoration:
                              oos ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        oos
                            ? 'OOS'
                            : low
                                ? '${s.stockQuantity} left'
                                : '${s.stockQuantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: oos
                              ? Colors.grey[400]
                              : sel
                                  ? Colors.white70
                                  : low
                                      ? Colors.red
                                      : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── 5. Banners ───────────────────────────────────────────────────────────

  Widget _lowStockBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Only $_stock left in size ${_sel.sizeName}! Order now!',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _oosBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey, size: 18),
          SizedBox(width: 8),
          Text('Out of stock in this size. Pick another.',
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ─── 6. Description ───────────────────────────────────────────────────────

  Widget _description() {
    final desc = widget.dress.description ?? 'No description available.';
    final isLong = desc.length > 150;
    final text =
        isLong && !_descExpanded ? '${desc.substring(0, 150)}…' : desc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Description',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A5A72),
                  height: 1.6)),
          if (isLong)
            GestureDetector(
              onTap: () =>
                  setState(() => _descExpanded = !_descExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _descExpanded ? 'Read less ▲' : 'Read more ▼',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── 7. Quantity + Cart button — inside scroll, no bottomNavigationBar ─────
  // This is the KEY FIX. By putting the cart button here instead of in
  // bottomNavigationBar, it can never expand to fill the screen.

  Widget _cartSection(bool inCart) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity row — only shown before adding to cart
          if (!_isOOS && !inCart) ...[
            Row(
              children: [
                const Text('Quantity',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const Spacer(),
                // − stepper
                _qtyBtn(Icons.remove_circle_outline, () {
                  if (_quantity > 1) setState(() => _quantity--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '$_quantity',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // + stepper
                _qtyBtn(Icons.add_circle_outline, () {
                  if (_quantity < _stock) setState(() => _quantity++);
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // CTA button — full width
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _isOOS
                ? ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Out of Stock',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  )
                : inCart
                    ? ElevatedButton.icon(
                        onPressed: () =>
                            context.router.push(const CartRoute()),
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Go to Cart',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .addToCart(
                                widget.dress,
                                quantity: _quantity,
                                size: _sel.sizeName,
                              );
                        },
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text('Add to Cart',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: AppTheme.primaryColor, size: 28),
      );
}