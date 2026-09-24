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
import '../widgets/priority_badge_chip.dart';
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
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _actionController;
  late TextEditingController _inspectorController;

  late String _selectedPriority;
  late String _selectedCategory;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTicket;
    _titleController = TextEditingController(text: t.title);
    _locationController = TextEditingController(text: t.location);
    _descriptionController = TextEditingController(text: t.description);
    _actionController = TextEditingController(text: t.suggestedAction);
    _inspectorController = TextEditingController(text: t.inspectorName);
    _selectedPriority = t.priority;
    _selectedCategory = t.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _actionController.dispose();
    _inspectorController.dispose();
    super.dispose();
  }

  InspectionTicket _buildCurrentTicket() {
    return widget.initialTicket.copyWith(
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      suggestedAction: _actionController.text.trim(),
      inspectorName: _inspectorController.text.trim(),
      priority: _selectedPriority,
      category: _selectedCategory,
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
                        'Biên bản tiếp nhận từ giọng nói • Vui lòng rà soát lại thông tin',
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
                            'Trích xuất tự động',
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

              // Card Section 1: Thông tin cơ bản
              _buildCardContainer(
                title: 'THÔNG TIN SỰ CỐ',
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
                ],
              ),

              const SizedBox(height: 16),

              // Card Section 2: Đánh giá & Phân loại
              _buildCardContainer(
                title: 'PHÂN LOẠI & MỨC ĐỘ KHẨN CẤP',
                children: [
                  _buildFieldLabel('Mức độ ưu tiên'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.priorities.map((p) {
                      return PriorityBadgeChip(
                        priority: p,
                        isInteractive: true,
                        isSelected: _selectedPriority.toLowerCase() == p,
                        onSelected: (val) {
                          setState(() => _selectedPriority = val);
                        },
                      );
                    }).toList(),
                  ),
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

              // Card Section 3: Hiện trạng & Đề xuất
              _buildCardContainer(
                title: 'HIỆN TRẠNG & BIỆN PHÁP XỬ LÝ',
                children: [
                  _buildFieldLabel('Mô tả hiện trạng'),
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

              const SizedBox(height: 16),



              // Swipe to Submit / Confirm Action
              SwipeToSubmitButton(
                onSubmit: _handleSubmit,
                isLoading: _isSubmitting,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
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
