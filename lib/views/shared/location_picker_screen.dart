import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../providers/location_provider.dart';
import '../../resources/app_theme.dart';
import '../../utils/location_result.dart';
import '../../utils/responsive.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  /// If provided, called with the confirmed location instead of saving to
  /// [locationNotifierProvider]. Use this when picking a location for a
  /// specific action (e.g. create post) without changing the global feed location.
  final void Function(LocationResult)? onConfirm;

  const LocationPickerScreen({super.key, this.onConfirm});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  static const _defaultLatLng = LatLng(9.9312, 76.2673);

  final _searchController = TextEditingController();
  final _mapCompleter = Completer<GoogleMapController>();

  List<_Suggestion> _suggestions = [];
  bool _showSuggestions = false;
  String _address = 'Tiruvananthapuram';
  LatLng _center = _defaultLatLng;
  Timer? _debounce;
  bool _geocoding = false;

  @override
  void initState() {
    super.initState();
    final loc = ref.read(locationNotifierProvider).selected;
    if (loc != null) {
      _center = LatLng(loc.latitude, loc.longitude);
      _address = loc.address;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json'
      '?input=${Uri.encodeComponent(query)}'
      '&key=$_apiKey'
      '&types=geocode',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200 && mounted) {
        final predictions = (jsonDecode(res.body)['predictions'] as List)
            .map((p) => _Suggestion(p['place_id'], p['description']))
            .toList();
        setState(() {
          _suggestions = predictions;
          _showSuggestions = predictions.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _selectSuggestion(_Suggestion s) async {
    setState(() => _showSuggestions = false);
    _searchController.clear();
    FocusScope.of(context).unfocus();

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=${s.placeId}'
      '&fields=geometry,formatted_address'
      '&key=$_apiKey',
    );
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final result = jsonDecode(res.body)['result'];
        final loc = result['geometry']['location'];
        final lat = (loc['lat'] as num).toDouble();
        final lng = (loc['lng'] as num).toDouble();
        final address = result['formatted_address'] as String;
        final controller = await _mapCompleter.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14),
        );
        if (mounted) {
          setState(() {
            _center = LatLng(lat, lng);
            _address = address;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _onCameraIdle() async {
    if (_geocoding) return;
    setState(() => _geocoding = true);
    try {
      final placemarks =
          await placemarkFromCoordinates(_center.latitude, _center.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [p.locality, p.administrativeArea]
            .where((s) => s != null && s.isNotEmpty)
            .map((s) => s!)
            .toList();
        setState(() => _address = parts.isEmpty ? 'Unknown location' : parts.join(', '));
      }
    } catch (_) {}
    if (mounted) setState(() => _geocoding = false);
  }

  Future<void> _useCurrentLocation() async {
    await ref.read(locationNotifierProvider.notifier).fetchCurrent();
    final loc = ref.read(locationNotifierProvider).selected;
    if (loc != null && mounted) {
      final controller = await _mapCompleter.future;
      final latLng = LatLng(loc.latitude, loc.longitude);
      await controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      setState(() {
        _center = latLng;
        _address = loc.address;
      });
    }
  }

  void _confirm() {
    final result = LocationResult(
      latitude: _center.latitude,
      longitude: _center.longitude,
      address: _address,
    );
    if (widget.onConfirm != null) {
      widget.onConfirm!(result);
    } else {
      ref.read(locationNotifierProvider.notifier).set(result);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(locationNotifierProvider).loading;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 13),
            onMapCreated: (c) => _mapCompleter.complete(c),
            onCameraMove: (pos) => _center = pos.target,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Fixed center pin
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, size: 48, color: AppColors.primary),
                SizedBox(height: 24),
              ],
            ),
          ),

          // Top bar: back + search
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Container(
                    color: AppColors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: context.wp(2),
                      vertical: context.hp(0.8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search for a location...',
                              hintStyle: TextStyle(
                                fontSize: context.sp(14),
                                color: AppColors.greyDark,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: AppColors.grey.withValues(alpha: 0.15),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: context.wp(3),
                                vertical: context.hp(1),
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showSuggestions)
                    Container(
                      color: AppColors.white,
                      constraints: BoxConstraints(maxHeight: context.hp(30)),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.place_outlined,
                              color: AppColors.greyDark),
                          title: Text(
                            _suggestions[i].description,
                            style: TextStyle(fontSize: context.sp(13)),
                          ),
                          onTap: () => _selectSuggestion(_suggestions[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom: GPS + Confirm
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  context.wp(4),
                  context.hp(1.5),
                  context.wp(4),
                  context.hp(2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: loading ? null : _useCurrentLocation,
                      icon: loading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded),
                      label: const Text('Use my current location'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, context.hp(5.5)),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: context.hp(1.2)),
                    ElevatedButton(
                      onPressed: _geocoding ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: Size(double.infinity, context.hp(5.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _geocoding ? 'Getting address…' : 'Confirm — $_address',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: context.sp(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestion {
  final String placeId;
  final String description;
  const _Suggestion(this.placeId, this.description);
}
