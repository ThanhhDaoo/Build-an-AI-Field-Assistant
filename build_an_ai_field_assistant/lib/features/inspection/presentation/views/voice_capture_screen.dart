import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        widget.controller.setSelectedImagePath(pickedFile.path);
      }
    } catch (e) {
      debugPrint('Lỗi chụp/chọn ảnh: $e');
      if (mounted) {
        DialogHelper.showSnackBar(
          context,
          'Không thể tải ảnh: $e',
          isError: true,
        );
      }
    }
  }

  Widget _buildImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    if (kIsWeb || path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 24),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 24),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.8,
                maxScale: 4.0,
                child: _buildImageWidget(path, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCaptureSection(InspectionController ctrl) {
    final imagePath = ctrl.selectedImagePath;

    if (imagePath != null && imagePath.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Row(
          children: [
            // Image Thumbnail
            GestureDetector(
              onTap: () => _showFullScreenImage(context, imagePath),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageWidget(imagePath),
                      Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        child: const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded, size: 11, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'ĐÃ ĐÍNH KÈM ẢNH HIỆN TRƯỜNG',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'AI sẽ phân tích đồng thời ảnh chụp & giọng nói để lập biên bản',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 20),
              tooltip: 'Chụp lại',
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.priorityHigh, size: 20),
              tooltip: 'Xóa ảnh',
              onPressed: () => ctrl.clearSelectedImage(),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh hiện trường (Tùy chọn)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chụp ảnh thiết bị trước khi nói để AI nhận diện tổn hại',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.camera_alt_rounded, size: 15),
            label: const Text('Chụp ảnh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            tooltip: 'Chọn ảnh từ thư viện',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechChip(InspectionController ctrl, String text) {
    return InkWell(
      onTap: () {
        ctrl.setLiveTranscript(text);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_none_rounded, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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

                  const SizedBox(height: 16),

                  // Photo Capture & Preview Section
                  _buildPhotoCaptureSection(ctrl),

                  const SizedBox(height: 24),

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

                  // Live Speech-to-Text Transcription Box (While Recording)
                  if (ctrl.isRecording) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ctrl.liveTranscript.isNotEmpty
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'BÓC BĂNG TRỰC TIẾP (SPEECH-TO-TEXT)',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ctrl.liveTranscript.isNotEmpty
                                ? ctrl.liveTranscript
                                : 'Đang lắng nghe giọng nói... Hãy mô tả sự cố (ví dụ: "Bơm áp lực bị kẹt puly kêu to")',
                            style: TextStyle(
                              color: ctrl.liveTranscript.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: ctrl.liveTranscript.isNotEmpty
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              fontStyle: ctrl.liveTranscript.isNotEmpty
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Gợi ý nhanh cho máy ảo / giả lập:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildSpeechChip(
                                ctrl,
                                'Puly máy bơm số 2 bị nứt vỡ kêu to',
                              ),
                              _buildSpeechChip(
                                ctrl,
                                'Rò rỉ van dầu DN50 phân xưởng cán thép',
                              ),
                              _buildSpeechChip(
                                ctrl,
                                'Aptomat tủ điện tổng quá nhiệt bốc khói',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

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

                  const SizedBox(height: 28),

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
