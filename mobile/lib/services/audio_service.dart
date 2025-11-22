import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentVibe;
  int _currentTrackIndex = 0;
  List<String> _currentPlaylist = [];
  StreamSubscription<PlayerState>? _playerStateSubscription;

  static const Map<String, List<String>> vibePlaylists = {
    "CHILL": [
      "assets/audio/chill_1.mp3",
      "assets/audio/chill_2.mp3",
    ],
    "PARTY": [
      "assets/audio/party_1.mp3",
    ],
    "FOCUS": [
      "assets/audio/focus_1.mp3",
    ],
    "ROMANTIC": [
      "assets/audio/romantic_1.mp3",
    ],
  };

  AudioPlayer get player => _player;
  String? get currentVibe => _currentVibe;
  int get currentTrackIndex => _currentTrackIndex;
  List<String> get currentPlaylist => _currentPlaylist;

  // Streams exposed for UI
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> playVibe(String vibe) async {
    try {
      print('[AUDIO] Playing vibe: $vibe');
      
      // Stop current playback
      await _player.stop();
      _playerStateSubscription?.cancel();

      // Get playlist for vibe
      final playlist = vibePlaylists[vibe] ?? [];
      if (playlist.isEmpty) {
        print('[AUDIO] ✗ No playlist found for vibe: $vibe');
        _currentVibe = null;
        _currentPlaylist = [];
        _currentTrackIndex = 0;
        return;
      }

      print('[AUDIO] Playlist: ${playlist.length} track(s)');
      for (var i = 0; i < playlist.length; i++) {
        print('[AUDIO]   Track ${i + 1}: ${playlist[i]}');
      }

      _currentVibe = vibe;
      _currentPlaylist = playlist;
      _currentTrackIndex = 0;

      // Create concatenating audio source from asset paths
      print('[AUDIO] Loading track: ${playlist[0]}');
      final audioSources = playlist.map((path) => AudioSource.asset(path)).toList();
      final concatenatingSource = ConcatenatingAudioSource(children: audioSources);

      // Set the playlist
      await _player.setAudioSource(concatenatingSource);
      print('[AUDIO] ✓ Audio source loaded');

      // Listen for track completion to auto-play next
      _playerStateSubscription = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          // Auto-advance to next track if available
          if (_currentTrackIndex < _currentPlaylist.length - 1) {
            nextTrack();
          }
        }
      });

      // Start playing
      await _player.play();
      print('[AUDIO] ✓ Playback started');
    } catch (e, stackTrace) {
      print('[AUDIO] ✗ Error loading audio: $e');
      print('[AUDIO] Stack trace: $stackTrace');
      // Handle missing assets gracefully
      _currentVibe = null;
      _currentPlaylist = [];
      _currentTrackIndex = 0;
    }
  }

  Future<void> pause() async {
    try {
      print('[AUDIO] Pausing playback');
      await _player.pause();
      print('[AUDIO] ✓ Playback paused');
    } catch (e) {
      print('[AUDIO] ✗ Error pausing: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_currentPlaylist.isEmpty) {
        // If no playlist, try to restart current vibe
        if (_currentVibe != null) {
          print('[AUDIO] Resuming by restarting vibe: ${_currentVibe}');
          await playVibe(_currentVibe!);
        }
        return;
      }
      print('[AUDIO] Resuming playback');
      await _player.play();
      print('[AUDIO] ✓ Playback resumed');
    } catch (e) {
      print('[AUDIO] ✗ Error resuming: $e');
    }
  }

  Future<void> nextTrack() async {
    if (_currentPlaylist.isEmpty) {
      return;
    }

    try {
      final nextIndex = (_currentTrackIndex + 1) % _currentPlaylist.length;
      print('[AUDIO] Next track: ${nextIndex + 1}/${_currentPlaylist.length}');
      _currentTrackIndex = nextIndex;
      
      // Recreate the playlist starting from the next track
      final currentVibe = _currentVibe;
      if (currentVibe != null) {
        await _player.stop();
        _playerStateSubscription?.cancel();
        
        // Create new source starting from next track
        final remainingPlaylist = _currentPlaylist.sublist(nextIndex);
        if (remainingPlaylist.isNotEmpty) {
          print('[AUDIO] Loading track: ${remainingPlaylist[0]}');
          final audioSources = remainingPlaylist.map((path) => AudioSource.asset(path)).toList();
          final concatenatingSource = ConcatenatingAudioSource(children: audioSources);
          await _player.setAudioSource(concatenatingSource);
          
          // Re-setup state listener
          _playerStateSubscription = _player.playerStateStream.listen((state) {
            if (state.processingState == ProcessingState.completed) {
              if (_currentTrackIndex < _currentPlaylist.length - 1) {
                nextTrack();
              }
            }
          });
          
          await _player.play();
          print('[AUDIO] ✓ Next track playing');
        }
      }
    } catch (e) {
      print('[AUDIO] ✗ Error playing next track: $e');
    }
  }

  Future<void> previousTrack() async {
    if (_currentPlaylist.isEmpty) {
      return;
    }

    try {
      final prevIndex = _currentTrackIndex > 0
          ? _currentTrackIndex - 1
          : _currentPlaylist.length - 1;
      print('[AUDIO] Previous track: ${prevIndex + 1}/${_currentPlaylist.length}');
      _currentTrackIndex = prevIndex;

      // Restart from the previous track
      final currentVibe = _currentVibe;
      if (currentVibe != null) {
        await _player.stop();
        _playerStateSubscription?.cancel();
        
        final remainingPlaylist = _currentPlaylist.sublist(prevIndex);
        if (remainingPlaylist.isNotEmpty) {
          print('[AUDIO] Loading track: ${remainingPlaylist[0]}');
          final audioSources = remainingPlaylist.map((path) => AudioSource.asset(path)).toList();
          final concatenatingSource = ConcatenatingAudioSource(children: audioSources);
          await _player.setAudioSource(concatenatingSource);
          
          // Re-setup state listener
          _playerStateSubscription = _player.playerStateStream.listen((state) {
            if (state.processingState == ProcessingState.completed) {
              if (_currentTrackIndex < _currentPlaylist.length - 1) {
                nextTrack();
              }
            }
          });
          
          await _player.play();
          print('[AUDIO] ✓ Previous track playing');
        }
      }
    } catch (e) {
      print('[AUDIO] ✗ Error playing previous track: $e');
    }
  }

  Future<void> stop() async {
    try {
      print('[AUDIO] Stopping playback');
      await _player.stop();
      _playerStateSubscription?.cancel();
      _currentVibe = null;
      _currentPlaylist = [];
      _currentTrackIndex = 0;
      print('[AUDIO] ✓ Playback stopped');
    } catch (e) {
      print('[AUDIO] ✗ Error stopping: $e');
    }
  }

  String getCurrentTrackName() {
    if (_currentPlaylist.isEmpty) {
      return 'No track';
    }
    final path = _currentPlaylist[_currentTrackIndex];
    // Extract filename from asset path
    final parts = path.split('/');
    final filename = parts.last.replaceAll('.mp3', '').replaceAll('_', ' ').toUpperCase();
    return filename.isNotEmpty ? filename : 'Track ${_currentTrackIndex + 1}';
  }

  void dispose() {
    _playerStateSubscription?.cancel();
    _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
