class FeeStructureResponse {
  final bool success;
  final String message;
  final FeeStructureData data;

  FeeStructureResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory FeeStructureResponse.fromJson(Map<String, dynamic> json) {
    return FeeStructureResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: FeeStructureData.fromJson(json['data'] ?? {}),
    );
  }
}

class FeeStructureData {
  final Student student;
  final List<FeeSession> fees;
  final double unallocatedPayments;
  final String? selectedSessionId;
  final String? selectedTermId;
  final List<AcademicSession> academicSessions;
  final AcademicSession activeSession;
  final Term activeTerm;

  FeeStructureData({
    required this.student,
    required this.fees,
    required this.unallocatedPayments,
    this.selectedSessionId,
    this.selectedTermId,
    required this.academicSessions,
    required this.activeSession,
    required this.activeTerm,
  });

  factory FeeStructureData.fromJson(Map<String, dynamic> json) {
    return FeeStructureData(
      student: Student.fromJson(json['student'] ?? {}),
      fees: (json['fees'] as List<dynamic>?)
          ?.map((x) => FeeSession.fromJson(x))
          .toList() ??
          [],
      unallocatedPayments:
      (json['unallocatedPayments'] ?? 0).toDouble(),
      selectedSessionId: json['selectedSessionId']?.toString(),
      selectedTermId: json['selectedTermId']?.toString(),
      academicSessions: (json['academicSessions'] as List<dynamic>?)
          ?.map((x) => AcademicSession.fromJson(x))
          .toList() ??
          [],
      activeSession:
      AcademicSession.fromJson(json['activeSession'] ?? {}),
      activeTerm: Term.fromJson(json['activeTerm'] ?? {}),
    );
  }
}

class Student {
  final int id;
  final String admissionNo;
  final String gender;
  final String type;
  final String term;
  final String year;
  final String? photoPath;

  Student({
    required this.id,
    required this.admissionNo,
    required this.gender,
    required this.type,
    required this.term,
    required this.year,
    this.photoPath,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      admissionNo: json['admission_no'] ?? '',
      gender: json['gender'] ?? '',
      type: json['type'] ?? '',
      term: json['term'] ?? '',
      year: json['year'] ?? '',
      photoPath: json['photo_path'],
    );
  }
}

class FeeSession {
  final int session;
  final DateTime startDate;
  final DateTime endDate;
  final double sessionTotalWithoutDiscounts;
  final double sessionTotalDiscounts;
  final double sessionTotalFees;
  final double sessionTotalPayments;
  final double sessionBalance;
  final double openingBalance;
  final Map<String, TermFee> terms;

  FeeSession({
    required this.session,
    required this.startDate,
    required this.endDate,
    required this.sessionTotalWithoutDiscounts,
    required this.sessionTotalDiscounts,
    required this.sessionTotalFees,
    required this.sessionTotalPayments,
    required this.sessionBalance,
    required this.openingBalance,
    required this.terms,
  });

  factory FeeSession.fromJson(Map<String, dynamic> json) {
    final termsJson = json['terms'] as Map<String, dynamic>? ?? {};
    final termsMap = termsJson.map((key, value) {
      return MapEntry(key, TermFee.fromJson(value));
    });

    return FeeSession(
      session: json['session'] ?? 0,
      startDate: DateTime.tryParse(json['start_date'] ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ??
          DateTime.now(),
      sessionTotalWithoutDiscounts:
      (json['session_total_without_discounts'] ?? 0).toDouble(),
      sessionTotalDiscounts:
      (json['session_total_discounts'] ?? 0).toDouble(),
      sessionTotalFees: (json['session_total_fees'] ?? 0).toDouble(),
      sessionTotalPayments:
      (json['session_total_payments'] ?? 0).toDouble(),
      sessionBalance: (json['session_balance'] ?? 0).toDouble(),
      openingBalance: (json['opening_balance'] ?? 0).toDouble(),
      terms: termsMap,
    );
  }
}

class TermFee {
  final String termNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double openingBalance;
  final double totalFeesBeforeDiscount;
  final double totalFees;
  final double totalPayments;
  final double closingBalance;
  final List<FeeItem> fees;

  TermFee({
    required this.termNumber,
    required this.startDate,
    required this.endDate,
    required this.openingBalance,
    required this.totalFeesBeforeDiscount,
    required this.totalFees,
    required this.totalPayments,
    required this.closingBalance,
    required this.fees,
  });

  factory TermFee.fromJson(Map<String, dynamic> json) {
    return TermFee(
      termNumber: json['term_number'] ?? '',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ??
          DateTime.now(),
      openingBalance: (json['opening_balance'] ?? 0).toDouble(),
      totalFeesBeforeDiscount:
      (json['total_fees_before_discount'] ?? 0).toDouble(),
      totalFees: (json['total_fees'] ?? 0).toDouble(),
      totalPayments: (json['total_payments'] ?? 0).toDouble(),
      closingBalance: (json['closing_balance'] ?? 0).toDouble(),
      fees: (json['fees'] as List<dynamic>?)
          ?.map((x) => FeeItem.fromJson(x))
          .toList() ??
          [],
    );
  }
}

class FeeItem {
  final FeeCategory feeCategory;
  final String amount;
  final double discountAmount;
  final double netAmount;
  final List<dynamic> discountDetails;

  FeeItem({
    required this.feeCategory,
    required this.amount,
    required this.discountAmount,
    required this.netAmount,
    required this.discountDetails,
  });

  factory FeeItem.fromJson(Map<String, dynamic> json) {
    return FeeItem(
      feeCategory: FeeCategory.fromJson(json['feeCategory'] ?? {}),
      amount: json['amount'] ?? '0',
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      netAmount: (json['net_amount'] ?? 0).toDouble(),
      discountDetails: json['discount_details'] ?? [],
    );
  }
}

class FeeCategory {
  final String name;
  final String description;

  FeeCategory({
    required this.name,
    required this.description,
  });

  factory FeeCategory.fromJson(Map<String, dynamic> json) {
    return FeeCategory(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class AcademicSession {
  final int id;
  final String year;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final List<Term> terms;

  AcademicSession({
    required this.id,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.terms,
  });

  factory AcademicSession.fromJson(Map<String, dynamic> json) {
    return AcademicSession(
      id: json['id'] ?? 0,
      year: json['year'] ?? '',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ??
          DateTime.now(),
      status: json['status'] ?? '',
      terms: (json['terms'] as List<dynamic>?)
          ?.map((x) => Term.fromJson(x))
          .toList() ??
          [],
    );
  }
}

class Term {
  final int id;
  final int academicSessionId;
  final String termNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  Term({
    required this.id,
    required this.academicSessionId,
    required this.termNumber,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory Term.fromJson(Map<String, dynamic> json) {
    return Term(
      id: json['id'] ?? 0,
      academicSessionId: json['academic_session_id'] ?? 0,
      termNumber: json['term_number'] ?? '',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ??
          DateTime.now(),
      status: json['status'] ?? '',
    );
  }
}
