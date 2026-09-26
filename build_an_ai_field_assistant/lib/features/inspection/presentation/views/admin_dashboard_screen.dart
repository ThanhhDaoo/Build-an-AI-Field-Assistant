import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/report_export_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../domain/entities/inspection_ticket.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/inspection_image_widget.dart';
import '../widgets/priority_badge_chip.dart';
import 'ticket_review_screen.dart';

/// Bảng điều khiển Quản trị & Điều độ Sự cố Hiện trường (Admin Operations Dashboard)
class AdminDashboardScreen extends StatefulWidget {
  final InspectionController controller;
  final VoidCallback? onSwitchToFieldMode;

  const AdminDashboardScreen({
    super.key,
    required this.controller,
    this.onSwitchToFieldMode,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchQuery = '';
  String _selectedPriorityFilter = 'all'; // 'all', 'critical', 'high', 'medium', 'low'
  String _selectedStatusFilter = 'all'; // 'all', 'pending_review', 'in_progress', 'resolved', 'closed'
  bool _isExporting = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InspectionTicket> _getFilteredTickets(List<InspectionTicket> allTickets) {
    return allTickets.where((ticket) {
      // 1. Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = ticket.title.toLowerCase().contains(query);
        final matchDesc = ticket.description.toLowerCase().contains(query);
        final matchLocation = ticket.location.toLowerCase().contains(query);
        final matchEquip = (ticket.equipmentId ?? '').toLowerCase().contains(query);
        final matchInspector = ticket.inspectorName.toLowerCase().contains(query);
        final matchAssignee = (ticket.assignedTo ?? '').toLowerCase().contains(query);
        if (!matchTitle && !matchDesc && !matchLocation && !matchEquip && !matchInspector && !matchAssignee) {
          return false;
        }
      }

      // 2. Priority filter
      if (_selectedPriorityFilter != 'all') {
        if (ticket.priority.toLowerCase() != _selectedPriorityFilter.toLowerCase()) {
          return false;
        }
      }

      // 3. Operational status filter
      if (_selectedStatusFilter != 'all') {
        if (ticket.operationalStatus != _selectedStatusFilter) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _handleExportCsv(List<InspectionTicket> tickets) async {
    if (tickets.isEmpty) {
      DialogHelper.showSnackBar(context, 'Không có phiếu nào để xuất báo cáo');
      return;
    }

    setState(() => _isExporting = true);
    final success = await ReportExportService.exportTicketsToCsvFile(tickets);
    setState(() => _isExporting = false);

    if (mounted) {
      if (success) {
        DialogHelper.showSnackBar(context, 'Đã xuất file báo cáo CSV thành công (chuẩn UTF-8)');
      } else {
        DialogHelper.showSnackBar(context, 'Không thể tải file báo cáo');
      }
    }
  }

  void _showDispatchModal(InspectionTicket ticket) {
    final assigneeController = TextEditingController(text: ticket.assignedTo ?? '');
    final notesController = TextEditingController(text: ticket.managerNotes ?? '');
    String currentOpStatus = ticket.operationalStatus;

    final presetAssignees = [
      'Kỹ sư Vũ Thành (Đội Cơ Điện)',
      'Kỹ sư Lê Minh (Bảo trì cơ khí)',
      'Kỹ sư Tuấn Anh (Tự động hóa & PLC)',
      'Kỹ sư Nguyễn Nam (An toàn công nghiệp)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.assignment_ind_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Điều độ & Phân công sự cố',
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
                Text(
                  ticket.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${ticket.equipmentId != null ? "[${ticket.equipmentId}] " : ""}${ticket.location}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // Trạng thái vận hành
                const Text(
                  'Trạng thái điều phối',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusChoiceChip('pending_review', 'Chờ tiếp nhận', currentOpStatus, (val) {
                      setModalState(() => currentOpStatus = val);
                    }),
                    _buildStatusChoiceChip('in_progress', 'Đang xử lý', currentOpStatus, (val) {
                      setModalState(() => currentOpStatus = val);
                    }),
                    _buildStatusChoiceChip('resolved', 'Đã khắc phục', currentOpStatus, (val) {
                      setModalState(() => currentOpStatus = val);
                    }),
                    _buildStatusChoiceChip('closed', 'Nghiệm thu đóng', currentOpStatus, (val) {
                      setModalState(() => currentOpStatus = val);
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Phân công kỹ sư
                const Text(
                  'Kỹ sư phụ trách sửa chữa',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: assigneeController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhập tên kỹ sư hoặc chọn gợi ý bên dưới...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.engineering_rounded, color: AppColors.textMuted, size: 18),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presetAssignees.map((name) {
                    final shortName = name.split(' (').first;
                    return ActionChip(
                      label: Text(shortName, style: const TextStyle(fontSize: 11)),
                      backgroundColor: AppColors.background,
                      labelStyle: const TextStyle(color: AppColors.textSecondary),
                      onPressed: () {
                        setModalState(() => assigneeController.text = name);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Ý kiến chỉ đạo của Quản đốc
                const Text(
                  'Ý kiến chỉ đạo & Duyệt cấp vật tư',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhập ghi chú điều độ, phê duyệt xuất kho linh kiện...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.speaker_notes_outlined, color: AppColors.textMuted, size: 18),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 20),

                // Nút Xác nhận
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final ok = await widget.controller.updateOperationalStatus(
                        ticket.id,
                        currentOpStatus,
                        assignedTo: assigneeController.text.trim().isNotEmpty ? assigneeController.text.trim() : null,
                        managerNotes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                      );
                      if (mounted) {
                        if (ok) {
                          DialogHelper.showSnackBar(context, 'Đã cập nhật điều độ phiếu thành công');
                        } else {
                          DialogHelper.showSnackBar(context, 'Không thể cập nhật phiếu');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Cập nhật điều độ & Giao việc', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChoiceChip(
    String value,
    String label,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = value == current;
    Color chipColor;
    switch (value) {
      case 'in_progress':
        chipColor = const Color(0xFF3B82F6);
        break;
      case 'resolved':
      case 'closed':
        chipColor = AppColors.success;
        break;
      default:
        chipColor = const Color(0xFFF59E0B);
    }

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: chipColor.withValues(alpha: 0.25),
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? chipColor : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : AppColors.cardBorder,
        width: isSelected ? 1.5 : 1,
      ),
    );
  }

  void _showImagePreviewDialog(String imagePath, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          onPressed: () => Navigator.of(ctx).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: InspectionImageWidget(
                        imagePath: imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
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
        final allTickets = ctrl.tickets;
        final filteredTickets = _getFilteredTickets(allTickets);
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth >= 850;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // 1. Top Admin Header & Role Switcher
                SliverToBoxAdapter(
                  child: _buildHeader(isDesktop, filteredTickets),
                ),

                // 2. KPI Summary Bar (5 Metrics)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildKpiRow(ctrl, isDesktop),
                  ),
                ),

                // 3. Search & Filter Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _buildFilterBar(),
                  ),
                ),

                // 4. Data Table or Responsive Cards
                if (filteredTickets.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else if (isDesktop)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: _buildDesktopDataTable(filteredTickets),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ticket = filteredTickets[index];
                          return _buildMobileTicketCard(ticket);
                        },
                        childCount: filteredTickets.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDesktop, List<InspectionTicket> currentFiltered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Trung tâm Điều độ',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 12, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              'QUẢN ĐỐC',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Giám sát sự cố, phân công bảo dưỡng & báo cáo hiện trường',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          // Actions: Switch to Field Mode & Export Report
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.onSwitchToFieldMode != null)
                OutlinedButton.icon(
                  onPressed: widget.onSwitchToFieldMode,
                  icon: const Icon(Icons.engineering_outlined, size: 16),
                  label: const Text('Kỹ sư hiện trường', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _handleExportCsv(currentFiltered),
                icon: _isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.file_download_outlined, size: 16),
                label: Text(
                  _isExporting ? 'Đang xuất...' : 'Xuất CSV / Excel',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(InspectionController ctrl, bool isDesktop) {
    final kpis = [
      _KpiData(
        title: 'Tổng phiếu',
        count: ctrl.totalTicketsCount,
        color: AppColors.primary,
        icon: Icons.assignment_outlined,
        filterKey: 'all',
      ),
      _KpiData(
        title: 'Khẩn cấp',
        count: ctrl.criticalTicketsCount,
        color: AppColors.error,
        icon: Icons.warning_amber_rounded,
        filterKey: 'critical_priority',
      ),
      _KpiData(
        title: 'Chờ tiếp nhận',
        count: ctrl.pendingReviewTicketsCount,
        color: const Color(0xFFF59E0B),
        icon: Icons.hourglass_empty_rounded,
        filterKey: 'pending_review',
      ),
      _KpiData(
        title: 'Đang xử lý',
        count: ctrl.inProgressTicketsCount,
        color: const Color(0xFF3B82F6),
        icon: Icons.build_circle_outlined,
        filterKey: 'in_progress',
      ),
      _KpiData(
        title: 'Đã hoàn tất',
        count: ctrl.resolvedTicketsCount,
        color: AppColors.success,
        icon: Icons.task_alt_rounded,
        filterKey: 'resolved',
      ),
    ];

    if (isDesktop) {
      return Row(
        children: kpis.map((kpi) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildKpiCard(kpi),
            ),
          );
        }).toList(),
      );
    }

    // Mobile scrollable row
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kpis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => SizedBox(
          width: 130,
          child: _buildKpiCard(kpis[index]),
        ),
      ),
    );
  }

  Widget _buildKpiCard(_KpiData kpi) {
    final isSelected = (_selectedStatusFilter == kpi.filterKey) ||
        (kpi.filterKey == 'critical_priority' && _selectedPriorityFilter == 'critical') ||
        (kpi.filterKey == 'all' && _selectedStatusFilter == 'all' && _selectedPriorityFilter == 'all');

    return InkWell(
      onTap: () {
        setState(() {
          if (kpi.filterKey == 'critical_priority') {
            _selectedPriorityFilter = 'critical';
            _selectedStatusFilter = 'all';
          } else if (kpi.filterKey == 'all') {
            _selectedPriorityFilter = 'all';
            _selectedStatusFilter = 'all';
          } else {
            _selectedStatusFilter = kpi.filterKey;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kpi.color.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kpi.color : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    kpi.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? kpi.color : AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${kpi.count}',
                    style: TextStyle(
                      color: isSelected ? kpi.color : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kpi.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(kpi.icon, color: kpi.color, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final hasActiveFilter = _searchQuery.isNotEmpty ||
        _selectedPriorityFilter != 'all' ||
        _selectedStatusFilter != 'all';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Ô tìm kiếm thông minh kết hợp nút Đặt lại
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo mã sự cố, thiết bị, khu vực...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ),
                  ),
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedPriorityFilter = 'all';
                        _selectedStatusFilter = 'all';
                      });
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 15),
                    label: const Text('Đặt lại', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // 2. Hàng 1: Mức độ ưu tiên
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 76,
                  child: Text(
                    'Mức độ:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('Tất cả', 'all', _selectedPriorityFilter, (val) {
                          setState(() => _selectedPriorityFilter = val);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterPill('Khẩn cấp', 'critical', _selectedPriorityFilter, (val) {
                          setState(() => _selectedPriorityFilter = val);
                        }, activeColor: AppColors.error),
                        const SizedBox(width: 6),
                        _buildFilterPill('Cao', 'high', _selectedPriorityFilter, (val) {
                          setState(() => _selectedPriorityFilter = val);
                        }, activeColor: AppColors.priorityHigh),
                        const SizedBox(width: 6),
                        _buildFilterPill('Trung bình', 'medium', _selectedPriorityFilter, (val) {
                          setState(() => _selectedPriorityFilter = val);
                        }, activeColor: AppColors.priorityMedium),
                        const SizedBox(width: 6),
                        _buildFilterPill('Thấp', 'low', _selectedPriorityFilter, (val) {
                          setState(() => _selectedPriorityFilter = val);
                        }, activeColor: AppColors.priorityLow),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.cardBorder),

          // 3. Hàng 2: Trạng thái điều độ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 76,
                  child: Text(
                    'Trạng thái:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('Tất cả', 'all', _selectedStatusFilter, (val) {
                          setState(() => _selectedStatusFilter = val);
                        }),
                        const SizedBox(width: 6),
                        _buildFilterPill('Chờ tiếp nhận', 'pending_review', _selectedStatusFilter, (val) {
                          setState(() => _selectedStatusFilter = val);
                        }, activeColor: const Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        _buildFilterPill('Đang xử lý', 'in_progress', _selectedStatusFilter, (val) {
                          setState(() => _selectedStatusFilter = val);
                        }, activeColor: const Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        _buildFilterPill('Đã khắc phục', 'resolved', _selectedStatusFilter, (val) {
                          setState(() => _selectedStatusFilter = val);
                        }, activeColor: AppColors.primary),
                        const SizedBox(width: 6),
                        _buildFilterPill('Đã nghiệm thu', 'closed', _selectedStatusFilter, (val) {
                          setState(() => _selectedStatusFilter = val);
                        }, activeColor: const Color(0xFF475569)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(
    String label,
    String value,
    String currentValue,
    ValueChanged<String> onSelected, {
    Color? activeColor,
  }) {
    final isSelected = value == currentValue;
    final color = activeColor ?? AppColors.primary;

    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_rounded, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopDataTable(List<InspectionTicket> tickets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const minTableWidth = 980.0;
        final tableWidth = availableWidth > minTableWidth ? availableWidth : minTableWidth;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(1.2), // Mã & Thời gian
                  1: FixedColumnWidth(60),  // Thumbnail ảnh
                  2: FlexColumnWidth(2.8), // Sự cố & Thiết bị
                  3: FlexColumnWidth(1.1), // Mức độ
                  4: FlexColumnWidth(1.7), // Người lập & Phân công
                  5: FlexColumnWidth(1.6), // Trạng thái điều độ
                  6: FixedColumnWidth(88),  // Thao tác
                },
                border: const TableBorder(
                  horizontalInside: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.surfaceLight),
                    children: [
                      _buildHeaderCell('MÃ & THỜI GIAN'),
                      _buildHeaderCell('ẢNH'),
                      _buildHeaderCell('SỰ CỐ & THIẾT BỊ'),
                      _buildHeaderCell('MỨC ĐỘ'),
                      _buildHeaderCell('NGƯỜI LẬP & PHÂN CÔNG'),
                      _buildHeaderCell('TRẠNG THÁI ĐIỀU ĐỘ'),
                      _buildHeaderCell('THAO TÁC', alignment: Alignment.center),
                    ],
                  ),
                  ...tickets.map((ticket) {
                    final hasImage = ticket.imagePath != null && ticket.imagePath!.isNotEmpty;

                    return TableRow(
                      children: [
                        // 1. Mã & Thời gian
                        _buildTableCell(
                          InkWell(
                            onTap: () => _navigateToTicketDetail(ticket),
                            borderRadius: BorderRadius.circular(4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '#${ticket.id.length > 8 ? ticket.id.substring(0, 8) : ticket.id}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatVietnamese(ticket.createdAt),
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Thumbnail Ảnh
                        _buildTableCell(
                          hasImage
                              ? InkWell(
                                  onTap: () => _showImagePreviewDialog(ticket.imagePath!, ticket.title),
                                  borderRadius: BorderRadius.circular(6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: InspectionImageWidget(
                                      imagePath: ticket.imagePath!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.cardBorder),
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                        ),

                        // 3. Sự cố & Thiết bị
                        _buildTableCell(
                          InkWell(
                            onTap: () => _navigateToTicketDetail(ticket),
                            borderRadius: BorderRadius.circular(4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    if (ticket.equipmentId != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(3),
                                          border: Border.all(color: AppColors.cardBorder),
                                        ),
                                        child: Text(
                                          ticket.equipmentId!,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        ticket.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 4. Mức độ
                        _buildTableCell(
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PriorityBadgeChip(priority: ticket.priority),
                          ),
                        ),

                        // 5. Người lập & Phân công
                        _buildTableCell(
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      ticket.inspectorName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.engineering_outlined,
                                    size: 12,
                                    color: ticket.assignedTo != null ? AppColors.primary : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      ticket.assignedTo ?? 'Chưa phân công',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: ticket.assignedTo != null ? AppColors.primary : AppColors.textMuted,
                                        fontSize: 10,
                                        fontWeight: ticket.assignedTo != null ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 6. Trạng thái điều độ (Dropdown)
                        _buildTableCell(
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _buildOperationalStatusDropdown(ticket),
                          ),
                        ),

                        // 7. Thao tác
                        _buildTableCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.assignment_ind_rounded, size: 18, color: AppColors.primary),
                                tooltip: 'Giao việc & Ghi chú',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                onPressed: () => _showDispatchModal(ticket),
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
                                tooltip: 'Xem chi tiết',
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                onPressed: () => _navigateToTicketDetail(ticket),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToTicketDetail(InspectionTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TicketReviewScreen(
          controller: widget.controller,
          initialTicket: ticket,
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {Alignment alignment = Alignment.centerLeft}) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child, {Alignment alignment = Alignment.centerLeft, EdgeInsetsGeometry? padding}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      alignment: alignment,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: child,
    );
  }

  Widget _buildOperationalStatusDropdown(InspectionTicket ticket) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (ticket.operationalStatus) {
      case 'in_progress':
        statusColor = const Color(0xFF2563EB); // Royal Blue
        statusLabel = 'Đang xử lý';
        statusIcon = Icons.autorenew_rounded;
        break;
      case 'resolved':
        statusColor = AppColors.primary; // Emerald
        statusLabel = 'Đã khắc phục';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'closed':
        statusColor = const Color(0xFF475569); // Slate
        statusLabel = 'Đã nghiệm thu';
        statusIcon = Icons.verified_outlined;
        break;
      default:
        statusColor = const Color(0xFFD97706); // Amber
        statusLabel = 'Chờ tiếp nhận';
        statusIcon = Icons.schedule_rounded;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.12),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Thay đổi trạng thái điều độ',
        initialValue: ticket.operationalStatus,
        offset: const Offset(0, 32),
        onSelected: (newStatus) async {
          if (newStatus == ticket.operationalStatus) return;
          final ok = await widget.controller.updateOperationalStatus(ticket.id, newStatus);
          if (mounted && ok) {
            DialogHelper.showSnackBar(context, 'Đã cập nhật trạng thái phiếu');
          }
        },
        itemBuilder: (ctx) => [
          _buildStatusMenuItem(
            value: 'pending_review',
            label: 'Chờ tiếp nhận',
            icon: Icons.schedule_rounded,
            color: const Color(0xFFD97706),
            isSelected: ticket.operationalStatus == 'pending_review',
          ),
          _buildStatusMenuItem(
            value: 'in_progress',
            label: 'Đang xử lý',
            icon: Icons.autorenew_rounded,
            color: const Color(0xFF2563EB),
            isSelected: ticket.operationalStatus == 'in_progress',
          ),
          _buildStatusMenuItem(
            value: 'resolved',
            label: 'Đã khắc phục',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            isSelected: ticket.operationalStatus == 'resolved',
          ),
          _buildStatusMenuItem(
            value: 'closed',
            label: 'Đã nghiệm thu',
            icon: Icons.verified_outlined,
            color: const Color(0xFF475569),
            isSelected: ticket.operationalStatus == 'closed',
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 5),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.expand_more_rounded, color: statusColor, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_rounded, size: 15, color: color),
        ],
      ),
    );
  }

  Widget _buildMobileTicketCard(InspectionTicket ticket) {
    final hasImage = ticket.imagePath != null && ticket.imagePath!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: ID, Priority, Operational Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '#${ticket.id.length > 8 ? ticket.id.substring(0, 8) : ticket.id}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadgeChip(priority: ticket.priority),
                ],
              ),
              _buildOperationalStatusDropdown(ticket),
            ],
          ),
          const SizedBox(height: 10),

          // Main info & optional thumbnail
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) ...[
                InkWell(
                  onTap: () => _showImagePreviewDialog(ticket.imagePath!, ticket.title),
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: InspectionImageWidget(
                      imagePath: ticket.imagePath!,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.location,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                    if (ticket.equipmentId != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Thiết bị: ${ticket.equipmentId!}',
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Assignment & Manager notes
          if (ticket.assignedTo != null || ticket.managerNotes != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ticket.assignedTo != null)
                    Row(
                      children: [
                        const Icon(Icons.engineering_rounded, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Phân công: ${ticket.assignedTo!}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  if (ticket.managerNotes != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.speaker_notes_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Chỉ đạo: ${ticket.managerNotes!}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Bottom action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormatter.formatVietnamese(ticket.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _showDispatchModal(ticket),
                    icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                    label: const Text('Giao việc', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TicketReviewScreen(
                            controller: widget.controller,
                            initialTicket: ticket,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 15),
                    label: const Text('Xem', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy sự cố nào phù hợp',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy thử xóa từ khóa tìm kiếm hoặc đặt lại bộ lọc',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedPriorityFilter = 'all';
                  _selectedStatusFilter = 'all';
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Đặt lại bộ lọc'),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiData {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final String filterKey;

  const _KpiData({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.filterKey,
  });
}
