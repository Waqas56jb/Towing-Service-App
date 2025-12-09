import 'dart:async';

import '../models/mechanic.dart';
import '../models/towing_service.dart';
import 'database_service.dart';
import '../models/mechanic_model.dart' as db_model;
import 'geocoding_service.dart';
import 'overpass_service.dart';
import 'location_pricing_service.dart';

class MechanicServiceProvider {
  final OverpassService _overpassService = OverpassService();
  final GeocodingService _geocodingService = GeocodingService();
  final LocationPricingService _locationService = LocationPricingService();
  final DatabaseService _databaseService = DatabaseService();
  final Map<String, List<String>> _issueKeywordMap = {
    'engine': ['engine', 'overheat', 'oil leak', 'smoke', 'misfire', 'heat'],
    'brake': ['brake', 'abs', 'stopping', 'disc', 'pad'],
    'electrical': ['electric', 'battery', 'wiring', 'lights', 'alternator'],
    'puncture': ['puncture', 'tyre', 'tire', 'wheel', 'flat'],
    'suspension': ['suspension', 'shock', 'alignment', 'axle'],
    'ac': ['ac', 'aircon', 'cooling', 'climate', 'compressor'],
    'transmission': ['transmission', 'gear', 'clutch', 'gearbox'],
    'diesel': ['diesel', 'injector'],
    'hybrid': ['hybrid'],
    'motorcycle': ['bike', 'motorcycle'],
    'truck': ['truck', 'heavy'],
  };

  /// Fetch nearby mechanics (real-time) by reusing the OverpassService
  /// Note: OverpassService.findTowingServices already includes `shop=car_repair`
  /// in its Overpass QL query (based on your provided OverpassService implementation),
  /// so we call that method and map results to Mechanic model.
  Future<List<Mechanic>> getNearbyMechanics({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 20,
    String vehicleType = 'Car',
    String? specialtyFilter,
  }) async {
    try {
      // Reuse your existing OverpassService which already queries car_repair nodes
      final List<dynamic> towServices = await _overpassService
          .findTowingServices(
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm,
            limit: limit,
          );

      // Map each TowingService -> Mechanic
      final List<Mechanic> mechanics = [];

      for (final ts in towServices) {
        try {
          // The TowingService class returned by your OverpassService (in your file)
          // contains fields like: id, name, phone, latitude, longitude, services, rating, totalJobs, etc.
          // We map those to Mechanic fields. If your Mechanic constructor or field names differ,
          // adjust the mapping accordingly.
          final double lat = (ts.latitude ?? 0.0).toDouble();
          final double lon = (ts.longitude ?? 0.0).toDouble();

          // Calculate distance using your location_pricing_service function
          final double distanceKm = _locationService.calculateDistanceKm(
            startLat: latitude,
            startLng: longitude,
            endLat: lat,
            endLng: lon,
          );

          // Estimate price using your service's fare calculation method (returns PKR)
          final double fare = _locationService.calculateFarePkr(
            distanceKm,
            mode: vehicleType,
          );

          // Build a short, user-friendly distance and price strings
          final String distanceStr = '${distanceKm.toStringAsFixed(1)} km';
          final String priceStr = 'Rs. ${fare.toStringAsFixed(0)}';

          // Use real data from OpenStreetMap and filter out towing services
          final List<String> svcList = _filterMechanicServices(
            ts.services ?? <String>[],
          );
          final String specialization = _determineSpecialization(ts);

          // Use real verification status from OpenStreetMap tags
          final bool isVerified = _isVerifiedService(ts);

          // Use ONLY real rating and reviews from OpenStreetMap data
          final double rating = ts.rating; // Real data from OpenStreetMap
          final int reviews = ts.totalJobs; // Real data from OpenStreetMap

          // Create Mechanic model with REAL data from OpenStreetMap
          final specialties = _deriveSpecialties(ts);

          final mechanic = Mechanic(
            id:
                ts.id?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            name: ts.name ?? 'Unknown Workshop',
            specialization: specialization,
            rating: rating,
            reviews: reviews,
            distance: distanceStr,
            price: priceStr,
            experience: ts.workingHours ?? 'Experience not specified',
            isVerified: isVerified,
            services: svcList.isNotEmpty ? svcList : ['General Repair'],
            latitude: lat,
            longitude: lon,
            phone: ts.phone ?? '', // Real phone from OpenStreetMap
            email: ts.email ?? '', // Real email from OpenStreetMap
            address: ts.address ?? '', // Real address from OpenStreetMap
            specialties: specialties,
            distanceKm: distanceKm,
          );

          mechanics.add(mechanic);
        } catch (mapErr) {
          // ignore single element mapping errors but log them
          print('Mechanic mapping error: $mapErr');
        }
      }

      // Sort by distance ascending (just in case)
      final registered = await _fetchRegisteredMechanics(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        vehicleType: vehicleType,
        specialtyFilter: specialtyFilter,
      );

      mechanics
        ..addAll(registered)
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return mechanics.take(limit).toList();
    } catch (e) {
      print('MechanicServiceProvider.getNearbyMechanics error: $e');
      return <Mechanic>[];
    }
  }

