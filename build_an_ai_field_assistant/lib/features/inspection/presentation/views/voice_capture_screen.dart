import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/wave_record_button.dart';
import 'ticket_review_screen.dart';

/// Professional Field Audio Logger & Incident Intake Station
class VoiceCaptureScreen extends StatefulWidget {
  final InspectionController controller;
  final bool embeddedMode;

  const VoiceCaptureScreen({
    super.key,
    required this.controller,
    this.embeddedMode = false,
  });

  @override
  State<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends State<VoiceCaptureScreen> {
  final TextEditingController _quickNoteController = TextEditingController();

  final List<Map<String, dynamic>> _commonScenarios = [
    {
      'title': 'Rò rỉ van dầu áp suất cao',
      'location': 'Phân xưởng cán thép 2',
      'text': 'Phát hiện van dầu áp lực cao tại Phân xưởng cán thép 2 bị nứt gioăng, dầu rỉ tràn sàn có nguy cơ trơn trượt té ngã. Cần thay van DN50 gấp.',
      'icon': Icons.water_drop_outlined,
      'color': AppColors.priorityHigh,
    },
    {
      'title': 'Quá nhiệt tủ điện phân phối',
      'location': 'Tủ điện số 4 - Kho vật tư',
      'text': 'Tủ điện số 4 cạnh kho vật tư có mùi khét nồng, aptomat quá nhiệt phát tia lửa điện lẹt xẹt, cần ngắt cầu dao tổng khu vực và đội cơ điện xử lý ngay.',
      'icon': Icons.bolt_outlined,
      'color': AppColors.priorityCritical,
    },
    {
      'title': 'Nứt kết cấu dầm chịu lực',
      'location': 'Tầng 3 Block B',
      'text': 'Phát hiện vết nứt dầm bê tông cốt thép tại trục D tầng 3 Block B, chiều dài khoảng 1.5 mét, cần kỹ sư kết cấu kiểm tra độ an toàn chịu tải.',
      'icon': Icons.foundation_outlined,
      'color': AppColors.priorityMedium,
    },
  ];

  @override
  void dispose() {
    _quickNoteController.dispose();
    super.dispose();
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
                const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Ghi nhận hiện trường thủ công',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                hintText: 'Nhập ghi chú hiện trường: Vị trí, thiết bị, hiện trạng...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check_rounded),
                label: const Text(
                  'Tạo biên bản kiểm tra',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRecordTap(InspectionController ctrl) async {
    if (ctrl.isRecording) {
      final ticket = await ctrl.stopRecordingAndExtract();
      if (!mounted) return;
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
      try {
        await ctrl.startRecording();
      } on MicrophonePermissionException catch (e) {
        if (!mounted) return;
        MicrophonePermissionDialog.show(
          context,
          isPermanentlyDenied: e.isPermanentlyDenied,
        );
      } catch (e) {
        if (!mounted) return;
        DialogHelper.showSnackBar(
          context,
          'Không thể khởi động ghi âm: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (_, child) {
        final ctrl = widget.controller;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: widget.embeddedMode
              ? null
              : AppBar(
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: const Text(
                    'Thu âm hiện trường',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header Title
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ghi âm mô tả sự cố hiện trường',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Nêu rõ: Vị trí cụ thể, tên thiết bị, hiện trạng và mức độ nguy cơ.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Center Wave Record Button
                  Center(
                    child: WaveRecordButton(
                      isRecording: ctrl.isRecording,
                      amplitude: ctrl.currentAmplitude,
                      duration: ctrl.recordDuration,
                      onCancel: () => ctrl.cancelRecording(),
                      onTap: () => _onRecordTap(ctrl),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status indicator
                  if (ctrl.state == InspectionViewState.analyzing)
                    const Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Đang xử lý âm thanh & cấu trúc biên bản...',
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
                          ? 'Nhấn nút vuông đỏ để dừng & lập biên bản'
                          : 'Nhấn vào micro để bắt đầu ghi âm',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 36),

                  // Manual Note Button (For noisy environment)
                  OutlinedButton.icon(
                    onPressed: _showTextPromptModal,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 16),
                    label: const Text('Môi trường ồn? Nhập văn bản thủ công', style: TextStyle(fontSize: 12.5)),
                  ),

                  const SizedBox(height: 30),

                  // Common Inspection Scenarios
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Biên bản mẫu thường gặp:',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._commonScenarios.map(
                          (scenario) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final ticket = await ctrl.extractFromText(scenario['text'] as String);
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
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(scenario['icon'] as IconData, color: scenario['color'] as Color, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              scenario['title'] as String,
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              scenario['location'] as String,
                                              style: const TextStyle(
                                                color: AppColors.textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
