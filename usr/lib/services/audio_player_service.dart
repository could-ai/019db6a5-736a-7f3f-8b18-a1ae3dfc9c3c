import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/models.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  Track? _currentTrack;
  List<Track> _playlist = [];
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Track? get currentTrack => _currentTrack;
  List<Track> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;

  AudioPlayerService() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index < _playlist.length) {
        _currentTrack = _playlist[index];
        notifyListeners();
      }
    });
  }

  Future<void> playTrack(Track track, List<Track> playlist) async {
    _playlist = playlist;
    _currentTrack = track;
    
    final initialIndex = playlist.indexWhere((t) => t.id == track.id);
    
    final audioSource = ConcatenatingAudioSource(
      children: playlist.map((t) => AudioSource.uri(Uri.file(t.path))).toList(),
    );

    await _player.setAudioSource(audioSource, initialIndex: initialIndex >= 0 ? initialIndex : 0);
    await _player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }
  
  Future<void> skipToNext() async {
    await _player.seekToNext();
  }
  
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
