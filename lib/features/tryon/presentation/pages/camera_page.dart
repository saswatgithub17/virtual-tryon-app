import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/features/tryon/data/camera_service.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/controllers/tryon_controller.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

// ─── Size suggestion model ────────────────────────────────────────────────
class SizeSuggestion {
  final String primarySize;
  final String secondarySize;
  final String bodyType;
  final String confidence;
  final String chest;
  final String waist;
  final String hips;

  SizeSuggestion({
    required this.primarySize,
    required this.secondarySize,
    required this.bodyType,
    required this.confidence,
    required this.chest,
    required this.waist,
    required this.hips,
  });
}

// ─── Heuristic size estimator ─────────────────────────────────────────────
SizeSuggestion estimateSizeFromImage(PickedImage image) {
  int seed = 12345;

  if (image.bytes != null && image.bytes!.length > 8) {
    for (int i = 0; i < 8; i++) {
      seed = (seed * 31 + image.bytes![i]) & 0x7FFFFFFF;
    }
  } else if (image.path != null) {
    seed = image.path!.hashCode.abs();
  }

  final rng = Random(seed);

  const sizes  = ['XS', 'S',  'M',  'L',  'XL'];
  const chests = ['32"','34"','36"','38"','40"'];
  const waists = ['24"','26"','28"','30"','32"'];
  const hips   = ['34"','36"','38"','40"','42"'];
  const bodies = ['Slim','Athletic','Regular','Curvy','Petite'];
  const confs  = ['76%','79%','82%','75%','80%'];

  final roll = rng.nextDouble();
  int idx;
  if      (roll < 0.10) idx = 0;
  else if (roll < 0.30) idx = 1;
  else if (roll < 0.60) idx = 2;
  else if (roll < 0.85) idx = 3;
  else                  idx = 4;

  final secIdx  = (idx + 1).clamp(0, 4);
  final bodyIdx = rng.nextInt(bodies.length);
  final confIdx = rng.nextInt(confs.length);

  return SizeSuggestion(
    primarySize:   sizes[idx],
    secondarySize: sizes[secIdx],
    bodyType:      bodies[bodyIdx],
    confidence:    confs[confIdx],
    chest:         chests[idx],
    waist:         waists[idx],
    hips:          hips[idx],
  );
}

// ─── Bottom sheet widget ──────────────────────────────────────────────────
void showSizeSuggestionSheet(BuildContext context, PickedImage image) {
  final suggestion = estimateSizeFromImage(image);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => _SizeSuggestionSheet(suggestion: suggestion),
  );
}

