import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/inspection_ticket.dart';
import '../../domain/repositories/i_inspection_repository.dart';
import '../datasources/inspection_local_ds.dart';
import '../datasources/inspection_remote_ds.dart';
import '../models/inspection_ticket_model.dart';

/// Repository implementation coordinating Online AI extraction & Offline local caching
class InspectionRepositoryImpl implements IInspectionRepository {
  final IInspectionRemoteDataSource remoteDataSource;
  final IInspectionLocalDataSource localDataSource;
  final ConnectivityService connectivityService;

  final _ticketsStreamController = StreamController<List<InspectionTicket>>.broadcast();

  InspectionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  }) {
    // Automatically trigger sync when network is restored
    connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        debugPrint('Network restored: Triggering auto-sync for pending tickets...');
        syncPendingTickets();
      }
    });
  }

  Future<String?> _getSavedApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyGeminiApiKey);
  }

  @override
  Future<InspectionTicket> extractTicketFromVoice({
    required String audioPath,
    String? audioTranscript,
  }) async {
    final apiKey = await _getSavedApiKey();

    // If real audio file is present and no manual transcript was provided, use Gemini Multimodal Audio analysis
    if (audioPath.isNotEmpty && (audioTranscript == null || audioTranscript.trim().isEmpty)) {
      return await remoteDataSource.extractTicketFromAudio(
        audioPath: audioPath,
        apiKey: apiKey,
      );
    }

    final transcript = (audioTranscript != null && audioTranscript.trim().isNotEmpty)
        ? audioTranscript
        : 'Ghi âm hiện trường tại địa điểm kiểm tra.';
    return extractTicketFromText(transcript, audioPath: audioPath);
  }

  @override
  Future<InspectionTicket> extractTicketFromText(
    String textNotes, {
    String? audioPath,
  }) async {
    final apiKey = await _getSavedApiKey();
    final model = await remoteDataSource.extractTicketFromText(
      text: textNotes,
      apiKey: apiKey,
      audioPath: audioPath,
    );
    return model;
  }

  @override
  Future<List<InspectionTicket>> getTickets() async {
    final models = await localDataSource.getTickets();
    _ticketsStreamController.add(models);
    return models;
  }

  @override
  Future<InspectionTicket> saveTicket(InspectionTicket ticket) async {
    InspectionTicketModel model = InspectionTicketModel.fromEntity(ticket);

    // If online, attempt immediate sync
    if (connectivityService.isOnline) {
      try {
        final synced = await remoteDataSource.syncTicketToRemote(model);
        if (synced) {
          model = InspectionTicketModel.fromEntity(
            model.copyWith(status: 'synced', updatedAt: DateTime.now()),
          );
        }
      } catch (e) {
        debugPrint('Immediate sync failed, queued for later: $e');
        model = InspectionTicketModel.fromEntity(
          model.copyWith(status: 'pending_sync', updatedAt: DateTime.now()),
        );
      }
    } else {
      model = InspectionTicketModel.fromEntity(
        model.copyWith(status: 'pending_sync', updatedAt: DateTime.now()),
      );
    }

    await localDataSource.saveTicket(model);
    await getTickets(); // Refresh stream
    return model;
  }

  @override
  Future<void> deleteTicket(String id) async {
    await localDataSource.deleteTicket(id);
    await getTickets(); // Refresh stream
  }

  @override
  Future<int> syncPendingTickets() async {
    if (!connectivityService.isOnline) return 0;

    final pendingList = await localDataSource.getPendingTickets();
    int syncedCount = 0;

    for (final ticket in pendingList) {
      try {
        final success = await remoteDataSource.syncTicketToRemote(ticket);
        if (success) {
          await localDataSource.markTicketAsSynced(ticket.id);
          syncedCount++;
        }
      } catch (e) {
        debugPrint('Failed to sync ticket ${ticket.id}: $e');
      }
    }

    if (syncedCount > 0) {
      await getTickets(); // Refresh stream
    }
    return syncedCount;
  }

  @override
  Stream<List<InspectionTicket>> watchTickets() {
    // Initial fetch to push onto stream
    getTickets();
    return _ticketsStreamController.stream;
  }

  void dispose() {
    _ticketsStreamController.close();
  }
}
