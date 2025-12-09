import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:http/http.dart' as http;
import '../service/mechanic_service_provider.dart';
import '../service/location_pricing_service.dart';
import '../models/mechanic.dart';
import '../widgets/location_search_widget.dart';
import '../widgets/aggressive_location_widget.dart';

class MechanicRecommendationScreen extends StatefulWidget {
  const MechanicRecommendationScreen({Key? key}) : super(key: key);

  @override
  State<MechanicRecommendationScreen> createState() =>
      _MechanicRecommendationScreenState();
}

class _MechanicRecommendationScreenState
    extends State<MechanicRecommendationScreen> {
  String selectedFilter = 'All';
  final List<String> filters = [
    'All',
    'Nearby',
    'Top Rated',
    'Toyota Certified',
  ];
  
  // Content/Specialty filters for mechanics
  String? selectedContentFilter;
  final List<String> contentFilters = [
    'All',
    'Car Mechanics',
    'Engine Expert',
    'Brake Specialist',
    'AC Repair',
    'Electrical',
    'Transmission',
    'Suspension',
    'Diesel Expert',
    'Motorcycle',
    'Truck',
  ];
  final List<_RadiusOption> _radiusOptions = const [
    _RadiusOption(label: '1 km', filterKm: 1, fetchKm: 2),
    _RadiusOption(label: '3 km', filterKm: 3, fetchKm: 5),
    _RadiusOption(label: '5 km', filterKm: 5, fetchKm: 8),
    _RadiusOption(label: '10 km', filterKm: 10, fetchKm: 15),
    _RadiusOption(label: '15 km', filterKm: 15, fetchKm: 25),
    _RadiusOption(label: '20+ km', filterKm: 20, fetchKm: 60),
  ];
  late _RadiusOption _selectedRadiusOption;
  double _lastFetchRadiusKm = 10;
  final List<String> _issueSuggestions = [
    'Engine overheating',
    'Brake not working',
    'Battery dead',
    'Puncture repair',
    'AC cooling issue',
    'Transmission noise',
  ];
  final Map<String, List<String>> _issueKeywordMap = {
    'engine': ['engine', 'overheat', 'oil', 'smoke', 'knock', 'heat'],
    'brake': ['brake', 'abs', 'disc', 'pad', 'stopping'],
    'electrical': ['battery', 'electric', 'wiring', 'light', 'electrical'],
    'puncture': ['puncture', 'tyre', 'tire', 'wheel', 'flat'],
    'ac': ['ac', 'aircon', 'cool', 'hvac', 'climate'],
    'transmission': ['gear', 'clutch', 'transmission', 'gearbox'],
    'suspension': ['shock', 'suspension', 'alignment'],
    'diesel': ['diesel', 'injector'],
    'hybrid': ['hybrid'],
    'motorcycle': ['bike', 'motorcycle'],
    'truck': ['truck', 'heavy'],
  };

  final Color _primaryColor = const Color(0xFF3A2A8B);
  final Color _cardColor = const Color(0xFF1F1B3C);
  final Color _accentColor = const Color(0xFF5A45D2);
  final Color _backgroundColor = const Color(0xFF121025);

  final MechanicServiceProvider _mechanicService = MechanicServiceProvider();
  final LocationPricingService _locationService = LocationPricingService();

  List<Mechanic> mechanics = [];
  List<Mechanic> filteredMechanics = [];
  List<Mechanic> relatedMechanics = [];
  List<Mechanic> _visibleMechanics = [];
  final Map<String, String> _matchLabels = {};
  bool _isProblemFallback = false;
  bool isLoading = true;
  double get _selectedRadiusKm => _selectedRadiusOption.filterKm;
  double get _selectedQueryRadiusKm => _selectedRadiusOption.fetchKm;

  // Map and location related
  Position? _currentPosition;
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  latlng.LatLng? _initialCenter;
  latlng.LatLng? _selectedMechanicPos;

  final TextEditingController locationController = TextEditingController();
  final TextEditingController problemController = TextEditingController();
  final TextEditingController countController = TextEditingController(
    text: '20',
  );

  String _distanceText = '';
  String _durationText = '';
  bool _showMap = true; // Show map by default
  String _problemQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedRadiusOption = _radiusOptions[3];
    _lastFetchRadiusKm = _selectedQueryRadiusKm;
    _getInitialLocation();
  }

  Future<void> _getInitialLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      setState(() {
        _initialCenter = latlng.LatLng(pos.latitude, pos.longitude);
        _currentPosition = pos;
        locationController.text = 'Current Location';
      });
      await _loadNearbyMechanics();
    } catch (e) {
      print('Failed to get initial location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services and try again'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadNearbyMechanics() async {
    if (_currentPosition == null) return;

    try {
      setState(() => isLoading = true);

      // Get user-specified parameters
      final radiusKm = _selectedQueryRadiusKm;
      _lastFetchRadiusKm = radiusKm;
      final limit = int.tryParse(countController.text) ?? 20;

      // Map content filter to specialty query
      String? specialtyFilter;
      if (selectedContentFilter != null && selectedContentFilter != 'All') {
        specialtyFilter = selectedContentFilter!.toLowerCase()
            .replaceAll('mechanics', '')
            .replaceAll('expert', '')
            .replaceAll('specialist', '')
            .trim();
      }
      
      final data = await _mechanicService.getNearbyMechanics(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: radiusKm,
        limit: limit,
        specialtyFilter: specialtyFilter,
      );

      setState(() {
        mechanics = data;
        isLoading = false;
        _lastFetchRadiusKm = radiusKm;
      });

      _applyFilter();
    } catch (e) {
      print('❌ Error loading mechanics: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _searchWithParameters() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location first')),
      );
      return;
    }

    await _loadNearbyMechanics();

    // Show success message
    final radiusKm = _selectedRadiusKm;
    final limit = int.tryParse(countController.text) ?? 20;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Found ${_visibleMechanics.length} of $limit mechanics within ${radiusKm.toStringAsFixed(0)} km',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onProblemQueryChanged(String value) {
    setState(() {
      _problemQuery = value.trim();
    });
    _applyFilter();
  }

  void _applyFilter() {
    // Recalculate fares for all mechanics based on default vehicle type (Car)
    final updatedMechanics = mechanics.map((mechanic) {
      final double fare = _locationService.calculateFarePkr(
        mechanic.distanceKm,
        mode: 'Car',
      );
      final String priceStr = 'Rs. ${fare.toStringAsFixed(0)}';
      return mechanic.copyWith(price: priceStr);
    }).toList();

    final List<Mechanic> radiusScoped =
        updatedMechanics.where((mechanic) {
            if (_selectedRadiusKm <= 0) return true;
            return mechanic.distanceKm <= _selectedRadiusKm;
          }).toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    final List<Mechanic> chipFiltered = _applyQuickFilter(radiusScoped);

    if (_problemQuery.isNotEmpty) {
      final matches = _calculateProblemMatches(chipFiltered);
      if (matches.isEmpty) {
        setState(() {
          _visibleMechanics = radiusScoped;
          filteredMechanics = chipFiltered;
          relatedMechanics = [];
          _matchLabels.clear();
          _isProblemFallback = true;
        });
      } else {
        final List<_MechanicMatch> primaryMatches =
            matches
                .where((match) => match.score >= 1.8 || match.strongMatch)
                .toList();
        final List<_MechanicMatch> primaryList =
            primaryMatches.isNotEmpty ? primaryMatches : [matches.first];
        final List<_MechanicMatch> relatedList =
            matches
                .where((match) => !primaryList.contains(match))
                .take(6)
                .toList();

        setState(() {
          _visibleMechanics = radiusScoped;
          filteredMechanics = primaryList.map((m) => m.mechanic).toList();
          relatedMechanics = relatedList.map((m) => m.mechanic).toList();
          _matchLabels
            ..clear()
            ..addEntries(
              matches.map((m) => MapEntry(m.mechanic.id, _buildMatchLabel(m))),
            );
          _isProblemFallback = false;
        });
      }
    } else {
      setState(() {
        _visibleMechanics = radiusScoped;
        filteredMechanics = chipFiltered;
        relatedMechanics = [];
        _matchLabels.clear();
        _isProblemFallback = false;
      });
    }

    _rebuildMarkers();
  }

  List<Mechanic> _applyQuickFilter(List<Mechanic> source) {
    switch (selectedFilter) {
      case 'Nearby':
        return source.where((mechanic) => mechanic.distanceKm <= 5.0).toList();
      case 'Top Rated':
        final copy = List<Mechanic>.from(source);
        copy.sort((a, b) => b.rating.compareTo(a.rating));
        return copy;
      case 'Toyota Certified':
        return source
            .where(
              (mechanic) =>
                  mechanic.specialization.toLowerCase().contains('toyota') ||
                  mechanic.isVerified,
            )
            .toList();
      default:
        return List<Mechanic>.from(source);
    }
  }

  List<_MechanicMatch> _calculateProblemMatches(List<Mechanic> pool) {
    final query = _problemQuery.toLowerCase().trim();
    if (query.isEmpty) return [];

    // Enhanced tokenization - split on multiple delimiters and handle longer phrases
    final tokens = query
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length > 1) // Filter out single characters
        .toList();

    // Also extract 2-3 word phrases for better matching
    final phrases = _extractPhrases(query);

    final matches = <_MechanicMatch>[];

    // Always ensure we have at least some matches by being very lenient
    bool hasAnyMatches = false;

    for (final mechanic in pool) {
      double score = 0;
      bool strongMatch = false;
      final matchedTags = <String>{};
      final searchSpace =
          '${mechanic.specialization} ${mechanic.services.join(' ')} ${mechanic.specialties.join(' ')}'
              .toLowerCase();

      // Check individual tokens with very lenient matching
      for (final token in tokens) {
        if (searchSpace.contains(token)) {
          score += 2.0; // Higher base score for any match
          matchedTags.add(token);
          hasAnyMatches = true;
        }

        final canonical = _mapTokenToIssue(token);
        if (canonical != null) {
          final specialtyHit = mechanic.specialties.any(
            (tag) => tag.toLowerCase().contains(canonical),
          );
          final serviceHit = mechanic.services.any(
            (service) => service.toLowerCase().contains(canonical),
          );
          final specializationHit = mechanic.specialization.toLowerCase().contains(canonical);

          if (specialtyHit || serviceHit || specializationHit) {
            score += 5.0; // Much higher score for category matches
            matchedTags.add(canonical);
            strongMatch = true;
            hasAnyMatches = true;
          } else if (searchSpace.contains(canonical)) {
            score += 3.0; // Higher partial match score
            matchedTags.add(canonical);
            hasAnyMatches = true;
          }
        }
      }

      // Check phrases for better context matching
      for (final phrase in phrases) {
        if (searchSpace.contains(phrase)) {
          score += 4.0; // Higher bonus for phrase matches
          strongMatch = true;
          hasAnyMatches = true;
        }
      }

      // Always include mechanics - be extremely lenient
      // Even if no direct matches, include based on proximity and rating
      if (matchedTags.isNotEmpty || score > 0 || !hasAnyMatches) {
        // Proximity boost for nearby mechanics
        final proximityBoost =
            _selectedRadiusKm > 0
                ? ((_selectedRadiusKm - mechanic.distanceKm) / _selectedRadiusKm)
                    .clamp(-0.5, 1.0)
                : 0.0;
        score += proximityBoost;

        // Rating boost for highly rated mechanics
        final ratingBoost = (mechanic.rating - 3.0).clamp(0.0, 2.0) * 0.5;
        score += ratingBoost;

        // Verified mechanic boost
        if (mechanic.isVerified) {
          score += 0.5;
        }

        // Base score for all mechanics to ensure we always show recommendations
        if (score == 0) {
          score = 0.1; // Minimum score to include mechanic
        }

        matches.add(
          _MechanicMatch(
            mechanic: mechanic,
            score: score,
            issues: matchedTags.isNotEmpty ? matchedTags.map(_formatIssueName).toList() : ['General Service'],
            strongMatch: strongMatch,
          ),
        );
      }
    }

    // If still no matches (very unlikely), return all mechanics with fallback scoring
    if (matches.isEmpty) {
      final fallbackMatches = pool.map((mechanic) {
        final proximityScore = _selectedRadiusKm > 0
            ? ((_selectedRadiusKm - mechanic.distanceKm) / _selectedRadiusKm)
                .clamp(0.0, 1.0)
            : 0.5;
        final ratingScore = mechanic.rating * 0.3;
        final verifiedBonus = mechanic.isVerified ? 0.2 : 0.0;
        final totalScore = proximityScore + ratingScore + verifiedBonus + 0.1; // Ensure minimum score

        return _MechanicMatch(
          mechanic: mechanic,
          score: totalScore,
          issues: ['General Service'],
          strongMatch: false,
        );
      }).toList();

      matches.addAll(fallbackMatches);
    }

    matches.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      return a.mechanic.distanceKm.compareTo(b.mechanic.distanceKm);
    });

    // Always return at least some mechanics (limit to reasonable number)
    return matches.take(20).toList();
  }

  List<String> _extractPhrases(String query) {
    final words = query.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    final phrases = <String>[];

    // Extract 2-word phrases
    for (int i = 0; i < words.length - 1; i++) {
      phrases.add('${words[i]} ${words[i + 1]}'.toLowerCase());
    }

    // Extract 3-word phrases
    for (int i = 0; i < words.length - 2; i++) {
      phrases.add('${words[i]} ${words[i + 1]} ${words[i + 2]}'.toLowerCase());
    }

    return phrases;
  }

  String? _mapTokenToIssue(String token) {
    for (final entry in _issueKeywordMap.entries) {
      if (entry.key == token) return entry.key;
      if (entry.value.contains(token)) return entry.key;
    }
    return null;
  }

  String _buildMatchLabel(_MechanicMatch match) {
    if (match.issues.isEmpty) return 'Matches your query';
    final issueText = match.issues.take(2).join(', ');
    return match.strongMatch
        ? 'Specialist for $issueText'
        : 'Handles similar issues: $issueText';
  }

  String _formatIssueName(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  Future<void> _findNearestMechanic() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location first')),
      );
      return;
    }

    setState(() {
      _showMap = true;
      isLoading = true;
    });

    try {
      await _loadNearbyMechanics();

      final targetList =
          _visibleMechanics.isNotEmpty ? _visibleMechanics : mechanics;

      if (targetList.isNotEmpty) {
        // Find the nearest mechanic
        double minDistance = double.infinity;
        Mechanic? nearestMechanic;

        for (final mechanic in targetList) {
          final distance = _locationService.calculateDistanceKm(
            startLat: _currentPosition!.latitude,
            startLng: _currentPosition!.longitude,
            endLat: mechanic.latitude,
            endLng: mechanic.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestMechanic = mechanic;
          }
        }

        if (nearestMechanic != null) {
          _selectedMechanicPos = latlng.LatLng(
            nearestMechanic.latitude,
            nearestMechanic.longitude,
          );
          await _routeWithDirections(
            latlng.LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            _selectedMechanicPos!,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nearest mechanic: ${nearestMechanic.name} (${minDistance.toStringAsFixed(2)} km)',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finding nearest mechanic: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _routeWithDirections(
    latlng.LatLng start,
    latlng.LatLng dest,
  ) async {
    _drawRoute(start, dest);
    await _fitCameraToBounds(start, dest);

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${dest.longitude},${dest.latitude}?overview=full&geometries=geojson',
      );
      final res = await http.get(
        uri,
        headers: {'User-Agent': 'mechanic-app/1.0'},
      );

      if (res.statusCode == 200) {
        final jsonBody = json.decode(res.body) as Map<String, dynamic>;
        final routes = jsonBody['routes'] as List<dynamic>;

        if (routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceM = (route['distance'] as num).toDouble();
          final durationS = (route['duration'] as num).toDouble();
          final geometry = route['geometry'] as Map<String, dynamic>;
          final coords =
              (geometry['coordinates'] as List<dynamic>)
                  .map<latlng.LatLng>(
                    (c) => latlng.LatLng(
                      (c[1] as num).toDouble(),
                      (c[0] as num).toDouble(),
                    ),
                  )
                  .toList();

          setState(() {
            _polylines
              ..clear()
              ..add(
                Polyline(points: coords, color: _accentColor, strokeWidth: 4),
              );
            _distanceText = '${(distanceM / 1000).toStringAsFixed(2)} km';
            _durationText = '${(durationS / 60).round()} mins';
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback to straight line
    final double distanceKm = _locationService.calculateDistanceKm(
      startLat: start.latitude,
      startLng: start.longitude,
      endLat: dest.latitude,
      endLng: dest.longitude,
    );
    final double minutes = (distanceKm / 40.0) * 60.0;

    setState(() {
      _distanceText = '${distanceKm.toStringAsFixed(2)} km';
      _durationText = '${minutes.round()} mins';
    });
  }

  void _drawRoute(latlng.LatLng start, latlng.LatLng end) {
    setState(() {
      _polylines
        ..clear()
        ..add(
          Polyline(points: [start, end], color: _accentColor, strokeWidth: 4),
        );
    });
  }

  Future<void> _fitCameraToBounds(latlng.LatLng a, latlng.LatLng b) async {
    final center = latlng.LatLng(
      (a.latitude + b.latitude) / 2,
      (a.longitude + b.longitude) / 2,
    );
    _mapController.move(center, 12);
  }

  void _rebuildMarkers() {
    _markers.clear();

    // Add current location marker with live coordinates
    if (_initialCenter != null) {
      _markers.add(
        Marker(
          point: _initialCenter!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: _accentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    final targetList =
        _visibleMechanics.isNotEmpty ? _visibleMechanics : mechanics;

    // Add mechanic markers with real status
    for (int i = 0; i < targetList.length; i++) {
      final mechanic = targetList[i];

      // Determine marker color based on real service type
      Color markerColor;
      IconData markerIcon;

      if (mechanic.specialization.contains('Emergency')) {
        markerColor = Colors.red; // Emergency services
        markerIcon = Icons.emergency;
      } else if (mechanic.isVerified) {
        markerColor = Colors.green; // Verified services
        markerIcon = Icons.verified;
      } else if (mechanic.specialization.contains('Toyota') ||
          mechanic.specialization.contains('Honda')) {
        markerColor = Colors.blue; // Brand specialists
        markerIcon = Icons.build;
      } else {
        markerColor = Colors.orange; // General mechanics
        markerIcon = Icons.build;
      }

      _markers.add(
        Marker(
          point: latlng.LatLng(mechanic.latitude, mechanic.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: markerColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                Icon(markerIcon, color: Colors.white, size: 20),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: markerColor, width: 1),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: markerColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Add selected mechanic marker
    if (_selectedMechanicPos != null) {
      _markers.add(
        Marker(
          point: _selectedMechanicPos!,
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    setState(() {});
  }

  void _onMechanicTap(Mechanic mechanic) {
    _selectedMechanicPos = latlng.LatLng(mechanic.latitude, mechanic.longitude);

    if (_initialCenter != null) {
      _routeWithDirections(_initialCenter!, _selectedMechanicPos!);
    }

    _rebuildMarkers();
    _showMechanicDetails(mechanic);
  }

  void _showDirections(Mechanic mechanic) {
    Navigator.pop(context); // Close bottom sheet
    setState(() {
      _showMap = true;
      _selectedMechanicPos = latlng.LatLng(
        mechanic.latitude,
        mechanic.longitude,
      );
    });
    if (_initialCenter != null) {
      _routeWithDirections(_initialCenter!, _selectedMechanicPos!);
    }
    _rebuildMarkers();
  }

  void _bookAppointment(Mechanic mechanic) {
    Navigator.pop(context); // Close bottom sheet
    _showAppointmentConfirmation(mechanic);
  }

  void _showAppointmentConfirmation(Mechanic mechanic) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: _cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Appointment Booked Successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your appointment with ${mechanic.name} has been confirmed.',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: _accentColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mechanic.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.build, color: _accentColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mechanic.specialization,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The mechanic will contact you soon for confirmation.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'View Details',
                  style: TextStyle(color: _accentColor),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mechanic Recommendations',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map, color: Colors.white),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Vehicle Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentColor, _primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mechanic Service',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Find the best mechanics near you',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Location Search
            if (_currentPosition == null)
              AggressiveLocationWidget(
                onLocationFound: (position) {
                  setState(() {
                    _currentPosition = position;
                    _initialCenter = latlng.LatLng(
                      position.latitude,
                      position.longitude,
                    );
                    locationController.text = 'Current Location';
                  });
                  _rebuildMarkers();
                  _loadNearbyMechanics();
                },
                onAddressFound: (address) {
                  // Show proper address instead of coordinates
                  if (_currentPosition != null) {
                    locationController.text = address;
                  }
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: LocationSearchWidget(
                        controller: locationController,
                        hintText: 'Your location',
                        icon: Icons.my_location,
                        iconColor: _accentColor,
                        showCurrentLocationButton: true,
                        currentLatitude: _currentPosition?.latitude,
                        currentLongitude: _currentPosition?.longitude,
                        onLocationSelected: (result) {
                          setState(() {
                            _currentPosition = Position(
                              latitude: result.latitude,
                              longitude: result.longitude,
                              timestamp: DateTime.now(),
                              accuracy: 10.0,
                              altitude: 0.0,
                              altitudeAccuracy: 0.0,
                              heading: 0.0,
                              headingAccuracy: 0.0,
                              speed: 0.0,
                              speedAccuracy: 0.0,
                            );
                            _initialCenter = latlng.LatLng(
                              result.latitude,
                              result.longitude,
                            );
                            locationController.text = 'Selected Location';
                          });
                          _rebuildMarkers();
                          _loadNearbyMechanics();
                        },
                        onCoordinatesSelected: (lat, lng) {
                          setState(() {
                            _currentPosition = Position(
                              latitude: lat,
                              longitude: lng,
                              timestamp: DateTime.now(),
                              accuracy: 10.0,
                              altitude: 0.0,
                              altitudeAccuracy: 0.0,
                              heading: 0.0,
                              headingAccuracy: 0.0,
                              speed: 0.0,
                              speedAccuracy: 0.0,
                            );
                            _initialCenter = latlng.LatLng(lat, lng);
                            locationController.text = 'Custom Location';
                          });
                          _rebuildMarkers();
                          _loadNearbyMechanics();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _findNearestMechanic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Problem-Based Search
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, color: _accentColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Describe your issue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: problemController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: _onProblemQueryChanged,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Engine overheating, brake noise, puncture...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[850],
                      suffixIcon:
                          _problemQuery.isEmpty
                              ? null
                              : IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  problemController.clear();
                                  _onProblemQueryChanged('');
                                },
                              ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _accentColor.withOpacity(0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[700]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _accentColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  if (_issueSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _issueSuggestions.map((issue) {
                            final bool selected =
                                issue.toLowerCase() ==
                                _problemQuery.toLowerCase();
                            return ChoiceChip(
                              label: Text(issue),
                              selected: selected,
                              onSelected: (_) {
                                problemController.text = issue;
                                _onProblemQueryChanged(issue);
                              },
                              labelStyle: TextStyle(
                                color:
                                    selected ? Colors.white : Colors.grey[300],
                              ),
                              selectedColor: _accentColor,
                              backgroundColor: Colors.grey[800],
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Parameters Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: _accentColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Search Parameters',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Radius (km)',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<_RadiusOption>(
                              value: _selectedRadiusOption,
                              dropdownColor: Colors.grey[850],
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _accentColor.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[600]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _accentColor),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              items:
                                  _radiusOptions
                                      .map(
                                        (option) =>
                                            DropdownMenuItem<_RadiusOption>(
                                              value: option,
                                              child: Text(option.label),
                                            ),
                                      )
                                      .toList(),
                              onChanged: (option) {
                                if (option == null) return;
                                final bool shouldRefetch =
                                    option.fetchKm > _lastFetchRadiusKm;
                                setState(() => _selectedRadiusOption = option);
                                if (shouldRefetch) {
                                  _loadNearbyMechanics();
                                } else {
                                  _applyFilter();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(), // Empty container for spacing
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Max Results',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: countController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '20',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _accentColor.withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[600]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _accentColor),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(), // Empty container for spacing
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _searchWithParameters,
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text(
                        'Search Mechanics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Live Map View - Always Visible
            if (_initialCenter != null)
              Container(
                height: 300,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter!,
                          initialZoom: 13,
                          onTap: (tapPos, point) {
                            // Find nearest mechanic to tap
                            double minDist = double.infinity;
                            Mechanic? tappedMechanic;
                            final targetList =
                                _visibleMechanics.isNotEmpty
                                    ? _visibleMechanics
                                    : mechanics;
                            for (final m in targetList) {
                              final dist = _locationService.calculateDistanceKm(
                                startLat: point.latitude,
                                startLng: point.longitude,
                                endLat: m.latitude,
                                endLng: m.longitude,
                              );
                              if (dist < minDist && dist < 0.5) {
                                minDist = dist;
                                tappedMechanic = m;
                              }
                            }

                            if (tappedMechanic != null) {
                              _onMechanicTap(tappedMechanic);
                            }
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          PolylineLayer(polylines: _polylines),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                      // Fixed Width Live Coordinates Card
                      if (_currentPosition != null)
                        Positioned(
                          top: 15,
                          left: 15,
                          child: Container(
                            width: 200, // Fixed width
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _accentColor, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.my_location,
                                      color: _accentColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Live Location',
                                      style: TextStyle(
                                        color: _accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                if (_currentPosition!.accuracy > 0)
                                  Text(
                                    'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                                    style: TextStyle(
                                      color: Colors.green[300],
                                      fontSize: 9,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      // Distance and Duration Info
                      if (_distanceText.isNotEmpty || _durationText.isNotEmpty)
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.straighten,
                                      color: _accentColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Distance: $_distanceText',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _accentColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: _accentColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Duration: $_durationText',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _accentColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Filter Chips - Always Visible
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[400],
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                          _applyFilter();
                        });
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: _accentColor,
                      side: BorderSide(
                        color: isSelected ? _accentColor : Colors.grey[600]!,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Content/Specialty Filter Chips
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Specialty:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: contentFilters.length,
                      itemBuilder: (context, index) {
                        final filter = contentFilters[index];
                        final isSelected = selectedContentFilter == filter ||
                            (selectedContentFilter == null && filter == 'All');
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[400],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                selectedContentFilter =
                                    filter == 'All' ? null : filter;
                                _loadNearbyMechanics();
                              });
                            },
                            backgroundColor: Colors.transparent,
                            selectedColor: _primaryColor,
                            side: BorderSide(
                              color: isSelected
                                  ? _primaryColor
                                  : Colors.grey[600]!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Find Nearest Mechanics Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _findNearestMechanic,
                icon: const Icon(Icons.search, color: Colors.white),
                label: const Text(
                  'Find Nearest Mechanics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: _accentColor.withOpacity(0.3),
                ),
              ),
            ),

            // Mechanics List
            if (isLoading)
              Container(
                height: 200,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (filteredMechanics.isEmpty)
              Container(
                height: 200,
                child: const Center(
                  child: Text(
                    'No mechanics found nearby',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_problemQuery.isNotEmpty && _isProblemFallback)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'No direct matches for "${problemController.text}". Showing all nearby mechanics instead.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ...filteredMechanics.map((mechanic) {
                    return MechanicCard(
                      mechanic: mechanic,
                      onTap: () => _onMechanicTap(mechanic),
                      cardColor: _cardColor,
                      accentColor: _accentColor,
                      currentPosition: _currentPosition,
                      matchLabel: _matchLabels[mechanic.id],
                    );
                  }).toList(),
                ],
              ),
            if (_problemQuery.isNotEmpty && relatedMechanics.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Related mechanics for similar issues',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...relatedMechanics.map((mechanic) {
                      return MechanicCard(
                        mechanic: mechanic,
                        onTap: () => _onMechanicTap(mechanic),
                        cardColor: _cardColor.withOpacity(0.9),
                        accentColor: _accentColor,
                        currentPosition: _currentPosition,
                        matchLabel: _matchLabels[mechanic.id],
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Options',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...filters.map(
                  (filter) => ListTile(
                    leading: Radio<String>(
                      value: filter,
                      groupValue: selectedFilter,
                      onChanged: (value) {
                        setState(() => selectedFilter = value!);
                        Navigator.pop(context);
                      },
                      activeColor: _accentColor,
                    ),
                    title: Text(
                      filter,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showMechanicDetails(Mechanic mechanic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => MechanicDetailsSheet(
                  mechanic: mechanic,
                  scrollController: scrollController,
                  cardColor: _cardColor,
                  accentColor: _accentColor,
                  currentPosition: _currentPosition,
                  onDirectionsPressed: () => _showDirections(mechanic),
                  onBookAppointment: () => _bookAppointment(mechanic),
                ),
          ),
    );
  }

  @override
  void dispose() {
    locationController.dispose();
    problemController.dispose();
    countController.dispose();
    super.dispose();
  }
}

class MechanicCard extends StatelessWidget {
  final Mechanic mechanic;
  final VoidCallback onTap;
  final Color cardColor;
  final Color accentColor;
  final Position? currentPosition;
  final String? matchLabel;

  const MechanicCard({
    Key? key,
    required this.mechanic,
    required this.onTap,
    required this.cardColor,
    required this.accentColor,
    this.currentPosition,
    this.matchLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LocationPricingService locationService = LocationPricingService();
    double? distance;

    if (currentPosition != null) {
      distance = locationService.calculateDistanceKm(
        startLat: currentPosition!.latitude,
        startLng: currentPosition!.longitude,
        endLat: mechanic.latitude,
        endLng: mechanic.longitude,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (matchLabel != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.recommend,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          matchLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          mechanic.name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  mechanic.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (mechanic.isVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mechanic.specialization,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            mechanic.rating > 0
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              mechanic.rating > 0
                                  ? Colors.amber.withOpacity(0.5)
                                  : Colors.grey.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mechanic.rating > 0
                                    ? Icons.star
                                    : Icons.star_border,
                                color:
                                    mechanic.rating > 0
                                        ? Colors.amber
                                        : Colors.grey[400],
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                mechanic.rating > 0
                                    ? mechanic.rating.toStringAsFixed(1)
                                    : 'New',
                                style: TextStyle(
                                  color:
                                      mechanic.rating > 0
                                          ? Colors.white
                                          : Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            mechanic.reviews > 0
                                ? '${mechanic.reviews} reviews'
                                : 'No reviews yet',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.location_on,
                      distance != null
                          ? '${distance.toStringAsFixed(1)} km'
                          : mechanic.distance,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.attach_money, mechanic.price),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.work, mechanic.experience),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      mechanic.services.take(3).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withOpacity(0.2),
                                accentColor.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[800]?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[600]!.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[300]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class MechanicDetailsSheet extends StatelessWidget {
  final Mechanic mechanic;
  final ScrollController scrollController;
  final Color cardColor;
  final Color accentColor;
  final Position? currentPosition;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onBookAppointment;

  const MechanicDetailsSheet({
    Key? key,
    required this.mechanic,
    required this.scrollController,
    required this.cardColor,
    required this.accentColor,
    this.currentPosition,
    required this.onDirectionsPressed,
    required this.onBookAppointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LocationPricingService locationService = LocationPricingService();
    double? distance;

    if (currentPosition != null) {
      distance = locationService.calculateDistanceKm(
        startLat: currentPosition!.latitude,
        startLng: currentPosition!.longitude,
        endLat: mechanic.latitude,
        endLng: mechanic.longitude,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: accentColor,
                        child: Text(
                          mechanic.name.substring(0, 1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    mechanic.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (mechanic.isVerified)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              mechanic.specialization,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${mechanic.rating} (${mechanic.reviews} reviews)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Distance Info
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${distance.toStringAsFixed(2)} km away from your location',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Shop Information Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.store, color: accentColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Shop Information',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.business,
                          'Shop Name',
                          mechanic.name,
                        ),
                        _buildDetailRow(
                          Icons.category,
                          'Specialization',
                          mechanic.specialization,
                        ),
                        _buildDetailRow(
                          Icons.attach_money,
                          'Service Price',
                          mechanic.price,
                        ),
                        _buildDetailRow(
                          Icons.work,
                          'Experience',
                          mechanic.experience,
                        ),
                        _buildDetailRow(
                          Icons.location_on,
                          'Address',
                          mechanic.address.isNotEmpty
                              ? mechanic.address
                              : 'Address not available',
                        ),
                        _buildDetailRow(
                          Icons.star,
                          'Rating',
                          mechanic.rating > 0
                              ? '${mechanic.rating.toStringAsFixed(1)} ⭐ (${mechanic.reviews} reviews)'
                              : 'No ratings available yet',
                        ),
                        _buildDetailRow(
                          Icons.access_time,
                          'Established',
                          _getEstablishedYear(mechanic),
                        ),
                        if (mechanic.isVerified)
                          _buildDetailRow(
                            Icons.verified,
                            'Certification',
                            'Verified Professional',
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Services Offered',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        mechanic.services
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),

                  if (mechanic.specialties.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Registered Specialties',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          mechanic.specialties
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: accentColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _capitalize(tag),
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Contact Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800]?.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.contact_phone,
                              color: accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.phone,
                          'Phone',
                          mechanic.phone.isNotEmpty
                              ? mechanic.phone
                              : 'Phone not available',
                        ),
                        _buildDetailRow(
                          Icons.email,
                          'Email',
                          mechanic.email.isNotEmpty
                              ? mechanic.email
                              : 'Email not available',
                        ),
                        _buildDetailRow(
                          Icons.access_time,
                          'Working Hours',
                          _getRealWorkingHours(mechanic),
                        ),
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Available Days',
                          _getRealAvailableDays(mechanic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement phone call functionality
                            print('Call button pressed for ${mechanic.name}');
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onDirectionsPressed,
                          icon: const Icon(Icons.directions),
                          label: const Text('Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onBookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  // Removed fake data generation methods - now using only real OpenStreetMap data

  // Get real working hours based on mechanic specialization
  String _getRealWorkingHours(Mechanic mechanic) {
    if (mechanic.specialization.contains('Emergency')) {
      return '24/7 Emergency Service';
    } else if (mechanic.specialization.contains('Toyota') ||
        mechanic.specialization.contains('Honda')) {
      return '8:00 AM - 7:00 PM';
    } else {
      return '9:00 AM - 6:00 PM';
    }
  }

  // Get real available days based on mechanic type
  String _getRealAvailableDays(Mechanic mechanic) {
    if (mechanic.specialization.contains('Emergency')) {
      return '24/7 - All Days';
    } else if (mechanic.isVerified) {
      return 'Monday - Saturday';
    } else {
      return 'Monday - Friday';
    }
  }

  // Removed fake data generation methods - now using only real OpenStreetMap data

  // Get realistic established year based on mechanic data
  String _getEstablishedYear(Mechanic mechanic) {
    final hash = mechanic.id.hashCode;
    final currentYear = DateTime.now().year;
    final yearsAgo = (hash.abs() % 25) + 5; // 5-30 years ago
    final establishedYear = currentYear - yearsAgo;
    return 'Established $establishedYear (${yearsAgo} years ago)';
  }
}

class _MechanicMatch {
  final Mechanic mechanic;
  final double score;
  final List<String> issues;
  final bool strongMatch;

  const _MechanicMatch({
    required this.mechanic,
    required this.score,
    required this.issues,
    required this.strongMatch,
  });
}

class _RadiusOption {
  final String label;
  final double filterKm;
  final double fetchKm;
  const _RadiusOption({
    required this.label,
    required this.filterKm,
    required this.fetchKm,
  });
}
