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

class _DressDetailPageState extends ConsumerState<DressDetailPage>
    with SingleTickerProviderStateMixin {
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _descExpanded = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  // ─── Size helpers ─────────────────────────────────────────────────────────

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

  DressSize get _selectedSize => _sizes[_selectedSizeIndex];
  int get _stock => _selectedSize.stockQuantity;
  bool get _isLowStock => _stock > 0 && _stock < 3;
  bool get _isOOS => _stock == 0;

  bool _isInCart(List cartItems) => cartItems.any((item) =>
      item.dress.dressId == widget.dress.dressId &&
      item.selectedSize == _selectedSize.sizeName);

  String _stockLabel(DressSize s) {
    final q = s.stockQuantity;
    if (q == 0) return 'OOS';
    if (q < 3) return '$q left!';
    return '$q';
  }

  @override
  void initState() {
    super.initState();
    final firstInStock = _sizes.indexWhere((s) => s.stockQuantity > 0);
    if (firstInStock >= 0) _selectedSizeIndex = firstInStock;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final inCart = _isInCart(cartItems);

    return Scaffold(
      backgroundColor: Colors.white,
      // ── Regular AppBar: always visible, no SliverAppBar complexity ──────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.router.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E), size: 20),
          ),
        ),
      ),
      // ── Body: SingleChildScrollView — ALL content immediately visible ───────
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),        // dress photo
            _buildNamePriceSection(),    // name + price + rating
            _buildDivider(),
            _buildInfoChips(),           // brand / color / material
            _buildDivider(),
            _buildSizeSection(),         // size chips with stock counts
            if (_isLowStock) _buildUrgencyBanner(),
            if (_isOOS) _buildOOSBanner(),
            _buildDivider(),
            _buildDescription(),
            const SizedBox(height: 120), // breathing room above bottom bar
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(inCart),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F2));

  // ─── Dress Image ──────────────────────────────────────────────────────────
  // Fixed height — content is immediately visible below it without scrolling.

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Image — 280px keeps it prominent but leaves room for content
        SizedBox(
          width: double.infinity,
          height: 280,
          child: CachedNetworkImage(
            imageUrl: ApiConfig.getUploadUrl(widget.dress.imageUrl),
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[100],
              child: Icon(Icons.image_not_supported,
                  color: Colors.grey[400], size: 64),
            ),
          ),
        ),
        // Gradient overlay at the bottom for the category badge
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
                colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
              ),
            ),
          ),
        ),
        // Category + Gender badges
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: Row(
            children: [
              if (widget.dress.category != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.dress.category!.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                ),
              const SizedBox(width: 8),
              if (widget.dress.gender != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.dress.gender == 'women'
                        ? const Color(0xFFE91E8C).withOpacity(0.88)
                        : AppTheme.primaryColor.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.dress.gender == 'women' ? '👗 Women' : '👔 Men',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Name + Price + Rating ────────────────────────────────────────────────

  Widget _buildNamePriceSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dress name
          Text(
            widget.dress.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price with gradient shader
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ).createShader(bounds),
                child: Text(
                  '₹${widget.dress.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // masked by shader
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'incl. taxes',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const Spacer(),
              // Rating badge
              if ((widget.dress.averageRating ?? 0) > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFFA000), Color(0xFFFFD54F)]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star,
                              color: Colors.white, size: 14),
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
                    const SizedBox(height: 2),
                    Text(
                      '${widget.dress.totalReviews ?? 0} reviews',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Info Chips (Brand / Color / Material) ────────────────────────────────

  Widget _buildInfoChips() {
    final infos = <MapEntry<String, String>>[
      if (widget.dress.brand != null)
        MapEntry('Brand', widget.dress.brand!),
      if (widget.dress.color != null)
        MapEntry('Color', widget.dress.color!),
      if (widget.dress.material != null)
        MapEntry('Material', widget.dress.material!),
    ];
    if (infos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: infos
            .map((e) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.25)),
                  ),
                  child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: '${e.key}: ',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontFamily: 'Inter'),
                      ),
                      TextSpan(
                        text: e.value,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A148C),
                            fontFamily: 'Inter'),
                      ),
                    ]),
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ─── Size Selector with stock counts ─────────────────────────────────────

  Widget _buildSizeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Select Size',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (!_isOOS) _stockPill(),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_sizes.length, (i) {
              final s = _sizes[i];
              final isSelected = _selectedSizeIndex == i;
              final isOos = s.stockQuantity == 0;
              final isLow = s.stockQuantity > 0 && s.stockQuantity < 3;

              return GestureDetector(
                onTap: isOos
                    ? null
                    : () => setState(() {
                          _selectedSizeIndex = i;
                          _quantity = 1;
                        }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: isOos
                        ? Colors.grey[50]
                        : isSelected
                            ? AppTheme.primaryColor
                            : isLow
                                ? const Color(0xFFFFF3F3)
                                : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: isSelected ? 2 : 1.5,
                      color: isOos
                          ? Colors.grey[200]!
                          : isSelected
                              ? AppTheme.primaryColor
                              : isLow
                                  ? const Color(0xFFFF4444)
                                  : Colors.grey[300]!,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color:
                                    AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.sizeName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isOos
                              ? Colors.grey[400]
                              : isSelected
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                          decoration: isOos
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _stockLabel(s),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isOos
                              ? Colors.grey[400]
                              : isSelected
                                  ? Colors.white70
                                  : isLow
                                      ? const Color(0xFFFF4444)
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

  Widget _stockPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _isLowStock
            ? const Color(0xFFFFF3F3)
            : const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isLowStock ? const Color(0xFFFF4444) : Colors.green,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isLowStock
                ? Icons.local_fire_department
                : Icons.inventory_2_outlined,
            size: 12,
            color: _isLowStock ? const Color(0xFFFF4444) : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            '$_stock in stock',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  _isLowStock ? const Color(0xFFFF4444) : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Urgency Banner ───────────────────────────────────────────────────────

  Widget _buildUrgencyBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: ScaleTransition(
        scale: _pulse,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.red.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Only $_stock left in size ${_selectedSize.sizeName}!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'This size is selling fast — order now!',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOOSBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey, size: 18),
            SizedBox(width: 10),
            Text(
              'Out of stock in this size. Pick another.',
              style: TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Description ──────────────────────────────────────────────────────────

  Widget _buildDescription() {
    final desc = widget.dress.description ?? 'No description available.';
    final isLong = desc.length > 130;
    final preview =
        isLong && !_descExpanded ? '${desc.substring(0, 130)}…' : desc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 10),
          Text(
            preview,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF5A5A72), height: 1.65),
          ),
          if (isLong)
            GestureDetector(
              onTap: () =>
                  setState(() => _descExpanded = !_descExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _descExpanded ? 'Read less ▲' : 'Read more ▼',
                  style: const TextStyle(
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

  // ─── Bottom Bar (counter + CTA) ───────────────────────────────────────────

  Widget _buildBottomBar(bool inCart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!_isOOS && !inCart) ...[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _qtyBtn(Icons.remove,
                        () { if (_quantity > 1) setState(() => _quantity--); }),
                    SizedBox(
                      width: 36,
                      child: Center(
                        child: Text('$_quantity',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A2E))),
                      ),
                    ),
                    _qtyBtn(Icons.add,
                        () { if (_quantity < _stock) setState(() => _quantity++); }),
                  ],
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: SizedBox(
                height: 54,
                child: _isOOS
                    ? _disabledBtn()
                    : inCart
                        ? _goToCartBtn()
                        : _addToCartBtn(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 18, color: AppTheme.primaryColor),
        ),
      );

  Widget _addToCartBtn() => ElevatedButton.icon(
        onPressed: _addToCart,
        icon: const Icon(Icons.shopping_cart_outlined),
        label: const Text('Add to Cart',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      );

  Widget _goToCartBtn() => ElevatedButton.icon(
        onPressed: () => context.router.push(const CartRoute()),
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Go to Cart',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      );

  Widget _disabledBtn() => ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Out of Stock',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
      );

  void _addToCart() {
    ref.read(cartControllerProvider.notifier).addToCart(
          widget.dress,
          quantity: _quantity,
          size: _selectedSize.sizeName,
        );
    // Button auto-switches to "Go to Cart" via ref.watch
  }
}