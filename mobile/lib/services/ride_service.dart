import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

class RideService {
  final ApiService _apiService;

  RideService(this._apiService);

  Future<List<dynamic>> getVibes() async {
    return await _apiService.getList('/vibes');
  }

  Future<Map<String, dynamic>> createRide({
    required String pickup,
    required String dropoff,
    required String vibe,
  }) async {
    return await _apiService.post('/rides', {
      'pickup': pickup,
      'dropoff': dropoff,
      'vibe': vibe,
    });
  }

  Future<List<dynamic>> getRideHistory() async {
    return await _apiService.getList('/rides');
  }

  Future<Map<String, dynamic>> getRide(String rideId) async {
    return await _apiService.get('/rides/$rideId');
  }

  Future<Map<String, dynamic>> updateRideStatus(String rideId, String status) async {
    return await _apiService.patch('/rides/$rideId/status', {
      'status': status,
    });
  }
}

final rideServiceProvider = Provider<RideService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RideService(apiService);
});

