
import '../../globalclass/kiotapay_constants.dart';
import '../../models/payment_methods.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PaymentMethodsService {
  final _storage = const FlutterSecureStorage();

  Future<List<PaymentMethod>> fetchActiveMethods() async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse(KiotaPayConstants.getPaymentsMethods),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch payment methods (${response.statusCode})');
    }

    final Map<String, dynamic> jsonData = json.decode(response.body);
    final data = jsonData['data'] as Map<String, dynamic>;

    return data.entries
        .map((e) => PaymentMethod.fromJson(e.key, e.value))
        .where((method) => method.isActive)
        .toList();
  }
}