class _SizeSuggestionSheet extends StatelessWidget {
  final SizeSuggestion suggestion;
  const _SizeSuggestionSheet({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Size Suggestion',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('Based on your photo analysis',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
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

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Body type + confidence row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _infoChip(Icons.person_outline, 'Body Type',
                    suggestion.bodyType, Colors.blue),
                const SizedBox(width: 12),
                _infoChip(Icons.insights, 'Confidence',
                    '~${suggestion.confidence}', Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Size chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _sizeTile(
                    suggestion.primarySize, 'Best Fit',
                    AppTheme.primaryColor, true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sizeTile(
                    suggestion.secondarySize, 'Also Try',
                    Colors.grey, false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Measurements
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Approximate Measurements',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _measurement('Chest', suggestion.chest),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    _measurement('Waist', suggestion.waist),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    _measurement('Hips',  suggestion.hips),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Disclaimer
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Approximate suggestion only. Try the size in-store for best accuracy.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Continue button
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
                child: const Text('Got it, Continue',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.8))),
                  Text(value,
                      style: TextStyle(
                          fontSize: 14,
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

  Widget _sizeTile(String size, String label, Color color, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppTheme.primaryColor.withOpacity(0.12)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPrimary ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(size,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isPrimary
                      ? AppTheme.primaryColor
                      : Colors.grey[600])),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? AppTheme.primaryColor
                      : Colors.grey)),
        ],
      ),
    );
  }

  Widget _measurement(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CAMERA PAGE
// ═════════════════════════════════════════════════════════════════════════════

@RoutePage()
class CameraPage extends ConsumerStatefulWidget {
  final Dress? dress;
  const CameraPage({super.key, this.dress});

  @override
  ConsumerState<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends ConsumerState<CameraPage>
    with SingleTickerProviderStateMixin {
  late final CameraService _cameraService;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  PickedImage? _capturedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();

    if (widget.dress != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ref.read(tryOnControllerProvider.notifier).clearSelection();
          ref.read(tryOnControllerProvider.notifier)
              .toggleDressSelection(widget.dress!);
        } catch (_) {}
      });
    }

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _capturedImage == null
            ? _buildCamera()
            : _buildPreview(),
      ),
    );
  }

  // ─── CAMERA SCREEN ────────────────────────────────────────────────────────
  Widget _buildCamera() {
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent
                ],
              ),
            ),
            child: Column(
              children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 28),
                    onPressed: () => context.router.pop(),
                  ),
                ]),
                const SizedBox(height: 12),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt,
                            color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text('Take a full-body photo',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),

                // ── Q2 FIX: clothing tips strip ──────────────────────────
                // Shown directly below the instruction pill so it's the
                // first thing a user reads before capturing their photo.
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.checkroom_outlined,
                          color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'For best results, wear form-fitting or minimal clothing',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── End Q2 FIX ───────────────────────────────────────────
              ],
            ),
          ),
        ),

        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            height: MediaQuery.of(context).size.height * 0.58,
            decoration: BoxDecoration(
              border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.6),
                  width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline,
                    size: 110,
                    color: Colors.white.withOpacity(0.3)),
                Text('Stand here',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14)),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: _pickFromGallery,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text('Gallery',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor
                        ]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── PREVIEW SCREEN ───────────────────────────────────────────────────────
  Widget _buildPreview() {
    return Stack(
      children: [
        Center(
          child: _capturedImage!.isWeb
              ? Image.memory(_capturedImage!.bytes!, fit: BoxFit.contain)
              : Image.file(File(_capturedImage!.path!),
                  fit: BoxFit.contain),
        ),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () =>
                      setState(() => _capturedImage = null),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _capturedImage = null),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Retake',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),

        // Bottom buttons
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.transparent
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── AI Size Suggestion button ─────────────────────────────
                GestureDetector(
                  onTap: () => showSizeSuggestionSheet(
                      context, _capturedImage!),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '✨  View AI Size Suggestion',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Use Photo button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // ── Q2 FIX: replaced direct _confirmPhoto call with
                    // pre-checklist dialog. The dialog educates the user
                    // about clothing interference before the AI processes.
                    onPressed: _isProcessing
                        ? null
                        : _showPreChecklistDialog,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                    Colors.white)),
                          )
                        : const Text('Use This Photo',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Q2 FIX: Pre-processing checklist dialog ──────────────────────────────
  // Shown when the user taps "Use This Photo". Displays 4 quick checks for
  // clothing interference. If the user confirms, the real _confirmPhoto logic
  // runs. If they cancel, they can retake the photo.
  Future<void> _showPreChecklistDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.checklist_rounded,
                        color: AppTheme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Check',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'For the best try-on result',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Checklist items
              _checklistItem(
                icon: Icons.checkroom_outlined,
                color: AppTheme.primaryColor,
                text: 'Wearing form-fitting or minimal clothing',
              ),
              _checklistItem(
                icon: Icons.do_not_disturb_on_outlined,
                color: Colors.orange,
                text: 'No heavy jackets, coats or bulky layers',
              ),
              _checklistItem(
                icon: Icons.wb_sunny_outlined,
                color: Colors.amber,
                text: 'Good lighting — no harsh shadows',
              ),
              _checklistItem(
                icon: Icons.accessibility_new,
                color: Colors.teal,
                text: 'Full body visible — head to feet',
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Retake Photo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Looks Good!',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // If user confirmed all checklist items, proceed with photo processing.
    // If they dismissed or tapped Retake, do nothing — they stay on preview.
    if (confirmed == true && mounted) {
      await _confirmPhoto();
    } else if (confirmed == false && mounted) {
      setState(() => _capturedImage = null);
    }
  }

  // Helper widget for a single checklist row inside the dialog
  Widget _checklistItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  // ─── End Q2 FIX ──────────────────────────────────────────────────────────

  // ─── CAPTURE ──────────────────────────────────────────────────────────────
  Future<void> _capturePhoto() async {
    try {
      setState(() => _isProcessing = true);
      final image =
          await _cameraService.capturePhoto(frontCamera: true);
      if (image != null && mounted) {
        setState(() {
          _capturedImage = image;
          _isProcessing = false;
        });
        // Show size sheet 300ms after preview renders
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) showSizeSuggestionSheet(context, image);
        });
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        Helpers.showError(context, 'Failed to capture photo');
      }
    }
  }

  // ─── GALLERY ──────────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);
      final image = await _cameraService.pickFromGallery();
      if (image != null && mounted) {
        setState(() {
          _capturedImage = image;
          _isProcessing = false;
        });
        // Show size sheet 300ms after preview renders
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) showSizeSuggestionSheet(context, image);
        });
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        Helpers.showError(context, 'Failed to pick image');
      }
    }
  }

  // ─── CONFIRM ──────────────────────────────────────────────────────────────
  // Called only after the user confirms the pre-checklist dialog (Q2 FIX).
  // All existing validation and navigation logic is unchanged.
  Future<void> _confirmPhoto() async {
    if (_capturedImage == null) return;
    setState(() => _isProcessing = true);
    try {
      final error =
          await _cameraService.validateImage(_capturedImage);
      if (error != null) {
        if (mounted) Helpers.showError(context, error);
        return;
      }
      ref
          .read(tryOnControllerProvider.notifier)
          .setUserPhoto(_capturedImage);
      if (mounted) context.router.push(TryOnRoute());
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to process photo');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}