import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Clean, Human-Centered Priority Badge and Segment Chip
class PriorityBadgeChip extends StatelessWidget {
  final String priority;
  final bool isSelected;
  final bool isInteractive;
  final ValueChanged<String>? onSelected;

  const PriorityBadgeChip({
    super.key,
    required this.priority,
    this.isSelected = false,
    this.isInteractive = false,
    this.onSelected,
  });

  Color _getColor() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.priorityCritical;
      case 'high':
        return AppColors.priorityHigh;
      case 'medium':
        return AppColors.priorityMedium;
      case 'low':
      default:
        return AppColors.priorityLow;
    }
  }

  Color _getBgColor() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.priorityCriticalBg;
      case 'high':
        return AppColors.priorityHighBg;
      case 'medium':
        return AppColors.priorityMediumBg;
      case 'low':
      default:
        return AppColors.priorityLowBg;
    }
  }

  String _getLabel() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 'Khẩn cấp';
      case 'high':
        return 'Mức cao';
      case 'medium':
        return 'Trung bình';
      case 'low':
      default:
        return 'Mức thấp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final bgColor = _getBgColor();
    final label = _getLabel();

    if (!isInteractive) {
      // Clean status pill for cards & lists
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    // Interactive selection chip (in Review Form)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected?.call(priority.toLowerCase()),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isSelected ? color : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
