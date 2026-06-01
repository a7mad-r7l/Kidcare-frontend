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
      status: json['status']?.toString() ?? '',
      clientSecret: json['client_secret']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString() ?? '',
    );
  }
}