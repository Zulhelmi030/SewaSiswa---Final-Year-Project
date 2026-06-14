class RentalTenantModel {
  final String id;
  final String listingId;
  final String userId;
  final DateTime? joinedAt;
  final String? status;

  RentalTenantModel({
    required this.id,
    required this.listingId,
    required this.userId,
    this.joinedAt,
    this.status,
  });

  factory RentalTenantModel.fromJson(Map<String, dynamic> json) {
    return RentalTenantModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'user_id': userId,
      if (joinedAt != null) 'joined_at': joinedAt?.toIso8601String(),
      if (status != null) 'status': status,
    };
  }
}
