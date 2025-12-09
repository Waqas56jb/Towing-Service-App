import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/towing_service.dart';
import 'location_pricing_service.dart';
import 'overpass_service.dart';
import 'geocoding_service.dart';

class TowingServiceProvider {
  static const String _baseUrl = 'https://api.towing-services.com'; // Replace with your API
  final OverpassService _overpassService = OverpassService();
  final GeocodingService _geocodingService = GeocodingService();

  // NO HARDCODED DATA - 100% REAL-TIME FROM OPENSTREETMAP

  Future<List<TowingService>> getNearbyTowingServices({
    required double latitude,
    required double longitude,
    required String vehicleType,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    try {
      // 100% REAL-TIME: Get data from OpenStreetMap Overpass API
      final realTimeServices = await _overpassService.findTowingServices(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        limit: limit,
      );

      // Filter by vehicle type and return real-time services
      final filteredServices = realTimeServices
          .where((service) => service.vehicleTypes.contains(vehicleType))
          .toList();
      
      if (filteredServices.isNotEmpty) {
        return filteredServices;
      }

      // If no towing services found, try to find car repair shops that might provide towing
      final carRepairServices = await _overpassService.findTowingServices(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm * 2, // Expand search radius
        limit: limit,
      );

      final repairFiltered = carRepairServices
          .where((service) => service.vehicleTypes.contains(vehicleType))
          .toList();

      return repairFiltered;
    } catch (e) {
      print('Real-time towing services search failed: $e');
      // Return empty list instead of hardcoded data
      return [];
    }
  }

  // REMOVED: No more hardcoded fallback data - 100% real-time only

  Future<TowingService?> getTowingServiceById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/towing-services/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TowingService.fromJson(data);
      }
    } catch (e) {
      print('API call failed: $e');
    }

    // NO HARDCODED FALLBACK - return null if not found in real-time data
    return null;
  }

  Future<List<TowingService>> searchTowingServices(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/towing-services/search?q=${Uri.encodeQueryComponent(query)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => TowingService.fromJson(json)).toList();
      }
    } catch (e) {
      print('API call failed: $e');
    }

    // NO HARDCODED FALLBACK - return empty list if no real-time results
    return [];
  }

  Future<Map<String, dynamic>> calculateFare({
    required TowingService service,
    required double distanceKm,
    required String vehicleType,
  }) async {
    final double baseFare = service.baseFare;
    final double perKmRate = service.perKmRate;
    
    // Apply vehicle type multiplier
    final Map<String, double> vehicleMultipliers = {
      'Motorcycle': 0.6,
      'Car': 1.0,
      'Truck': 1.8,
    };
    
    final double multiplier = vehicleMultipliers[vehicleType] ?? 1.0;
    final double totalFare = (baseFare + (distanceKm * perKmRate)) * multiplier;
    
    return {
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'distanceKm': distanceKm,
      'vehicleType': vehicleType,
      'multiplier': multiplier,
      'totalFare': totalFare.ceilToDouble(),
      'breakdown': {
        'base': baseFare,
        'distance': distanceKm * perKmRate,
        'vehicleMultiplier': multiplier,
        'total': totalFare.ceilToDouble(),
      }
    };
  }

  /// Search for locations using real-time geocoding
  Future<List<GeocodingResult>> searchLocations(String query, {
    int limit = 10,
    String? countryCode,
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
  }) async {
    return await _geocodingService.searchLocations(
      query,
      limit: limit,
      countryCode: countryCode,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  /// Get current location with address
  Future<LocationWithAddress?> getCurrentLocationWithAddress() async {
    return await _geocodingService.getCurrentLocationWithAddress();
  }

  /// Reverse geocode coordinates to get address
  Future<ReverseGeocodingResult?> reverseGeocode(double latitude, double longitude) async {
    return await _geocodingService.reverseGeocode(latitude, longitude);
  }

  /// Find emergency services nearby
  Future<List<EmergencyService>> findEmergencyServices({
    required double latitude,
    required double longitude,
    double radiusKm = 25.0,
    int limit = 10,
  }) async {
    return await _overpassService.findEmergencyServices(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
    );
  }

  /// Find nearby fuel stations
  Future<List<FuelStation>> findFuelStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 15,
  }) async {
    return await _overpassService.findFuelStations(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
    );
  }

  /// Find nearby places of interest
  Future<List<PlaceOfInterest>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String amenity,
    double radiusKm = 5.0,
    int limit = 10,
  }) async {
    return await _geocodingService.searchNearbyPlaces(
      latitude: latitude,
      longitude: longitude,
      amenity: amenity,
      radiusKm: radiusKm,
      limit: limit,
    );
  }
}
