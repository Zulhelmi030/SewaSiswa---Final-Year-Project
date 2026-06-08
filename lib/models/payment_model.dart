class PaymentModel {
  final String id;
  final String rentalId;
  final String senderId;
  final String receiverId;
  final double amount;
  final String status; // 'pending', 'completed', 'failed'
  final DateTime? paymentDate;

  PaymentModel({
    required this.id,
    required this.rentalId,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    required this.status,
    this.paymentDate,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      rentalId: json['rental_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rental_id': rentalId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'amount': amount,
      'status': status,
      if (paymentDate != null) 'payment_date': paymentDate?.toIso8601String(),
    };
  }
}
