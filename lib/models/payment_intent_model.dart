class PaymentIntentModel {
  final String status;
  final String clientSecret;
  final String transactionId;

  PaymentIntentModel({
    required this.status,
    required this.clientSecret,
    required this.transactionId,
  });


  factory PaymentIntentModel.fromJson(Map<String, dynamic> json) {
    return PaymentIntentModel(
      status: json['status'] ?? '',
      clientSecret: json['client_secret'] ?? '',
      transactionId: json['transaction_id'] ?? '',
    );
  }
}