import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/in_app_sync_banner.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/wave_record_button.dart';
import 'ticket_review_screen.dart';

/// Clean Enterprise Field Audio & Incident Intake Screen
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
      'text':
          'Phát hiện van dầu áp lực cao tại Phân xưởng cán thép 2 bị nứt gioăng, dầu rỉ tràn sàn có nguy cơ trơn trượt té ngã. Cần thay van DN50 gấp.',
      'icon': Icons.water_drop_outlined,
      'color': AppColors.priorityHigh,
    },
    {
      'title': 'Quá nhiệt tủ điện phân phối',
      'location': 'Tủ điện số 4 - Kho vật tư',
      'text':
          'Tủ điện số 4 cạnh kho vật tư có mùi khét nồng, aptomat quá nhiệt phát tia lửa điện lẹt xẹt, cần ngắt cầu dao tổng khu vực và đội cơ điện xử lý ngay.',
      'icon': Icons.bolt_outlined,
      'color': AppColors.priorityCritical,
    },
    {
      'title': 'Nứt kết cấu dầm chịu lực',
      'location': 'Tầng 3 Block B',
      'text':
          'Phát hiện vết nứt dầm bê tông cốt thép tại trục D tầng 3 Block B, chiều dài khoảng 1.5 mét, cần kỹ sư kết cấu kiểm tra độ an toàn chịu tải.',
      'icon': Icons.foundation_outlined,
      'color': AppColors.priorityMedium,
    },
  ];

  @override
  void dispose() {
    _quickNoteController.dispose();
    super.dispose();
  }

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
      debugPrint('Lỗi tải ảnh: $e');
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
          child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 20),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 20),
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

  /// Compact attachment toolbar: Camera & GPS on a single sleek bar
  Widget _buildAttachmentToolbar(InspectionController ctrl) {
    final imagePath = ctrl.selectedImagePath;
    final gpsLoc = ctrl.taggedGpsLocation;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final hasGps = gpsLoc != null && gpsLoc.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Photo Attachment Segment
          Expanded(
            child: hasImage
                ? Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showFullScreenImage(context, imagePath),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: _buildImageWidget(imagePath),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Đã có ảnh sự cố',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        tooltip: 'Xóa ảnh',
                        onPressed: () => ctrl.clearSelectedImage(),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: () => _pickImage(ImageSource.camera),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Chụp ảnh',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Divider
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppColors.cardBorder,
          ),

          // GPS Location Segment
          Expanded(
            child: hasGps
                ? Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          gpsLoc,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                        tooltip: 'Bỏ tọa độ GPS',
                        onPressed: () => ctrl.clearTaggedGpsLocation(),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: ctrl.isFetchingLocation
                        ? null
                        : () async {
                            final loc = await ctrl.fetchGpsLocation();
                            if (loc != null && mounted) {
                              DialogHelper.showSnackBar(context, '📍 Đã gắn GPS: $loc');
                            } else if (mounted) {
                              DialogHelper.showSnackBar(
                                context,
                                '⚠️ Không thể lấy GPS. Vui lòng bật định vị thiết bị.',
                              );
                            }
                          },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (ctrl.isFetchingLocation)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.8,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            const Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            ctrl.isFetchingLocation ? 'Đang lấy vị trí...' : 'Gắn GPS',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
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

  void _showTestScenarioMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kịch bản kiểm thử mẫu',
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
              const SizedBox(height: 8),
              ..._commonScenarios.map(
                (s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: (s['color'] as Color).withValues(alpha: 0.15),
                    child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                  ),
                  title: Text(
                    s['title'] as String,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    s['location'] as String,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final ticket = await widget.controller.extractFromText(s['text'] as String);
                    if (!mounted) return;
                    if (ticket != null) {
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
                ),
              ),
            ],
          ),
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
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: widget.embeddedMode
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            title: const Text(
              'Ghi nhận hiện trường',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.playlist_add_rounded, color: AppColors.textSecondary),
                tooltip: 'Kịch bản sự cố mẫu',
                onPressed: _showTestScenarioMenu,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InAppSyncBanner(controller: ctrl),

                  // Compact Attachment Toolbar (Camera & GPS)
                  _buildAttachmentToolbar(ctrl),

                  const SizedBox(height: 36),

                  // Wave Record Button
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

                  // Recording Guidance
                  if (ctrl.state == InspectionViewState.analyzing)
                    const Column(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Đang xử lý âm thanh & lập biên bản...',
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
                          ? 'Chạm nút vuông đỏ để hoàn tất & tạo phiếu'
                          : 'Chạm micro để bắt đầu mô tả sự cố',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Sleek Live Transcript (while recording)
                  if (ctrl.isRecording) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ctrl.liveTranscript.isNotEmpty
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.cardBorder,
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
                                'Lời thoại nhận diện thời gian thực',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ctrl.liveTranscript.isNotEmpty
                                ? ctrl.liveTranscript
                                : 'Đang lắng nghe... Nêu rõ mã thiết bị, vị trí và hiện trạng hư hỏng.',
                            style: TextStyle(
                              color: ctrl.liveTranscript.isNotEmpty
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 13.5,
                              fontWeight: ctrl.liveTranscript.isNotEmpty
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Alternative input: Keyboard note
                  TextButton.icon(
                    onPressed: _showTextPromptModal,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 16),
                    label: const Text(
                      'Môi trường quá ồn? Nhập bằng bàn phím',
                      style: TextStyle(fontSize: 12),
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
