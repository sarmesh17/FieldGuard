import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A driving route between two points, as returned by the Mapbox Directions
/// API. [geometry] is the decoded polyline (lng/lat pairs) ready to feed a
/// GeoJSON LineString; [distanceMeters]/[durationSeconds] drive the ETA card.
class DirectionsRoute {
  /// Ordered `[longitude, latitude]` pairs along the route.
  final List<List<double>> geometry;
  final double distanceMeters;
  final double durationSeconds;

  const DirectionsRoute({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// Fetches driving routes from the Mapbox Directions API for the in-app route
/// line (admin "follow route to a shop"). Uses its own bare [Dio] with the
/// public Mapbox token — this talks to Mapbox, not our backend, so it must not
/// carry our auth/refresh interceptors.
class MapboxDirectionsService {
  MapboxDirectionsService._();
  static final MapboxDirectionsService instance = MapboxDirectionsService._();

  final Dio _dio = Dio();

  static const _base = 'https://api.mapbox.com/directions/v5/mapbox/driving';

  /// Requests a driving route from ([originLat],[originLng]) to
  /// ([destLat],[destLng]). Returns null if the token is missing, the request
  /// fails, or no route is found — callers fall back to a straight line / no
  /// route rather than throwing.
  Future<DirectionsRoute?> drivingRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final token = dotenv.env['MAPBOX_PUBLIC_TOKEN'];
    if (token == null || token.isEmpty) return null;

    // Mapbox wants lng,lat order; polyline6 keeps ~0.1 m precision.
    final coords = '$originLng,$originLat;$destLng,$destLat';
    try {
      final res = await _dio.get(
        '$_base/$coords',
        queryParameters: {
          'geometries': 'polyline6',
          'overview': 'full',
          'access_token': token,
        },
      );
      final data = res.data;
      if (data is! Map) return null;
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route = routes.first as Map;
      final encoded = route['geometry'];
      if (encoded is! String) return null;

      return DirectionsRoute(
        geometry: _decodePolyline6(encoded),
        distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decodes a Mapbox `polyline6` string into `[lng, lat]` pairs (precision
  /// 1e6). Standard Google-polyline algorithm with a factor of 1e6.
  static List<List<double>> _decodePolyline6(String encoded) {
    final result = <List<double>>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    final len = encoded.length;

    while (index < len) {
      int shift = 0, b, value = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        value |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (value & 1) != 0 ? ~(value >> 1) : (value >> 1);

      shift = 0;
      value = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        value |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (value & 1) != 0 ? ~(value >> 1) : (value >> 1);

      result.add([lng / 1e6, lat / 1e6]);
    }
    return result;
  }

  /// Straight-line distance in meters (haversine) — a fallback ETA basis when
  /// the Directions API can't be reached.
  static double haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
