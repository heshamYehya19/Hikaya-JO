import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsResult {
  final List<LatLng> routePoints;
  final String durationText;
  final String distanceText;
  final int durationMinutes;

  DirectionsResult({
    required this.routePoints,
    required this.durationText,
    required this.distanceText,
    required this.durationMinutes,
  });
}

class DirectionsService {
  final String _apiKey = dotenv.env['GOOGLE_DIRECTIONS_API_KEY'] ?? '';

  Future<DirectionsResult?> getRoute({
    required LatLng origin,
    required LatLng destination,
    int maxRetries = 2,
  }) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&key=$_apiKey',
    );

    int attempt = 0;
    while (true) {
      try {
        final response = await http.get(uri);
        if (response.statusCode != 200) {
          throw Exception('Directions API error ${response.statusCode}');
        }

        final data = jsonDecode(response.body);

        if (data['status'] != 'OK') {
          // ZERO_RESULTS, REQUEST_DENIED, etc. — not retryable, just no route available
          return null;
        }

        final route = data['routes'][0];
        final leg = route['legs'][0];
        final encodedPolyline = route['overview_polyline']['points'] as String;

        return DirectionsResult(
          routePoints: _decodePolyline(encodedPolyline),
          durationText: leg['duration']['text'],
          distanceText: leg['distance']['text'],
          durationMinutes: (leg['duration']['value'] as int) ~/ 60,
        );
      } catch (e) {
        attempt++;
        final isRetryable = e.toString().contains('503') || e.toString().contains('timeout');
        if (!isRetryable || attempt >= maxRetries) return null;
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Decodes Google's encoded polyline format into a list of LatLng points.
  /// Standard algorithm — no extra package needed.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}