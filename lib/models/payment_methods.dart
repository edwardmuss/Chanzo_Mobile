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
    // Safely parse credentials: if it's a Map, use it. If it's a List (like []), default to empty {}
    Map<String, dynamic> safeCredentials = {};
    if (json['api_credentials'] is Map) {
      safeCredentials = Map<String, dynamic>.from(json['api_credentials']);
    }

    return PaymentMethod(
      name: key,
      credentials: safeCredentials,
      // Added safety: handles both int (1/0) and boolean (true/false) responses
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}