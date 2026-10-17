import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Request location permissions with fallback guidance
  static Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get continuous position updates
  static Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    );
  }

  /// Mathematical Haversine Distance in meters
  static double calculateDistanceInMeters(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // in meters
    final double dLat = _degToRad(to.latitude - from.latitude);
    final double dLon = _degToRad(to.longitude - from.longitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(from.latitude)) *
            math.cos(_degToRad(to.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Bearing Angle (0 to 360 degrees) pointing toward the bike
  static double calculateBearing(LatLng from, LatLng to) {
    final double lat1 = _degToRad(from.latitude);
    final double lon1 = _degToRad(from.longitude);
    final double lat2 = _degToRad(to.latitude);
    final double lon2 = _degToRad(to.longitude);

    final double dLon = lon2 - lon1;

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double radians = math.atan2(y, x);
    final double degrees = (radians * 180 / math.pi + 360) % 360;
    return degrees;
  }

  static double _degToRad(double degrees) => degrees * (math.pi / 180.0);

  /// 100% Free Voice Walking Turn-by-Turn via native Google Maps
  static Future<void> launchWalkingNavigation(LatLng destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

