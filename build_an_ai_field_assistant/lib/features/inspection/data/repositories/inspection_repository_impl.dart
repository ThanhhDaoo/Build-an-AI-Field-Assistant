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
  StreamSubscription<bool>? _connectivitySubscription;

  InspectionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  }) {
    // Automatically trigger sync when network is restored
    _connectivitySubscription = connectivityService.onConnectivityChanged.listen((isOnline) {
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

    // 1. If Gemini API key is available and audio exists, use Gemini Multimodal Audio analysis
    if (apiKey != null && apiKey.trim().isNotEmpty && audioPath.isNotEmpty) {
      return await remoteDataSource.extractTicketFromAudio(
        audioPath: audioPath,
        apiKey: apiKey,
        userNote: audioTranscript,
      );
    }

    // 2. If we have a transcribed text from device Speech-to-Text, extract ticket from text
    if (audioTranscript != null && audioTranscript.trim().isNotEmpty) {
      return extractTicketFromText(audioTranscript, audioPath: audioPath);
    }

    // 3. Fallback when offline / without Gemini API key and no words recognized
    return await remoteDataSource.extractTicketFromAudio(
      audioPath: audioPath,
      apiKey: apiKey,
      userNote: audioTranscript,
    );
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
        } else {
          model = InspectionTicketModel.fromEntity(
            model.copyWith(status: 'pending', updatedAt: DateTime.now()),
          );
        }
      } catch (e) {
        debugPrint('Immediate sync failed, queued for later: $e');
        model = InspectionTicketModel.fromEntity(
          model.copyWith(status: 'pending', updatedAt: DateTime.now()),
        );
      }
    } else {
      model = InspectionTicketModel.fromEntity(
        model.copyWith(status: 'pending', updatedAt: DateTime.now()),
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
    if (pendingList.isEmpty) return 0;

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
    _connectivitySubscription?.cancel();
    _ticketsStreamController.close();
  }
}
