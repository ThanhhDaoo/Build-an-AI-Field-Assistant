import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/wave_record_button.dart';
import 'ticket_history_screen.dart';
import 'ticket_review_screen.dart';

/// Main Voice Capture Screen for Field Inspectors
class VoiceCaptureScreen extends StatefulWidget {
  final InspectionController controller;

  const VoiceCaptureScreen({
    super.key,
    required this.controller,
  });

  @override
  State<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends State<VoiceCaptureScreen> {
  final TextEditingController _quickNoteController = TextEditingController();

  final List<String> _quickScenarios = [
    'Rò rỉ van dầu áp suất cao tại Phân xưởng cán thép 2, dầu tràn mặt sàn trơn trượt.',
    'Tủ điện số 4 cạnh kho vật tư có mùi khét nồng, aptomat quá nhiệt phát tia lửa điện.',
    'Phát hiện nứt kết cấu dầm bê tông tầng 3 Block B, chiều dài vết nứt khoảng 1.5 mét.',
  ];

  @override
  void dispose() {
    _quickNoteController.dispose();
    super.dispose();
  }

  void _showApiKeyDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString(AppConstants.keyGeminiApiKey) ?? '';
    final textController = TextEditingController(text: currentKey);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Cấu hình Gemini API Key',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập Google Gemini API Key để kích hoạt trích xuất thông minh trực tuyến. (Nếu để trống, hệ thống sẽ sử dụng thuật toán NLP offline dự phòng)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await prefs.setString(
                AppConstants.keyGeminiApiKey,
                textController.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
              if (mounted) {
                DialogHelper.showSnackBar(context, 'Đã lưu cấu hình API Key thành công!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showTextPromptModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nhập ghi chú hiện trường',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quickNoteController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nhập hoặc dán ghi chú sự cố tại hiện trường...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final text = _quickNoteController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.of(ctx).pop();
                  _quickNoteController.clear();

                  final ticket = await widget.controller.extractFromText(text);
                  if (ticket != null && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TicketReviewScreen(
                          controller: widget.controller,
                          initialTicket: ticket,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text(
                  'AI Phân tích & Trích xuất phiếu',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.engineering_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Field AI Assistant',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Giám sát Hiện trường',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Online / Offline Status
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ctrl.isOnline
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.statusPending.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ctrl.isOnline
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.statusPending.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ctrl.isOnline ? AppColors.primary : AppColors.statusPending,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        ctrl.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: ctrl.isOnline ? AppColors.primary : AppColors.statusPending,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Gemini API Key config
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                tooltip: 'Cài đặt API Key',
                onPressed: _showApiKeyDialog,
              ),

              // History Screen Navigation with badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary),
                    tooltip: 'Danh sách phiếu',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TicketHistoryScreen(controller: ctrl),
                        ),
                      );
                    },
                  ),
                  if (ctrl.pendingCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.priorityCritical,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${ctrl.pendingCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Header Guidance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thu âm & Tự động tạo phiếu',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Nói rõ vị trí, sự cố, nguyên nhân và mức độ nguy hiểm. AI sẽ tự động điền form biên bản.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Main Audio Wave Record Button
                  Center(
                    child: WaveRecordButton(
                      isRecording: ctrl.isRecording,
                      amplitude: ctrl.currentAmplitude,
                      duration: ctrl.recordDuration,
                      onTap: () async {
                        if (ctrl.isRecording) {
                          final ticket = await ctrl.stopRecordingAndExtract();
                          if (!context.mounted) return;
                          if (ticket != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TicketReviewScreen(
                                  controller: ctrl,
                                  initialTicket: ticket,
                                ),
                              ),
                            );
                          }
                        } else {
                          await ctrl.startRecording();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Status Text
                  if (ctrl.state == InspectionViewState.analyzing)
                    const Column(
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Gemini AI đang lắng nghe và trích xuất cấu trúc JSON...',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      ctrl.isRecording
                          ? 'Chạm nút dừng để AI phân tích giọng nói'
                          : 'Chạm biểu tượng micro để bắt đầu nói',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 36),

                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showTextPromptModal,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Nhập tay'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TicketHistoryScreen(controller: ctrl),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        icon: const Icon(Icons.list_alt_rounded, size: 18),
                        label: Text('Lịch sử (${ctrl.tickets.length})'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Quick Testing Scenarios (Demo Templates)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bolt_rounded, color: AppColors.primaryLight, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Tình huống mẫu thử nghiệm nhanh:',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._quickScenarios.map(
                          (scenario) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () async {
                                final ticket = await ctrl.extractFromText(scenario);
                                if (!context.mounted) return;
                                if (ticket != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TicketReviewScreen(
                                        controller: ctrl,
                                        initialTicket: ticket,
                                      ),
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        scenario,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppColors.textMuted,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
