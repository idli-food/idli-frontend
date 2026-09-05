import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../resources/app_theme.dart';
import '../../services/directions_service.dart';
import '../../utils/responsive.dart';

class PostLocationScreen extends StatefulWidget {
  final double lat;
  final double lon;
  final String label;

  const PostLocationScreen({
    super.key,
    required this.lat,
    required this.lon,
    required this.label,
  });

  @override
  State<PostLocationScreen> createState() => _PostLocationScreenState();
}

class _PostLocationScreenState extends State<PostLocationScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String? _error;
  bool _loading = true;

  final _directionsService = DirectionsService();
  List<LatLng>? _routePoints;
  bool _routeError = false;
  int? _durationSeconds;
  int? _staticDurationSeconds;
  int? _distanceMeters;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _routeRefreshTimer;
  bool _hasFittedRouteOnce = false;
  bool _following = false;

  late final LatLng _destination = LatLng(widget.lat, widget.lon);

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _routeRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = 'Location permission denied';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _loading = false;
        });
        _fitBounds();
        _fetchRoute(position);
        _startLiveTracking();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not get your current location';
        });
      }
    }
  }

  void _startLiveTracking() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);

    _routeRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      final current = _currentPosition;
      if (current != null) _fetchRoute(current);
    });
  }

  void _onPositionUpdate(Position position) {
    if (!mounted) return;
    setState(() => _currentPosition = position);
    if (_following) _followCamera(position);
  }

  void _followCamera(Position position) {
    final controller = _mapController;
    if (controller == null) return;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17,
          bearing: position.heading >= 0 ? position.heading : 0,
          tilt: 45,
        ),
      ),
    );
  }

  void _toggleFollow() {
    setState(() => _following = !_following);
    final current = _currentPosition;
    if (current == null) return;
    if (_following) {
      _followCamera(current);
    } else {
      _fitBounds();
    }
  }

  Future<void> _fetchRoute(Position position) async {
    final result = await _directionsService.getDrivingRoute(
      origin: LatLng(position.latitude, position.longitude),
      destination: _destination,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _routeError = true);
      return;
    }
    setState(() {
      _routePoints = result.points;
      _durationSeconds = result.durationSeconds;
      _staticDurationSeconds = result.staticDurationSeconds;
      _distanceMeters = result.distanceMeters;
      _routeError = false;
    });
    if (!_hasFittedRouteOnce) {
      _hasFittedRouteOnce = true;
      _fitBounds();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_following) _toggleFollow();
      });
    }
  }

  static String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    return remaining == 0 ? '$hours hr' : '$hours hr $remaining min';
  }

  static String _formatDistance(int meters) {
    if (meters < 1000) return '$meters m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  void _fitBounds() {
    final controller = _mapController;
    final current = _currentPosition;
    if (controller == null || current == null) return;

    final pts = _routePoints ?? [LatLng(current.latitude, current.longitude), _destination];

    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentPosition;
    final markers = {
      Marker(
        markerId: const MarkerId('destination'),
        position: _destination,
        infoWindow: InfoWindow(title: widget.label),
      ),
      if (current != null)
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(current.latitude, current.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'You'),
        ),
    };

    final polylines = current == null
        ? <Polyline>{}
        : {
            if (_routePoints != null)
              Polyline(
                polylineId: const PolylineId('route'),
                points: _routePoints!,
                color: AppColors.primary,
                width: 4,
              )
            else
              Polyline(
                polylineId: const PolylineId('route'),
                points: [LatLng(current.latitude, current.longitude), _destination],
                color: AppColors.primary,
                width: 4,
                patterns: [PatternItem.dash(20), PatternItem.gap(10)],
              ),
          };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _destination, zoom: 15),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitBounds();
            },
            markers: markers,
            polylines: polylines,
            trafficEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.wp(4),
                vertical: context.hp(1.5),
              ),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: context.wp(3)),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.wp(4),
                        vertical: context.hp(1.2),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: context.wp(3)),
                  _RoundIconButton(
                    icon: _following
                        ? Icons.navigation_rounded
                        : Icons.map_outlined,
                    onTap: _toggleFollow,
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (!_loading && _error != null)
            Positioned(
              left: context.wp(4),
              right: context.wp(4),
              bottom: context.hp(3),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(4),
                  vertical: context.hp(1.5),
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_error — showing destination only',
                  style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
                ),
              ),
            ),
          if (!_loading && _error == null && _routeError)
            Positioned(
              left: context.wp(4),
              right: context.wp(4),
              bottom: context.hp(3),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.wp(4),
                  vertical: context.hp(1.5),
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Route info unavailable — showing direct line',
                  style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
                ),
              ),
            ),
          if (!_loading &&
              _error == null &&
              !_routeError &&
              _durationSeconds != null &&
              _distanceMeters != null)
            Positioned(
              left: context.wp(4),
              right: context.wp(4),
              bottom: context.hp(3),
              child: _RouteInfoCard(
                label: widget.label,
                etaText: _formatDuration(_durationSeconds!),
                trafficDeltaText:
                    (_staticDurationSeconds != null &&
                            _durationSeconds! - _staticDurationSeconds! > 120)
                        ? '+${_formatDuration(_durationSeconds! - _staticDurationSeconds!)} traffic'
                        : null,
                distanceText: _formatDistance(_distanceMeters!),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteInfoCard extends StatelessWidget {
  final String label;
  final String etaText;
  final String? trafficDeltaText;
  final String distanceText;

  const _RouteInfoCard({
    required this.label,
    required this.etaText,
    required this.trafficDeltaText,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.wp(4.5),
        vertical: context.hp(1.8),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: context.sp(15),
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: context.hp(0.8)),
          Row(
            children: [
              Text(
                etaText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (trafficDeltaText != null) ...[
                SizedBox(width: context.wp(2)),
                Text(
                  trafficDeltaText!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: context.sp(12),
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
              SizedBox(width: context.wp(2)),
              Text(
                '· $distanceText',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: context.sp(13),
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.dark, size: 20),
      ),
    );
  }
}
