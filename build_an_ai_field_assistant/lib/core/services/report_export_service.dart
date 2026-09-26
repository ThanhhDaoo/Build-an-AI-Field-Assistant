import 'package:intl/intl.dart';
import '../../features/inspection/domain/entities/inspection_ticket.dart';
import '../utils/file_download_helper.dart';

/// Dịch vụ xuất báo cáo sự cố hiện trường sang định dạng CSV/Excel
class ReportExportService {
  /// Chuyển đổi danh sách phiếu thành chuỗi CSV chuẩn UTF-8 có BOM (tương thích Microsoft Excel)
  static String generateTicketsCsv(List<InspectionTicket> tickets) {
    final buffer = StringBuffer();

    // 1. Thêm UTF-8 Byte Order Mark (BOM) để Microsoft Excel mở tiếng Việt không bị lỗi font
    buffer.write('\uFEFF');

    // 2. Dòng tiêu đề các cột
    const headers = [
      'Mã phiếu',
      'Tiêu đề sự cố',
      'Mã thiết bị',
      'Vị trí hiện trường',
      'Chuyên môn',
      'Mức độ ưu tiên',
      'Trạng thái điều độ',
      'Trạng thái đồng bộ',
      'Kỹ sư lập phiếu',
      'Kỹ sư phụ trách',
      'Lỗi phát hiện',
      'Vật tư linh kiện yêu cầu',
      'Hành động đề xuất',
      'Ghi chú Quản đốc',
      'Thời gian ghi nhận',
      'Thời gian nghiệm thu',
    ];
    buffer.writeln(headers.map(_escapeCsvCell).join(','));

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // 3. Dữ liệu từng phiếu
    for (final ticket in tickets) {
      final partsSummary = ticket.requiredParts.isNotEmpty
          ? ticket.requiredParts.map((p) => '${p.name} (x${p.quantity})').join('; ')
          : 'Không yêu cầu';

      final issuesSummary = ticket.detectedIssues.isNotEmpty
          ? ticket.detectedIssues.join('; ')
          : ticket.description;

      final row = [
        ticket.id,
        ticket.title,
        ticket.equipmentId ?? 'Không xác định',
        ticket.location,
        _translateCategory(ticket.category),
        _translatePriority(ticket.priority),
        _translateOperationalStatus(ticket.operationalStatus),
        ticket.isSynced ? 'Đã đồng bộ máy chủ' : 'Chờ đồng bộ ngoại tuyến',
        ticket.inspectorName,
        ticket.assignedTo ?? 'Chưa phân công',
        issuesSummary,
        partsSummary,
        ticket.suggestedAction,
        ticket.managerNotes ?? 'Chưa có ghi chú',
        dateFormat.format(ticket.createdAt),
        ticket.resolvedAt != null ? dateFormat.format(ticket.resolvedAt!) : 'Chưa nghiệm thu',
      ];

      buffer.writeln(row.map(_escapeCsvCell).join(','));
    }

    return buffer.toString();
  }

  /// Tải file CSV báo cáo về máy
  static Future<bool> exportTicketsToCsvFile(
    List<InspectionTicket> tickets, {
    String? customFileName,
  }) async {
    try {
      final csvData = generateTicketsCsv(tickets);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = customFileName ?? 'Bao_cao_su_co_hien_truong_$timestamp.csv';

      await FileDownloadHelper.downloadFile(
        filename: filename,
        content: csvData,
        mimeType: 'text/csv;charset=utf-8',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _escapeCsvCell(String cell) {
    if (cell.contains(',') || cell.contains('"') || cell.contains('\n') || cell.contains('\r')) {
      final escaped = cell.replaceAll('"', '""');
      return '"$escaped"';
    }
    return cell;
  }

  static String _translateCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'electrical':
        return 'Cơ điện';
      case 'mechanical':
        return 'Cơ khí';
      case 'safety':
        return 'An toàn lao động';
      case 'civil':
        return 'Xây dựng / Hạ tầng';
      case 'hvac':
        return 'Thông gió / Điều hòa';
      default:
        return 'Chung';
    }
  }

  static String _translatePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return 'Khẩn cấp';
      case 'high':
        return 'Cao';
      case 'medium':
        return 'Trung bình';
      case 'low':
        return 'Thấp';
      default:
        return priority;
    }
  }

  static String _translateOperationalStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_review':
        return 'Chờ tiếp nhận';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã khắc phục';
      case 'closed':
        return 'Đã nghiệm thu / Đóng';
      default:
        return status;
    }
  }
}
