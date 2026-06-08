class RentalTenantModel {
  final String id;
  final String rentalId;
  final String userId;
  final String tenantRole; // 'house_leader' or 'house_member'
  final DateTime? joinedAt;

  RentalTenantModel({
    required this.id,
    required this.rentalId,
    required this.userId,
    required this.tenantRole,
    this.joinedAt,
  });

  factory RentalTenantModel.fromJson(Map<String, dynamic> json) {
    return RentalTenantModel(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      userId: json['user_id'] as String,
      tenantRole: json['tenant_role'] as String,
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rental_id': rentalId,
      'user_id': userId,
      'tenant_role': tenantRole,
      if (joinedAt != null) 'joined_at': joinedAt?.toIso8601String(),
    };
  }
}
