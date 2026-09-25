import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/inspection_controller.dart';

/// Floating In-App Banner notifying users when offline tickets have synced automatically
class InAppSyncBanner extends StatefulWidget {
  final InspectionController controller;
  final Duration autoDismissDuration;

  const InAppSyncBanner({
    super.key,
    required this.controller,
    this.autoDismissDuration = const Duration(seconds: 4),
  });

  @override
  State<InAppSyncBanner> createState() => _InAppSyncBannerState();
}

class _InAppSyncBannerState extends State<InAppSyncBanner> with SingleTickerProviderStateMixin {
  Timer? _dismissTimer;
  String? _lastMessage;

  @override
  void didUpdateWidget(covariant InAppSyncBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkMessageUpdate();
  }

  void _checkMessageUpdate() {
    final currentMsg = widget.controller.activeSyncMessage;
    if (currentMsg != null && currentMsg != _lastMessage) {
      _lastMessage = currentMsg;
      _dismissTimer?.cancel();
      _dismissTimer = Timer(widget.autoDismissDuration, () {
        if (mounted && widget.controller.activeSyncMessage != null) {
          widget.controller.dismissSyncMessage();
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.controller.activeSyncMessage;
    if (message == null) return const SizedBox.shrink();

    _checkMessageUpdate();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Container(
        key: ValueKey(message),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5), // Emerald 50
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_done_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF065F46), // Emerald 900
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => widget.controller.dismissSyncMessage(),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
