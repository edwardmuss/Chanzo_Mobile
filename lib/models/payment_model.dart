import 'package:hive/hive.dart';

// part 'payment_model.g.dart';

@HiveType(typeId: 0)
class Payment {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int studentId;

  @HiveField(2)
  final int? feeCategoryId;

  @HiveField(3)
  final int? accountId;

  @HiveField(4)
  final String transId;

  @HiveField(5)
  final String method;

  @HiveField(6)
  final double amount;

  @HiveField(7)
  final DateTime paymentDate;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final String paymentType;

  Payment({
    required this.id,
    required this.studentId,
    this.feeCategoryId,
    this.accountId,
    required this.transId,
    required this.method,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentType,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      studentId: json['student_id'],
      feeCategoryId: json['fee_category_id'],
      accountId: json['account_id'],
      transId: json['trans_id'],
      method: json['method'],
      amount: double.parse(json['amount'].toString()),
      paymentDate: DateTime.parse(json['payment_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      paymentType: json['payment_type'],
    );
  }
}

class PaymentResponse {
  final List<Payment> payments;
  final Pagination pagination;

  PaymentResponse({
    required this.payments,
    required this.pagination,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      payments: (json['data'] as List)
          .map((payment) => Payment.fromJson(payment))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class Pagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'],
      perPage: json['per_page'],
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      from: json['from'] ?? 0,
      to: json['to'] ?? 0,
    );
  }
}