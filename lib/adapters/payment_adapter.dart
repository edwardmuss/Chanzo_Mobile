import 'package:hive/hive.dart';
import '../../models/payment_model.dart';

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 0; // Unique ID for this adapter

  @override
  Payment read(BinaryReader reader) {
    return Payment(
      id: reader.read(),
      studentId: reader.read(),
      feeCategoryId: reader.read(),
      accountId: reader.read(),
      transId: reader.read(),
      method: reader.read(),
      amount: reader.read(),
      paymentDate: DateTime.parse(reader.read()),
      createdAt: DateTime.parse(reader.read()),
      updatedAt: DateTime.parse(reader.read()),
      paymentType: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer.write(obj.id);
    writer.write(obj.studentId);
    writer.write(obj.feeCategoryId);
    writer.write(obj.accountId);
    writer.write(obj.transId);
    writer.write(obj.method);
    writer.write(obj.amount);
    writer.write(obj.paymentDate.toIso8601String());
    writer.write(obj.createdAt.toIso8601String());
    writer.write(obj.updatedAt.toIso8601String());
    writer.write(obj.paymentType);
  }
}