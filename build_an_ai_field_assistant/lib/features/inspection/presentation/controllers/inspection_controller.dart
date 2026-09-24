import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/audio_recorder_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../domain/entities/inspection_ticket.dart';
import '../../domain/repositories/i_inspection_repository.dart';

enum InspectionViewState {
  idle,
  recording,
  analyzing,
  success,
  error,
}

/// Main presentation controller coordinating audio recording, AI extraction & ticket lifecycle
class InspectionController extends ChangeNotifier {
  final IInspectionRepository repository;
  final AudioRecorderService audioRecorderService;
  final ConnectivityService connectivityService;

  // Subscriptions
  StreamSubscription<double>? _amplitudeSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<InspectionTicket>>? _ticketsSubscription;

  // View States
  InspectionViewState _state = InspectionViewState.idle;
  InspectionViewState get state => _state;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Audio & Wave
  double _currentAmplitude = 0.0;
  double get currentAmplitude => _currentAmplitude;

  Duration _recordDuration = Duration.zero;
  Duration get recordDuration => _recordDuration;

  bool get isRecording => audioRecorderService.isRecording;

  // Tickets & Connectivity
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  List<InspectionTicket> _tickets = [];
  List<InspectionTicket> get tickets => _tickets;

  String _filter = 'all'; // 'all', 'pending', 'synced'
  String get filter => _filter;

  List<InspectionTicket> get filteredTickets {
    if (_filter == 'pending') {
      return _tickets.where((t) => t.isPendingSync).toList();
    } else if (_filter == 'synced') {
      return _tickets.where((t) => t.isSynced).toList();
    }
    return _tickets;
  }

  int get pendingCount => _tickets.where((t) => t.isPendingSync).length;
  int get syncedCount => _tickets.where((t) => t.isSynced).length;

  // Currently active draft ticket being reviewed
  InspectionTicket? _currentDraftTicket;
  InspectionTicket? get currentDraftTicket => _currentDraftTicket;

  InspectionController({
    required this.repository,
    required this.audioRecorderService,
    required this.connectivityService,
  }) {
    _init();
  }

  void _init() {
    _isOnline = connectivityService.isOnline;

    _connectivitySubscription = connectivityService.onConnectivityChanged.listen((online) {
      _isOnline = online;
      notifyListeners();
    });

    _amplitudeSubscription = audioRecorderService.amplitudeStream.listen((amp) {
      _currentAmplitude = amp;
      notifyListeners();
    });

    _durationSubscription = audioRecorderService.durationStream.listen((dur) {
      _recordDuration = dur;
      notifyListeners();
    });

    _ticketsSubscription = repository.watchTickets().listen((ticketList) {
      _tickets = ticketList;
      notifyListeners();
    });

    loadTickets();
  }

  Future<void> loadTickets() async {
    try {
      _tickets = await repository.getTickets();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void setFilter(String filterKey) {
    _filter = filterKey;
    notifyListeners();
  }

  /// Start Recording Voice Note (.m4a or .wav)
  Future<void> startRecording({AudioOutputFormat format = AudioOutputFormat.m4a}) async {
    _errorMessage = null;
    try {
      await audioRecorderService.startRecording(format: format);
      _state = InspectionViewState.recording;
      notifyListeners();
    } on MicrophonePermissionException catch (e) {
      _errorMessage = e.message;
      _state = InspectionViewState.idle;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _state = InspectionViewState.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Stop Recording & Invoke AI JSON Extraction
  Future<InspectionTicket?> stopRecordingAndExtract({String? mockSpeechText}) async {
    try {
      final audioPath = await audioRecorderService.stopRecording();
      _state = InspectionViewState.analyzing;
      notifyListeners();

      final extractedTicket = await repository.extractTicketFromVoice(
        audioPath: audioPath ?? '',
        audioTranscript: mockSpeechText,
      );

      _currentDraftTicket = extractedTicket;
      _state = InspectionViewState.success;
      notifyListeners();
      return extractedTicket;
    } catch (e) {
      _errorMessage = 'Không thể phân tích giọng nói: $e';
      _state = InspectionViewState.error;
      notifyListeners();
      return null;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    await audioRecorderService.cancelRecording();
    _state = InspectionViewState.idle;
    _currentAmplitude = 0.0;
    _recordDuration = Duration.zero;
    notifyListeners();
  }

  /// Extract ticket directly from text prompt (e.g. manual entry or quick template)
  Future<InspectionTicket?> extractFromText(String promptText) async {
    _state = InspectionViewState.analyzing;
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await repository.extractTicketFromText(promptText);
      _currentDraftTicket = ticket;
      _state = InspectionViewState.success;
      notifyListeners();
      return ticket;
    } catch (e) {
      _errorMessage = 'Trích xuất thất bại: $e';
      _state = InspectionViewState.error;
      notifyListeners();
      return null;
    }
  }

  /// Update the draft ticket fields during inspector review
  void updateDraftTicket(InspectionTicket updatedTicket) {
    _currentDraftTicket = updatedTicket;
    notifyListeners();
  }

  /// Save and submit the reviewed ticket
  Future<bool> submitDraftTicket() async {
    if (_currentDraftTicket == null) return false;

    try {
      await repository.saveTicket(_currentDraftTicket!);
      _currentDraftTicket = null;
      _state = InspectionViewState.idle;
      await loadTickets();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể lưu phiếu: $e';
      notifyListeners();
      return false;
    }
  }

  /// Manually sync all pending tickets
  Future<int> syncAllPending() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    notifyListeners();

    try {
      final count = await repository.syncPendingTickets();
      await loadTickets();
      return count;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Delete a ticket
  Future<void> deleteTicket(String id) async {
    await repository.deleteTicket(id);
    await loadTickets();
  }

  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _durationSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _ticketsSubscription?.cancel();
    super.dispose();
  }
}
