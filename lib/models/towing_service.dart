class TowingService {
  final String id;
  final String name;
  final String phone;
  final String email;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> vehicleTypes; // ['Motorcycle', 'Car', 'Truck']
  final List<String> services; // ['Emergency', 'Scheduled', 'Accident', 'Roadside']
  final double rating;
  final int totalJobs;
  final bool isAvailable;
  final String workingHours; // "24/7" or "8AM-6PM"
  final double baseFare;
  final double perKmRate;
  final String imageUrl;
  final DateTime lastUpdated;

  TowingService({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.vehicleTypes,
    required this.services,
    required this.rating,
    required this.totalJobs,
    required this.isAvailable,
    required this.workingHours,
    required this.baseFare,
    required this.perKmRate,
    required this.imageUrl,
    required this.lastUpdated,
  });

  factory TowingService.fromJson(Map<String, dynamic> json) {
    return TowingService(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? '',
      vehicleTypes: List<String>.from(json['vehicleTypes'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalJobs: json['totalJobs'] ?? 0,
      isAvailable: json['isAvailable'] ?? false,
      workingHours: json['workingHours'] ?? '',
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      perKmRate: (json['perKmRate'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'vehicleTypes': vehicleTypes,
      'services': services,
      'rating': rating,
      'totalJobs': totalJobs,
      'isAvailable': isAvailable,
      'workingHours': workingHours,
      'baseFare': baseFare,
      'perKmRate': perKmRate,
      'imageUrl': imageUrl,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
