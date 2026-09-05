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

  late final LatLng _destination = LatLng(widget.lat, widget.lon);

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
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
    setState(() => _routePoints = result.points);
    _fitBounds();
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
