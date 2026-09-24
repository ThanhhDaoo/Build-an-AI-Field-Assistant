import '../entities/inspection_ticket.dart';

/// Abstract Repository Interface defining inspection operations
abstract class IInspectionRepository {
  /// Extract structured ticket from voice audio recording or transcript
  Future<InspectionTicket> extractTicketFromVoice({
    required String audioPath,
    String? audioTranscript,
  });

  /// Extract structured ticket from raw text notes or voice transcripts
  Future<InspectionTicket> extractTicketFromText(String textNotes);

  /// Fetch all inspection tickets from local repository
  Future<List<InspectionTicket>> getTickets();

  /// Save or update an inspection ticket (handles online vs offline sync logic)
  Future<InspectionTicket> saveTicket(InspectionTicket ticket);

  /// Delete an inspection ticket
  Future<void> deleteTicket(String id);

  /// Sync all pending tickets to remote cloud backend
  Future<int> syncPendingTickets();

  /// Watch tickets changes in real-time
  Stream<List<InspectionTicket>> watchTickets();
}
