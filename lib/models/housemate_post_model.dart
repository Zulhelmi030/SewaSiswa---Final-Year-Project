class HousematePostModel {
  final String id;
  final String rentalId;
  final String authorId;
  final String title;
  final String description;
  final List<String> preferences;
  final DateTime? createdAt;

  HousematePostModel({
    required this.id,
    required this.rentalId,
    required this.authorId,
    required this.title,
    required this.description,
    required this.preferences,
    this.createdAt,
  });

  factory HousematePostModel.fromJson(Map<String, dynamic> json) {
    return HousematePostModel(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      preferences: (json['preferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ?? 
          [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rental_id': rentalId,
      'author_id': authorId,
      'title': title,
      'description': description,
      'preferences': preferences,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
