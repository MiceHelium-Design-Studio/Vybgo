import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ride_service.dart';
import '../../services/audio_service.dart';

class RideStatusScreen extends ConsumerStatefulWidget {
  final String rideId;

  const RideStatusScreen({super.key, required this.rideId});

  @override
  ConsumerState<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends ConsumerState<RideStatusScreen> {
  Map<String, dynamic>? _ride;
  bool _isLoading = true;
  bool _isPlaying = false;
  StreamSubscription<bool>? _playingSubscription;

  @override
  void initState() {
    super.initState();
    _loadRide();
    _setupAudioListener();
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    // Don't stop audio here - let it continue playing if user wants
    // Only pause if you want to stop when leaving screen
    super.dispose();
  }

  Future<void> _loadRide() async {
    try {
      final rideService = ref.read(rideServiceProvider);
      final ride = await rideService.getRide(widget.rideId);
      setState(() {
        _ride = ride;
        _isLoading = false;
      });

      // Start playing the vibe for this ride
      if (mounted) {
        final vibe = ride['vibe'] as String;
        final audioService = ref.read(audioServiceProvider);
        
        // Only start playing if not already playing this vibe
        if (audioService.currentVibe != vibe) {
          await audioService.playVibe(vibe);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupAudioListener() {
    final audioService = ref.read(audioServiceProvider);
    _isPlaying = audioService.player.playing;
    
    // Listen to playing state changes
    _playingSubscription = audioService.player.playingStream.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Waiting for driver...';
      case 'ACCEPTED':
        return 'Driver on the way';
      case 'IN_PROGRESS':
        return 'Ride in progress';
      case 'COMPLETED':
        return 'Ride completed';
      case 'CANCELLED':
        return 'Ride cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ACCEPTED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.green;
      case 'COMPLETED':
        return Colors.grey;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getVibeColor(String vibe) {
    final colors = {
      'CHILL': Colors.blue,
      'PARTY': Colors.pink,
      'FOCUS': Colors.green,
      'ROMANTIC': Colors.red,
    };
    return colors[vibe] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Status')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ride Status')),
        body: const Center(child: Text('Ride not found')),
      );
    }

    final status = _ride!['status'] as String;
    final vibe = _ride!['vibe'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Status'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            'Pickup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ride!['pickup'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Dropoff',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _ride!['dropoff'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getVibeColor(vibe).withOpacity(0.1),
                        _getVibeColor(vibe).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _getVibeColor(vibe),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getVibeColor(vibe).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Vibe',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vibe,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _getVibeColor(vibe),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Consumer(
                        builder: (context, ref, child) {
                          final audioService = ref.watch(audioServiceProvider);
                          final trackName = audioService.getCurrentTrackName();
                          final trackIndex = audioService.currentTrackIndex;
                          final totalTracks = audioService.currentPlaylist.length;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          trackName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (totalTracks > 0)
                                          Text(
                                            'Track ${trackIndex + 1} of $totalTracks',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous),
                                    iconSize: 32,
                                    onPressed: () async {
                                      final audioService =
                                          ref.read(audioServiceProvider);
                                      await audioService.previousTrack();
                                    },
                                    tooltip: 'Previous track',
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _getVibeColor(vibe),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getVibeColor(vibe)
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      iconSize: 40,
                                      onPressed: () async {
                                        final audioService =
                                            ref.read(audioServiceProvider);
                                        if (_isPlaying) {
                                          await audioService.pause();
                                        } else {
                                          // If no vibe is playing, start it
                                          if (audioService.currentVibe != vibe) {
                                            await audioService.playVibe(vibe);
                                          } else {
                                            await audioService.resume();
                                          }
                                        }
                                      },
                                      tooltip: _isPlaying ? 'Pause' : 'Play',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next),
                                    iconSize: 32,
                                    onPressed: () async {
                                      final audioService =
                                          ref.read(audioServiceProvider);
                                      await audioService.nextTrack();
                                    },
                                    tooltip: 'Next track',
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Debug panel (only in debug mode)
              if (kDebugMode)
                Consumer(
                  builder: (context, ref, child) {
                    final audioService = ref.watch(audioServiceProvider);
                    final playerState = audioService.player.playerState;
                    final position = audioService.player.position;
                    
                    return Card(
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🐛 Debug Info',
                              style: TextStyle(
                                color: Colors.yellow[300],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDebugRow('Vibe ID', vibe),
                            _buildDebugRow('Ride ID', widget.rideId),
                            _buildDebugRow('Track Index', '${audioService.currentTrackIndex + 1}/${audioService.currentPlaylist.length}'),
                            _buildDebugRow('Player State', '${playerState.processingState.name}'),
                            _buildDebugRow('Playing', '${audioService.player.playing}'),
                            _buildDebugRow('Position', '${position.inSeconds}s'),
                            if (audioService.currentPlaylist.isNotEmpty)
                              _buildDebugRow('Current Track', audioService.currentPlaylist[audioService.currentTrackIndex]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

