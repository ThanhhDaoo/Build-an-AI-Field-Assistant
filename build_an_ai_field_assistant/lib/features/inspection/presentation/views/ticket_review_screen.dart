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

/// Review & Edit Screen for AI-extracted Inspection Ticket
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
  final bool _showRawTranscript = false;

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
            ? 'Đã gửi biên bản lên hệ thống thành công!'
            : 'Đã lưu offline. Biên bản sẽ tự động đồng bộ khi có mạng!',
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
        return 'Điện / Tủ điện';
      case 'mechanical':
        return 'Cơ khí / Van';
      case 'civil':
        return 'Xây dựng / Kết cấu';
      case 'safety':
        return 'An toàn / PCCC';
      case 'hvac':
        return 'HVAC / Thông gió';
      case 'general':
      default:
        return 'Khác / Tổng quát';
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
    final confidencePct = (widget.initialTicket.confidenceScore * 100).toInt();

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
          'Duyệt biên bản AI tự điền',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Confidence Badge Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primaryLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gemini AI đã tự động điền form • Độ tin cậy: $confidencePct%',
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Title Field
              _buildSectionLabel('Tiêu đề sự cố:'),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                decoration: _inputDecoration(
                  hint: 'Nhập tiêu đề biên bản kiểm tra...',
                  prefixIcon: Icons.title_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // Location Field
              _buildSectionLabel('Vị trí phát hiện:'),
              TextField(
                controller: _locationController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Nhập vị trí cụ thể trong nhà máy...',
                  prefixIcon: Icons.place_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // Priority Selector
              _buildSectionLabel('Mức độ ưu tiên:'),
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

              const SizedBox(height: 16),

              // Category Selector
              _buildSectionLabel('Danh mục kỹ thuật:'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.categories.map((c) {
                  final isSelected = _selectedCategory.toLowerCase() == c;
                  return ChoiceChip(
                    label: Text(_getCategoryLabel(c)),
                    avatar: Icon(
                      _getCategoryIcon(c),
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryDark,
                    backgroundColor: AppColors.surface,
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

              const SizedBox(height: 16),

              // Description Field
              _buildSectionLabel('Mô tả hiện trạng:'),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                decoration: _inputDecoration(
                  hint: 'Mô tả chi tiết biểu hiện của sự cố...',
                  prefixIcon: Icons.description_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // Suggested Action
              _buildSectionLabel('Hành động đề xuất khắc phục:'),
              TextField(
                controller: _actionController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.4),
                decoration: _inputDecoration(
                  hint: 'Khuyến nghị giải pháp kỹ thuật...',
                  prefixIcon: Icons.handyman_rounded,
                ),
              ),

              const SizedBox(height: 16),

              // Inspector Name
              _buildSectionLabel('Người lập biên bản:'),
              TextField(
                controller: _inspectorController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration(
                  hint: 'Tên kỹ sư hiện trường...',
                  prefixIcon: Icons.person_rounded,
                ),
              ),

              const SizedBox(height: 20),

              // Audio Playback Preview (if audio was recorded)
              if (widget.initialTicket.audioPath != null &&
                  widget.initialTicket.audioPath!.isNotEmpty) ...[
                _AudioPlaybackCard(audioPath: widget.initialTicket.audioPath!),
                const SizedBox(height: 16),
              ],

              // Original Voice Transcript Expansion (if available)
              if (widget.initialTicket.rawTranscript != null &&
                  widget.initialTicket.rawTranscript!.isNotEmpty) ...[
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    initiallyExpanded: _showRawTranscript,
                    title: const Text(
                      'Xem bản ghi âm thô (Transcript)',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Text(
                          widget.initialTicket.rawTranscript!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Swipe to Submit Button
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

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface,
      prefixIcon: Icon(prefixIcon, color: AppColors.textMuted, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
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
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _posSub = _playerService.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _durSub = _playerService.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
              _isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              size: 36,
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

