class ReviewModel {
  final String id;
  final String rentalId;
  final String reviewerId;
  final double rating;
  final String? comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.rentalId,
    required this.reviewerId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rental_id': rentalId,
      'reviewer_id': reviewerId,
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
