import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Animated Pulsating & Soundwave Recording Button
class WaveRecordButton extends StatefulWidget {
  final bool isRecording;
  final double amplitude;
  final Duration duration;
  final VoidCallback onTap;

  const WaveRecordButton({
    super.key,
    required this.isRecording,
    required this.amplitude,
    required this.duration,
    required this.onTap,
  });

  @override
  State<WaveRecordButton> createState() => _WaveRecordButtonState();
}

class _WaveRecordButtonState extends State<WaveRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic amplitude scale
    final ampScale = (widget.amplitude * 0.4).clamp(0.0, 0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isRecording) ...[
          // Duration Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.recordingActive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.recordingActive.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.recordingActive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đang ghi âm: ${DateFormatter.formatDuration(widget.duration)}',
                  style: const TextStyle(
                    color: AppColors.recordingActive,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],

        // Waveform Button
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ripple 2 (Only when recording)
                  if (widget.isRecording)
                    Container(
                      width: 140 + (ampScale * 50),
                      height: 140 + (ampScale * 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.recordingActive.withValues(
                          alpha: ((1.0 - _animController.value) * 0.25).clamp(0.0, 1.0),
                        ),
                      ),
                    ),

                  // Outer Ripple 1
                  if (widget.isRecording)
                    Container(
                      width: 115 + (ampScale * 35),
                      height: 115 + (ampScale * 35),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.recordingActive.withValues(alpha: 0.35),
                      ),
                    ),

                  // Main Button Container
                  Transform.scale(
                    scale: widget.isRecording ? (1.0 + ampScale) : _scaleAnimation.value,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.isRecording
                              ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                              : [AppColors.primary, const Color(0xFF059669)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isRecording
                                ? AppColors.recordingGlow
                                : AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: widget.isRecording ? 30 : 20,
                            spreadRadius: widget.isRecording ? 6 : 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
