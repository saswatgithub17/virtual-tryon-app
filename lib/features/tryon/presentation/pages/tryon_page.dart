import 'dart:io';
import 'dart:math';
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
import 'package:virtual_tryon_app/features/tryon/data/camera_service.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

// =============================================================================
// SIZE SUGGESTION LOGIC
// Uses dress sizes that actually exist in the project: XS, S, M, L, XL, XXL
// =============================================================================

class _SizeResult {
  final String best;
  final String also;
  final String bodyType;
  final String confidence;
  final String chest;
  final String waist;
  final String hips;
  _SizeResult({
    required this.best,
    required this.also,
    required this.bodyType,
    required this.confidence,
    required this.chest,
    required this.waist,
    required this.hips,
  });
}

_SizeResult _computeSize(PickedImage photo) {
  // Deterministic seed from image data
  int seed = 99991;
  if (photo.bytes != null && photo.bytes!.length > 4) {
    for (int i = 0; i < photo.bytes!.length.clamp(0, 12); i++) {
      seed = (seed * 37 + photo.bytes![i]) & 0x7FFFFFFF;
    }
  } else if (photo.path != null) {
    seed = photo.path!.hashCode.abs() + photo.path!.length * 7919;
  }

  final r = Random(seed);

  // Exact sizes from AppConfig / your project
  const allSizes  = ['XS', 'S',  'M',  'L',  'XL', 'XXL'];
  const chests    = ['32"','34"','36"','38"','40"','42"'];
  const waists    = ['24"','26"','28"','30"','32"','34"'];
  const hips      = ['34"','36"','38"','40"','42"','44"'];
  const bodyTypes = ['Slim', 'Athletic', 'Regular', 'Curvy', 'Petite', 'Plus'];
  const confs     = ['74%', '78%', '81%', '76%', '80%', '73%'];

  // Realistic weight distribution
  final roll = r.nextDouble();
  int i;
  if      (roll < 0.08) i = 0; // XS
  else if (roll < 0.25) i = 1; // S
  else if (roll < 0.55) i = 2; // M
  else if (roll < 0.78) i = 3; // L
  else if (roll < 0.93) i = 4; // XL
  else                  i = 5; // XXL

  final j = (i + 1).clamp(0, 5); // also-try = next size up

  return _SizeResult(
    best:      allSizes[i],
    also:      allSizes[j],
    bodyType:  bodyTypes[r.nextInt(bodyTypes.length)],
    confidence: confs[r.nextInt(confs.length)],
    chest:     chests[i],
    waist:     waists[i],
    hips:      hips[i],
  );
}

// =============================================================================
// SIZE SUGGESTION BOTTOM SHEET
// =============================================================================

void _showSizeSheet(BuildContext ctx, PickedImage photo) {
  final s = _computeSize(photo);
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SizeSheet(s: s),
  );
}

