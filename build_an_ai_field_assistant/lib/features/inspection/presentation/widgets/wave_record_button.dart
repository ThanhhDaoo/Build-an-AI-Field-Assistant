import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Professional Soundwave Recording Widget with large central mic button,
/// multi-layer radar ripple waves, and prominent digital seconds timer.
class WaveRecordButton extends StatefulWidget {
  final bool isRecording;
  final double amplitude;
  final Duration duration;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const WaveRecordButton({
    super.key,
    required this.isRecording,
    required this.amplitude,
    required this.duration,
    required this.onTap,
    this.onCancel,
  });

  @override
  State<WaveRecordButton> createState() => _WaveRecordButtonState();
}

class _WaveRecordButtonState extends State<WaveRecordButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (widget.isRecording) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _rippleController.repeat();
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 88.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Real-time audio frequency equalizer bars
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: widget.isRecording ? 58 : 0,
          child: widget.isRecording
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(24, (index) {
                    final normalizedAmp = widget.amplitude.clamp(0.12, 1.0);
                    final factor =
                        (sin(index * 0.45 + _pulseController.value * pi) + 1) /
                            2;
                    final barHeight =
                        (10 + (factor * 44 * normalizedAmp)).clamp(6.0, 54.0);

                    return Container(
                      width: 4.5,
                      height: barHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.recordingActive,
                            AppColors.primary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 14),

        // Digital HUD Timer đếm giây ghi âm
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isRecording
                ? AppColors.surfaceLight
                : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isRecording
                  ? AppColors.recordingActive.withValues(alpha: 0.6)
                  : AppColors.cardBorder,
              width: widget.isRecording ? 1.5 : 1.0,
            ),
            boxShadow: widget.isRecording
                ? [
                    BoxShadow(
                      color: AppColors.recordingActive.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated recording dot
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final active = widget.isRecording;
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.recordingActive
                          : AppColors.textMuted,
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.recordingActive.withValues(
                                  alpha: _pulseController.value * 0.9,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              // Formatted Duration Time
              Text(
                DateFormatter.formatDuration(widget.duration),
                style: TextStyle(
                  color: widget.isRecording
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isRecording
                      ? AppColors.recordingActive.withValues(alpha: 0.18)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.isRecording ? 'ĐANG THU' : 'CHỜ THU',
                  style: TextStyle(
                    color: widget.isRecording
                        ? AppColors.recordingActive
                        : AppColors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Nút micro trung tâm kích thước lớn kèm hiệu ứng đổi màu & ripple radar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cancel Button (if recording)
            if (widget.isRecording && widget.onCancel != null)
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: IconButton(
                  onPressed: widget.onCancel,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 24),
                  tooltip: 'Hủy ghi âm',
                ),
              ),

            // Central Recording Button with Ripple
            SizedBox(
              width: buttonSize + 36,
              height: buttonSize + 36,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple wave 1
                  if (widget.isRecording)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, _) {
                        final progress = _rippleController.value;
                        final currentSize = buttonSize + (36 * progress);
                        final opacity = (1.0 - progress).clamp(0.0, 0.6);

                        return Container(
                          width: currentSize,
                          height: currentSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.recordingActive
                                  .withValues(alpha: opacity),
                              width: 2.0,
                            ),
                          ),
                        );
                      },
                    ),

                  // Outer ripple wave 2 (phase offset)
                  if (widget.isRecording)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, _) {
                        final progress = (_rippleController.value + 0.5) % 1.0;
                        final currentSize = buttonSize + (36 * progress);
                        final opacity = (1.0 - progress).clamp(0.0, 0.4);

                        return Container(
                          width: currentSize,
                          height: currentSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.recordingActive
                                  .withValues(alpha: opacity),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),

                  // Central Core Button
                  GestureDetector(
                    onTap: widget.onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Hiệu ứng đổi màu: Xanh Emerald khi chờ -> Đỏ Alert khi đang thu
                        gradient: LinearGradient(
                          colors: widget.isRecording
                              ? [
                                  AppColors.recordingActive,
                                  const Color(0xFFDC2626),
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (widget.isRecording
                                    ? AppColors.recordingActive
                                    : AppColors.primary)
                                .withValues(
                                    alpha: widget.isRecording ? 0.5 : 0.35),
                            blurRadius: widget.isRecording ? 24 : 16,
                            spreadRadius: widget.isRecording ? 3 : 1,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: widget.isRecording
                              ? Container(
                                  key: const ValueKey('stop_box'),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                )
                              : const Icon(
                                  Icons.mic_rounded,
                                  key: ValueKey('mic_icon_large'),
                                  color: Colors.white,
                                  size: 44,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (widget.isRecording && widget.onCancel != null)
              const SizedBox(width: 72), // Balances the Cancel button on left
          ],
        ),
      ],
    );
  }
}
