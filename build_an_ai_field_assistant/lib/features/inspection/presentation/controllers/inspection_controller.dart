import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/audio_recorder_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/speech_to_text_service.dart';
import '../../../../core/services/sync_notification_service.dart';
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
  final SpeechToTextService? speechToTextService;
  final LocationService? locationService;
  final SyncNotificationService? syncNotificationService;

  // Subscriptions
  StreamSubscription<double>? _amplitudeSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<InspectionTicket>>? _ticketsSubscription;
  StreamSubscription<SyncNotificationEvent>? _syncNotificationSubscription;

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

  // Admin Operations Metrics
  int get totalTicketsCount => _tickets.length;
  int get criticalTicketsCount => _tickets.where((t) => t.priority.toLowerCase() == 'critical').length;
  int get pendingReviewTicketsCount => _tickets.where((t) => t.isPendingReview).length;
  int get inProgressTicketsCount => _tickets.where((t) => t.isInProgress).length;
  int get resolvedTicketsCount => _tickets.where((t) => t.isResolved).length;

  // Currently active draft ticket being reviewed
  InspectionTicket? _currentDraftTicket;
  InspectionTicket? get currentDraftTicket => _currentDraftTicket;

  // Live Speech Recognition Transcript
  String _liveTranscript = '';
  String get liveTranscript => _liveTranscript;

  void setLiveTranscript(String text) {
    _liveTranscript = text;
    notifyListeners();
  }

  // Attached Image Path for Visual Inspection
  String? _selectedImagePath;
  String? get selectedImagePath => _selectedImagePath;

  void setSelectedImagePath(String? path) {
    _selectedImagePath = path;
    notifyListeners();
  }

  void clearSelectedImage() {
    _selectedImagePath = null;
    notifyListeners();
  }

  // Tagged GPS Location
  String? _taggedGpsLocation;
  String? get taggedGpsLocation => _taggedGpsLocation;

  bool _isFetchingLocation = false;
  bool get isFetchingLocation => _isFetchingLocation;

  /// 1-Touch GPS Coordinate Acquisition
  Future<String?> fetchGpsLocation() async {
    if (locationService == null) return null;
    _isFetchingLocation = true;
    notifyListeners();
    try {
      final loc = await locationService!.getCurrentFormattedLocation();
      if (loc != null) {
        _taggedGpsLocation = loc;
      }
      return loc;
    } finally {
      _isFetchingLocation = false;
      notifyListeners();
    }
  }

  void setTaggedGpsLocation(String? loc) {
    _taggedGpsLocation = loc;
    notifyListeners();
  }

  void clearTaggedGpsLocation() {
    _taggedGpsLocation = null;
    notifyListeners();
  }

  // Active Sync Notification Banner Message
  String? _activeSyncMessage;
  String? get activeSyncMessage => _activeSyncMessage;

  void dismissSyncMessage() {
    _activeSyncMessage = null;
    notifyListeners();
  }

  InspectionController({
    required this.repository,
    required this.audioRecorderService,
    required this.connectivityService,
    this.speechToTextService,
    this.locationService,
    this.syncNotificationService,
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

    if (syncNotificationService != null) {
      _syncNotificationSubscription = syncNotificationService!.onSyncNotification.listen((event) {
        _activeSyncMessage = event.message;
        notifyListeners();
      });
    }

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

  /// Start Recording Voice Note (.m4a or .wav) & activate live speech transcription
  Future<void> startRecording({AudioOutputFormat format = AudioOutputFormat.m4a}) async {
    _errorMessage = null;
    _liveTranscript = '';
    try {
      await audioRecorderService.startRecording(format: format);
      // Start real-time speech recognition simultaneously
      try {
        speechToTextService?.startListening(onResult: (words) {
          _liveTranscript = words;
          notifyListeners();
        });
      } catch (e) {
        debugPrint('STT listening skipped: $e');
      }
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
      String sttWords = '';
      try {
        if (speechToTextService != null) {
          sttWords = await speechToTextService!.stopListening();
        }
      } catch (e) {
        debugPrint('STT stop skipped: $e');
      }

      _state = InspectionViewState.analyzing;
      notifyListeners();

      // Resolve final transcript from mock input or live recognized words
      final transcriptToUse = (mockSpeechText != null && mockSpeechText.isNotEmpty)
          ? mockSpeechText
          : (sttWords.isNotEmpty ? sttWords : (_liveTranscript.isNotEmpty ? _liveTranscript : null));

      final extractedTicket = await repository.extractTicketFromVoice(
        audioPath: audioPath ?? '',
        audioTranscript: transcriptToUse,
        imagePath: _selectedImagePath,
      );

      InspectionTicket ticketWithImage = (extractedTicket.imagePath == null && _selectedImagePath != null)
          ? extractedTicket.copyWith(imagePath: _selectedImagePath)
          : extractedTicket;

      if (_taggedGpsLocation != null && _taggedGpsLocation!.isNotEmpty) {
        if (ticketWithImage.location.isEmpty ||
            ticketWithImage.location.toLowerCase().contains('chưa rõ') ||
            ticketWithImage.location.toLowerCase().contains('hiện trường')) {
          ticketWithImage = ticketWithImage.copyWith(location: _taggedGpsLocation);
        } else if (!ticketWithImage.location.contains('GPS')) {
          ticketWithImage = ticketWithImage.copyWith(location: '${ticketWithImage.location} - $_taggedGpsLocation');
        }
      }

      _currentDraftTicket = ticketWithImage;
      _state = InspectionViewState.success;
      notifyListeners();
      return _currentDraftTicket;
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
    try {
      await speechToTextService?.cancelListening();
    } catch (_) {}
    _state = InspectionViewState.idle;
    _currentAmplitude = 0.0;
    _recordDuration = Duration.zero;
    _liveTranscript = '';
    notifyListeners();
  }

  /// Extract ticket directly from text prompt (e.g. manual entry or quick template)
  Future<InspectionTicket?> extractFromText(String promptText, {String? imagePath}) async {
    _state = InspectionViewState.analyzing;
    _errorMessage = null;
    notifyListeners();

    final imgPath = imagePath ?? _selectedImagePath;

    try {
      final ticket = await repository.extractTicketFromText(
        promptText,
        imagePath: imgPath,
      );
      InspectionTicket ticketWithImage = (ticket.imagePath == null && imgPath != null)
          ? ticket.copyWith(imagePath: imgPath)
          : ticket;

      if (_taggedGpsLocation != null && _taggedGpsLocation!.isNotEmpty) {
        if (ticketWithImage.location.isEmpty ||
            ticketWithImage.location.toLowerCase().contains('chưa rõ') ||
            ticketWithImage.location.toLowerCase().contains('hiện trường')) {
          ticketWithImage = ticketWithImage.copyWith(location: _taggedGpsLocation);
        } else if (!ticketWithImage.location.contains('GPS')) {
          ticketWithImage = ticketWithImage.copyWith(location: '${ticketWithImage.location} - $_taggedGpsLocation');
        }
      }

      _currentDraftTicket = ticketWithImage;
      _state = InspectionViewState.success;
      notifyListeners();
      return _currentDraftTicket;
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
      _selectedImagePath = null;
      _taggedGpsLocation = null;
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
      if (count > 0) {
        syncNotificationService?.notifySyncSuccess(count);
      }
      return count;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Update operational status, assignee, and notes for dispatcher workflow
  Future<bool> updateOperationalStatus(
    String ticketId,
    String operationalStatus, {
    String? assignedTo,
    String? managerNotes,
  }) async {
    try {
      final updated = await repository.updateTicketOperationalStatus(
        ticketId,
        operationalStatus,
        assignedTo: assignedTo,
        managerNotes: managerNotes,
      );
      if (updated != null) {
        await loadTickets();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật trạng thái: $e';
      notifyListeners();
      return false;
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
    _syncNotificationSubscription?.cancel();
    super.dispose();
  }
}
