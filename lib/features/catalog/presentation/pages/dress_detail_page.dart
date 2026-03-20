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

  // ─── Standard size measurements for dresses (inches) ─────────────────────
  // Only rows whose size exists in widget.dress.sizes will be shown.
  static const Map<String, Map<String, String>> _sizeChart = {
    'XS': {'Bust': '32', 'Waist': '26', 'Hip': '35', 'Length': '36'},
    'S':  {'Bust': '34', 'Waist': '28', 'Hip': '37', 'Length': '37'},
    'M':  {'Bust': '36', 'Waist': '30', 'Hip': '39', 'Length': '38'},
    'L':  {'Bust': '38', 'Waist': '32', 'Hip': '41', 'Length': '39'},
    'XL': {'Bust': '40', 'Waist': '34', 'Hip': '43', 'Length': '40'},
    'XXL':{'Bust': '42', 'Waist': '36', 'Hip': '45', 'Length': '41'},
  };

  // ─── Sizes ────────────────────────────────────────────────────────────────

  List<DressSize> get _sizes {
    final raw = widget.dress.sizes;
    if (raw.isEmpty) {
      return [
        DressSize(sizeName: 'S',  stockQuantity: 10),
        DressSize(sizeName: 'M',  stockQuantity: 15),
        DressSize(sizeName: 'L',  stockQuantity: 12),
        DressSize(sizeName: 'XL', stockQuantity: 8),
      ];
    }
    return raw;
  }

  DressSize get _sel   => _sizes[_selectedSizeIndex];
  int  get _stock      => _sel.stockQuantity;
  bool get _isLow      => _stock > 0 && _stock < 3;
  bool get _isOOS      => _stock == 0;

  bool _inCart(List items) => items.any((i) =>
      i.dress.dressId == widget.dress.dressId &&
      i.selectedSize  == _sel.sizeName);

  @override
  void initState() {
    super.initState();
    final idx = _sizes.indexWhere((s) => s.stockQuantity > 0);
    if (idx >= 0) _selectedSizeIndex = idx;
  }

  // ─── Size Chart bottom sheet ───────────────────────────────────────────────

  void _showSizeChart() {
    // Only include sizes that are actually in this dress's size list
    final availableSizeNames = _sizes.map((s) => s.sizeName).toSet();
    final chartRows = _sizeChart.entries
        .where((e) => availableSizeNames.contains(e.key))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ─────────────────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),

              // ── Header row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.straighten,
                        color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Size Chart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Dress name ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: const Color(0xFFF8F0FF),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Text(
                  widget.dress.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A148C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // ── Table ──────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        _buildTable(chartRows),
                        const SizedBox(height: 20),
                        _buildMeasurementGuidelines(),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildTable(List<MapEntry<String, Map<String, String>>> rows) {
    const headers = ['Size', 'Bust', 'Waist', 'Hip', 'Length'];
    const cols = ['Bust', 'Waist', 'Hip', 'Length'];

    return Table(
      border: TableBorder.all(color: const Color(0xFFEEEEEE), width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.2),
      },
      children: [
        // ── Header row ───────────────────────────────────────────────────────
        TableRow(
          decoration: const BoxDecoration(
            color: Color(0xFF6C3DEB),
          ),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Text(
              h,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )).toList(),
        ),
        // ── Data rows — only sizes from the database ─────────────────────────
        ...rows.asMap().entries.map((entry) {
          final i      = entry.key;
          final e      = entry.value;
          final isEven = i % 2 == 0;
          // Highlight the currently selected size
          final isSelected = e.key == _sel.sizeName;

          return TableRow(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFEDE7FF)
                  : isEven
                      ? Colors.white
                      : const Color(0xFFFAFAFA),
            ),
            children: [
              // Size name cell
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 6),
                child: Text(
                  e.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              // Measurement cells
              ...cols.map((col) => Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 6),
                child: Text(
                  e.value[col] ?? '-',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFF444444),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              )),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildMeasurementGuidelines() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Measurement Guidelines',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 10),
          _guide('👗', 'Bust',
              'Measure around the fullest part of your chest.'),
          _guide('📏', 'Waist',
              'Measure around the narrowest part of your waist.'),
          _guide('📐', 'Hip',
              'Measure around the fullest part of your hips.'),
          _guide('📍', 'Length',
              'Measured from shoulder to hemline.'),
          const SizedBox(height: 8),
          const Text(
            '* All measurements are in inches.',
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _guide(String emoji, String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartControllerProvider);
    final inCart = _inCart(cartItems);

    return Scaffold(
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
            _image(),
            _priceRow(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _infoChips(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _sizeSection(),
            if (_isLow) _lowStockBanner(),
            if (_isOOS) _oosBanner(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _description(),
            const SizedBox(height: 24),
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
                  style: const TextStyle(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  // ─── 4. Size selector + Size Chart link ───────────────────────────────────

  Widget _sizeSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: "Select Size"  +  "Size Chart ›" ──────────────────
          Row(
            children: [
              const Text(
                'Select Size',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const Spacer(),
              // Size Chart button
              GestureDetector(
                onTap: _showSizeChart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.straighten,
                          size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Size Chart',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 14, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Size chips ────────────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_sizes.length, (i) {
              final s   = _sizes[i];
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
              style: TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
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
                  fontSize: 14, color: Color(0xFF5A5A72), height: 1.6)),
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

  // ─── 7. Cart section ──────────────────────────────────────────────────────

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
          if (!_isOOS && !inCart) ...[
            Row(
              children: [
                const Text('Quantity',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const Spacer(),
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
                _qtyBtn(Icons.add_circle_outline, () {
                  if (_quantity < _stock) setState(() => _quantity++);
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
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