import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:virtual_tryon_app/features/catalog/data/models/dress_model.dart';
import 'package:virtual_tryon_app/features/tryon/data/camera_service.dart';
import 'package:virtual_tryon_app/features/tryon/presentation/controllers/tryon_controller.dart';
import 'package:virtual_tryon_app/core/theme/app_theme.dart';
import 'package:virtual_tryon_app/core/utils/helpers.dart';
import 'package:virtual_tryon_app/core/router/app_router.dart';

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
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  File? _capturedImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _capturedImage == null
            ? _buildCameraInterface()
            : _buildPreviewInterface(),
      ),
    );
  }

  Widget _buildCameraInterface() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                        onPressed: () => context.router.pop()),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.camera_alt,
                            color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 8),
                        Text('Take a full-body photo for best results',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.5), width: 3),
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline,
                    size: 120, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('Position yourself here',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 16)),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent]),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: _pickFromGallery),
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4)),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor
                          ])),
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

  Widget _buildPreviewInterface() {
    return Stack(
      children: [
        Center(
          child: Hero(
              tag: 'captured_image',
              child: Image.file(_capturedImage!, fit: BoxFit.contain)),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent]),
            ),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _capturedImage = null)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _capturedImage = null),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Retake',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent]),
            ),
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirmPhoto,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Use This Photo',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _capturePhoto() async {
    try {
      setState(() => _isProcessing = true);
      final image = await _cameraService.capturePhoto(frontCamera: true);
      if (image != null && mounted) {
        setState(() {
          _capturedImage = image;
          _isProcessing = false;
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

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);
      final image = await _cameraService.pickFromGallery();
      if (image != null && mounted) {
        setState(() {
          _capturedImage = image;
          _isProcessing = false;
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

  Future<void> _confirmPhoto() async {
    if (_capturedImage == null) return;
    setState(() => _isProcessing = true);
    try {
      final error = await _cameraService.validateImage(_capturedImage);
      if (error != null) {
        if (mounted) Helpers.showError(context, error);
        return;
      }
      ref.read(tryOnControllerProvider.notifier).setUserPhoto(_capturedImage);
      if (mounted) {
        context.router.push(const TryOnRoute());
      }
    } catch (e) {
      if (mounted) Helpers.showError(context, 'Failed to process photo');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