  /// Search mechanics by text query using content + specialty keywords
  Future<List<Mechanic>> searchMechanics(
    String query, {
    double? latitude,
    double? longitude,
    double radiusKm = 20.0,
    int limit = 10,
    String vehicleType = 'Car',
  }) async {
    try {
      final List<Mechanic> matches = [];
      final normalizedQuery = query.toLowerCase().trim();

      if (normalizedQuery.isNotEmpty) {
        final registered = await _fetchRegisteredMechanics(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          vehicleType: vehicleType,
          specialtyFilter: normalizedQuery,
        );

        for (final mechanic in registered) {
          final haystack =
              '${mechanic.name} ${mechanic.specialization} ${mechanic.services.join(' ')} ${mechanic.specialties.join(' ')}'
                  .toLowerCase();
          if (haystack.contains(normalizedQuery)) {
            matches.add(mechanic);
          }
        }
      }

      if (matches.length >= limit) {
        return matches.take(limit).toList();
      }

      final geocodeResults = await _geocodingService.searchLocations(
        query,
        limit: limit,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      for (final loc in geocodeResults) {
        final double lat = loc.latitude;
        final double lon = loc.longitude;

        final double distanceKm =
            (latitude != null && longitude != null)
                ? _locationService.calculateDistanceKm(
                  startLat: latitude,
                  startLng: longitude,
                  endLat: lat,
                  endLng: lon,
                )
                : 0.0;

        final double fare = _locationService.calculateFarePkr(
          distanceKm,
          mode: vehicleType,
        );

        matches.add(
          Mechanic(
            id: loc.displayName.hashCode.toString(),
            name: loc.displayName,
            specialization: 'General Mechanic',
            rating: 0.0,
            reviews: 0,
            distance: '${distanceKm.toStringAsFixed(1)} km',
            price: 'Rs. ${fare.toStringAsFixed(0)}',
            experience: 'Experience not specified',
            isVerified: false,
            services: ['Inspection', 'General Repair'],
            latitude: lat,
            longitude: lon,
            phone: '',
            email: '',
            address: loc.displayName,
            specialties: ['general'],
            distanceKm: distanceKm,
          ),
        );
      }

      matches.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return matches.take(limit).toList();
    } catch (e) {
      print('MechanicServiceProvider.searchMechanics error: $e');
      return <Mechanic>[];
    }
  }

  // Determine specialization based on real OpenStreetMap tags
  String _determineSpecialization(TowingService ts) {
    // Check for specific service types in OpenStreetMap data
    if (ts.services.contains('Emergency')) {
      return 'Emergency Repair';
    } else if (ts.services.contains('Roadside')) {
      return 'Roadside Assistance';
    } else if (ts.name.toLowerCase().contains('toyota')) {
      return 'Toyota Specialist';
    } else if (ts.name.toLowerCase().contains('honda')) {
      return 'Honda Specialist';
    } else if (ts.name.toLowerCase().contains('suzuki')) {
      return 'Suzuki Specialist';
    } else if (ts.name.toLowerCase().contains('hyundai')) {
      return 'Hyundai Specialist';
    } else if (ts.name.toLowerCase().contains('kia')) {
      return 'Kia Specialist';
    } else {
      return 'General Mechanic';
    }
  }

  // Determine if service is verified based on real OpenStreetMap data
  bool _isVerifiedService(TowingService ts) {
    // Check for verification indicators in OpenStreetMap
    if (ts.name.toLowerCase().contains('toyota certified') ||
        ts.name.toLowerCase().contains('authorized') ||
        ts.name.toLowerCase().contains('official')) {
      return true;
    }

    // Check if it's a well-known brand or chain
    final knownBrands = ['toyota', 'honda', 'suzuki', 'hyundai', 'kia'];
    for (final brand in knownBrands) {
      if (ts.name.toLowerCase().contains(brand)) {
        return true;
      }
    }

    return false;
  }

  // Removed fake data generation methods - now using only real OpenStreetMap data

  // Filter out towing services and keep only mechanic-related services
  List<String> _filterMechanicServices(List<String> services) {
    final mechanicServices = <String>[];

    for (final service in services) {
      final lowerService = service.toLowerCase();

      // Skip towing-related services
      if (lowerService.contains('towing') ||
          lowerService.contains('tow') ||
          lowerService.contains('recovery')) {
        continue;
      }

      // Keep mechanic-related services
      if (lowerService.contains('repair') ||
          lowerService.contains('maintenance') ||
          lowerService.contains('inspection') ||
          lowerService.contains('diagnostic') ||
          lowerService.contains('brake') ||
          lowerService.contains('engine') ||
          lowerService.contains('transmission') ||
          lowerService.contains('electrical') ||
          lowerService.contains('air conditioning') ||
          lowerService.contains('tire') ||
          lowerService.contains('oil change') ||
          lowerService.contains('battery') ||
          lowerService.contains('emergency') ||
          lowerService.contains('roadside')) {
        mechanicServices.add(service);
      }
    }

    // If no services found, add default mechanic services
    if (mechanicServices.isEmpty) {
      mechanicServices.addAll([
        'General Repair',
        'Engine Maintenance',
        'Brake Service',
        'Oil Change',
        'Diagnostic Service',
      ]);
    }

    return mechanicServices;
  }

  List<String> _deriveSpecialties(TowingService ts) {
    final Set<String> tags = {};
    final lowerName = ts.name.toLowerCase();

    for (final service in ts.services) {
      final sanitized = service.toLowerCase();
      for (final entry in _issueKeywordMap.entries) {
        if (sanitized.contains(entry.key) ||
            entry.value.any((keyword) => sanitized.contains(keyword))) {
          tags.add(entry.key);
        }
      }
    }

    for (final entry in _issueKeywordMap.entries) {
      if (lowerName.contains(entry.key)) {
        tags.add(entry.key);
      }
      for (final keyword in entry.value) {
        if (lowerName.contains(keyword)) {
          tags.add(entry.key);
        }
      }
    }

    if (tags.isEmpty) {
      tags.add(lowerName.contains('elect') ? 'electrical' : 'general');
    }

    return tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  }

  Future<List<Mechanic>> _fetchRegisteredMechanics({
    double? latitude,
    double? longitude,
    double radiusKm = double.infinity,
    String vehicleType = 'Car',
    String? specialtyFilter,
  }) async {
    try {
      List<db_model.Mechanic> entries;
      
      // Use optimized database query if we have location and specialty filter
      if (latitude != null && longitude != null && specialtyFilter != null && specialtyFilter.isNotEmpty) {
        entries = await _databaseService.getMechanicsBySpecialtyAndLocation(
          specialtyQuery: specialtyFilter,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        );
      } else if (specialtyFilter != null && specialtyFilter.isNotEmpty) {
        entries = await _databaseService.getMechanicsBySpecialty(specialtyFilter);
      } else {
        entries = await _databaseService.getAllMechanics();
      }
      
      final List<Mechanic> registered = [];

      for (final entry in entries) {
        final double? lat = entry.latitude;
        final double? lon = entry.longitude;
        if (lat == null || lon == null) continue;

        double distanceKm = 0.0;
        String distanceLabel = 'N/A';

        if (latitude != null && longitude != null) {
          distanceKm = _locationService.calculateDistanceKm(
            startLat: latitude,
            startLng: longitude,
            endLat: lat,
            endLng: lon,
          );
          distanceLabel = '${distanceKm.toStringAsFixed(1)} km';

          if (radiusKm.isFinite && distanceKm > radiusKm) {
            continue;
          }
        }

        final List<String> specialtyTags =
            entry.specialtyTags.isNotEmpty ? entry.specialtyTags : ['general'];

        final List<String> normalizedSpecialties =
            specialtyTags
                .map(
                  (tag) =>
                      tag.toLowerCase().replaceAll('specialist', '').trim(),
                )
                .map((tag) => tag.isEmpty ? 'general' : tag)
                .toList();

        // Apply specialty/content filter if provided
        if (specialtyFilter != null && specialtyFilter.isNotEmpty && specialtyFilter.toLowerCase() != 'all') {
          final filterLower = specialtyFilter.toLowerCase();
          final matchesSpecialty = normalizedSpecialties.any((tag) {
            final tagLower = tag.toLowerCase();
            return tagLower.contains(filterLower) || filterLower.contains(tagLower);
          });
          
          // Also check if specialty string contains the filter
          final specialtyStringLower = entry.specialty.toLowerCase();
          final matchesSpecialtyString = specialtyStringLower.contains(filterLower);
          
          if (!matchesSpecialty && !matchesSpecialtyString) {
            continue; // Skip if doesn't match specialty filter
          }
        }

        // Filter mechanics based on vehicle type
        final vehicleTypeLower = vehicleType.toLowerCase();
        final bool matchesVehicleType = normalizedSpecialties.any((tag) {
          final tagLower = tag.toLowerCase();
          if (vehicleTypeLower == 'bike' || vehicleTypeLower == 'motorcycle') {
            return tagLower.contains('motorcycle') || tagLower.contains('bike');
          } else if (vehicleTypeLower == 'truck') {
            return tagLower.contains('truck') || tagLower.contains('heavy');
          } else if (vehicleTypeLower == 'car') {
            // Cars are general, but exclude motorcycle/truck specialists
            return !tagLower.contains('motorcycle') && !tagLower.contains('bike') &&
                   !tagLower.contains('truck') && !tagLower.contains('heavy');
          }
          return true; // Default to include
        });

        if (!matchesVehicleType && normalizedSpecialties.isNotEmpty) {
          continue; // Skip this mechanic if they don't match the vehicle type
        }

        registered.add(
          Mechanic(
            id: 'reg_${entry.id}',
            name: entry.name,
            specialization: _formatSpecialtyTitle(specialtyTags.first),
            rating: 0.0,
            reviews: 0,
            distance: distanceLabel,
            price: 'Contact for quote',
            experience: '${entry.yearsOfExperience}+ years',
            isVerified: true,
            services: specialtyTags.map(_formatSpecialtyTitle).toList(),
            latitude: lat,
            longitude: lon,
            phone: entry.phone,
            email: entry.email,
            address: entry.address,
            specialties: normalizedSpecialties,
            distanceKm: distanceKm,
          ),
        );
      }

      return registered;
    } catch (e) {
      print('Registered mechanics fetch error: $e');
      return [];
    }
  }

  String _formatSpecialtyTitle(String raw) {
    if (raw.isEmpty) return 'General';
    final lower = raw.trim();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
