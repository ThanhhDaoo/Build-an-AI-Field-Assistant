import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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

  /// Play audio from local file or web URL
  Future<void> play(String path) async {
    try {
      _currentSource = path;
      if (kIsWeb || path.startsWith('http://') || path.startsWith('https://')) {
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
