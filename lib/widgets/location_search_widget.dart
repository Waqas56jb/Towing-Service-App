import 'package:flutter/material.dart';
import '../service/geocoding_service.dart';
import '../service/towing_service_provider.dart';

class LocationSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Color iconColor;
  final Function(GeocodingResult)? onLocationSelected;
  final Function(double, double)? onCoordinatesSelected;
  final double? currentLatitude;
  final double? currentLongitude;
  final bool showCurrentLocationButton;

  const LocationSearchWidget({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.iconColor,
    this.onLocationSelected,
    this.onCoordinatesSelected,
    this.currentLatitude,
    this.currentLongitude,
    this.showCurrentLocationButton = false,
  }) : super(key: key);

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final TowingServiceProvider _towingServiceProvider = TowingServiceProvider();
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    if (query.length >= 2) {
      _performSearch(query);
    } else {
      _hideResults();
    }
  }

  Future<void> _performSearch(String query) async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _towingServiceProvider.searchLocations(
        query,
        limit: 8,
        latitude: widget.currentLatitude,
        longitude: widget.currentLongitude,
        radiusKm: 50.0,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _showResults = results.isNotEmpty;
        });
        _showOverlay();
      }
    } catch (e) {
      print('Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _showResults = false;
        });
        _hideResults();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();
    
    if (!_showResults || _searchResults.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: _getOverlayTop(),
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1B3C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5A45D2).withOpacity(0.3),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return _buildSearchResultItem(result);
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _hideResults() {
    setState(() {
      _showResults = false;
    });
    _removeOverlay();
  }

  double _getOverlayTop() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      return position.dy + renderBox.size.height + 5;
    }
    return 200; // Fallback position
  }

  Widget _buildSearchResultItem(GeocodingResult result) {
    return InkWell(
      onTap: () => _selectLocation(result),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF5A45D2).withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getLocationIcon(result.type),
              color: const Color(0xFF5A45D2),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.shortAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      result.shortAddress,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (result.importance != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A45D2).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(result.importance! * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getLocationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'house':
      case 'building':
        return Icons.home;
      case 'road':
      case 'street':
        return Icons.route;
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'country':
        return Icons.public;
      case 'postcode':
        return Icons.local_post_office;
      default:
        return Icons.place;
    }
  }

  void _selectLocation(GeocodingResult result) {
    widget.controller.text = result.displayName;
    _hideResults();
    
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(result);
    }
    
    if (widget.onCoordinatesSelected != null) {
      widget.onCoordinatesSelected!(result.latitude, result.longitude);
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      setState(() {
        _isSearching = true;
      });

      final locationWithAddress = await _towingServiceProvider.getCurrentLocationWithAddress();
      
      if (locationWithAddress != null && mounted) {
        widget.controller.text = locationWithAddress.address.displayName;
        
        if (widget.onLocationSelected != null) {
          // Create a GeocodingResult from the reverse geocoding result
          final result = GeocodingResult(
            displayName: locationWithAddress.address.displayName,
            latitude: locationWithAddress.position.latitude,
            longitude: locationWithAddress.position.longitude,
            type: 'current_location',
            address: locationWithAddress.address.address,
          );
          widget.onLocationSelected!(result);
        }
        
        if (widget.onCoordinatesSelected != null) {
          widget.onCoordinatesSelected!(
            locationWithAddress.position.latitude,
            locationWithAddress.position.longitude,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting current location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1B3C),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.iconColor.withOpacity(0.3),
            ),
          ),
          child: TextField(
            controller: widget.controller,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: Icon(widget.icon, color: widget.iconColor),
              suffixIcon: _isSearching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : widget.showCurrentLocationButton
                      ? IconButton(
                          icon: const Icon(Icons.my_location, color: Colors.green),
                          onPressed: _useCurrentLocation,
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            onTap: () {
              if (_searchResults.isNotEmpty) {
                _showOverlay();
              }
            },
          ),
        ),
        if (_showResults && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: Text(
              '${_searchResults.length} results found',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
