class Mechanic {
  final String id;
  final String name;
  final String specialization;
  final double rating;
  final int reviews;
  final String distance;
  final String price;
  final String experience;
  final bool isVerified;
  final List<String> services;
  final double latitude;
  final double longitude;
  final String phone; // Real phone from OpenStreetMap
  final String email; // Real email from OpenStreetMap
  final String address; // Real address from OpenStreetMap
  final List<String> specialties; // Mechanic-declared specialties
  final double distanceKm; // Precise distance used for ranking

  Mechanic({
    required this.id,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.price,
    required this.experience,
    required this.isVerified,
    required this.services,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
    required this.address,
    required this.specialties,
    required this.distanceKm,
  });

  Mechanic copyWith({
    String? id,
    String? name,
    String? specialization,
    double? rating,
    int? reviews,
    String? distance,
    String? price,
    String? experience,
    bool? isVerified,
    List<String>? services,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? address,
    List<String>? specialties,
    double? distanceKm,
  }) {
    return Mechanic(
      id: id ?? this.id,
      name: name ?? this.name,
      specialization: specialization ?? this.specialization,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      distance: distance ?? this.distance,
      price: price ?? this.price,
      experience: experience ?? this.experience,
      isVerified: isVerified ?? this.isVerified,
      services: services ?? this.services,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      specialties: specialties ?? this.specialties,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  factory Mechanic.fromJson(Map<String, dynamic> json) {
    return Mechanic(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      specialization: json['specialization'] ?? 'General Mechanic',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      distance: json['distance']?.toString() ?? 'N/A',
      price: json['price'] ?? 'N/A',
      experience: json['experience'] ?? 'N/A',
      isVerified: json['isVerified'] ?? false,
      services: List<String>.from(json['services'] ?? []),
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      specialties: List<String>.from(json['specialties'] ?? []),
      distanceKm: (json['distanceKm'] ?? 0.0).toDouble(),
    );
  }
}
