import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationService {
  /// Request location permissions safely without ever blocking the UI thread or throwing ANRs
  static Future<bool> checkAndRequestPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 4), onTimeout: () => false);

      if (!serviceEnabled) {
        return false;
      }

      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 4), onTimeout: () => LocationPermission.denied);

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 8), onTimeout: () => LocationPermission.denied);
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Location permission check error: $e');
      return false;
    }
  }

  /// Get initial position quickly: first from cache, then with safe timeout fallback
  static Future<Position?> getInitialPosition() async {
    try {
      // 1. Try cached last known position instantly
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }

      // 2. Fallback to fresh position with strict 5-second timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('Initial position lookup error: $e');
      return null;
    }
  }

  /// Get continuous position updates with safe error handling
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

  /// 100% Free Turn-by-Turn Walking Route via native Google Maps or external browser
  static Future<bool> launchWalkingNavigation(LatLng destination) async {
    final lat = destination.latitude;
    final lng = destination.longitude;

    // 1. Google Navigation intent (launches Google Maps app directly in Turn-by-Turn walking mode)
    final navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=w');

    // 2. Google Maps universal direction link with walking mode
    final mapsWebUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking',
    );

    // 3. Fallback Geo URI
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    // Attempt 1: Direct Google Maps navigation intent
    try {
      final launched = await launchUrl(navUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (e) {
      debugPrint('Google navigation intent launch failed: $e');
    }

    // Attempt 2: Universal Google Maps URL via external application (Maps app or browser)
    try {
      final launched = await launchUrl(mapsWebUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (e) {
      debugPrint('Universal Google Maps URL external launch failed: $e');
    }

    // Attempt 3: Universal Google Maps URL via platform default
    try {
      final launched = await launchUrl(mapsWebUri, mode: LaunchMode.platformDefault);
      if (launched) return true;
    } catch (e) {
      debugPrint('Universal Google Maps URL platform default launch failed: $e');
    }

    // Attempt 4: Geo URI
    try {
      final launched = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (e) {
      debugPrint('Geo URI launch failed: $e');
    }

    return false;
  }
}
