// lib/services/camera_service.dart
// Camera & Image Picker Service

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtual_tryon_app/core/utils/app_config.dart';

/// Represents an image that can be used on both mobile and web platforms
class PickedImage {
  final String? path;
  final Uint8List? bytes;
  final String name;
  int? _cachedLength;
  
  PickedImage({this.path, this.bytes, required this.name});
  
  bool get isWeb => kIsWeb;
  
  Future<int> get length async {
    if (_cachedLength != null) return _cachedLength!;
    
    if (kIsWeb && bytes != null) {
      _cachedLength = bytes!.length;
      return _cachedLength!;
    } else if (path != null) {
      final file = File(path!);
      _cachedLength = await file.length();
      return _cachedLength!;
    }
    _cachedLength = 0;
    return _cachedLength!;
  }
  
  int? get cachedLength => _cachedLength;
}

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Capture photo from camera
  Future<PickedImage?> capturePhoto({
    bool frontCamera = true,
  }) async {
    try {
      // Higher quality settings for better photos (up to 10MB)
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
        frontCamera ? CameraDevice.front : CameraDevice.rear,
        imageQuality: 95, // Higher quality for better try-on results
        maxWidth: 2160, // Higher resolution (up to 4K)
        maxHeight: 3840,
      );

      if (photo == null) return null;

      // Handle web vs mobile
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        final image = PickedImage(
          bytes: bytes,
          name: photo.name,
        );
        
        // Validate file size
        final fileSize = await image.length;
        if (!AppConfig.isValidImageSize(fileSize)) {
          throw Exception(
            'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
                'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
          );
        }
        
        return image;
      } else {
        final file = File(photo.path);
        
        // Validate file size
        final fileSize = await file.length();
        if (!AppConfig.isValidImageSize(fileSize)) {
          throw Exception(
            'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
                'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
          );
        }
        
        return PickedImage(
          path: photo.path,
          name: photo.name,
        );
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      rethrow;
    }
  }

  // Pick image from gallery
  Future<PickedImage?> pickFromGallery() async {
    try {
      // Higher quality settings for better photos (up to 10MB)
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95, // Higher quality for better try-on results
        maxWidth: 2160, // Higher resolution
        maxHeight: 3840,
      );

      if (image == null) return null;

      // Handle web vs mobile
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        final pickedImage = PickedImage(
          bytes: bytes,
          name: image.name,
        );
        
        // Validate file size
        final fileSize = await pickedImage.length;
        if (!AppConfig.isValidImageSize(fileSize)) {
          throw Exception(
            'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
                'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
          );
        }
        
        return pickedImage;
      } else {
        final file = File(image.path);
        
        // Validate file size
        final fileSize = await file.length();
        if (!AppConfig.isValidImageSize(fileSize)) {
          throw Exception(
            'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
                'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
          );
        }
        
        return PickedImage(
          path: image.path,
          name: image.name,
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  // Capture live photo from camera (iOS only)
  Future<PickedImage?> captureLivePhoto({
    bool frontCamera = true,
  }) async {
    try {
      // Higher quality settings for live photos (up to 10MB)
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
            frontCamera ? CameraDevice.front : CameraDevice.rear,
        imageQuality: 95, // Higher quality for better try-on results
        maxWidth: 2160, // Higher resolution (up to 4K)
        maxHeight: 3840,
        // Request live photo metadata if available
        requestFullMetadata: true,
      );

      if (photo == null) return null;

      // Handle web vs mobile
      if (kIsWeb) {
        final bytes = await photo.readAsBytes();
        final image = PickedImage(
          bytes: bytes,
          name: photo.name,
        );
        
        // Validate file size
        final fileSize = await image.length;
        if (!AppConfig.isValidImageSize(fileSize)) {
          throw Exception(
            'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
                'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
          );
        }
        
        return image;
      } else {
        final file = File(photo.path);
        
        // Validate file size
        final fileSize = await file.length();
        if (!AppConfig.isValidImageSize(fileSize)) {
          throw Exception(
            'Image size (${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB) '
                'exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB',
          );
        }
        
        return PickedImage(
          path: photo.path,
          name: photo.name,
        );
      }
    } catch (e) {
      debugPrint('Error capturing live photo: $e');
      rethrow;
    }
  }

  // Pick multiple images from gallery
  Future<List<PickedImage>?> pickMultipleFromGallery({
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

      // Convert to PickedImage list and validate sizes
      final List<PickedImage> pickedImages = [];
      for (final image in selectedImages) {
        int fileSize;
        
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          fileSize = bytes.length;
          if (AppConfig.isValidImageSize(fileSize)) {
            pickedImages.add(PickedImage(bytes: bytes, name: image.name));
          }
        } else {
          final file = File(image.path);
          fileSize = await file.length();
          if (AppConfig.isValidImageSize(fileSize)) {
            pickedImages.add(PickedImage(path: image.path, name: image.name));
          }
        }
        
        if (!AppConfig.isValidImageSize(fileSize)) {
          debugPrint(
            'Skipping image ${image.name}: size ${AppConfig.getFileSizeInMB(fileSize).toStringAsFixed(1)}MB exceeds limit',
          );
        }
      }

      return pickedImages.isEmpty ? null : pickedImages;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      rethrow;
    }
  }

  // Show image source selection dialog with live photo support
  Future<PickedImage?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<PickedImage>(
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
                  final image = await capturePhoto();
                  if (context.mounted && image != null) {
                    Navigator.pop(context, image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickFromGallery();
                  if (context.mounted && image != null) {
                    Navigator.pop(context, image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Live Photo'),
                subtitle: const Text('Capture a live moment'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await captureLivePhoto();
                  if (context.mounted && image != null) {
                    Navigator.pop(context, image);
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
  Future<double> getImageSizeInMB(PickedImage image) async {
    final int bytes = await image.length;
    return bytes / (1024 * 1024);
  }

  // Check if image size is valid
  Future<bool> isImageSizeValid(PickedImage image) async {
    final int bytes = await image.length;
    return (bytes / (1024 * 1024)) <= AppConfig.maxImageSizeMB;
  }

  // Validate image file
  Future<String?> validateImage(PickedImage? image) async {
    if (image == null) {
      return 'Please select an image';
    }

    int fileSize;
    if (image.cachedLength != null) {
      fileSize = image.cachedLength!;
    } else {
      fileSize = await image.length;
    }
    
    if (!AppConfig.isValidImageSize(fileSize)) {
      final double sizeMB = AppConfig.getFileSizeInMB(fileSize);
      return 'Image size (${sizeMB.toStringAsFixed(1)}MB) exceeds maximum allowed size of ${AppConfig.maxImageSizeMB}MB';
    }

    return null; // Valid
  }
}
