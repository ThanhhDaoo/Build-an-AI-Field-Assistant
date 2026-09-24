import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Swipe-To-Submit Button preventing accidental touches in the field
class SwipeToSubmitButton extends StatefulWidget {
  final Future<void> Function() onSubmit;
  final String label;
  final bool isLoading;

  const SwipeToSubmitButton({
    super.key,
    required this.onSubmit,
    this.label = 'Vuốt để gửi biên bản',
    this.isLoading = false,
  });

  @override
  State<SwipeToSubmitButton> createState() => _SwipeToSubmitButtonState();
}

class _SwipeToSubmitButtonState extends State<SwipeToSubmitButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isSubmitted = false;

  static const double _buttonHeight = 56.0;
  static const double _thumbSize = 48.0;
  static const double _padding = 4.0;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        height: _buttonHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Đang lưu & đồng bộ biên bản...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - _thumbSize - (_padding * 2);

        return Container(
          height: _buttonHeight,
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Background track progress glow
              Container(
                width: _dragPosition + _thumbSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),

              // Centered Prompt Label
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      color: AppColors.primaryLight,
                      size: 18,
                    ),
                  ],
                ),
              ),

              // Draggable Swipe Thumb
              Positioned(
                left: _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isSubmitted) return;
                    setState(() {
                      _dragPosition = (_dragPosition + details.delta.dx)
                          .clamp(0.0, maxDrag);
                    });
                  },
                  onHorizontalDragEnd: (details) async {
                    if (_isSubmitted) return;

                    // If dragged over 75% of track, trigger submission
                    if (_dragPosition >= maxDrag * 0.75) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _isSubmitted = true;
                      });
                      try {
                        await widget.onSubmit();
                      } finally {
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0.0;
                            _isSubmitted = false;
                          });
                        }
                      }
                    } else {
                      // Spring back
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
