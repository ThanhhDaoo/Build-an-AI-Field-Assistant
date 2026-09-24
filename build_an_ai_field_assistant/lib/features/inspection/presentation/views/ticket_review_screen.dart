import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../domain/entities/inspection_ticket.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/swipe_to_submit_btn.dart';

/// Professional Field Inspection Report Review Form
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
  bool _isSubmitting = false;

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

    // Map initial priority to standard 3 levels if necessary
    final initialP = t.priority.toLowerCase();
    _selectedPriority = (initialP == 'critical' || initialP == 'high')
        ? (initialP == 'high' ? 'medium' : 'critical')
        : (initialP == 'low' ? 'low' : 'medium');

    _selectedCategory = t.category;

    // Initialize detected issues list
    _detectedIssues = t.detectedIssues.isNotEmpty
        ? List.from(t.detectedIssues)
        : [
            'Phát hiện sự cố rò rỉ / biến dạng kết cấu tại hiện trường',
            'Cần kiểm tra an toàn vận hành trước ca làm việc tiếp theo',
          ];

    // Initialize required parts list
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

  // --- Helpers for Parts Management ---
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
          title: const Row(
            children: [
              Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Thêm linh kiện / vật tư',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tên linh kiện hoặc mã vật tư:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                decoration: _inputDecoration(hint: 'Ví dụ: Gioăng chịu nhiệt DN50...'),
              ),
              const SizedBox(height: 14),
              const Text('Số lượng yêu cầu:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
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

  // --- Helpers for Detected Issues Management ---
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
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: AppColors.priorityHigh, size: 20),
            SizedBox(width: 8),
            Text(
              'Thêm hiện tượng lỗi phát hiện',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: TextField(
          controller: issueCtrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
          decoration: _inputDecoration(hint: 'Mô tả ngắn gọn lỗi phát hiện tại hiện trường...'),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Metadata Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
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
                    const Expanded(
                      child: Text(
                        'Biên bản tiếp nhận từ giọng nói • Rà soát & duyệt thông tin',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Audio Playback Bar (if available)
              if (widget.initialTicket.audioPath != null &&
                  widget.initialTicket.audioPath!.isNotEmpty) ...[
                _AudioPlaybackCard(audioPath: widget.initialTicket.audioPath!),
                const SizedBox(height: 16),
              ],

              // Speech-to-Text Extracted Transcript Card
              if (widget.initialTicket.rawTranscript != null &&
                  widget.initialTicket.rawTranscript!.isNotEmpty) ...[
                _buildCardContainer(
                  title: 'VĂN BẢN BÓC BĂNG GIỌNG NÓI (TRANSCRIPT)',
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Lời thoại nhận diện từ âm thanh:',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AI trích xuất tự động',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        widget.initialTicket.rawTranscript!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // --- YÊU CẦU 1: Trường mã thiết bị / xe được AI bóc tách tự động ---
              _buildCardContainer(
                title: 'ĐỊNH DANH THIẾT BỊ / PHƯƠNG TIỆN',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mã thiết bị / Xe cơ giới',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: AppColors.primary, size: 11),
                            SizedBox(width: 4),
                            Text(
                              'AI BÓC TÁCH',
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
                  TextField(
                    controller: _equipmentIdController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                    decoration: _inputDecoration(
                      hint: 'Ví dụ: PUMP-02, XE-NANG-01, TỦ-ĐIỆN-04...',
                      prefixIcon: Icons.precision_manufacturing_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- YÊU CẦU 2: Selector chọn mức ưu tiên: Thấp (Xanh), Trung bình (Vàng), Khẩn cấp (Đỏ) ---
              _buildCardContainer(
                title: 'MỨC ĐỘ KHẨN CẤP / ƯU TIÊN XỬ LÝ',
                children: [
                  _buildPrioritySelector(),
                  const SizedBox(height: 14),
                  _buildFieldLabel('Danh mục kỹ thuật'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.categories.map((c) {
                      final isSelected = _selectedCategory.toLowerCase() == c;
                      return ChoiceChip(
                        label: Text(_getCategoryLabel(c)),
                        avatar: Icon(
                          _getCategoryIcon(c),
                          size: 15,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primaryDark,
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12,
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

              const SizedBox(height: 16),

              // --- YÊU CẦU 3: Danh sách lỗi phát hiện hiển thị dạng thẻ (Cards) ---
              _buildCardContainer(
                title: 'DANH SÁCH LỖI / HIỆN TƯỢNG PHÁT HIỆN',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tổng số lỗi ghi nhận: ${_detectedIssues.length}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddIssueDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: const Text('Thêm lỗi', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_detectedIssues.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa ghi nhận lỗi cụ thể nào. Nhấn "+ Thêm lỗi" để bổ sung.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        ),
                      ),
                    )
                  else
                    ..._detectedIssues.asMap().entries.map((entry) {
                      final index = entry.key;
                      final issue = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.priorityHigh.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.priorityHigh.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                color: AppColors.priorityHigh,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                issue,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() => _detectedIssues.removeAt(index));
                              },
                              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                              tooltip: 'Xóa thẻ lỗi này',
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),

              const SizedBox(height: 16),

              // --- YÊU CẦU 4: Danh sách linh kiện kèm nút + / - để tăng giảm số lượng nhanh ---
              _buildCardContainer(
                title: 'VẬT TƯ & LINH KIỆN THAY THẾ',
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Danh sách vật tư cần dùng: ${_requiredParts.length}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddPartDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: const Text('Thêm vật tư', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_requiredParts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa có linh kiện yêu cầu. Nhấn "+ Thêm vật tư" để chỉ định.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                        ),
                      ),
                    )
                  else
                    ..._requiredParts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final part = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                part.name,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Quick Quantity Incrementor / Decrementor
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => _decrementPart(index),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.remove_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    color: AppColors.surfaceLight,
                                    child: Text(
                                      '${part.quantity}',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => _incrementPart(index),
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),

              const SizedBox(height: 16),

              // Thông tin sự cố cơ bản
              _buildCardContainer(
                title: 'THÔNG TIN SỰ CỐ & HIỆN TRƯỜNG',
                children: [
                  _buildFieldLabel('Tiêu đề biên bản'),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: _inputDecoration(hint: 'Nhập tiêu đề sự cố...'),
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel('Vị trí hiện trường'),
                  TextField(
                    controller: _locationController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                    decoration: _inputDecoration(
                      hint: 'Ví dụ: Phân xưởng cán thép 2, Trạm biến áp T1...',
                      prefixIcon: Icons.place_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel('Mô tả hiện trạng chi tiết'),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.4),
                    decoration: _inputDecoration(hint: 'Mô tả chi tiết sự cố phát hiện tại hiện trường...'),
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel('Hành động đề xuất khắc phục'),
                  TextField(
                    controller: _actionController,
                    maxLines: 2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, height: 1.4),
                    decoration: _inputDecoration(hint: 'Khuyến nghị giải pháp kỹ thuật tức thời...'),
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel('Người lập biên bản'),
                  TextField(
                    controller: _inspectorController,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                    decoration: _inputDecoration(
                      hint: 'Tên kỹ sư kiểm tra...',
                      prefixIcon: Icons.person_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- YÊU CẦU 5: Nút trượt để gửi (Swipe to Submit) thay vì nút bấm thông thường ---
              SwipeToSubmitButton(
                onSubmit: _handleSubmit,
                isLoading: _isSubmitting,
                label: 'Vuốt để duyệt & gửi biên bản',
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Selector chọn mức ưu tiên: Thấp (Xanh), Trung bình (Vàng), Khẩn cấp (Đỏ)
  Widget _buildPrioritySelector() {
    final options = [
      {
        'key': 'low',
        'label': 'Thấp',
        'color': AppColors.priorityLow, // Xanh lá (#10B981)
        'icon': Icons.check_circle_outline_rounded,
        'desc': 'Bảo dưỡng / Theo dõi',
      },
      {
        'key': 'medium',
        'label': 'Trung bình',
        'color': AppColors.priorityMedium, // Vàng hổ phách (#F59E0B)
        'icon': Icons.warning_amber_rounded,
        'desc': 'Xử lý trong 24-48h',
      },
      {
        'key': 'critical',
        'label': 'Khẩn cấp',
        'color': AppColors.priorityCritical, // Đỏ alert (#EF4444)
        'icon': Icons.local_fire_department_rounded,
        'desc': 'Dừng máy / Nguy hiểm',
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
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedPriority = key);
                },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.18) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? color : AppColors.cardBorder,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(icon, color: color, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        opt['desc'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? color : AppColors.textMuted,
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardContainer({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.background,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textMuted, size: 18) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          IconButton(
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
              size: 32,
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
                    fontSize: 13,
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
