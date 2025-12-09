import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../service/geocoding_service.dart';
import '../service/towing_service_provider.dart';
import 'manual_location_widget.dart';

class LocationAccuracyWidget extends StatefulWidget {
  final Position position;
  final Function(Position) onLocationUpdated;
  final Function(String) onAddressUpdated;
  final Function(latlng.LatLng)? onManualLocationSelected;

  const LocationAccuracyWidget({
    Key? key,
    required this.position,
    required this.onLocationUpdated,
    required this.onAddressUpdated,
    this.onManualLocationSelected,
  }) : super(key: key);

  @override
  State<LocationAccuracyWidget> createState() => _LocationAccuracyWidgetState();
}

class _LocationAccuracyWidgetState extends State<LocationAccuracyWidget> {
  final TowingServiceProvider _towingServiceProvider = TowingServiceProvider();
  ReverseGeocodingResult? _address;
  bool _isLoadingAddress = false;
  double _accuracy = 0.0;

  @override
  void initState() {
    super.initState();
    _accuracy = widget.position.accuracy;
    _getAddressFromPosition();
  }

  Future<void> _getAddressFromPosition() async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final address = await _towingServiceProvider.reverseGeocode(
        widget.position.latitude,
        widget.position.longitude,
      );
      
      if (mounted) {
        setState(() {
          _address = address;
          _isLoadingAddress = false;
        });
        
        if (address != null) {
          widget.onAddressUpdated(address.displayName);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  Future<void> _refreshLocation() async {
    try {
      final newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      );
      
      if (mounted) {
        setState(() {
          _accuracy = newPosition.accuracy;
        });
        
        widget.onLocationUpdated(newPosition);
        await _getAddressFromPosition();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh location: $e')),
        );
      }
    }
  }

  Color _getAccuracyColor() {
    if (_accuracy <= 10) return Colors.green;
    if (_accuracy <= 50) return Colors.orange;
    return Colors.red;
  }

  String _getAccuracyText() {
    if (_accuracy <= 10) return 'High Accuracy';
    if (_accuracy <= 50) return 'Medium Accuracy';
    return 'Low Accuracy';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1B3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getAccuracyColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _getAccuracyColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Location Accuracy',
                style: TextStyle(
                  color: _getAccuracyColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                onPressed: _refreshLocation,
                tooltip: 'Refresh Location',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Accuracy: ${_accuracy.toStringAsFixed(1)} meters',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            _getAccuracyText(),
            style: TextStyle(
              color: _getAccuracyColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoadingAddress)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Getting address...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            )
          else if (_address != null) ...[
            Text(
              'Address:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _address!.displayName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          if (_accuracy > 50)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location accuracy is low. Try moving to an open area or refresh location.',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (widget.onManualLocationSelected != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ManualLocationWidget(
                              onLocationSelected: (location) {
                                widget.onManualLocationSelected!(location);
                              },
                              currentAddress: _address?.displayName,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_location, size: 16),
                        label: const Text('Enter Manual Location', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
