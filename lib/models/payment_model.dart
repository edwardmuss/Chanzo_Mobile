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
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List)
          .map((payment) => Payment.fromJson(payment))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
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
      id: json['id'],
      studentId: json['student_id'],
      feeCategoryId: json['fee_category_id'],
      accountId: json['account_id'],
      transId: json['trans_id'],
      method: json['method'],
      amount: double.parse(json['amount'].toString()),
      balance: json['balance'] != null ? double.parse(json['balance'].toString()) : null,
      paymentDate: DateTime.parse(json['payment_date']),
      paymentType: json['payment_type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      feeCategory: json['fee_category'] != null ? FeeCategory.fromJson(json['fee_category']) : null,
      account: Account.fromJson(json['account']),
      student: Student.fromJson(json['student']),
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
    if (json == null) {
      throw Exception("FeeCategory JSON is null");
    }

    return FeeCategory(
      id: json['id'] ?? 0,
      schoolId: json['school_id'] ?? 0,
      branchId: json['branch_id'] ?? 0,
      name: json['name'] ?? 'Uncategorized',
      description: json['description'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
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

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      branchId: json['branch_id'],
      accountTypeId: json['account_type_id'],
      parentId: json['parent_id'],
      name: json['name'],
      code: json['code'],
      currencyCode: json['currency_code'],
      openingBalance: json['opening_balance'],
      balanceType: json['balance_type'],
      isSystemAccount: json['is_system_account'],
      isActive: json['is_active'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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

  @HiveField(12)
  final int initialClassId;

  @HiveField(13)
  final int initialStreamId;

  @HiveField(14)
  final int initialTermId;

  @HiveField(15)
  final int initialAcademicSessionId;

  @HiveField(16)
  final DateTime enrolDate;

  @HiveField(17)
  final String gender;

  @HiveField(18)
  final String type;

  @HiveField(19)
  final String term;

  @HiveField(20)
  final String year;

  @HiveField(21)
  final String transport;

  @HiveField(22)
  final String? bloodGroup;

  @HiveField(23)
  final String? allergies;

  @HiveField(24)
  final String? medicalInfo;

  @HiveField(25)
  final String? photoPath;

  @HiveField(26)
  final int active;

  @HiveField(27)
  final int graduated;

  @HiveField(28)
  final DateTime createdAt;

  @HiveField(29)
  final DateTime updatedAt;

  @HiveField(30)
  final DateTime? deletedAt;

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
    required this.initialClassId,
    required this.initialStreamId,
    required this.initialTermId,
    required this.initialAcademicSessionId,
    required this.enrolDate,
    required this.gender,
    required this.type,
    required this.term,
    required this.year,
    required this.transport,
    this.bloodGroup,
    this.allergies,
    this.medicalInfo,
    this.photoPath,
    required this.active,
    required this.graduated,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.branch,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      classId: json['class_id'],
      streamId: json['stream_id'],
      userId: json['user_id'],
      schoolId: json['school_id'],
      branchId: json['branch_id'],
      zoneId: json['zone_id'],
      termId: json['term_id'],
      academicSessionId: json['academic_session_id'],
      estateId: json['estate_id'],
      admissionNo: json['admission_no'],
      dob: DateTime.parse(json['dob']),
      initialClassId: json['initial_class_id'],
      initialStreamId: json['initial_stream_id'],
      initialTermId: json['initial_term_id'],
      initialAcademicSessionId: json['initial_academic_session_id'],
      enrolDate: DateTime.parse(json['enrol_date']),
      gender: json['gender'],
      type: json['type'],
      term: json['term'],
      year: json['year'],
      transport: json['transport'],
      bloodGroup: json['blood_group'],
      allergies: json['allergies'],
      medicalInfo: json['medical_info'],
      photoPath: json['photo_path'],
      active: json['active'],
      graduated: json['graduated'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      branch: Branch.fromJson(json['branch']),
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

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      schoolId: json['school_id'],
      name: json['name'],
      motto: json['motto'],
      address: json['address'],
      contact: json['contact'],
      email: json['email'],
      website: json['website'],
      smsBalance: json['sms_balance'],
      smsPricing: json['sms_pricing'],
      paymentDetails: json['payment_details'],
      invoiceNotes: json['invoice_notes'],
      receiptNotes: json['receipt_notes'],
      kraPin: json['kra_pin'],
      admissionPrefix: json['admission_prefix'],
      admissionSuffix: json['admission_suffix'],
      juniorSecAdmissionPrefix: json['junior_sec_admission_prefix'],
      highSchoolPrefix: json['high_school_prefix'],
      highSchoolDetails: json['high_school_details'],
      schoolLogo: json['school_logo'],
      accountStampLogo: json['account_stamp_logo'],
      reportStampLogo: json['report_stamp_logo'],
      juniorSecLogo: json['junior_sec_logo'],
      highSchoolLogo: json['high_school_logo'],
      primaryColor: json['primary_color'],
      secondaryColor: json['secondary_color'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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