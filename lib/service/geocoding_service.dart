import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GeocodingService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'TowingServiceApp/1.0 (contact: support@towingapp.com)';
  
  // Cache for geocoding results to avoid repeated API calls
  static final Map<String, GeocodingResult> _geocodingCache = {};
  static final Map<String, ReverseGeocodingResult> _reverseGeocodingCache = {};

  /// Search for locations using OpenStreetMap Nominatim API
  Future<List<GeocodingResult>> searchLocations(String query, {
    int limit = 10,
    String? countryCode,
    double? latitude,
    double? longitude,
    double radiusKm = 50.0,
  }) async {
    if (query.trim().isEmpty) return [];

    // Check cache first
    final cacheKey = '${query.toLowerCase()}_${countryCode ?? 'all'}_${limit}';
    if (_geocodingCache.containsKey(cacheKey)) {
      return [_geocodingCache[cacheKey]!];
    }

    try {
      final Map<String, String> queryParams = {
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        'extratags': '1',
        'namedetails': '1',
      };

      // Add country filter if specified
      if (countryCode != null) {
        queryParams['countrycodes'] = countryCode;
      }

      // Add proximity search if coordinates provided
      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude.toString();
        queryParams['lon'] = longitude.toString();
        queryParams['radius'] = (radiusKm * 1000).toString(); // Convert km to meters
      }

      final uri = Uri.parse('$_nominatimBaseUrl/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<GeocodingResult> results = data
            .map((json) => GeocodingResult.fromJson(json))
            .toList();

        // Cache the first result
        if (results.isNotEmpty) {
          _geocodingCache[cacheKey] = results.first;
        }

        return results;
      }
    } catch (e) {
      print('Geocoding error: $e');
    }

    return [];
  }

  /// Reverse geocoding - get address from coordinates
  Future<ReverseGeocodingResult?> reverseGeocode(double latitude, double longitude) async {
    final cacheKey = '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
    
    if (_reverseGeocodingCache.containsKey(cacheKey)) {
      return _reverseGeocodingCache[cacheKey];
    }

    try {
      final uri = Uri.parse('$_nominatimBaseUrl/reverse').replace(
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'json',
          'addressdetails': '1',
          'extratags': '1',
          'namedetails': '1',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final result = ReverseGeocodingResult.fromJson(data);
        
        // Cache the result
        _reverseGeocodingCache[cacheKey] = result;
        
        return result;
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }

    return null;
  }

  /// Get current location and reverse geocode it
  Future<LocationWithAddress?> getCurrentLocationWithAddress() async {
    try {
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      final address = await reverseGeocode(position.latitude, position.longitude);

      if (address != null) {
        return LocationWithAddress(
          position: position,
          address: address,
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
    }

    return null;
  }

  /// Search for nearby places of interest (gas stations, hospitals, etc.)
  Future<List<PlaceOfInterest>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    required String amenity, // 'fuel', 'hospital', 'police', 'restaurant'
    double radiusKm = 5.0,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse('$_nominatimBaseUrl/search').replace(
        queryParameters: {
          'q': '[amenity=$amenity]',
          'format': 'json',
          'limit': limit.toString(),
          'addressdetails': '1',
          'extratags': '1',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'radius': (radiusKm * 1000).toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((json) => PlaceOfInterest.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Nearby places search error: $e');
    }

    return [];
  }

  /// Clear cache (useful for testing or when you want fresh data)
  static void clearCache() {
    _geocodingCache.clear();
    _reverseGeocodingCache.clear();
  }
}

class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final String type; // 'house', 'road', 'city', 'country', etc.
  final Map<String, dynamic> address;
  final double? importance;
  final String? osmType;
  final int? osmId;

  GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.address,
    this.importance,
    this.osmType,
    this.osmId,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    return GeocodingResult(
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat'] ?? '0'),
      longitude: double.parse(json['lon'] ?? '0'),
      type: json['type'] ?? '',
      address: Map<String, dynamic>.from(json['address'] ?? {}),
      importance: json['importance']?.toDouble(),
      osmType: json['osm_type'],
      osmId: json['osm_id'],
    );
  }

  String get city => address['city'] ?? address['town'] ?? address['village'] ?? '';
  String get state => address['state'] ?? address['province'] ?? '';
  String get country => address['country'] ?? '';
  String get postcode => address['postcode'] ?? '';
  String get road => address['road'] ?? address['street'] ?? '';
  String get houseNumber => address['house_number'] ?? '';
  
  String get shortAddress {
    final parts = <String>[];
    if (houseNumber.isNotEmpty) parts.add(houseNumber);
    if (road.isNotEmpty) parts.add(road);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }
}

class ReverseGeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> address;
  final String? osmType;
  final int? osmId;

  ReverseGeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.osmType,
    this.osmId,
  });

  factory ReverseGeocodingResult.fromJson(Map<String, dynamic> json) {
    return ReverseGeocodingResult(
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat'] ?? '0'),
      longitude: double.parse(json['lon'] ?? '0'),
      address: Map<String, dynamic>.from(json['address'] ?? {}),
      osmType: json['osm_type'],
      osmId: json['osm_id'],
    );
  }

  String get city => address['city'] ?? address['town'] ?? address['village'] ?? '';
  String get state => address['state'] ?? address['province'] ?? '';
  String get country => address['country'] ?? '';
  String get postcode => address['postcode'] ?? '';
  String get road => address['road'] ?? address['street'] ?? '';
  String get houseNumber => address['house_number'] ?? '';
  
  String get shortAddress {
    final parts = <String>[];
    if (houseNumber.isNotEmpty) parts.add(houseNumber);
    if (road.isNotEmpty) parts.add(road);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }
}

class LocationWithAddress {
  final Position position;
  final ReverseGeocodingResult address;

  LocationWithAddress({
    required this.position,
    required this.address,
  });
}

class PlaceOfInterest {
  final String name;
  final String displayName;
  final double latitude;
  final double longitude;
  final String type;
  final Map<String, dynamic> address;
  final Map<String, dynamic>? extratags;

  PlaceOfInterest({
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.address,
    this.extratags,
  });

  factory PlaceOfInterest.fromJson(Map<String, dynamic> json) {
    return PlaceOfInterest(
      name: json['name'] ?? json['display_name'] ?? 'Unknown',
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat'] ?? '0'),
      longitude: double.parse(json['lon'] ?? '0'),
      type: json['type'] ?? '',
      address: Map<String, dynamic>.from(json['address'] ?? {}),
      extratags: json['extratags'] != null 
          ? Map<String, dynamic>.from(json['extratags']) 
          : null,
    );
  }

  String get city => address['city'] ?? address['town'] ?? address['village'] ?? '';
  String get road => address['road'] ?? address['street'] ?? '';
  
  String get shortAddress {
    final parts = <String>[];
    if (road.isNotEmpty) parts.add(road);
    if (city.isNotEmpty) parts.add(city);
    return parts.join(', ');
  }
}
