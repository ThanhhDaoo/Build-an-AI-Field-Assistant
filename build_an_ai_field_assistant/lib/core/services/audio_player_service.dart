import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../utils/media_persistence_helper.dart';

/// Audio Player Service for playback of field inspection voice recordings
class AudioPlayerService {
  final AudioPlayer _player;

  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _currentSource;

  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  AudioPlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _init();
  }

  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get currentSource => _currentSource;

  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;
  Stream<Duration> get onDurationChanged => _player.onDurationChanged;

  void _init() {
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
    });

    _positionSubscription = _player.onPositionChanged.listen((pos) {
      _position = pos;
    });

    _durationSubscription = _player.onDurationChanged.listen((dur) {
      _duration = dur;
    });
  }

  /// Play audio from local file, web URL or persistent Base64 Data URI
  Future<void> play(String path) async {
    try {
      _currentSource = path;

      // 1. Base64 Data URI (Permanent cross-platform audio)
      if (path.startsWith('data:audio')) {
        final bytes = MediaPersistenceHelper.decodeAudioBytes(path);
        if (bytes != null && bytes.isNotEmpty) {
          final mime = MediaPersistenceHelper.extractMimeType(path, fallback: 'audio/mp4');
          await _player.play(BytesSource(bytes, mimeType: mime));
          return;
        }
      }

      // 2. Web URL or Blob
      if (kIsWeb || path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')) {
        await _player.play(UrlSource(path));
      } else {
        await _player.play(DeviceFileSource(path));
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  /// Pause current audio
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  /// Resume current audio
  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  /// Stop current audio
  Future<void> stop() async {
    try {
      await _player.stop();
      _position = Duration.zero;
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Seek to duration
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  void dispose() {
    _stateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _player.dispose();
  }
}
