import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/features/cart/presentation/cart_controller.dart';
import 'package:virtual_tryon_app/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/network/api_config.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';

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
  static const Map<String, Map<String, String>> _sizeChart = {
    'XS':  {'Bust': '32', 'Waist': '26', 'Hip': '35', 'Length': '36'},
    'S':   {'Bust': '34', 'Waist': '28', 'Hip': '37', 'Length': '37'},
    'M':   {'Bust': '36', 'Waist': '30', 'Hip': '39', 'Length': '38'},
    'L':   {'Bust': '38', 'Waist': '32', 'Hip': '41', 'Length': '39'},
    'XL':  {'Bust': '40', 'Waist': '34', 'Hip': '43', 'Length': '40'},
    'XXL': {'Bust': '42', 'Waist': '36', 'Hip': '45', 'Length': '41'},
  };

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

  void _openVirtualTryOn() {
    if (_isOOS) return;

    final cat = ref.read(catalogControllerProvider.notifier);
    String gender = cat.selectedGender;
    if (widget.dress.gender == 'women') {
      gender = 'women';
    } else if (widget.dress.gender == 'men') {
      gender = 'men';
    }

    String category = cat.selectedCategory;
    final dressCat = widget.dress.category;
    if (dressCat != null && AppConfig.categories.contains(dressCat)) {
      category = dressCat;
    }

    context.router.push(TryOnRoute(
      initialDress: widget.dress,
      catalogGender: gender,
      catalogCategory: category,
      initialTryOnSize: _sel.sizeName,
    ));
  }

  @override
  void initState() {
    super.initState();
    final idx = _sizes.indexWhere((s) => s.stockQuantity > 0);
    if (idx >= 0) _selectedSizeIndex = idx;
  }

  // ─── Q4 FIX: measurement formatter ───────────────────────────────────────
  String _formatMeasurement(String value, bool isCm) {
    final inches = double.tryParse(value);
    if (inches == null) return value;
    if (!isCm) return '$value"';
    return '${(inches * 2.54).toStringAsFixed(1)}';
  }

  // ─── Size Chart bottom sheet ───────────────────────────────────────────────

  void _showSizeChart() {
    final availableSizeNames = _sizes.map((s) => s.sizeName).toSet();
    final chartRows = _sizeChart.entries
        .where((e) => availableSizeNames.contains(e.key))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool isCm = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
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
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _unitToggleButton(
                                  label: 'IN',
                                  selected: !isCm,
                                  onTap: () =>
                                      setSheetState(() => isCm = false),
                                ),
                                _unitToggleButton(
                                  label: 'CM',
                                  selected: isCm,
                                  onTap: () =>
                                      setSheetState(() => isCm = true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            children: [
                              _buildTable(chartRows, isCm: isCm),
                              const SizedBox(height: 20),
                              _buildMeasurementGuidelines(isCm: isCm),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _unitToggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTable(
    List<MapEntry<String, Map<String, String>>> rows, {
    bool isCm = false,
  }) {
    final unitSuffix = isCm ? ' (cm)' : ' (in)';
    final headers = ['Size', 'Bust$unitSuffix', 'Waist$unitSuffix', 'Hip$unitSuffix', 'Length$unitSuffix'];
    const cols = ['Bust', 'Waist', 'Hip', 'Length'];

    return Table(
      border: TableBorder.all(color: const Color(0xFFEEEEEE), width: 1),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FlexColumnWidth(1.0),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF6C3DEB)),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Text(
              h,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          )).toList(),
        ),
        ...rows.asMap().entries.map((entry) {
          final i         = entry.key;
          final e         = entry.value;
          final isEven    = i % 2 == 0;
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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
              ...cols.map((col) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Text(
                  _formatMeasurement(e.value[col] ?? '-', isCm),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFF444444),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              )),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildMeasurementGuidelines({bool isCm = false}) {
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
          Text(
            isCm
                ? '* All measurements are in centimetres (cm).'
                : '* All measurements are in inches (in). Tap CM to switch.',
            style: const TextStyle(
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

  // ─── Q5 FIX: Custom size request bottom sheet ─────────────────────────────
  // Opens a form with Bust / Waist / Hip TextFields.
  // No backend needed for demo — pressing Submit shows a confirmation snackbar.
  void _showCustomSizeSheet() {
    final bustCtrl  = TextEditingController();
    final waistCtrl = TextEditingController();
    final hipCtrl   = TextEditingController();
    final formKey   = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune,
                              color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Request Custom Size',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Share your measurements — we\'ll contact you',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
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

                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 20),

                    // Dress context chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.checkroom,
                              color: AppTheme.primaryColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.dress.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A148C),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Your measurements (in inches)',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 12),

                    _measurementField(
                      controller: bustCtrl,
                      label: 'Bust',
                      hint: 'e.g. 38',
                      icon: Icons.favorite_border,
                    ),
                    const SizedBox(height: 12),

                    _measurementField(
                      controller: waistCtrl,
                      label: 'Waist',
                      hint: 'e.g. 30',
                      icon: Icons.straighten,
                    ),
                    const SizedBox(height: 12),

                    _measurementField(
                      controller: hipCtrl,
                      label: 'Hip',
                      hint: 'e.g. 40',
                      icon: Icons.accessibility_new,
                    ),

                    const SizedBox(height: 20),

                    // Info note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Our team will reach out within 2 business days with availability and pricing.',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.pop(sheetContext);
                            bustCtrl.dispose();
                            waistCtrl.dispose();
                            hipCtrl.dispose();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Request sent! We\'ll contact you soon.',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.send_outlined, size: 18),
                        label: const Text(
                          'Submit Request',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
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
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      // Safety net — guard against double-dispose if user swiped sheet down
      try { bustCtrl.dispose(); } catch (_) {}
      try { waistCtrl.dispose(); } catch (_) {}
      try { hipCtrl.dispose(); } catch (_) {}
    });
  }

  // Helper: single measurement TextFormField for the custom size sheet
  Widget _measurementField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '$label (inches)',
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please enter your $label measurement';
        }
        final n = double.tryParse(v.trim());
        if (n == null || n <= 0) {
          return 'Enter a valid number in inches';
        }
        return null;
      },
    );
  }
  // ─── End Q5 FIX ──────────────────────────────────────────────────────────

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
          // Header row
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

          // Size chips
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

          // ── Q5 FIX: Request Custom Size button ────────────────────────────
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showCustomSizeSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.tune,
                      size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Request Custom Size',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
          // ── End Q5 FIX ───────────────────────────────────────────────────
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
          if (!_isOOS) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openVirtualTryOn,
                icon: const Icon(Icons.auto_fix_high_outlined,
                    color: AppTheme.primaryColor),
                label: const Text(
                  'Virtual Try-On',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
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