import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_persistence_helper.dart';

/// Widget hiển thị ảnh hiện trường thông minh
/// Hỗ trợ cả Base64 Data URI (vĩnh cửu), Network URL và Local File System
class InspectionImageWidget extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const InspectionImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    // 1. Base64 Data URI (Hoạt động vĩnh cửu trên cả Web và Mobile)
    if (imagePath.startsWith('data:image')) {
      final bytes = MediaPersistenceHelper.decodeImageBytes(imagePath);
      if (bytes != null && bytes.isNotEmpty) {
        content = Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
        );
      } else {
        content = _buildErrorPlaceholder();
      }
    }
    // 2. Web Network URL
    else if (kIsWeb || imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('blob:')) {
      content = Image.network(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
      );
    }
    // 3. Local File System (Android / iOS / macOS native)
    else {
      final file = io.File(imagePath);
      if (file.existsSync()) {
        content = Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
        );
      } else {
        content = _buildErrorPlaceholder();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}
