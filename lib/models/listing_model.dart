class ListingModel {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? postcode;
  final String? state;
  final double monthlyRent;
  final double? deposit;
  final String? houseRule;
  final String? genderPreference;
  final List<String>? facilities;
  final String? status;
  final double? rating;
  final int? reviewCount;
  final String postType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // All photo URLs from listing_photos join
  final List<String> imageUrls;

  // Housemate post: room slot tracking
  final int? totalSlots;
  final int? occupiedSlots;

  ListingModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.postcode,
    this.state,
    required this.monthlyRent,
    this.deposit,
    this.houseRule,
    this.genderPreference,
    this.facilities,
    this.status,
    this.rating,
    this.reviewCount,
    this.postType = 'property',
    this.createdAt,
    this.updatedAt,
    this.imageUrls = const [],
    this.totalSlots,
    this.occupiedSlots,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    final photos = json['listing_photos'];
    // Extract all photo URLs from joined listing_photos if present
    List<String> imageUrlsList = [];
    if (photos != null && photos is List) {
      imageUrlsList = photos
          .map((p) => p['photo_url'] as String?)
          .whereType<String>()
          .toList();
    }

    // Parse facilities array from Postgres TEXT[]
    List<String>? facilitiesList;
    final rawFacilities = json['facilities'];
    if (rawFacilities != null && rawFacilities is List) {
      facilitiesList = List<String>.from(rawFacilities);
    }

    return ListingModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      latitude: json['latitude'] != null
          ? (json['latitude'] is String
                ? double.tryParse(json['latitude']) ?? 0.0
                : (json['latitude'] as num).toDouble())
          : 0.0,
      longitude: json['longitude'] != null
          ? (json['longitude'] is String
                ? double.tryParse(json['longitude']) ?? 0.0
                : (json['longitude'] as num).toDouble())
          : 0.0,
      city: json['city'] as String?,
      postcode: json['postcode'] as String?,
      state: json['state'] as String?,
      monthlyRent: json['monthly_rent'] is String
          ? double.tryParse(json['monthly_rent']) ?? 0.0
          : (json['monthly_rent'] as num).toDouble(),
      deposit: json['deposit'] != null
          ? (json['deposit'] is String
                ? double.tryParse(json['deposit'])
                : (json['deposit'] as num).toDouble())
          : null,
      houseRule: json['house_rule'] as String?,
      genderPreference: json['gender_preference'] as String?,
      facilities: facilitiesList,
      status: json['status'] as String?,
      rating: json['rating'] != null
          ? (json['rating'] is String
                ? double.tryParse(json['rating'])
                : (json['rating'] as num).toDouble())
          : null,
      reviewCount: json['review_count'] as int?,
      postType: json['post_type'] as String? ?? 'property',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      imageUrls: imageUrlsList,
      totalSlots: json['total_slots'] as int?,
      occupiedSlots: json['occupied_slots'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (city != null) 'city': city,
      if (postcode != null) 'postcode': postcode,
      if (state != null) 'state': state,
      'monthly_rent': monthlyRent,
      if (deposit != null) 'deposit': deposit,
      if (houseRule != null) 'house_rule': houseRule,
      if (genderPreference != null) 'gender_preference': genderPreference,
      if (facilities != null) 'facilities': facilities,
      'post_type': postType,
      if (status != null) 'status': status,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'review_count': reviewCount,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt?.toIso8601String(),
      if (totalSlots != null) 'total_slots': totalSlots,
      if (occupiedSlots != null) 'occupied_slots': occupiedSlots,
    };
  }

  /// First photo URL — used by cards and legacy widgets
  String? get imageUrl => imageUrls.firstOrNull;

  /// Slots still available (housemate posts only)
  int? get availableSlots {
    if (totalSlots == null || occupiedSlots == null) return null;
    return totalSlots! - occupiedSlots!;
  }

  /// Display address combining address + postcode + city + state smartly
  String get fullAddress {
    List<String> parts = [address];
    
    if (postcode != null && postcode!.isNotEmpty && !address.contains(postcode!)) {
      parts.add(postcode!);
    }
    if (city != null && city!.isNotEmpty && !address.toLowerCase().contains(city!.toLowerCase())) {
      parts.add(city!);
    }
    if (state != null && state!.isNotEmpty && !address.toLowerCase().contains(state!.toLowerCase())) {
      parts.add(state!);
    }
    
    return parts.join(', ');
  }

  /// Whether the listing is currently available
  bool get isAvailable => status == 'available';

  /// Display-friendly rating string (e.g. "4.5" or "No ratings yet")
  String get ratingDisplay {
    if (rating == null || reviewCount == 0) return 'No ratings yet';
    return rating!.toStringAsFixed(1);
  }
}
