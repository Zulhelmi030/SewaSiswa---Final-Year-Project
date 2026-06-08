class UserModel {
  final String id;
  final String fullName;
  final String? email;
  final String? globalRole; // 'student' or 'owner'
  final String? matricNumber;
  final String? faculty;
  final String? phoneNumber;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    this.email,
    this.globalRole,
    this.matricNumber,
    this.faculty,
    this.phoneNumber,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      globalRole: json['global_role'] as String?,
      matricNumber: json['matric_number'] as String?,
      faculty: json['faculty'] as String?,
      phoneNumber: json['phone_number'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      if (email != null) 'email': email,
      if (globalRole != null) 'global_role': globalRole,
      if (matricNumber != null) 'matric_number': matricNumber,
      if (faculty != null) 'faculty': faculty,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
