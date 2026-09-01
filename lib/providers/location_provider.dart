import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/location_result.dart';

part 'location_provider.g.dart';

class LocationState {
  final LocationResult? selected;
  final bool loading;
  final String? error;

  const LocationState({this.selected, this.loading = false, this.error});

  LocationState copyWith({
    LocationResult? Function()? selected,
    bool? loading,
    String? Function()? error,
  }) =>
      LocationState(
        selected: selected != null ? selected() : this.selected,
        loading: loading ?? this.loading,
        error: error != null ? error() : this.error,
      );
}

@riverpod
class LocationNotifier extends _$LocationNotifier {
  @override
  LocationState build() => const LocationState();

  Future<void> fetchCurrent() async {
    state = state.copyWith(loading: true, error: () => null);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          loading: false,
          error: () => 'Location permission denied',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final address = _buildAddress(placemarks.isNotEmpty ? placemarks.first : null);
      state = LocationState(
        selected: LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
        ),
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: () => e.toString());
    }
  }

  void set(LocationResult result) {
    state = LocationState(selected: result);
  }

  static String _buildAddress(Placemark? p) {
    if (p == null) return 'Unknown location';
    return [p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .map((s) => s!)
        .join(', ')
        .ifEmpty('Unknown location');
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
