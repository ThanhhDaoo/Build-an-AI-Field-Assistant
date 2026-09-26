import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/media_persistence_helper.dart';

/// Widget hiển thị ảnh hiện trường thông minh
/// Hỗ trợ cả Base64 Data URI (vĩnh cửu), Network URL và Local File System
class InspectionImageWidget extends StatelessWidget {
  final String? imagePath;
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
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder(Icons.image_outlined);
    }

    final path = imagePath!;
    Widget content;

    // 1. Base64 Data URI (Hoạt động vĩnh cửu trên cả Web và Mobile)
    if (path.startsWith('data:image')) {
      final bytes = MediaPersistenceHelper.decodeImageBytes(path);
      if (bytes != null && bytes.isNotEmpty) {
        content = Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildPlaceholder(Icons.broken_image_rounded),
        );
      } else {
        content = _buildPlaceholder(Icons.broken_image_rounded);
      }
    }
    // 2. Web Network URL
    else if (kIsWeb || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
      content = Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _buildPlaceholder(Icons.broken_image_rounded),
      );
    }
    // 3. Local File System (Android / iOS / macOS native)
    else {
      final file = io.File(path);
      if (file.existsSync()) {
        content = Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _buildPlaceholder(Icons.broken_image_rounded),
        );
      } else {
        content = _buildPlaceholder(Icons.broken_image_rounded);
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

  Widget _buildPlaceholder(IconData icon) {
    return Container(
      width: width,
      height: height,
      color: AppColors.background,
      child: Center(
        child: Icon(
          icon,
          color: AppColors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}
