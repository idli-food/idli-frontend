import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsResult {
  final List<LatLng> points;
  const DirectionsResult(this.points);
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
              'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
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
      final polyline =
          (routes.first as Map<String, dynamic>)['polyline'] as Map<String, dynamic>?;
      final encoded = polyline?['encodedPolyline'] as String?;
      if (encoded == null || encoded.isEmpty) return null;
      final points = _decodePolyline(encoded);
      if (points.isEmpty) return null;
      return DirectionsResult(points);
    } catch (e) {
      debugPrint('[DirectionsService] error: $e');
      return null;
    }
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
