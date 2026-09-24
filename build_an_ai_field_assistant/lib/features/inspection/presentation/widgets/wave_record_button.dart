import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Professional Soundwave Recording Widget with real-time frequency equalizer
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Equalizer frequency visualizer (only visible when recording)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: widget.isRecording ? 60 : 0,
          child: widget.isRecording
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(24, (index) {
                    final normalizedAmp = widget.amplitude.clamp(0.1, 1.0);
                    // Add slight deterministic variance across bars
                    final factor = (sin(index * 0.5 + _pulseController.value * pi) + 1) / 2;
                    final barHeight = (12 + (factor * 44 * normalizedAmp)).clamp(6.0, 56.0);

                    return Container(
                      width: 4,
                      height: barHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: index.isEven
                            ? AppColors.primary
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // Recording Duration Pill
        if (widget.isRecording) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.recordingActive.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.recordingActive,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.recordingActive.withValues(
                              alpha: _pulseController.value * 0.8,
                            ),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.formatDuration(widget.duration),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '• REC',
                  style: TextStyle(
                    color: AppColors.recordingActive,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Main Center Record Button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cancel Button (if recording)
            if (widget.isRecording && widget.onCancel != null)
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  onPressed: widget.onCancel,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMuted,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  tooltip: 'Hủy ghi âm',
                ),
              ),

            // Big Action Button
            GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: widget.isRecording ? 76 : 76,
                height: widget.isRecording ? 76 : 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isRecording
                      ? AppColors.recordingActive
                      : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isRecording
                              ? AppColors.recordingActive
                              : AppColors.primary)
                          .withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.isRecording
                        ? Container(
                            key: const ValueKey('stop_icon'),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          )
                        : const Icon(
                            Icons.mic_rounded,
                            key: ValueKey('mic_icon'),
                            color: Colors.white,
                            size: 38,
                          ),
                  ),
                ),
              ),
            ),

            if (widget.isRecording && widget.onCancel != null)
              const SizedBox(width: 60), // balance the row
          ],
        ),
      ],
    );
  }
}
