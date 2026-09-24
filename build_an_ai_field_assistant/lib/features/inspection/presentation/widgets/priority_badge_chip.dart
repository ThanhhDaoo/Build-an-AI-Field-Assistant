import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Priority Badge and Selector Chip with industrial high-visibility styling
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

  IconData _getIcon() {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;
      case 'high':
        return Icons.arrow_upward_rounded;
      case 'medium':
        return Icons.remove_rounded;
      case 'low':
      default:
        return Icons.arrow_downward_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final bgColor = _getBgColor();
    final label = _getLabel();
    final icon = _getIcon();

    if (!isInteractive) {
      // Compact read-only badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Interactive selection chip
    return InkWell(
      onTap: () => onSelected?.call(priority.toLowerCase()),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
