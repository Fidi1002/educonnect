import 'package:educonnect/core/providers/backend_providers.dart';
import 'package:educonnect/features/auth/data/repositories/user_repository.dart';
import 'package:educonnect/features/home/domain/models/tutor_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserLocationSource { gps, manual }

class UserLocationState {
  const UserLocationState({
    required this.latitude,
    required this.longitude,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final UserLocationSource source;
}

final userLocationProvider = StateProvider<UserLocationState?>((ref) => null);
final locationErrorProvider = StateProvider<String?>((ref) => null);
final searchRadiusKmProvider = StateProvider<double>((ref) => 5);
final locationLoadingProvider = StateProvider<bool>((ref) => false);

final nearbyTutorsProvider = StreamProvider<List<TutorSummary>>((ref) {
  final position = ref.watch(userLocationProvider);
  final radiusKm = ref.watch(searchRadiusKmProvider);
  if (position == null) {
    return const Stream<List<TutorSummary>>.empty();
  }

  return ref
      .watch(userRepositoryProvider)
      .watchNearbyTutors(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: radiusKm,
      );
});

final nearbyTutorControllerProvider = Provider<NearbyTutorController>((ref) {
  return NearbyTutorController(ref);
});

class NearbyTutorController {
  NearbyTutorController(this._ref);

  final Ref _ref;

  Future<void> refreshUserLocation() async {
    await _ref
        .read(analyticsServiceProvider)
        .logEvent('location_refresh_started');

    _ref.read(locationLoadingProvider.notifier).state = true;
    _ref.read(locationErrorProvider.notifier).state = null;
    try {
      final position = await _ref
          .read(locationServiceProvider)
          .getCurrentPosition();
      _ref.read(userLocationProvider.notifier).state = UserLocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        source: UserLocationSource.gps,
      );
      await _ref
          .read(analyticsServiceProvider)
          .logEvent(
            'location_refresh_success',
            parameters: {
              'source': 'gps',
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          );
    } catch (error) {
      _ref.read(locationErrorProvider.notifier).state = error.toString();
      await _ref
          .read(analyticsServiceProvider)
          .logEvent(
            'location_refresh_failed',
            parameters: {'error': error.toString()},
          );
    } finally {
      _ref.read(locationLoadingProvider.notifier).state = false;
    }
  }

  Future<void> setManualLocation({
    required double latitude,
    required double longitude,
  }) async {
    _ref.read(locationErrorProvider.notifier).state = null;
    _ref.read(userLocationProvider.notifier).state = UserLocationState(
      latitude: latitude,
      longitude: longitude,
      source: UserLocationSource.manual,
    );
    await _ref
        .read(analyticsServiceProvider)
        .logEvent(
          'manual_location_set',
          parameters: {'latitude': latitude, 'longitude': longitude},
        );
  }

  Future<void> setSearchRadius(double radiusKm) async {
    _ref.read(searchRadiusKmProvider.notifier).state = radiusKm;
    await _ref
        .read(analyticsServiceProvider)
        .logEvent('nearby_radius_changed', parameters: {'radius_km': radiusKm});
  }
}
