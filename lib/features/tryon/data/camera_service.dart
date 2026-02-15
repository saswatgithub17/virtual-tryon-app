// lib/services/camera_service.dart
// Camera & Image Picker Service

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Capture photo from camera
  Future<File?> capturePhoto({
    bool frontCamera = true,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
        frontCamera ? CameraDevice.front : CameraDevice.rear,
        imageQuality: AppConfig.imageQuality,
        maxWidth: AppConfig.maxImageWidth.toDouble(),
        maxHeight: AppConfig.maxImageHeight.toDouble(),
      );

      if (photo == null) return null;

      final file = File(photo.path);

      // Validate file size
      final fileSize = await file.length();
      if (!AppConfig.isValidImageSize(fileSize)) {
        throw Exception(
          'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
              'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
        );
      }

      return file;
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      rethrow;
    }
  }

  // Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: AppConfig.imageQuality,
        maxWidth: AppConfig.maxImageWidth.toDouble(),
        maxHeight: AppConfig.maxImageHeight.toDouble(),
      );

      if (image == null) return null;

      final file = File(image.path);

      // Validate file size
      final fileSize = await file.length();
      if (!AppConfig.isValidImageSize(fileSize)) {
        throw Exception(
          'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
              'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
        );
      }

      return file;
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  // Pick multiple images from gallery
  Future<List<File>?> pickMultipleFromGallery({
    int maxImages = 5,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: AppConfig.imageQuality,
        maxWidth: AppConfig.maxImageWidth.toDouble(),
        maxHeight: AppConfig.maxImageHeight.toDouble(),
      );

      if (images.isEmpty) return null;

      // Limit number of images
      final selectedImages = images.take(maxImages).toList();

      // Convert to File list and validate sizes
      final List<File> files = [];
      for (final image in selectedImages) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (AppConfig.isValidImageSize(fileSize)) {
          files.add(file);
        } else {
          debugPrint(
            'Skipping image ${image.name}: size ${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB exceeds limit',
          );
        }
      }

      return files.isEmpty ? null : files;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      rethrow;
    }
  }

  // Show image source selection dialog
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<File>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await capturePhoto();
                  if (context.mounted && file != null) {
                    Navigator.pop(context, file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final file = await pickFromGallery();
                  if (context.mounted && file != null) {
                    Navigator.pop(context, file);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Get image file size in MB
  Future<double> getImageSizeInMB(File file) async {
    final bytes = await file.length();
    return AppConfig.getFileSizeInMB(bytes);
  }

  // Check if image size is valid
  Future<bool> isImageSizeValid(File file) async {
    final bytes = await file.length();
    return AppConfig.isValidImageSize(bytes);
  }

  // Validate image file
  Future<String?> validateImage(File? file) async {
    if (file == null) {
      return 'Please select an image';
    }

    if (!await file.exists()) {
      return 'Image file not found';
    }

    final isValid = await isImageSizeValid(file);
    if (!isValid) {
      final sizeMB = await getImageSizeInMB(file);
      return 'Image size (${sizeMB.toStringAsFixed(1)}MB) exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB';
    }

    return null; // Valid
  }
}