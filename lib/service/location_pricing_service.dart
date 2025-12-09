import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class LocationPricingService {
  static const double basePkrPerKilometer = 150.0;
  static const Map<String, double> modeMultiplier = {
    'Motorcycle': 0.4,   // ₨60/km - lightest assistance
    'Car': 1.0,          // ₨150/km - standard rate
    'Truck': 2.2,        // ₨330/km - heavy-duty towing
  };

  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Please allow location access.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable location access in settings.');
    }

    // Single fast attempt with medium accuracy
    try {
      print('Getting live location...');
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
        forceAndroidLocationManager: false,
      );
      
      print('Got live position: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
      return position;
      
    } catch (e) {
      print('Location error: $e');
      throw Exception('Unable to get live location. Please check GPS and try again.');
    }
  }

  double calculateDistanceKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _toRadians(endLat - startLat);
    final double dLon = _toRadians(endLng - startLng);

    final double lat1 = _toRadians(startLat);
    final double lat2 = _toRadians(endLat);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double calculateFarePkr(double distanceKm, {String mode = 'Car'}) {
    final mult = modeMultiplier[mode] ?? 1.0;
    return (distanceKm * basePkrPerKilometer * mult).ceilToDouble();
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;
}
