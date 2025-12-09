import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/towing_service.dart';

class OverpassService {
  static const String _overpassApiUrl = 'https://overpass-api.de/api/interpreter';
  static const String _userAgent = 'TowingServiceApp/1.0 (contact: support@towingapp.com)';

  /// Find towing services using OpenStreetMap Overpass API
  Future<List<TowingService>> findTowingServices({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
  }) async {
    try {
      // Overpass QL query to find towing services, car repair shops, and related services
      final query = '''
        [out:json][timeout:25];
        (
          // Find towing services
          node["amenity"="towing"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["amenity"="towing"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["amenity"="towing"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          
          // Find car repair shops (often provide towing)
          node["shop"="car_repair"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["shop"="car_repair"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["shop"="car_repair"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          
          // Find automotive services
          node["shop"="car"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["shop"="car"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["shop"="car"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          
          // Find emergency services that might provide towing
          node["emergency"="towing"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["emergency"="towing"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["emergency"="towing"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          
          // Find roadside assistance services
          node["service:vehicle:car_repair"="yes"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["service:vehicle:car_repair"="yes"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["service:vehicle:car_repair"="yes"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
        );
        out center meta;
      ''';

      final response = await http.post(
        Uri.parse(_overpassApiUrl),
        headers: {
          'User-Agent': _userAgent,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> elements = data['elements'] ?? [];
        
        final List<TowingService> services = [];
        
        for (final element in elements) {
          final service = _parseOverpassElement(element);
          if (service != null) {
            services.add(service);
          }
        }

        // Sort by distance and limit results
        services.sort((a, b) {
          final distanceA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
          final distanceB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
          return distanceA.compareTo(distanceB);
        });

        return services.take(limit).toList();
      }
    } catch (e) {
      print('Overpass API error: $e');
    }

    return [];
  }

  /// Find emergency services (police, hospitals) that might help with towing
  Future<List<EmergencyService>> findEmergencyServices({
    required double latitude,
    required double longitude,
    double radiusKm = 25.0,
    int limit = 10,
  }) async {
    try {
      final query = '''
        [out:json][timeout:25];
        (
          // Police stations
          node["amenity"="police"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["amenity"="police"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["amenity"="police"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          
          // Hospitals
          node["amenity"="hospital"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["amenity"="hospital"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["amenity"="hospital"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          
          // Fire stations
          node["amenity"="fire_station"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["amenity"="fire_station"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["amenity"="fire_station"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
        );
        out center meta;
      ''';

      final response = await http.post(
        Uri.parse(_overpassApiUrl),
        headers: {
          'User-Agent': _userAgent,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> elements = data['elements'] ?? [];
        
        final List<EmergencyService> services = [];
        
        for (final element in elements) {
          final service = _parseEmergencyElement(element);
          if (service != null) {
            services.add(service);
          }
        }

        // Sort by distance
        services.sort((a, b) {
          final distanceA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
          final distanceB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
          return distanceA.compareTo(distanceB);
        });

        return services.take(limit).toList();
      }
    } catch (e) {
      print('Emergency services search error: $e');
    }

    return [];
  }

  /// Find nearby fuel stations
  Future<List<FuelStation>> findFuelStations({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 15,
  }) async {
    try {
      final query = '''
        [out:json][timeout:25];
        (
          node["amenity"="fuel"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          way["amenity"="fuel"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
          relation["amenity"="fuel"](around:${(radiusKm * 1000).toInt()},$latitude,$longitude);
        );
        out center meta;
      ''';

      final response = await http.post(
        Uri.parse(_overpassApiUrl),
        headers: {
          'User-Agent': _userAgent,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> elements = data['elements'] ?? [];
        
        final List<FuelStation> stations = [];
        
        for (final element in elements) {
          final station = _parseFuelStationElement(element);
          if (station != null) {
            stations.add(station);
          }
        }

        // Sort by distance
        stations.sort((a, b) {
          final distanceA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
          final distanceB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
          return distanceA.compareTo(distanceB);
        });

        return stations.take(limit).toList();
      }
    } catch (e) {
      print('Fuel stations search error: $e');
    }

    return [];
  }

  TowingService? _parseOverpassElement(Map<String, dynamic> element) {
    try {
      final tags = Map<String, dynamic>.from(element['tags'] ?? {});
      final lat = element['lat']?.toDouble() ?? element['center']?['lat']?.toDouble();
      final lon = element['lon']?.toDouble() ?? element['center']?['lon']?.toDouble();
      
      if (lat == null || lon == null) return null;

      final name = tags['name'] ?? 
                  tags['brand'] ?? 
                  tags['operator'] ?? 
                  'Towing Service';
      
      final phone = tags['phone'] ?? 
                   tags['contact:phone'] ?? 
                   '';
      
      final address = _buildAddress(tags);
      
      // Determine vehicle types based on tags
      final List<String> vehicleTypes = [];
      if (tags['service:vehicle:car'] == 'yes' || tags['service:vehicle:car'] == 'true') {
        vehicleTypes.add('Car');
      }
      if (tags['service:vehicle:truck'] == 'yes' || tags['service:vehicle:truck'] == 'true') {
        vehicleTypes.add('Truck');
      }
      if (tags['service:vehicle:motorcycle'] == 'yes' || tags['service:vehicle:motorcycle'] == 'true') {
        vehicleTypes.add('Motorcycle');
      }
      
      // Default to all vehicle types if not specified
      if (vehicleTypes.isEmpty) {
        vehicleTypes.addAll(['Motorcycle', 'Car', 'Truck']);
      }
      
      // Determine services offered
      final List<String> services = [];
      if (tags['amenity'] == 'towing' || tags['emergency'] == 'towing') {
        services.add('Emergency');
      }
      if (tags['shop'] == 'car_repair') {
        services.add('Roadside');
      }
      if (services.isEmpty) {
        services.addAll(['Emergency', 'Scheduled']);
      }
      
      // Use real data from OpenStreetMap tags - no fake generation
      double rating = 0.0;
      int totalJobs = 0;
      
      // Try to get real rating from OpenStreetMap tags
      if (tags['rating'] != null) {
        rating = double.tryParse(tags['rating'].toString()) ?? 0.0;
      }
      
      // Try to get real review count from OpenStreetMap tags
      if (tags['reviews'] != null) {
        totalJobs = int.tryParse(tags['reviews'].toString()) ?? 0;
      }
      
      // If no real data available, don't show fake data
      if (rating == 0.0) rating = 0.0; // Will be handled in UI
      if (totalJobs == 0) totalJobs = 0; // Will be handled in UI
      
      // Determine working hours
      String workingHours = '24/7';
      if (tags['opening_hours'] != null) {
        workingHours = tags['opening_hours'];
      } else if (tags['shop'] == 'car_repair') {
        workingHours = '8AM-6PM';
      }
      
      // Use real pricing data from OpenStreetMap tags
      double baseFare = 0.0;
      double perKmRate = 0.0;
      
      // Try to get real pricing from OpenStreetMap tags
      if (tags['fee'] != null) {
        baseFare = double.tryParse(tags['fee'].toString()) ?? 0.0;
      }
      if (tags['rate'] != null) {
        perKmRate = double.tryParse(tags['rate'].toString()) ?? 0.0;
      }
      
      // If no real pricing data, set to 0 (will be calculated by location service)
      if (baseFare == 0.0) baseFare = 0.0;
      if (perKmRate == 0.0) perKmRate = 0.0;

      final email = tags['email'] ?? 
                   tags['contact:email'] ?? 
                   '';

      return TowingService(
        id: element['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        email: email,
        latitude: lat,
        longitude: lon,
        address: address,
        vehicleTypes: vehicleTypes,
        services: services,
        rating: double.parse(rating.toStringAsFixed(1)),
        totalJobs: totalJobs,
        isAvailable: true, // Assume available unless specified otherwise
        workingHours: workingHours,
        baseFare: baseFare,
        perKmRate: perKmRate,
        imageUrl: tags['image'] ?? tags['photo'] ?? '', // Use real image if available
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error parsing overpass element: $e');
      return null;
    }
  }

  EmergencyService? _parseEmergencyElement(Map<String, dynamic> element) {
    try {
      final tags = Map<String, dynamic>.from(element['tags'] ?? {});
      final lat = element['lat']?.toDouble() ?? element['center']?['lat']?.toDouble();
      final lon = element['lon']?.toDouble() ?? element['center']?['lon']?.toDouble();
      
      if (lat == null || lon == null) return null;

      final name = tags['name'] ?? 
                  tags['brand'] ?? 
                  tags['operator'] ?? 
                  'Emergency Service';
      
      final phone = tags['phone'] ?? 
                   tags['contact:phone'] ?? 
                   tags['emergency'] ?? 
                   '';
      
      final address = _buildAddress(tags);
      final type = tags['amenity'] ?? 'emergency';
      
      return EmergencyService(
        id: element['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        latitude: lat,
        longitude: lon,
        address: address,
        type: type,
        isAvailable: true,
      );
    } catch (e) {
      print('Error parsing emergency element: $e');
      return null;
    }
  }

  FuelStation? _parseFuelStationElement(Map<String, dynamic> element) {
    try {
      final tags = Map<String, dynamic>.from(element['tags'] ?? {});
      final lat = element['lat']?.toDouble() ?? element['center']?['lat']?.toDouble();
      final lon = element['lon']?.toDouble() ?? element['center']?['lon']?.toDouble();
      
      if (lat == null || lon == null) return null;

      final name = tags['name'] ?? 
                  tags['brand'] ?? 
                  tags['operator'] ?? 
                  'Fuel Station';
      
      final phone = tags['phone'] ?? 
                   tags['contact:phone'] ?? 
                   '';
      
      final address = _buildAddress(tags);
      final brand = tags['brand'] ?? '';
      final openingHours = tags['opening_hours'] ?? '24/7';
      
      return FuelStation(
        id: element['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: phone,
        latitude: lat,
        longitude: lon,
        address: address,
        brand: brand,
        openingHours: openingHours,
        isOpen: true, // Assume open unless specified otherwise
      );
    } catch (e) {
      print('Error parsing fuel station element: $e');
      return null;
    }
  }

  String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    
    if (tags['addr:housenumber'] != null) {
      parts.add(tags['addr:housenumber']);
    }
    if (tags['addr:street'] != null) {
      parts.add(tags['addr:street']);
    } else if (tags['addr:road'] != null) {
      parts.add(tags['addr:road']);
    }
    if (tags['addr:city'] != null) {
      parts.add(tags['addr:city']);
    } else if (tags['addr:town'] != null) {
      parts.add(tags['addr:town']);
    } else if (tags['addr:village'] != null) {
      parts.add(tags['addr:village']);
    }
    if (tags['addr:state'] != null) {
      parts.add(tags['addr:state']);
    }
    if (tags['addr:country'] != null) {
      parts.add(tags['addr:country']);
    }
    
    return parts.join(', ');
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * (3.14159265359 / 180.0);
}

class EmergencyService {
  final String id;
  final String name;
  final String phone;
  final double latitude;
  final double longitude;
  final String address;
  final String type; // 'police', 'hospital', 'fire_station'
  final bool isAvailable;

  EmergencyService({
    required this.id,
    required this.name,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.type,
    required this.isAvailable,
  });
}

class FuelStation {
  final String id;
  final String name;
  final String phone;
  final double latitude;
  final double longitude;
  final String address;
  final String brand;
  final String openingHours;
  final bool isOpen;

  FuelStation({
    required this.id,
    required this.name,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.brand,
    required this.openingHours,
    required this.isOpen,
  });
}
