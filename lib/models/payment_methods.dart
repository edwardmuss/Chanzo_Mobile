class PaymentMethod {
  final String name;
  final Map<String, dynamic> credentials;
  final bool isActive;

  PaymentMethod({
    required this.name,
    required this.credentials,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(String key, Map<String, dynamic> json) {
    return PaymentMethod(
      name: key,
      credentials: Map<String, dynamic>.from(json['api_credentials'] ?? {}),
      isActive: json['is_active'] == 1,
    );
  }
}
