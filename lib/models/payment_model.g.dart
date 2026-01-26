// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentResponseAdapter extends TypeAdapter<PaymentResponse> {
  @override
  final int typeId = 0;

  @override
  PaymentResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentResponse(
      success: fields[0] as bool,
      message: fields[1] as String,
      data: (fields[2] as List).cast<Payment>(),
      pagination: fields[3] as Pagination,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentResponse obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.success)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.data)
      ..writeByte(3)
      ..write(obj.pagination);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 1;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as int,
      studentId: fields[1] as int,
      feeCategoryId: fields[2] as int?,
      accountId: fields[3] as int,
      transId: fields[4] as String,
      method: fields[5] as String,
      amount: fields[6] as double,
      balance: fields[7] as double?,
      paymentDate: fields[8] as DateTime,
      paymentType: fields[9] as String,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
      feeCategory: fields[12] as FeeCategory?,
      account: fields[13] as Account,
      student: fields[14] as Student,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.feeCategoryId)
      ..writeByte(3)
      ..write(obj.accountId)
      ..writeByte(4)
      ..write(obj.transId)
      ..writeByte(5)
      ..write(obj.method)
      ..writeByte(6)
      ..write(obj.amount)
      ..writeByte(7)
      ..write(obj.balance)
      ..writeByte(8)
      ..write(obj.paymentDate)
      ..writeByte(9)
      ..write(obj.paymentType)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt)
      ..writeByte(12)
      ..write(obj.feeCategory)
      ..writeByte(13)
      ..write(obj.account)
      ..writeByte(14)
      ..write(obj.student);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FeeCategoryAdapter extends TypeAdapter<FeeCategory> {
  @override
  final int typeId = 2;

  @override
  FeeCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeeCategory(
      id: fields[0] as int,
      schoolId: fields[1] as int,
      branchId: fields[2] as int,
      name: fields[3] as String,
      description: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FeeCategory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.schoolId)
      ..writeByte(2)
      ..write(obj.branchId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 3;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as int,
      branchId: fields[1] as int?,
      accountTypeId: fields[2] as int,
      parentId: fields[3] as int?,
      name: fields[4] as String,
      code: fields[5] as String,
      currencyCode: fields[6] as String,
      openingBalance: fields[7] as String,
      balanceType: fields[8] as String?,
      isSystemAccount: fields[9] as int,
      isActive: fields[10] as int,
      description: fields[11] as String?,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.branchId)
      ..writeByte(2)
      ..write(obj.accountTypeId)
      ..writeByte(3)
      ..write(obj.parentId)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.code)
      ..writeByte(6)
      ..write(obj.currencyCode)
      ..writeByte(7)
      ..write(obj.openingBalance)
      ..writeByte(8)
      ..write(obj.balanceType)
      ..writeByte(9)
      ..write(obj.isSystemAccount)
      ..writeByte(10)
      ..write(obj.isActive)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 4;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      id: fields[0] as int,
      classId: fields[1] as int,
      streamId: fields[2] as int,
      userId: fields[3] as int,
      schoolId: fields[4] as int,
      branchId: fields[5] as int,
      zoneId: fields[6] as int,
      termId: fields[7] as int,
      academicSessionId: fields[8] as int,
      estateId: fields[9] as int,
      admissionNo: fields[10] as String,
      dob: fields[11] as DateTime,
      branch: fields[31] as Branch,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(32)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.classId)
      ..writeByte(2)
      ..write(obj.streamId)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.schoolId)
      ..writeByte(5)
      ..write(obj.branchId)
      ..writeByte(6)
      ..write(obj.zoneId)
      ..writeByte(7)
      ..write(obj.termId)
      ..writeByte(8)
      ..write(obj.academicSessionId)
      ..writeByte(9)
      ..write(obj.estateId)
      ..writeByte(10)
      ..write(obj.admissionNo)
      ..writeByte(11)
      ..write(obj.dob)
      ..writeByte(12)
      ..writeByte(31)
      ..write(obj.branch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BranchAdapter extends TypeAdapter<Branch> {
  @override
  final int typeId = 5;

  @override
  Branch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Branch(
      id: fields[0] as int,
      schoolId: fields[1] as int,
      name: fields[2] as String,
      motto: fields[3] as String,
      address: fields[4] as String,
      contact: fields[5] as String,
      email: fields[6] as String,
      website: fields[7] as String?,
      smsBalance: fields[8] as String,
      smsPricing: fields[9] as String,
      paymentDetails: fields[10] as String,
      invoiceNotes: fields[11] as String,
      receiptNotes: fields[12] as String,
      kraPin: fields[13] as String?,
      admissionPrefix: fields[14] as String?,
      admissionSuffix: fields[15] as String?,
      juniorSecAdmissionPrefix: fields[16] as String?,
      highSchoolPrefix: fields[17] as String?,
      highSchoolDetails: fields[18] as String?,
      schoolLogo: fields[19] as String,
      accountStampLogo: fields[20] as String?,
      reportStampLogo: fields[21] as String?,
      juniorSecLogo: fields[22] as String?,
      highSchoolLogo: fields[23] as String?,
      primaryColor: fields[24] as String,
      secondaryColor: fields[25] as String,
      createdAt: fields[26] as DateTime,
      updatedAt: fields[27] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Branch obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.schoolId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.motto)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.contact)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.website)
      ..writeByte(8)
      ..write(obj.smsBalance)
      ..writeByte(9)
      ..write(obj.smsPricing)
      ..writeByte(10)
      ..write(obj.paymentDetails)
      ..writeByte(11)
      ..write(obj.invoiceNotes)
      ..writeByte(12)
      ..write(obj.receiptNotes)
      ..writeByte(13)
      ..write(obj.kraPin)
      ..writeByte(14)
      ..write(obj.admissionPrefix)
      ..writeByte(15)
      ..write(obj.admissionSuffix)
      ..writeByte(16)
      ..write(obj.juniorSecAdmissionPrefix)
      ..writeByte(17)
      ..write(obj.highSchoolPrefix)
      ..writeByte(18)
      ..write(obj.highSchoolDetails)
      ..writeByte(19)
      ..write(obj.schoolLogo)
      ..writeByte(20)
      ..write(obj.accountStampLogo)
      ..writeByte(21)
      ..write(obj.reportStampLogo)
      ..writeByte(22)
      ..write(obj.juniorSecLogo)
      ..writeByte(23)
      ..write(obj.highSchoolLogo)
      ..writeByte(24)
      ..write(obj.primaryColor)
      ..writeByte(25)
      ..write(obj.secondaryColor)
      ..writeByte(26)
      ..write(obj.createdAt)
      ..writeByte(27)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaginationAdapter extends TypeAdapter<Pagination> {
  @override
  final int typeId = 6;

  @override
  Pagination read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Pagination(
      total: fields[0] as int,
      perPage: fields[1] as int,
      currentPage: fields[2] as int,
      lastPage: fields[3] as int,
      from: fields[4] as int,
      to: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Pagination obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.total)
      ..writeByte(1)
      ..write(obj.perPage)
      ..writeByte(2)
      ..write(obj.currentPage)
      ..writeByte(3)
      ..write(obj.lastPage)
      ..writeByte(4)
      ..write(obj.from)
      ..writeByte(5)
      ..write(obj.to);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
