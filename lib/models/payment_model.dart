import 'package:hive/hive.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 0)
class PaymentResponse {
  @HiveField(0)
  final bool success;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final List<Payment> data;

  @HiveField(3)
  final Pagination pagination;

  PaymentResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((payment) => Payment.fromJson(payment as Map<String, dynamic>))
          .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

@HiveType(typeId: 1)
class Payment {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int studentId;

  @HiveField(2)
  final int? feeCategoryId;

  @HiveField(3)
  final int accountId;

  @HiveField(4)
  final String transId;

  @HiveField(5)
  final String method;

  @HiveField(6)
  final double amount;

  @HiveField(7)
  final double? balance;

  @HiveField(8)
  final DateTime paymentDate;

  @HiveField(9)
  final String paymentType;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime updatedAt;

  @HiveField(12)
  final FeeCategory? feeCategory;

  @HiveField(13)
  final Account account;

  @HiveField(14)
  final Student student;

  Payment({
    required this.id,
    required this.studentId,
    this.feeCategoryId,
    required this.accountId,
    required this.transId,
    required this.method,
    required this.amount,
    this.balance,
    required this.paymentDate,
    required this.paymentType,
    required this.createdAt,
    required this.updatedAt,
    this.feeCategory,
    required this.account,
    required this.student,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int? ?? 0,
      studentId: json['student_id'] as int? ?? 0,
      feeCategoryId: json['fee_category_id'] as int?,
      accountId: json['account_id'] as int? ?? 0,
      transId: json['trans_id'] as String? ?? '',
      method: json['method'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      balance: json['balance'] != null ? double.tryParse(json['balance']?.toString() ?? '0') : null,
      paymentDate: DateTime.tryParse(json['payment_date'] as String? ?? '') ?? DateTime.now(),
      paymentType: json['payment_type'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
      feeCategory: json['fee_category'] != null
          ? FeeCategory.fromJson(json['fee_category'] as Map<String, dynamic>?)
          : null,
      account: Account.fromJson(json['account'] as Map<String, dynamic>? ?? {}),
      student: Student.fromJson(json['student'] as Map<String, dynamic>? ?? {}),
    );
  }
}

@HiveType(typeId: 2)
class FeeCategory {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int schoolId;

  @HiveField(2)
  final int branchId;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  FeeCategory({
    required this.id,
    required this.schoolId,
    required this.branchId,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeeCategory.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return FeeCategory(
      id: json['id'] as int? ?? 0,
      schoolId: json['school_id'] as int? ?? 0,
      branchId: json['branch_id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Uncategorized',
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

@HiveType(typeId: 3)
class Account {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int? branchId;

  @HiveField(2)
  final int accountTypeId;

  @HiveField(3)
  final int? parentId;

  @HiveField(4)
  final String name;

  @HiveField(5)
  final String code;

  @HiveField(6)
  final String currencyCode;

  @HiveField(7)
  final String openingBalance;

  @HiveField(8)
  final String? balanceType;

  @HiveField(9)
  final int isSystemAccount;

  @HiveField(10)
  final int isActive;

  @HiveField(11)
  final String? description;

  @HiveField(12)
  final DateTime createdAt;

  @HiveField(13)
  final DateTime updatedAt;

  Account({
    required this.id,
    this.branchId,
    required this.accountTypeId,
    this.parentId,
    required this.name,
    required this.code,
    required this.currencyCode,
    required this.openingBalance,
    this.balanceType,
    required this.isSystemAccount,
    required this.isActive,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Account.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return Account(
      id: json['id'] as int? ?? 0,
      branchId: json['branch_id'] as int?,
      accountTypeId: json['account_type_id'] as int? ?? 0,
      parentId: json['parent_id'] as int?,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      currencyCode: json['currency_code'] as String? ?? '',
      openingBalance: json['opening_balance'] as String? ?? '0',
      balanceType: json['balance_type'] as String?,
      isSystemAccount: json['is_system_account'] as int? ?? 0,
      isActive: json['is_active'] as int? ?? 0,
      description: json['description'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

@HiveType(typeId: 4)
class Student {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int classId;

  @HiveField(2)
  final int streamId;

  @HiveField(3)
  final int userId;

  @HiveField(4)
  final int schoolId;

  @HiveField(5)
  final int branchId;

  @HiveField(6)
  final int zoneId;

  @HiveField(7)
  final int termId;

  @HiveField(8)
  final int academicSessionId;

  @HiveField(9)
  final int estateId;

  @HiveField(10)
  final String admissionNo;

  @HiveField(11)
  final DateTime dob;

  @HiveField(31)
  final Branch branch;

  Student({
    required this.id,
    required this.classId,
    required this.streamId,
    required this.userId,
    required this.schoolId,
    required this.branchId,
    required this.zoneId,
    required this.termId,
    required this.academicSessionId,
    required this.estateId,
    required this.admissionNo,
    required this.dob,
    required this.branch,
  });

  factory Student.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return Student(
      id: json['id'] as int? ?? 0,
      classId: json['class_id'] as int? ?? 0,
      streamId: json['stream_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      schoolId: json['school_id'] as int? ?? 0,
      branchId: json['branch_id'] as int? ?? 0,
      zoneId: json['zone_id'] as int? ?? 0,
      termId: json['term_id'] as int? ?? 0,
      academicSessionId: json['academic_session_id'] as int? ?? 0,
      estateId: json['estate_id'] as int? ?? 0,
      admissionNo: json['admission_no'] as String? ?? '',
      dob: DateTime.tryParse(json['dob'] as String? ?? '') ?? DateTime.now(),
      branch: Branch.fromJson(json['branch'] as Map<String, dynamic>?),
    );
  }
}

@HiveType(typeId: 5)
class Branch {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int schoolId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String motto;

  @HiveField(4)
  final String address;

  @HiveField(5)
  final String contact;

  @HiveField(6)
  final String email;

  @HiveField(7)
  final String? website;

  @HiveField(8)
  final String smsBalance;

  @HiveField(9)
  final String smsPricing;

  @HiveField(10)
  final String paymentDetails;

  @HiveField(11)
  final String invoiceNotes;

  @HiveField(12)
  final String receiptNotes;

  @HiveField(13)
  final String? kraPin;

  @HiveField(14)
  final String? admissionPrefix;

  @HiveField(15)
  final String? admissionSuffix;

  @HiveField(16)
  final String? juniorSecAdmissionPrefix;

  @HiveField(17)
  final String? highSchoolPrefix;

  @HiveField(18)
  final String? highSchoolDetails;

  @HiveField(19)
  final String schoolLogo;

  @HiveField(20)
  final String? accountStampLogo;

  @HiveField(21)
  final String? reportStampLogo;

  @HiveField(22)
  final String? juniorSecLogo;

  @HiveField(23)
  final String? highSchoolLogo;

  @HiveField(24)
  final String primaryColor;

  @HiveField(25)
  final String secondaryColor;

  @HiveField(26)
  final DateTime createdAt;

  @HiveField(27)
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.motto,
    required this.address,
    required this.contact,
    required this.email,
    this.website,
    required this.smsBalance,
    required this.smsPricing,
    required this.paymentDetails,
    required this.invoiceNotes,
    required this.receiptNotes,
    this.kraPin,
    this.admissionPrefix,
    this.admissionSuffix,
    this.juniorSecAdmissionPrefix,
    this.highSchoolPrefix,
    this.highSchoolDetails,
    required this.schoolLogo,
    this.accountStampLogo,
    this.reportStampLogo,
    this.juniorSecLogo,
    this.highSchoolLogo,
    required this.primaryColor,
    required this.secondaryColor,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return Branch(
      id: json['id'] as int? ?? 0,
      schoolId: json['school_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      motto: json['motto'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      email: json['email'] as String? ?? '',
      website: json['website'] as String?,
      smsBalance: json['sms_balance'] as String? ?? '0',
      smsPricing: json['sms_pricing'] as String? ?? '0',
      paymentDetails: json['payment_details'] as String? ?? '',
      invoiceNotes: json['invoice_notes'] as String? ?? '',
      receiptNotes: json['receipt_notes'] as String? ?? '',
      kraPin: json['kra_pin'] as String?,
      admissionPrefix: json['admission_prefix'] as String?,
      admissionSuffix: json['admission_suffix'] as String?,
      juniorSecAdmissionPrefix: json['junior_sec_admission_prefix'] as String?,
      highSchoolPrefix: json['high_school_prefix'] as String?,
      highSchoolDetails: json['high_school_details'] as String?,
      schoolLogo: json['school_logo'] as String? ?? '',
      accountStampLogo: json['account_stamp_logo'] as String?,
      reportStampLogo: json['report_stamp_logo'] as String?,
      juniorSecLogo: json['junior_sec_logo'] as String?,
      highSchoolLogo: json['high_school_logo'] as String?,
      primaryColor: json['primary_color'] as String? ?? '#000000',
      secondaryColor: json['secondary_color'] as String? ?? '#000000',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

@HiveType(typeId: 6)
class Pagination {
  @HiveField(0)
  final int total;

  @HiveField(1)
  final int perPage;

  @HiveField(2)
  final int currentPage;

  @HiveField(3)
  final int lastPage;

  @HiveField(4)
  final int from;

  @HiveField(5)
  final int to;

  Pagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory Pagination.fromJson(Map<String, dynamic>? json) {
    json ??= {};

    return Pagination(
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 0,
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      from: json['from'] as int? ?? 0,
      to: json['to'] as int? ?? 0,
    );
  }
}