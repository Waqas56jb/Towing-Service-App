import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../service/location_pricing_service.dart';
import '../service/geocoding_service.dart';
import 'manual_location_widget.dart';

class AggressiveLocationWidget extends StatefulWidget {
  final Function(Position) onLocationFound;
  final Function(String) onAddressFound;

  const AggressiveLocationWidget({
    Key? key,
    required this.onLocationFound,
    required this.onAddressFound,
  }) : super(key: key);

  @override
  State<AggressiveLocationWidget> createState() => _AggressiveLocationWidgetState();
}

class _AggressiveLocationWidgetState extends State<AggressiveLocationWidget> {
  final LocationPricingService _locationService = LocationPricingService();
  final GeocodingService _geocodingService = GeocodingService();
  
  bool _isGettingLocation = false;
  int _attemptCount = 0;
  String _statusMessage = 'Getting your exact location...';
  Position? _lastPosition;
  double _bestAccuracy = double.infinity;

  @override
  void initState() {
    super.initState();
    _startAggressiveLocationSearch();
  }

  Future<void> _startAggressiveLocationSearch() async {
    setState(() {
      _isGettingLocation = true;
      _attemptCount = 0;
      _statusMessage = 'Getting your exact location...';
    });

    // Try multiple times with different strategies
    for (int attempt = 1; attempt <= 5; attempt++) {
      if (!mounted) return;
      
      setState(() {
        _attemptCount = attempt;
        _statusMessage = 'Attempt $attempt/5: Getting precise location...';
      });

      try {
        final position = await _locationService.getCurrentPosition();
        
        if (mounted) {
          setState(() {
            _lastPosition = position;
            if (position.accuracy < _bestAccuracy) {
              _bestAccuracy = position.accuracy;
            }
          });

          // If we get a good accuracy (less than 100m), use it
          if (position.accuracy < 100) {
            setState(() {
              _statusMessage = 'Excellent! Found your location with ${position.accuracy.toStringAsFixed(1)}m accuracy';
            });
            
            // Get address for this location
            await _getAddressForPosition(position);
            
            widget.onLocationFound(position);
            return;
          }
          
          // If accuracy is improving, keep trying
          if (attempt < 5) {
            setState(() {
              _statusMessage = 'Found location with ${position.accuracy.toStringAsFixed(1)}m accuracy. Trying for better...';
            });
            await Future.delayed(const Duration(seconds: 3));
          } else {
            // Use the best position we found
            setState(() {
              _statusMessage = 'Using best location found: ${position.accuracy.toStringAsFixed(1)}m accuracy';
            });
            
            await _getAddressForPosition(position);
            widget.onLocationFound(position);
            return;
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _statusMessage = 'Attempt $attempt failed: ${e.toString()}';
          });
          
          if (attempt < 5) {
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }
    }

    // If all attempts failed, show manual option
    if (mounted) {
      setState(() {
        _isGettingLocation = false;
        _statusMessage = 'Unable to get precise location. Please enter manually.';
      });
    }
  }

  Future<void> _getAddressForPosition(Position position) async {
    try {
      final address = await _geocodingService.reverseGeocode(position.latitude, position.longitude);
      if (address != null && mounted) {
        widget.onAddressFound(address.displayName);
      }
    } catch (e) {
      print('Failed to get address: $e');
    }
  }

  void _showManualLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => ManualLocationWidget(
        onLocationSelected: (location) {
          // Create a Position object from the manual location
          final position = Position(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: DateTime.now(),
            accuracy: 5.0, // Assume good accuracy for manual input
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
          
          widget.onLocationFound(position);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1B3C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isGettingLocation ? Colors.blue.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isGettingLocation ? Icons.my_location : Icons.location_searching,
                color: _isGettingLocation ? Colors.blue : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isGettingLocation ? 'Finding Your Exact Location' : 'Location Search Complete',
                  style: TextStyle(
                    color: _isGettingLocation ? Colors.blue : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_isGettingLocation) ...[
            // Progress indicator
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                    value: _attemptCount / 5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
            
            if (_lastPosition != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Best Location:',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accuracy: ${_lastPosition!.accuracy.toStringAsFixed(1)} meters',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      'Coordinates: ${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            // Final status
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            
            if (_lastPosition != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Location:',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accuracy: ${_lastPosition!.accuracy.toStringAsFixed(1)} meters',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      'Coordinates: ${_lastPosition!.latitude.toStringAsFixed(6)}, ${_lastPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ],
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              if (!_isGettingLocation) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startAggressiveLocationSearch,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Try Again', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showManualLocationDialog,
                  icon: const Icon(Icons.edit_location, size: 16),
                  label: const Text('Enter Manually', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
