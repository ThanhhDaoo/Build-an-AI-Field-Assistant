import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/dialog_helper.dart';
import '../../domain/entities/inspection_ticket.dart';
import '../controllers/inspection_controller.dart';
import '../widgets/priority_badge_chip.dart';
import 'ticket_review_screen.dart';

/// Screen listing inspection tickets with offline/online sync status and filter tabs
class TicketHistoryScreen extends StatelessWidget {
  final InspectionController controller;

  const TicketHistoryScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final tickets = controller.filteredTickets;

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
              'Lịch sử biên bản hiện trường',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              // Manual Sync Button
              if (controller.pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: TextButton.icon(
                    onPressed: controller.isOnline && !controller.isSyncing
                        ? () async {
                            final syncedCount = await controller.syncAllPending();
                            if (context.mounted) {
                              DialogHelper.showSnackBar(
                                context,
                                'Đã đồng bộ thành công $syncedCount phiếu!',
                              );
                            }
                          }
                        : null,
                    icon: controller.isSyncing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, color: AppColors.primary, size: 18),
                    label: Text(
                      controller.isSyncing
                          ? 'Đang sync...'
                          : 'Sync (${controller.pendingCount})',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Filter Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả (${controller.tickets.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'pending',
                      'Chờ đồng bộ (${controller.pendingCount})',
                      badgeColor: controller.pendingCount > 0
                          ? AppColors.priorityHigh
                          : null,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('synced', 'Đã sync (${controller.syncedCount})'),
                  ],
                ),
              ),

              // Offline Status Banner
              if (!controller.isOnline)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.statusPending.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: AppColors.statusPending, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang hoạt động ngoại tuyến. Các phiếu mới sẽ lưu cục bộ và tự đồng bộ khi có mạng.',
                          style: TextStyle(
                            color: AppColors.statusPending,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Tickets List
              Expanded(
                child: tickets.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: tickets.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ticket = tickets[index];
                          return _buildTicketCard(context, ticket);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String key, String label, {Color? badgeColor}) {
    final isSelected = controller.filter == key;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setFilter(key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceLight : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, InspectionTicket ticket) {
    return Dismissible(
      key: Key(ticket.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.priorityCritical,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await DialogHelper.showConfirmDialog(
          context,
          title: 'Xóa biên bản này?',
          message: 'Hành động này không thể hoàn tác.',
          confirmText: 'Xóa',
          isDestructive: true,
        );
      },
      onDismissed: (_) {
        controller.deleteTicket(ticket.id);
        DialogHelper.showSnackBar(context, 'Đã xóa biên bản kiểm tra');
      },
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TicketReviewScreen(
                controller: controller,
                initialTicket: ticket,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header: Priority Badge + Sync Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriorityBadgeChip(priority: ticket.priority),
                  Row(
                    children: [
                      Icon(
                        ticket.isSynced
                            ? Icons.cloud_done_rounded
                            : Icons.cloud_upload_outlined,
                        color: ticket.isSynced
                            ? AppColors.statusSynced
                            : AppColors.statusPending,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.isSynced ? 'Đã sync' : 'Chờ sync',
                        style: TextStyle(
                          color: ticket.isSynced
                              ? AppColors.statusSynced
                              : AppColors.statusPending,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                ticket.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Location
              Row(
                children: [
                  const Icon(Icons.place_rounded, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.location,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Description snippet
              Text(
                ticket.description,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Card Footer: Inspector & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        ticket.inspectorName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormatter.formatTimeAgo(ticket.createdAt),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: AppColors.textMuted,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có biên bản nào',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bắt đầu ghi âm hiện trường để tạo phiếu đầu tiên',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