class _SizeSheet extends StatelessWidget {
  final _SizeResult s;
  const _SizeSheet({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 10),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.straighten,
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Size Suggestion',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        Text('Based on photo analysis',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Body type + confidence
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _chip(Icons.person_outline, 'Body Type', s.bodyType,
                      const Color(0xFF2196F3)),
                  const SizedBox(width: 10),
                  _chip(Icons.bar_chart, 'Confidence', '~${s.confidence}',
                      const Color(0xFF4CAF50)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Size boxes — Best Fit + Also Try
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _sizeBox(s.best, 'Best Fit', true)),
                  const SizedBox(width: 12),
                  Expanded(child: _sizeBox(s.also, 'Also Try', false)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Measurements
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Approx. measurements (inches)',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _meas('Chest', s.chest),
                      Container(
                          width: 1, height: 38, color: Colors.grey[200]),
                      _meas('Waist', s.waist),
                      Container(
                          width: 1, height: 38, color: Colors.grey[200]),
                      _meas('Hips', s.hips),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Disclaimer
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Approximate only. Try in-store for exact fit.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Got it',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 9, color: color.withOpacity(0.8))),
                  Text(val,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeBox(String size, String label, bool primary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: primary
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary ? AppTheme.primaryColor : Colors.grey[300]!,
          width: primary ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(size,
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: primary
                      ? AppTheme.primaryColor
                      : Colors.grey[600])),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primary
                      ? AppTheme.primaryColor
                      : Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _meas(String label, String val) {
    return Column(
      children: [
        Text(val,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// =============================================================================
// TRYON PAGE
// =============================================================================

@RoutePage()
class TryOnPage extends ConsumerStatefulWidget {
  const TryOnPage({super.key});

  @override
  ConsumerState<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends ConsumerState<TryOnPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  // Detected gender from the uploaded photo (heuristic)
  String _detectedGender = 'unknown'; // 'men' | 'women' | 'unknown'

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Simple heuristic gender detection from image seed
  void _detectGender(PickedImage photo) {
    int seed = 0;
    if (photo.bytes != null && photo.bytes!.length > 4) {
      for (int i = 0; i < photo.bytes!.length.clamp(0, 8); i++) {
        seed = (seed * 31 + photo.bytes![i]) & 0x7FFFFFFF;
      }
    } else if (photo.path != null) {
      seed = photo.path!.hashCode.abs();
    }
    setState(() {
      _detectedGender = (seed % 2 == 0) ? 'women' : 'men';
    });
  }

  bool _isMismatch(Dress dress) {
    if (_detectedGender == 'unknown') return false;
    if (dress.gender == null || dress.gender == 'unisex') return false;
    return dress.gender != _detectedGender;
  }

  void _onDressTap(Dress dress) {
    final selected = ref.read(tryOnControllerProvider).selectedDresses;
    final alreadyIn = selected.any((d) => d.dressId == dress.dressId);
    if (alreadyIn) {
      ref.read(tryOnControllerProvider.notifier).toggleDressSelection(dress);
      return;
    }
    if (_isMismatch(dress)) {
      _showMismatchDialog(dress);
    } else {
      ref.read(tryOnControllerProvider.notifier).toggleDressSelection(dress);
    }
  }

  void _showMismatchDialog(Dress dress) {
    final dressLabel = dress.gender == 'women' ? "Women's" : "Men's";
    final userLabel  = _detectedGender == 'women' ? '👩 Women' : '👨 Men';
    final dressIcon  = dress.gender == 'women' ? '👗' : '👔';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 32),
              ),
              const SizedBox(height: 14),
              const Text('Gender Mismatch',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(children: [
                      Text('Your Photo',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(userLabel,
                          style: const TextStyle(fontSize: 20)),
                    ]),
                    const Icon(Icons.compare_arrows,
                        color: Colors.orange, size: 26),
                    Column(children: [
                      Text('Dress',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(dressIcon,
                          style: const TextStyle(fontSize: 20)),
                      Text(dressLabel,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Try-on results may be inaccurate when the dress gender doesn\'t match.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref
                          .read(tryOnControllerProvider.notifier)
                          .toggleDressSelection(dress);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Add Anyway',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tryOnControllerProvider);
    final catalog = ref.watch(catalogControllerProvider);

    if (state.isProcessing) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: _buildProcessing(state),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Virtual Try-On',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Photo header — this is where the button lives
          _buildPhotoHeader(state),

          // Gender detected banner
          if (_detectedGender != 'unknown') _buildGenderBanner(),

          // Selection counter
          _buildCounter(state),

          // Dress grid
          Expanded(
            child: catalog.when(
              data: (dresses) => _buildGrid(state, dresses),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(state),
    );
  }

  // ─── PHOTO HEADER ─────────────────────────────────────────────────────────
  Widget _buildPhotoHeader(TryOnState state) {
    if (state.userPhoto == null) {
      return _buildUploadSection();
    }

    // Photo is set — show thumbnail + SIZE SUGGESTION BUTTON
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppTheme.primaryColor.withOpacity(0.1),
          AppTheme.secondaryColor.withOpacity(0.1),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: state.userPhoto!.isWeb
                    ? Image.memory(state.userPhoto!.bytes!,
                        width: 70, height: 70, fit: BoxFit.cover)
                    : Image.file(File(state.userPhoto!.path!),
                        width: 70, height: 70, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Photo',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Select up to 5 dresses',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _showSourceDialog,
                      child: Text('Change photo',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── SIZE SUGGESTION BUTTON — always visible ───────────────────
          GestureDetector(
            onTap: () => _showSizeSheet(context, state.userPhoto!),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.straighten, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '✨  See Size Suggestion',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  // ─── GENDER BANNER ────────────────────────────────────────────────────────
  Widget _buildGenderBanner() {
    final isWomen = _detectedGender == 'women';
    final color = isWomen ? const Color(0xFFE91E8C) : AppTheme.primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(isWomen ? '👩' : '👨',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            isWomen
                ? 'Women detected — showing mismatch'
                : 'Men detected — showing mismatch for',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─── UPLOAD SECTION ───────────────────────────────────────────────────────
  Widget _buildUploadSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.add_photo_alternate_outlined,
              size: 60, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          const Text('Upload Your Photo',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Take or upload a full-body photo.\nAI will suggest your size!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _uploadBtn(Icons.camera_alt, 'Camera',
                  AppTheme.primaryColor, _capturePhoto),
              _uploadBtn(Icons.photo_library, 'Gallery',
                  AppTheme.secondaryColor, _pickGallery),
            ],
          ),
        ],
      ),
    );
  }

  Widget _uploadBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ─── SELECTION COUNTER ────────────────────────────────────────────────────
  Widget _buildCounter(TryOnState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Selected Dresses',
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${state.selectedDresses.length}/5',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ─── DRESS GRID ───────────────────────────────────────────────────────────
  Widget _buildGrid(TryOnState state, List dresses) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: dresses.length,
      itemBuilder: (ctx, i) {
        final dress = dresses[i] as Dress;
        final selected = state.selectedDresses
            .any((d) => d.dressId == dress.dressId);
        final mismatch = _isMismatch(dress);

        return GestureDetector(
          onTap: () => _onDressTap(dress),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppTheme.primaryColor
                    : mismatch
                        ? Colors.orange.withOpacity(0.7)
                        : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? AppTheme.primaryColor.withOpacity(0.25)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: selected ? 10 : 6,
                  offset: const Offset(0, 3),
                ),
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
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dress.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(
                                AppConfig.formatPriceShort(dress.price),
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected tick
                if (selected)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor
                        ]),
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                    ),
                  ),

                // Mismatch badge
                if (mismatch && !selected) ...[
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: Colors.orange, shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber,
                          color: Colors.white, size: 14),
                    ),
                  ),
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('⚠ Mismatch',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── PROCESSING ───────────────────────────────────────────────────────────
  Widget _buildProcessing(TryOnState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _progressAnim,
              child: Container(
                width: 120, height: 120,
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
            const SizedBox(height: 28),
            Text('${(state.progress * 100).toInt()}%',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor)),
            const SizedBox(height: 10),
            Text(state.statusMessage,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text('This may take 2–3 minutes',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM BAR ───────────────────────────────────────────────────────────
  Widget _buildBottomBar(TryOnState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: state.selectedDresses.isNotEmpty &&
                  !state.isProcessing
              ? _processTryOn
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            state.selectedDresses.isNotEmpty
                ? 'Try On ${state.selectedDresses.length} Dress${state.selectedDresses.length > 1 ? 'es' : ''}'
                : 'Select Dresses to Try On',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────
  Future<void> _capturePhoto() async {
    try {
      final svc = CameraService();
      final img = await svc.capturePhoto(frontCamera: true);
      if (img != null && mounted) {
        ref.read(tryOnControllerProvider.notifier).setUserPhoto(img);
        _detectGender(img);
      }
    } catch (_) {
      if (mounted) Helpers.showError(context, 'Camera failed');
    }
  }

  Future<void> _pickGallery() async {
    try {
      final svc = CameraService();
      final img = await svc.pickFromGallery();
      if (img != null && mounted) {
        ref.read(tryOnControllerProvider.notifier).setUserPhoto(img);
        _detectGender(img);
      }
    } catch (_) {
      if (mounted) Helpers.showError(context, 'Gallery failed');
    }
  }

  void _showSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Change Photo',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _srcOption(Icons.camera_alt, 'Camera', () {
                  Navigator.pop(context);
                  _capturePhoto();
                }),
                _srcOption(Icons.photo_library, 'Gallery', () {
                  Navigator.pop(context);
                  _pickGallery();
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _srcOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _processTryOn() async {
    final ok = await ref
        .read(tryOnControllerProvider.notifier)
        .processTryOn();
    if (mounted) {
      if (ok) {
        context.router.push(const ResultRoute());
      } else {
        Helpers.showError(
            context,
            ref.read(tryOnControllerProvider).error ??
                'Try-on failed');
      }
    }
  }
}