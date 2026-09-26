import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../domain/entities/inspection_ticket.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/in_app_sync_banner.dart';
import '../widgets/inspection_image_widget.dart';
import '../widgets/priority_badge_chip.dart';
import 'ticket_history_screen.dart';
import 'ticket_review_screen.dart';
import 'voice_capture_screen.dart';

/// Modern Production-grade Mobile Navigation Shell
class MainShellScreen extends StatefulWidget {
  final InspectionController controller;

  const MainShellScreen({
    super.key,
    required this.controller,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _showSettingsModal() async {
    final prefs = await SharedPreferences.getInstance();
    final currentKey = prefs.getString(AppConstants.keyGeminiApiKey) ?? '';
    final textController = TextEditingController(text: currentKey);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Cài đặt & Cấu hình hệ thống',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Google Gemini API Key',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: textController,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhập AIzaSy...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.textMuted, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            const SizedBox(height: 8),
            const Text(
              'Nếu không có API key, hệ thống sẽ sử dụng bộ xử lý NLP cục bộ (Offline-first) dự phòng.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, height: 1.3),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await prefs.setString(
                        AppConstants.keyGeminiApiKey,
                        textController.text.trim(),
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        DialogHelper.showSnackBar(context, 'Đã lưu cấu hình API Key');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Lưu cấu hình'),
                  ),
                ),
              ],
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
          body: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: [
                  _DashboardTabView(
                    controller: ctrl,
                    onNavigateToRecord: () => setState(() => _currentIndex = 1),
                    onOpenSettings: _showSettingsModal,
                  ),
                  VoiceCaptureScreen(
                    controller: ctrl,
                    embeddedMode: true,
                  ),
                  TicketHistoryScreen(
                    controller: ctrl,
                    embeddedMode: true,
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: InAppSyncBanner(controller: ctrl),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.cardBorder, width: 1),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: AppColors.surface,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard_rounded),
                  label: 'Tổng quan',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 1 ? AppColors.primary : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      color: _currentIndex == 1 ? Colors.white : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  label: 'Thu âm',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.receipt_long_outlined),
                      if (ctrl.pendingCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.priorityHigh,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '${ctrl.pendingCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: const Icon(Icons.receipt_long_rounded),
                  label: 'Biên bản',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Professional Dashboard Tab View
class _DashboardTabView extends StatefulWidget {
  final InspectionController controller;
  final VoidCallback onNavigateToRecord;
  final VoidCallback onOpenSettings;

  const _DashboardTabView({
    required this.controller,
    required this.onNavigateToRecord,
    required this.onOpenSettings,
  });

  @override
  State<_DashboardTabView> createState() => _DashboardTabViewState();
}

class _DashboardTabViewState extends State<_DashboardTabView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String _activeFilter = 'all'; // 'all', 'pending', 'critical'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showManualEntrySheet() {
    final noteController = TextEditingController();
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
                      'Tạo biên bản thủ công',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú hiện trường: Vị trí, thiết bị, hiện trạng sự cố...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final text = noteController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.of(ctx).pop();

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
                icon: const Icon(Icons.fact_check_rounded, size: 18),
                label: const Text('Tạo biên bản sự cố', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final allTickets = ctrl.tickets;
    final criticalCount = allTickets.where((t) => t.priority.toLowerCase() == 'critical').length;

    // Filter by active category segment & search query
    final filteredByFilter = allTickets.where((t) {
      if (_activeFilter == 'pending') {
        return !t.isSynced;
      } else if (_activeFilter == 'critical') {
        return t.priority.toLowerCase() == 'critical';
      }
      return true;
    }).toList();

    // Filter by search
    final displayedTickets = _searchQuery.isEmpty
        ? filteredByFilter
        : filteredByFilter.where((t) {
            final q = _searchQuery.toLowerCase();
            return t.title.toLowerCase().contains(q) ||
                t.location.toLowerCase().contains(q) ||
                t.description.toLowerCase().contains(q);
          }).toList();

    return SafeArea(
      child: Column(
        children: [
          // Top Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Inspector Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kỹ sư hiện trường',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Giám sát & Quản lý thiết bị',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Online/Offline status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ctrl.isOnline
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.statusPending.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ctrl.isOnline ? AppColors.primary : AppColors.statusPending,
                      width: 1,
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
                      const SizedBox(width: 5),
                      Text(
                        ctrl.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: ctrl.isOnline ? AppColors.primary : AppColors.statusPending,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Settings icon button
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 22),
                  onPressed: widget.onOpenSettings,
                  tooltip: 'Cài đặt hệ thống',
                ),
              ],
            ),
          ),

          // Main Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  // Harmonious Filter Pill Row (Thiết kế hòa quyện chuẩn Linear / GitHub)
                  Row(
                    children: [
                      // 1. Tất cả
                      Expanded(
                        child: _buildFilterPill(
                          label: 'Tất cả',
                          count: allTickets.length,
                          isSelected: _activeFilter == 'all',
                          onTap: () => setState(() => _activeFilter = 'all'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Chờ sync
                      Expanded(
                        child: _buildFilterPill(
                          label: 'Chờ sync',
                          count: ctrl.pendingCount,
                          isPending: ctrl.pendingCount > 0,
                          isSelected: _activeFilter == 'pending',
                          onTap: () => setState(() => _activeFilter = 'pending'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3. Khẩn cấp
                      Expanded(
                        child: _buildFilterPill(
                          label: 'Khẩn cấp',
                          count: criticalCount,
                          isCritical: criticalCount > 0,
                          isSelected: _activeFilter == 'critical',
                          onTap: () => setState(() => _activeFilter = 'critical'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Quick Action Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.surface,
                          AppColors.surfaceLight.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thao tác nhanh hiện trường',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Thu âm trực tiếp mô tả sự cố hoặc nhập nhanh biên bản.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onNavigateToRecord,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.mic_rounded, size: 18),
                                label: const Text('Thu âm sự cố', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showManualEntrySheet,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(color: AppColors.cardBorder),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.edit_note_rounded, size: 18),
                                label: const Text('Nhập tay', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Search Field & Recent Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Danh sách biên bản',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_activeFilter != 'all') ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _activeFilter = 'all'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBorder.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _activeFilter == 'pending' ? 'Chờ sync' : 'Khẩn cấp',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.close_rounded, size: 12, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (ctrl.pendingCount > 0 && ctrl.isOnline)
                        GestureDetector(
                          onTap: () => ctrl.syncAllPending(),
                          child: const Row(
                            children: [
                              Icon(Icons.sync_rounded, color: AppColors.primary, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Đồng bộ tất cả',
                                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search box
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo sự cố hoặc vị trí...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surface,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.cardBorder),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tickets List
                  if (displayedTickets.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.assignment_outlined, color: AppColors.textMuted, size: 36),
                          SizedBox(height: 10),
                          Text(
                            'Chưa có biên bản kiểm tra nào',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else
                    ...displayedTickets.take(6).map((ticket) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildTicketItem(context, ticket, ctrl),
                        )),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    bool isPending = false,
    bool isCritical = false,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Theme-harmonized accent color based on filter type
    final Color activeAccent = isCritical && count > 0
        ? AppColors.priorityCritical
        : (isPending && count > 0 ? AppColors.statusPending : AppColors.primary);

    final Color backgroundColor = isSelected
        ? activeAccent.withValues(alpha: 0.1)
        : AppColors.surface;

    final Color borderColor = isSelected
        ? activeAccent
        : AppColors.cardBorder;

    final Color textColor = isSelected
        ? activeAccent
        : AppColors.textSecondary;

    final Color badgeBg = isSelected
        ? activeAccent
        : (isCritical && count > 0
            ? AppColors.priorityCritical.withValues(alpha: 0.12)
            : (isPending && count > 0
                ? AppColors.statusPending.withValues(alpha: 0.12)
                : AppColors.surfaceLight));

    final Color badgeTextColor = isSelected
        ? Colors.white
        : (isCritical && count > 0
            ? AppColors.priorityCritical
            : (isPending && count > 0
                ? AppColors.statusPending
                : AppColors.textSecondary));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketItem(BuildContext context, InspectionTicket ticket, InspectionController ctrl) {
    final hasImage = ticket.imagePath != null && ticket.imagePath!.isNotEmpty;
    final hasAudio = ticket.audioPath != null && ticket.audioPath!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TicketReviewScreen(
                controller: ctrl,
                initialTicket: ticket,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                InspectionImageWidget(
                  imagePath: ticket.imagePath!,
                  width: 58,
                  height: 58,
                  borderRadius: BorderRadius.circular(8),
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PriorityBadgeChip(priority: ticket.priority),
                        Row(
                          children: [
                            if (hasAudio) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.mic_rounded, size: 11, color: AppColors.primary),
                                    SizedBox(width: 2),
                                    Text('Voice', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                            Icon(
                              ticket.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                              size: 14,
                              color: ticket.isSynced ? AppColors.statusSynced : AppColors.statusPending,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.isSynced ? 'Đã sync' : 'Chờ sync',
                              style: TextStyle(
                                fontSize: 11,
                                color: ticket.isSynced ? AppColors.statusSynced : AppColors.statusPending,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, color: AppColors.textMuted, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ticket.location,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormatter.formatTimeAgo(ticket.createdAt),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
