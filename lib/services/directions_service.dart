import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsResult {
  final List<LatLng> points;
  final int durationSeconds;
  final int staticDurationSeconds;
  final int distanceMeters;

  const DirectionsResult({
    required this.points,
    required this.durationSeconds,
    required this.staticDurationSeconds,
    required this.distanceMeters,
  });
}

class DirectionsService {
  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Fetches a driving route between [origin] and [destination] using the
  /// Routes API (the legacy Directions API is disabled for many projects
  /// and Google recommends this replacement).
  /// Returns null on any failure — callers should fall back to a straight line.
  Future<DirectionsResult?> getDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_apiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://routes.googleapis.com/directions/v2:computeRoutes',
      );
      final res = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': _apiKey,
              'X-Goog-FieldMask':
                  'routes.duration,routes.staticDuration,routes.distanceMeters,routes.polyline.encodedPolyline',
            },
            body: jsonEncode({
              'origin': {
                'location': {
                  'latLng': {
                    'latitude': origin.latitude,
                    'longitude': origin.longitude,
                  },
                },
              },
              'destination': {
                'location': {
                  'latLng': {
                    'latitude': destination.latitude,
                    'longitude': destination.longitude,
                  },
                },
              },
              'travelMode': 'DRIVE',
              'routingPreference': 'TRAFFIC_AWARE',
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        debugPrint('[DirectionsService] HTTP ${res.statusCode}: ${res.body}');
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;

      final polyline = route['polyline'] as Map<String, dynamic>?;
      final encoded = polyline?['encodedPolyline'] as String?;
      if (encoded == null || encoded.isEmpty) return null;
      final points = _decodePolyline(encoded);
      if (points.isEmpty) return null;

      final durationSeconds = _parseSeconds(route['duration'] as String?);
      final staticDurationSeconds = _parseSeconds(route['staticDuration'] as String?);
      final distanceMeters = (route['distanceMeters'] as num?)?.toInt();
      if (durationSeconds == null ||
          staticDurationSeconds == null ||
          distanceMeters == null) {
        return null;
      }

      return DirectionsResult(
        points: points,
        durationSeconds: durationSeconds,
        staticDurationSeconds: staticDurationSeconds,
        distanceMeters: distanceMeters,
      );
    } catch (e) {
      debugPrint('[DirectionsService] error: $e');
      return null;
    }
  }

  /// Parses a Routes API duration string like "734s" into whole seconds.
  int? _parseSeconds(String? value) {
    if (value == null || !value.endsWith('s')) return null;
    return int.tryParse(value.substring(0, value.length - 1));
  }

  /// Standard Google encoded-polyline decoding algorithm.
  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
