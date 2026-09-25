import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../domain/entities/inspection_ticket.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/in_app_sync_banner.dart';
import '../widgets/swipe_to_submit_btn.dart';

/// Clean Enterprise Field Inspection Report Review Form
class TicketReviewScreen extends StatefulWidget {
  final InspectionController controller;
  final InspectionTicket initialTicket;

  const TicketReviewScreen({
    super.key,
    required this.controller,
    required this.initialTicket,
  });

  @override
  State<TicketReviewScreen> createState() => _TicketReviewScreenState();
}

class _TicketReviewScreenState extends State<TicketReviewScreen> {
  late TextEditingController _titleController;
  late TextEditingController _equipmentIdController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _actionController;
  late TextEditingController _inspectorController;

  late String _selectedPriority;
  late String _selectedCategory;
  late List<String> _detectedIssues;
  late List<InspectionPart> _requiredParts;
  String? _currentImagePath;
  bool _isSubmitting = false;
  bool _isFetchingGps = false;

  Future<void> _fetchAndApplyGps() async {
    setState(() => _isFetchingGps = true);
    try {
      final loc = await widget.controller.fetchGpsLocation();
      if (loc != null && mounted) {
        if (_locationController.text.trim().isEmpty ||
            _locationController.text.contains('chưa rõ')) {
          _locationController.text = loc;
        } else if (!_locationController.text.contains('GPS')) {
          _locationController.text = '${_locationController.text.trim()} - $loc';
        }
        DialogHelper.showSnackBar(context, '📍 Đã lấy tọa độ GPS: $loc');
      } else if (mounted) {
        DialogHelper.showSnackBar(
          context,
          '⚠️ Không thể lấy tọa độ GPS. Vui lòng kiểm tra quyền và bật GPS thiết bị.',
        );
      }
    } catch (e) {
      if (mounted) {
        DialogHelper.showSnackBar(context, '⚠️ Lỗi GPS: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingGps = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final t = widget.initialTicket;
    _titleController = TextEditingController(text: t.title);
    _equipmentIdController = TextEditingController(text: t.equipmentId ?? '');
    _locationController = TextEditingController(text: t.location);
    _descriptionController = TextEditingController(text: t.description);
    _actionController = TextEditingController(text: t.suggestedAction);
    _inspectorController = TextEditingController(text: t.inspectorName);
    _currentImagePath = t.imagePath;

    final initialP = t.priority.toLowerCase();
    _selectedPriority = (initialP == 'critical' || initialP == 'high')
        ? (initialP == 'high' ? 'medium' : 'critical')
        : (initialP == 'low' ? 'low' : 'medium');

    _selectedCategory = t.category;

    _detectedIssues = t.detectedIssues.isNotEmpty
        ? List.from(t.detectedIssues)
        : [
            'Phát hiện sự cố rò rỉ / biến dạng kết cấu tại hiện trường',
            'Cần kiểm tra an toàn vận hành trước ca làm việc tiếp theo',
          ];

    _requiredParts = t.requiredParts.isNotEmpty
        ? List.from(t.requiredParts)
        : [
            const InspectionPart(name: 'Gioăng chịu dầu áp lực cao', quantity: 2),
            const InspectionPart(name: 'Bu-lông siết mặt bích M12', quantity: 4),
          ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _equipmentIdController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _actionController.dispose();
    _inspectorController.dispose();
    super.dispose();
  }

  InspectionTicket _buildCurrentTicket() {
    return widget.initialTicket.copyWith(
      title: _titleController.text.trim(),
      equipmentId: _equipmentIdController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      suggestedAction: _actionController.text.trim(),
      inspectorName: _inspectorController.text.trim(),
      priority: _selectedPriority,
      category: _selectedCategory,
      detectedIssues: _detectedIssues,
      requiredParts: _requiredParts,
      imagePath: _currentImagePath,
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    final updated = _buildCurrentTicket();
    widget.controller.updateDraftTicket(updated);

    final success = await widget.controller.submitDraftTicket();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      DialogHelper.showSnackBar(
        context,
        widget.controller.isOnline
            ? 'Đã duyệt & gửi biên bản lên hệ thống'
            : 'Đã lưu offline. Hệ thống sẽ tự đồng bộ khi có mạng!',
      );
      Navigator.of(context).pop();
    } else {
      DialogHelper.showSnackBar(
        context,
        'Không thể lưu biên bản. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  void _incrementPart(int index) {
    setState(() {
      final part = _requiredParts[index];
      _requiredParts[index] = part.copyWith(quantity: part.quantity + 1);
    });
  }

  void _decrementPart(int index) {
    setState(() {
      final part = _requiredParts[index];
      if (part.quantity > 1) {
        _requiredParts[index] = part.copyWith(quantity: part.quantity - 1);
      } else {
        _requiredParts.removeAt(index);
      }
    });
  }

  void _showAddPartDialog() {
    final nameCtrl = TextEditingController();
    int qty = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          title: const Text(
            'Thêm vật tư / linh kiện',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tên linh kiện hoặc mã vật tư:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                decoration: _inputDecoration(hint: 'Ví dụ: Gioăng chịu nhiệt DN50...'),
              ),
              const SizedBox(height: 14),
              const Text('Số lượng yêu cầu:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (qty > 1) setDlgState(() => qty--);
                    },
                    style: IconButton.styleFrom(backgroundColor: AppColors.background),
                    icon: const Icon(Icons.remove, color: AppColors.textPrimary, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setDlgState(() => qty++),
                    style: IconButton.styleFrom(backgroundColor: AppColors.background),
                    icon: const Icon(Icons.add, color: AppColors.textPrimary, size: 18),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _requiredParts.add(InspectionPart(name: name, quantity: qty));
                  });
                  Navigator.of(ctx).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIssueDialog() {
    final issueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text(
          'Thêm hiện tượng lỗi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: issueCtrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration: _inputDecoration(hint: 'Mô tả ngắn gọn lỗi phát hiện...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = issueCtrl.text.trim();
              if (text.isNotEmpty) {
                setState(() => _detectedIssues.add(text));
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageForTicket(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _currentImagePath = pickedFile.path);
      }
    } catch (e) {
      debugPrint('Lỗi chọn/chụp ảnh: $e');
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

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'electrical':
        return 'Điện lực';
      case 'mechanical':
        return 'Cơ khí / Van';
      case 'civil':
        return 'Xây dựng';
      case 'safety':
        return 'An toàn / PCCC';
      case 'hvac':
        return 'HVAC / Làm mát';
      case 'general':
      default:
        return 'Chung / Khác';
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'electrical':
        return Icons.bolt_rounded;
      case 'mechanical':
        return Icons.build_rounded;
      case 'civil':
        return Icons.foundation_rounded;
      case 'safety':
        return Icons.health_and_safety_rounded;
      case 'hvac':
        return Icons.ac_unit_rounded;
      case 'general':
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Duyệt biên bản kiểm tra',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InAppSyncBanner(controller: widget.controller),

              // ================= SECTION 1: THIẾT BỊ & ĐỘ ƯU TIÊN =================
              _buildSectionContainer(
                title: 'Thông tin thiết bị & Mức độ ưu tiên',
                icon: Icons.precision_manufacturing_rounded,
                children: [
                  // Photo Inspection Display
                  if (_currentImagePath != null && _currentImagePath!.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => _showFullScreenImage(context, _currentImagePath!),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildImageWidget(_currentImagePath!),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Chạm để phóng to',
                                          style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _pickImageForTicket(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 14),
                          label: const Text('Chụp lại', style: TextStyle(fontSize: 11.5)),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => _currentImagePath = null),
                          style: TextButton.styleFrom(foregroundColor: AppColors.priorityHigh),
                          icon: const Icon(Icons.delete_outline_rounded, size: 14),
                          label: const Text('Xóa ảnh', style: TextStyle(fontSize: 11.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: () => _pickImageForTicket(ImageSource.camera),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                      label: const Text('Bổ sung ảnh hiện trường (Tùy chọn)',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Mã thiết bị / Phương tiện
                  _buildFieldLabel('Mã thiết bị / Phương tiện'),
                  TextField(
                    controller: _equipmentIdController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Ví dụ: PUMP-01, ELEC-04, XE-NANG-02...',
                      prefixIcon: Icons.qr_code_rounded,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tiêu đề sự cố
                  _buildFieldLabel('Tiêu đề biên bản sự cố'),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(hint: 'Mô tả ngắn gọn sự cố...'),
                  ),

                  const SizedBox(height: 14),

                  // Mức độ ưu tiên
                  _buildFieldLabel('Mức độ ưu tiên xử lý'),
                  _buildPrioritySelector(),

                  const SizedBox(height: 14),

                  // Phân loại kỹ thuật
                  _buildFieldLabel('Phân loại kỹ thuật'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: AppConstants.categories.map((c) {
                      final isSelected = _selectedCategory.toLowerCase() == c;
                      return ChoiceChip(
                        label: Text(_getCategoryLabel(c)),
                        avatar: Icon(
                          _getCategoryIcon(c),
                          size: 14,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryDark,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          ),
                        ),
                        onSelected: (_) {
                          setState(() => _selectedCategory = c);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ================= SECTION 2: HIỆN TRƯỜNG & CHI TIẾT SỰ CỐ =================
              _buildSectionContainer(
                title: 'Hiện trường & Chi tiết sự cố',
                icon: Icons.location_on_rounded,
                children: [
                  // Vị trí & GPS 1-touch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Vị trí hiện trường'),
                      InkWell(
                        onTap: _isFetchingGps ? null : _fetchAndApplyGps,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isFetchingGps)
                                const SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: AppColors.primary,
                                  ),
                                )
                              else
                                const Icon(Icons.my_location_rounded,
                                    size: 13, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                _isFetchingGps ? 'Đang lấy...' : 'GPS 1-chạm',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _locationController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: _inputDecoration(
                      hint: 'Ví dụ: Phân xưởng cán thép 2, Trạm biến áp T1...',
                      prefixIcon: Icons.place_outlined,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.gps_fixed_rounded, size: 16, color: AppColors.primary),
                        tooltip: 'Lấy tọa độ GPS',
                        onPressed: _isFetchingGps ? null : _fetchAndApplyGps,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Audio playback (if recorded)
                  if (widget.initialTicket.audioPath != null &&
                      widget.initialTicket.audioPath!.isNotEmpty) ...[
                    _AudioPlaybackCard(audioPath: widget.initialTicket.audioPath!),
                    const SizedBox(height: 10),
                  ],

                  // Transcript quote
                  if (widget.initialTicket.rawTranscript != null &&
                      widget.initialTicket.rawTranscript!.isNotEmpty) ...[
                    _buildFieldLabel('Lời thoại ghi âm hiện trường'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        widget.initialTicket.rawTranscript!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Mô tả chi tiết
                  _buildFieldLabel('Mô tả hiện trạng kỹ thuật'),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                    decoration: _inputDecoration(hint: 'Mô tả chi tiết sự cố phát hiện...'),
                  ),

                  const SizedBox(height: 14),

                  // Danh sách lỗi phát hiện
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Danh sách hiện tượng lỗi'),
                      TextButton.icon(
                        onPressed: _showAddIssueDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
                        label: const Text('Thêm lỗi', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  if (_detectedIssues.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa ghi nhận lỗi cụ thể nào.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ..._detectedIssues.asMap().entries.map((entry) {
                      final index = entry.key;
                      final issue = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.priorityHigh.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.priorityHigh, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                issue,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() => _detectedIssues.removeAt(index));
                              },
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.textMuted, size: 16),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),

              const SizedBox(height: 14),

              // ================= SECTION 3: VẬT TƯ & KHẮC PHỤC =================
              _buildSectionContainer(
                title: 'Vật tư & Biện pháp khắc phục',
                icon: Icons.inventory_2_outlined,
                children: [
                  // Danh mục vật tư
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Linh kiện & Vật tư cần dùng'),
                      TextButton.icon(
                        onPressed: _showAddPartDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                        label: const Text('Thêm vật tư', style: TextStyle(fontSize: 11.5)),
                      ),
                    ],
                  ),
                  if (_requiredParts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa chỉ định vật tư thay thế.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ..._requiredParts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final part = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.build_outlined,
                                color: AppColors.textSecondary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                part.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Quick Quantity Incrementor / Decrementor
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _decrementPart(index),
                                    child: const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.remove_rounded,
                                          size: 15, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    color: AppColors.surfaceLight,
                                    child: Text(
                                      '${part.quantity}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _incrementPart(index),
                                    child: const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Icon(Icons.add_rounded,
                                          size: 15, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 14),

                  // Hành động khắc phục đề xuất
                  _buildFieldLabel('Hành động khắc phục đề xuất'),
                  TextField(
                    controller: _actionController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                    decoration: _inputDecoration(hint: 'Giải pháp xử lý tức thời hoặc kế hoạch sửa chữa...'),
                  ),

                  const SizedBox(height: 12),

                  // Người lập biên bản
                  _buildFieldLabel('Kỹ sư lập biên bản'),
                  TextField(
                    controller: _inspectorController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: _inputDecoration(
                      hint: 'Tên kỹ sư kiểm tra...',
                      prefixIcon: Icons.badge_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Swipe to Submit Button
              SwipeToSubmitButton(
                onSubmit: _handleSubmit,
                isLoading: _isSubmitting,
                label: 'Vuốt để duyệt & gửi biên bản',
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  /// 3-State Priority Selector
  Widget _buildPrioritySelector() {
    final options = [
      {
        'key': 'low',
        'label': 'Thấp',
        'color': AppColors.priorityLow,
        'icon': Icons.check_circle_outline_rounded,
        'desc': 'Theo dõi',
      },
      {
        'key': 'medium',
        'label': 'Trung bình',
        'color': AppColors.priorityMedium,
        'icon': Icons.warning_amber_rounded,
        'desc': 'Trong 24-48h',
      },
      {
        'key': 'critical',
        'label': 'Khẩn cấp',
        'color': AppColors.priorityCritical,
        'icon': Icons.error_outline_rounded,
        'desc': 'Dừng máy ngay',
      },
    ];

    return Row(
      children: options.map((opt) {
        final key = opt['key'] as String;
        final label = opt['label'] as String;
        final color = opt['color'] as Color;
        final icon = opt['icon'] as IconData;
        final isSelected = _selectedPriority == key;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: InkWell(
              onTap: () {
                setState(() => _selectedPriority = key);
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt['desc'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Clean section container replacing cluttered separate cards
  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      filled: true,
      fillColor: AppColors.background,
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: AppColors.textMuted, size: 16) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

/// Internal Audio Playback Card for listening to captured field audio
class _AudioPlaybackCard extends StatefulWidget {
  final String audioPath;

  const _AudioPlaybackCard({required this.audioPath});

  @override
  State<_AudioPlaybackCard> createState() => _AudioPlaybackCardState();
}

class _AudioPlaybackCardState extends State<_AudioPlaybackCard> {
  late final AudioPlayerService _playerService;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  @override
  void initState() {
    super.initState();
    _playerService = sl<AudioPlayerService>();

    _stateSub = _playerService.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });

    _posSub = _playerService.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _durSub = _playerService.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playerService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              if (_isPlaying) {
                _playerService.pause();
              } else {
                _playerService.play(widget.audioPath);
              }
            },
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bản ghi âm giọng nói hiện trường',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormatter.formatDuration(_position)} / ${DateFormatter.formatDuration(_duration)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
